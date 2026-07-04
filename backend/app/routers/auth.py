from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Merchant, User, UserRole
from app.schemas import (
    MessageResponse,
    OAuthCallbackRequest,
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: UserRegister, db: AsyncSession = Depends(get_db)) -> User:
    """
    Register a new user account.

    **Request:** email, full_name, password (min 8 chars), role (customer|merchant|admin blocked for public)
    **Response:** Created user profile (no tokens — login separately)
    **Errors:** 409 if email exists
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


@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """
    Authenticate with email and password.

    **Request:** email, password
    **Response:** JWT access_token + refresh_token
    **Errors:** 401 invalid credentials, 403 inactive account
    """
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account suspended")

    return TokenResponse(
        access_token=create_access_token(str(user.id), {"role": user.role.value}),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(refresh_token: str, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """
    Exchange a valid refresh token for new access + refresh tokens.

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

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    return TokenResponse(
        access_token=create_access_token(str(user.id), {"role": user.role.value}),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)) -> User:
    """Get the currently authenticated user. Requires Bearer token."""
    return current_user


@router.post("/oauth/callback", response_model=TokenResponse)
async def oauth_callback(payload: OAuthCallbackRequest) -> TokenResponse:
    """
    OAuth placeholder — simulates successful Google/GitHub login.

    **Request:** provider, code, redirect_uri
    **Response:** Mock JWT tokens (replace with real OAuth exchange in production)
    """
    if not payload.code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Authorization code required")

    mock_user_id = "00000000-0000-0000-0000-000000000001"
    return TokenResponse(
        access_token=create_access_token(mock_user_id, {"role": "customer", "oauth": payload.provider}),
        refresh_token=create_refresh_token(mock_user_id),
    )


@router.post("/logout", response_model=MessageResponse)
async def logout() -> MessageResponse:
    """
    Logout placeholder — client should discard tokens.
    In production, add token blocklist via Redis.
    """
    return MessageResponse(message="Logged out successfully. Discard tokens on client.")
