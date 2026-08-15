from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.rate_limit import limiter
from app.core.security import (
    create_access_token,
    create_mfa_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.database import get_db
from app.dependencies import get_current_user, security
from app.models import Merchant, User, UserRole
from app.schemas import (
    ForgotPasswordRequest,
    GoogleAuthRequest,
    LoginResult,
    LogoutRequest,
    MessageResponse,
    MfaTokenRequest,
    MfaTotpCodeRequest,
    ResetPasswordRequest,
    TokenResponse,
    TotpSetupResponse,
    UserLogin,
    UserProfileUpdate,
    UserRegister,
    UserResponse,
)
from app.services.cache import (
    blocklist_token,
    clear_login_failures,
    get_redis,
    is_login_locked,
    is_token_blocklisted,
    record_login_failure,
)
from app.services.email import try_send_password_reset
from app.services.google_auth import InvalidGoogleTokenError, verify_google_id_token
from app.services.mfa import (
    build_otpauth_uri,
    decrypt_totp_secret,
    encrypt_totp_secret,
    generate_totp_secret,
    qr_svg_for_uri,
    verify_totp_code,
)
from app.services.password_reset import consume_reset_token, create_reset_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

# One string for known and unknown addresses -- no extra account enumeration
# compared with today's login (technical spec AC 2).
FORGOT_PASSWORD_GENERIC_MESSAGE = "If an account exists for that email, we sent password-reset instructions."


def _issue_session_tokens(user: User) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(str(user.id), {"role": user.role.value}),
        refresh_token=create_refresh_token(str(user.id)),
    )


async def _user_from_mfa_token(
    mfa_token: str,
    *,
    purpose: str,
    db: AsyncSession,
) -> User:
    try:
        payload = decode_token(mfa_token)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid MFA token") from exc
    if payload.get("type") != "mfa" or payload.get("purpose") != purpose:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid MFA token")
    jti = payload.get("jti")
    if jti and await is_token_blocklisted(jti):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="MFA token has been revoked")
    result = await db.execute(select(User).where(User.id == payload["sub"]))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user


async def _consume_mfa_token(mfa_token: str) -> None:
    """Blocklist MFA jti after successful use so it cannot be replayed."""
    try:
        payload = decode_token(mfa_token)
    except ValueError:
        return
    jti, exp = payload.get("jti"), payload.get("exp")
    if jti and exp:
        await blocklist_token(jti, exp)


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register(request: Request, payload: UserRegister, db: AsyncSession = Depends(get_db)) -> User:
    """
    Register a new user account.

    **Request:** email, full_name, password (min 12 chars, at least one letter and one digit), role (customer|merchant|admin blocked for public)
    **Response:** Created user profile (no tokens — login separately; password login requires TOTP enrollment)
    **Errors:** 409 if email exists, 422 if password policy fails, 429 if rate-limited (5/minute per IP)
    """
    if payload.role == UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot self-register as admin")

    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    user = User(
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=get_password_hash(payload.password),
        role=payload.role,
    )
    db.add(user)
    await db.flush()

    if payload.role == UserRole.MERCHANT:
        db.add(Merchant(user_id=user.id))

    await db.refresh(user)
    return user


@router.post("/login", response_model=LoginResult)
@limiter.limit("10/minute")
async def login(request: Request, payload: UserLogin, db: AsyncSession = Depends(get_db)) -> LoginResult:
    """
    Authenticate with email and password.

    **Request:** email, password
    **Response:** Either JWT tokens (should not happen for password accounts without TOTP),
    or `{ mfa_required, mfa_token }` / `{ mfa_enrollment_required, mfa_token }` for TOTP.
    **Errors:** 400 account is Google-only (no password set), 401 invalid credentials, 403 inactive,
    429 if rate-limited (10/minute per IP) -- bcrypt makes each attempt expensive, so this also
    caps CPU spent on credential stuffing, not just attempt count. After 5 failed password
    attempts for the same email, Redis lockout applies for 15 minutes (best-effort; skipped
    if Redis is unreachable).
    """
    if await is_login_locked(payload.email):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many failed login attempts. Try again later.",
        )

    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if user and user.hashed_password is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account uses Google sign-in. Continue with Google instead.",
        )
    if not user or not verify_password(payload.password, user.hashed_password):
        locked = await record_login_failure(payload.email)
        if locked:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed login attempts. Try again later.",
            )
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account suspended")

    await clear_login_failures(payload.email)

    # Password accounts must complete authenticator MFA before receiving session tokens.
    if user.totp_enabled:
        return LoginResult(
            mfa_required=True,
            mfa_token=create_mfa_token(str(user.id), "verify"),
        )
    return LoginResult(
        mfa_enrollment_required=True,
        mfa_token=create_mfa_token(str(user.id), "enroll"),
    )


@router.post("/forgot-password", response_model=MessageResponse)
@limiter.limit("5/minute")
async def forgot_password(
    request: Request, payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)
) -> MessageResponse:
    """
    Request a password-reset email. Always returns the same generic message,
    whether or not the address is registered -- the response never confirms
    account existence (ADR-007).

    **Request:** email
    **Response:** Always 200, generic confirmation copy
    **Errors:** 422 invalid email shape, 429 rate-limited (5/minute per IP),
    503 Redis unreachable (cannot store a hashed token -- fails closed before
    the account lookup, so the 503 itself does not distinguish known vs
    unknown addresses)
    """
    try:
        redis_client = await get_redis()
        await redis_client.ping()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Try again shortly"
        ) from exc

    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    # Google-only accounts (hashed_password is None) have no password to reset.
    if user and user.hashed_password is not None:
        token = await create_reset_token(str(user.id))
        await try_send_password_reset(user.email, token)

    return MessageResponse(message=FORGOT_PASSWORD_GENERIC_MESSAGE)


@router.post("/reset-password", response_model=MessageResponse)
@limiter.limit("5/minute")
async def reset_password(
    request: Request, payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)
) -> MessageResponse:
    """
    Complete a password reset with a token from the reset email.

    **Request:** token, new_password (min 12 chars, at least one letter and
    one digit -- same policy as register)
    **Response:** Confirmation message. No session tokens are issued -- sign
    in still requires TOTP (ADR-001).
    **Errors:** 422 password policy, 400 invalid/expired/already-used token
    (generic, does not distinguish which), 429 rate-limited (5/minute per
    IP), 503 Redis unreachable
    """
    try:
        user_id = await consume_reset_token(payload.token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Try again shortly"
        ) from exc

    if user_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset link")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset link")

    user.hashed_password = get_password_hash(payload.new_password)
    await db.flush()

    return MessageResponse(message="Password updated. Sign in with your new password.")


@router.post("/mfa/totp/setup", response_model=TotpSetupResponse)
async def totp_setup(payload: MfaTokenRequest, db: AsyncSession = Depends(get_db)) -> TotpSetupResponse:
    """
    Start TOTP enrollment after password login (mfa_enrollment_required).
    Returns otpauth URI, manual secret, and QR SVG for the authenticator app.
    """
    user = await _user_from_mfa_token(payload.mfa_token, purpose="enroll", db=db)
    if user.totp_enabled:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Authenticator already enabled")

    secret = generate_totp_secret()
    user.totp_secret = encrypt_totp_secret(secret)
    user.totp_enabled = False
    await db.flush()

    uri = build_otpauth_uri(secret, user.email)
    return TotpSetupResponse(otpauth_uri=uri, secret=secret, qr_svg=qr_svg_for_uri(uri))


@router.post("/mfa/totp/confirm", response_model=TokenResponse)
async def totp_confirm(payload: MfaTotpCodeRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """Confirm TOTP enrollment with a first code from the authenticator app; issues session tokens."""
    user = await _user_from_mfa_token(payload.mfa_token, purpose="enroll", db=db)
    if not user.totp_secret:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Call /mfa/totp/setup first")
    if user.totp_enabled:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Authenticator already enabled")

    try:
        secret = decrypt_totp_secret(user.totp_secret)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid TOTP secret") from exc

    if not verify_totp_code(secret, payload.code):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authenticator code")

    user.totp_enabled = True
    await db.flush()
    await _consume_mfa_token(payload.mfa_token)
    await clear_login_failures(user.email)
    return _issue_session_tokens(user)


@router.post("/mfa/totp/verify", response_model=TokenResponse)
async def totp_verify(payload: MfaTotpCodeRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """Complete password login by verifying the authenticator code; issues session tokens."""
    user = await _user_from_mfa_token(payload.mfa_token, purpose="verify", db=db)
    if not user.totp_enabled or not user.totp_secret:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Authenticator not enabled")

    try:
        secret = decrypt_totp_secret(user.totp_secret)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid TOTP secret") from exc

    if not verify_totp_code(secret, payload.code):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authenticator code")

    await _consume_mfa_token(payload.mfa_token)
    await clear_login_failures(user.email)
    return _issue_session_tokens(user)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(refresh_token: str, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """
    Exchange a valid refresh token for a new access + refresh pair. The presented
    refresh token's jti is blocklisted so it cannot be reused (rotation).

    **Request:** refresh_token (query/body depending on client)
    **Response:** New token pair
    """
    try:
        payload = decode_token(refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
        user_id = payload["sub"]
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token") from exc

    jti = payload.get("jti")
    if jti and await is_token_blocklisted(jti):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has been revoked")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    exp = payload.get("exp")
    if jti and exp:
        await blocklist_token(jti, exp)

    return _issue_session_tokens(user)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)) -> User:
    """Get the currently authenticated user. Requires Bearer token."""
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    payload: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Update the caller's own profile (name, avatar, phone, address, national ID).
    email, role, is_active, and TOTP fields are not on the schema and are silently ignored if sent.
    """
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)
    await db.flush()
    await db.refresh(current_user)
    return current_user


@router.post("/google", response_model=TokenResponse)
async def google_auth(payload: GoogleAuthRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """
    Sign in (or register) with Google. ID-token flow: the frontend obtains a
    signed credential from Google Identity Services client-side and sends it
    here for verification -- no authorization code, no redirect_uri, no
    client secret on this side.

    Google path does **not** require TOTP (Gmail identity is the alternate factor).

    **Request:** credential — the ID token JWT from Google's sign-in button
    **Response:** JWT access_token + refresh_token
    **Errors:** 401 invalid/expired Google token, 403 email already registered
    and not Google-verified (link rejected — take over risk), inactive account
    """
    settings = get_settings()
    try:
        identity = await verify_google_id_token(payload.credential, settings.google_client_id)
    except InvalidGoogleTokenError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token") from exc

    result = await db.execute(select(User).where(User.google_sub == identity.sub))
    user = result.scalar_one_or_none()

    if not user:
        email_result = await db.execute(select(User).where(User.email == identity.email))
        existing = email_result.scalar_one_or_none()
        if existing:
            if not identity.email_verified:
                # Google itself won't vouch for this email, so linking it to
                # an existing account would let anyone claim that account by
                # signing up for Google mail they don't control.
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="An account with this email already exists. Sign in with your password instead.",
                )
            existing.google_sub = identity.sub
            existing.email_verified = True
            if not existing.avatar_url and identity.picture:
                existing.avatar_url = identity.picture
            user = existing
        else:
            user = User(
                email=identity.email,
                full_name=identity.name,
                hashed_password=None,
                role=UserRole.CUSTOMER,
                auth_provider="google",
                google_sub=identity.sub,
                email_verified=identity.email_verified,
                avatar_url=identity.picture,
            )
            db.add(user)
            await db.flush()

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account suspended")

    return _issue_session_tokens(user)


@router.post("/logout", response_model=MessageResponse)
async def logout(
    payload: LogoutRequest | None = None,
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> MessageResponse:
    """
    Logout: blocklist the caller's access token in Redis (and its refresh
    token, if supplied), so both stop working immediately instead of
    lingering until their natural expiry.

    **Request:** `Authorization: Bearer <access_token>` header (required);
    optional JSON body `{"refresh_token": "..."}` to also revoke a refresh
    token
    **Response:** confirmation message
    **Errors:** 401 if the Authorization header is missing or not a valid
    access token
    """
    if not credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    try:
        access_payload = decode_token(credentials.credentials)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc
    if access_payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

    jti, exp = access_payload.get("jti"), access_payload.get("exp")
    if jti and exp:
        await blocklist_token(jti, exp)

    refresh_token = payload.refresh_token if payload else None
    if refresh_token:
        try:
            refresh_payload = decode_token(refresh_token)
        except ValueError:
            refresh_payload = None
        if refresh_payload and refresh_payload.get("type") == "refresh":
            r_jti, r_exp = refresh_payload.get("jti"), refresh_payload.get("exp")
            if r_jti and r_exp:
                await blocklist_token(r_jti, r_exp)

    return MessageResponse(message="Logged out successfully.")
