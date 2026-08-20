import re
from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models import BusinessStatus, DraftStatus, NationalIdType, ReviewStatus, Sentiment, UserRole

_PAN_RE = re.compile(r"^[A-Z]{5}[0-9]{4}[A-Z]{1}$")
_AADHAAR_RE = re.compile(r"^\d{12}$")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class LoginResult(BaseModel):
    """Password login: either full tokens, or an MFA challenge / enrollment gate."""

    access_token: str | None = None
    refresh_token: str | None = None
    token_type: str = "bearer"
    mfa_required: bool = False
    mfa_enrollment_required: bool = False
    mfa_token: str | None = None


class MfaTokenRequest(BaseModel):
    mfa_token: str


class MfaTotpCodeRequest(BaseModel):
    mfa_token: str
    code: str = Field(min_length=6, max_length=8)


class TotpSetupResponse(BaseModel):
    otpauth_uri: str
    secret: str
    qr_svg: str


class LogoutRequest(BaseModel):
    refresh_token: str | None = None


class UserBase(BaseModel):
    email: EmailStr
    full_name: str


def _require_letter_and_digit(value: str) -> str:
    if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
        raise ValueError("Password must contain at least one letter and one digit")
    return value


class UserRegister(UserBase):
    password: str = Field(min_length=12)
    role: UserRole = UserRole.CUSTOMER

    @field_validator("password")
    @classmethod
    def password_complexity(cls, value: str) -> str:
        return _require_letter_and_digit(value)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=12)

    @field_validator("new_password")
    @classmethod
    def password_complexity(cls, value: str) -> str:
        return _require_letter_and_digit(value)


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr | None = None
    full_name: str
    role: UserRole
    is_active: bool
    avatar_url: str | None = None
    phone: str | None = None
    address_line1: str | None = None
    address_line2: str | None = None
    city: str | None = None
    state: str | None = None
    postal_code: str | None = None
    country: str | None = None
    national_id_type: NationalIdType | None = None
    national_id_number: str | None = None
    auth_provider: str = "password"
    totp_enabled: bool = False
    created_at: datetime


class UserProfileUpdate(BaseModel):
    """Self-service PATCH /auth/me. role, is_active, and TOTP secrets are omitted.
    `email` is applied only when a valid `reauth_token` is supplied. Merchant
    phone and national ID changes also require that token (S-114)."""

    full_name: str | None = Field(default=None, min_length=1, max_length=255)
    email: EmailStr | None = None
    avatar_url: str | None = None
    phone: str | None = Field(default=None, max_length=50)
    address_line1: str | None = Field(default=None, max_length=255)
    address_line2: str | None = Field(default=None, max_length=255)
    city: str | None = Field(default=None, max_length=100)
    state: str | None = Field(default=None, max_length=100)
    postal_code: str | None = Field(default=None, max_length=20)
    country: str | None = Field(default=None, max_length=100)
    national_id_type: NationalIdType | None = None
    national_id_number: str | None = Field(default=None, max_length=64)

    @field_validator("national_id_number")
    @classmethod
    def _validate_national_id(cls, v: str | None, info: Any) -> str | None:
        id_type = info.data.get("national_id_type")
        if v and id_type == NationalIdType.PAN and not _PAN_RE.match(v.strip().upper()):
            raise ValueError("PAN must be 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F)")
        if v and id_type == NationalIdType.AADHAAR and not _AADHAAR_RE.match(v.strip()):
            raise ValueError("Aadhaar must be exactly 12 digits")
        return v


class MockAadhaarOtpRequest(BaseModel):
    aadhaar_number: str = Field(max_length=64)

    @field_validator("aadhaar_number")
    @classmethod
    def _validate_aadhaar(cls, v: str) -> str:
        if not _AADHAAR_RE.match(v.strip()):
            raise ValueError("Aadhaar must be exactly 12 digits")
        return v.strip()


class MockOtpVerifyRequest(BaseModel):
    code: str = Field(min_length=6, max_length=6)


class MockAadhaarOtpResponse(BaseModel):
    message: str
    dev_code: str | None = None


class PublicPlatformStats(BaseModel):
    """Public home-page counts — deliberately excludes admin-only fields."""

    total_businesses: int
    total_reviews: int
    total_categories: int
    total_cities: int


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    description: str | None = None
    icon: str | None = None


class CategoryCreate(BaseModel):
    name: str
    slug: str
    description: str | None = None
    icon: str | None = None


class BusinessCreate(BaseModel):
    name: str
    description: str | None = None
    address: str
    city: str
    state: str | None = None
    postal_code: str | None = None
    country: str = "US"
    latitude: float | None = None
    longitude: float | None = None
    phone: str
    email: EmailStr
    website: str | None = None
    business_hours: dict[str, Any] | None = None
    category_ids: list[UUID] = []

    @field_validator("phone")
    @classmethod
    def _phone_format(cls, v: str) -> str:
        # Loose E.164-ish check -- an optional leading "+" then 7-15 digits --
        # deliberately permissive so valid international numbers aren't rejected.
        if not re.fullmatch(r"\+?\d{7,15}", v.strip()):
            raise ValueError("Enter a valid phone number.")
        return v.strip()


class BusinessUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    address: str | None = None
    city: str | None = None
    state: str | None = None
    postal_code: str | None = None
    country: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    phone: str | None = None
    email: str | None = None
    website: str | None = None
    business_hours: dict[str, Any] | None = None
    category_ids: list[UUID] | None = None
    # S-073: required only when this business's address_edit_count >= 1 and the
    # payload changes an address-bearing field.
    address_otp_code: str | None = None


class BusinessResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    description: str | None = None
    address: str
    city: str
    state: str | None = None
    postal_code: str | None = None
    country: str
    latitude: float | None = None
    longitude: float | None = None
    phone: str | None = None
    email: str | None = None
    website: str | None = None
    logo_url: str | None = None
    storefront_url: str | None = None
    business_hours: dict[str, Any] | None = None
    status: BusinessStatus
    average_rating: float
    review_count: int
    ai_merchant_summary: str | None = None
    categories: list[CategoryResponse] = []
    is_featured: bool = False


class ReviewCreate(BaseModel):
    business_id: UUID
    rating: int = Field(ge=1, le=5)
    title: str | None = None
    body: str = Field(min_length=1)


class ReviewUpdate(BaseModel):
    rating: int | None = Field(default=None, ge=1, le=5)
    title: str | None = None
    body: str | None = Field(default=None, min_length=1)


class AIAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    analysis_type: str
    sentiment: Sentiment | None = None
    summary: str | None = None
    positives: list[str] | None = None
    complaints: list[str] | None = None
    suggested_response: str | None = None
    image_insights: dict[str, Any] | None = None
    provider: str
    # True when the configured AI provider failed and this analysis was served
    # by the fallback instead -- lets the frontend distinguish real analysis
    # from a plausible-looking fabricated stand-in.
    degraded: bool = False


class ReplyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    body: str
    created_at: datetime


class BusinessSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    city: str | None = None
    status: BusinessStatus


class ReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    author_id: UUID
    rating: int
    title: str | None = None
    body: str
    status: ReviewStatus
    like_count: int
    created_at: datetime
    author: UserResponse | None = None
    ai_analysis: AIAnalysisResponse | None = None
    reply: ReplyResponse | None = None
    photo_urls: list[str] = []
    business: BusinessSummary | None = None


class ReplyCreate(BaseModel):
    body: str = Field(min_length=5)


class ReviewReportCreate(BaseModel):
    reason: str = Field(min_length=10)


class PhotoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    url: str
    caption: str | None = None
    photo_type: str
    ai_analysis: AIAnalysisResponse | None = None


class SearchParams(BaseModel):
    q: str | None = None
    city: str | None = None
    category: str | None = None
    min_rating: float | None = None
    sentiment: Sentiment | None = None
    lat: float | None = None
    lng: float | None = None
    radius_km: float = 10.0
    page: int = 1
    page_size: int = 20


class MerchantInsightsResponse(BaseModel):
    business_id: UUID
    merchant_summary: str | None
    frequently_mentioned_positives: list[str]
    frequently_mentioned_complaints: list[str]
    suggested_responses: list[str]
    monthly_trends: list[dict[str, Any]]
    sentiment_breakdown: dict[str, int]
    degraded: bool = False


class TopicItem(BaseModel):
    label: str
    count: int
    sentiment: Literal["positive", "negative", "mixed"]
    example_quote: str


class TopicClusterResponse(BaseModel):
    business_id: UUID
    topics: list[TopicItem] = []
    degraded: bool = False
    insufficient_data: bool = False
    unavailable: bool = False


class BenchmarkResponse(BaseModel):
    business_id: UUID
    own_rating: float
    category_median: float | None = None
    city_median: float | None = None
    category_sample_size: int
    city_sample_size: int
    disclaimer: str


class DashboardStats(BaseModel):
    total_reviews: int
    average_rating: float
    sentiment_breakdown: dict[str, int]
    recent_reviews: list[ReviewResponse]
    review_volume_by_month: list[dict[str, Any]]
    rating_distribution: dict[str, int]
    reply_rate: float | None = None
    review_count_in_range: int | None = None
    review_count_previous: int | None = None
    reply_rate_previous: float | None = None


class PlatformAnalytics(BaseModel):
    total_users: int
    total_businesses: int
    pending_businesses: int
    total_reviews: int
    reported_reviews: int
    open_support_tickets: int = 0
    repeat_shop_reports: int = 0
    processing_businesses: int = 0


class PlatformAnalyticsSeries(BaseModel):
    granularity: Literal["day", "week"]
    days: int
    series: dict[str, list[dict[str, Any]]]


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    type: str
    title: str
    message: str
    is_read: bool
    scenario: str | None = None
    extra_data: dict[str, Any] | None = None
    created_at: datetime


class MessageResponse(BaseModel):
    message: str


class ReauthRequest(BaseModel):
    """Exactly one of: password, totp_code, phone+otp_code, or Google credential."""

    password: str | None = None
    totp_code: str | None = Field(default=None, max_length=16)
    phone: str | None = Field(default=None, max_length=20)
    otp_code: str | None = Field(default=None, max_length=16)
    credential: str | None = None


class ReauthResponse(BaseModel):
    reauth_token: str


class PhoneOtpRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)


class PhoneOtpVerifyRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    code: str = Field(min_length=4, max_length=8)
    full_name: str | None = Field(default=None, max_length=255)
    role: UserRole | None = None


class GoogleAuthRequest(BaseModel):
    # The ID token JWT ("credential") returned client-side by Google Identity
    # Services -- not an authorization code, so there's no redirect_uri or
    # client secret involved on this side at all.
    credential: str


class GoogleConfigResponse(BaseModel):
    """Public Web OAuth client ID (same value already shipped in the Next.js bundle)."""

    client_id: str = ""


class NearbyBusinessRequest(BaseModel):
    lat: float
    lng: float
    radius_km: float = 10.0


class FavoriteCreate(BaseModel):
    business_id: UUID


class FavoriteResponse(BaseModel):
    favorited: bool
    business_id: UUID


class FeaturedCheckoutRequest(BaseModel):
    business_id: UUID
    sku_code: str


class FeaturedSku(BaseModel):
    code: str
    duration_days: int
    listed_price_inr: int
    amount_paise: int | None = None


class CheckoutFields(BaseModel):
    key_id: str
    order_id: str
    amount: int
    currency: str
    name: str
    description: str
    prefill: dict[str, str] = {}


class FeaturedCheckoutResponse(BaseModel):
    payment_id: UUID
    provider: str
    provider_order_id: str
    amount_paise: int
    currency: str
    sku: FeaturedSku
    checkout: CheckoutFields


class WebhookAck(BaseModel):
    ok: bool = True
    duplicate: bool = False


class MockCompleteRequest(BaseModel):
    provider_order_id: str
    outcome: str = Field(pattern="^(paid|failed)$")


class PlacementWindow(BaseModel):
    id: UUID
    starts_at: datetime
    ends_at: datetime
    disabled_at: datetime | None = None
    payment_id: UUID


class PaymentLedger(BaseModel):
    id: UUID
    status: str
    amount_paise: int
    currency: str
    sku_code: str | None = None
    duration_days: int | None = None
    platform_fee_paise: int | None = None
    gateway_fee_paise: int | None = None
    provider: str
    provider_order_id: str
    created_at: datetime
    approved_at: datetime | None = None
    rejected_at: datetime | None = None


class PlacementResponse(BaseModel):
    business_id: UUID
    active: bool
    placement: PlacementWindow | None = None
    sku: FeaturedSku
    skus: list[FeaturedSku] = []
    awaiting_approval: bool = False
    payment: PaymentLedger | None = None


class AdminPaymentRow(BaseModel):
    id: UUID
    status: str
    amount_paise: int
    currency: str
    sku_code: str
    duration_days: int
    provider: str
    provider_order_id: str
    created_at: datetime
    approved_at: datetime | None = None
    rejected_at: datetime | None = None
    platform_fee_paise: int | None = None
    gateway_fee_paise: int | None = None
    business_id: UUID
    business_name: str
    merchant_user_id: UUID
    merchant_email: str
    merchant_name: str
    merchant_payment_count: int
    awaiting_approval: bool


class PaymentApproveResponse(BaseModel):
    id: UUID
    approved_at: datetime
    placement_id: UUID
    ends_at: datetime


class PaymentRejectResponse(BaseModel):
    id: UUID
    rejected_at: datetime


class PlacementDisableResponse(BaseModel):
    id: UUID
    disabled_at: datetime


class PaymentRefundResponse(BaseModel):
    id: UUID
    status: str


# --- S-048 review aggregator (Google Places) ---------------------------------


class GooglePlaceCandidateResponse(BaseModel):
    place_id: str
    name: str
    address: str
    latitude: float
    longitude: float


class GooglePlacesSearchRequest(BaseModel):
    query: str = Field(min_length=2)


class GooglePlacesSearchResponse(BaseModel):
    candidates: list[GooglePlaceCandidateResponse]


class GoogleReviewsStatusResponse(BaseModel):
    linked: bool
    place_id: str | None = None
    review_count: int
    last_synced_at: datetime | None = None


class GooglePlaceLinkRequest(BaseModel):
    place_id: str
    # UI-confirmation echoes only -- not persisted.
    name: str | None = None
    address: str | None = None


class GooglePlaceLinkResponse(BaseModel):
    linked: bool
    place_id: str


class GoogleReviewsSyncResponse(BaseModel):
    synced_count: int
    last_synced_at: datetime
    debounced: bool


class ExternalReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    author_name: str
    author_photo_url: str | None = None
    rating: int
    body: str | None = None
    source: str
    source_url: str | None = None
    external_posted_at: datetime | None = None


class WhatsAppLinkResponse(BaseModel):
    available: bool
    wa_url: str | None = None
    token: str | None = None
    expires_at: datetime | None = None
    display_number: str | None = None


class WhatsAppDraftResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    source: str
    extracted_fields: dict[str, Any]
    status: DraftStatus
    degraded: bool = False
    created_at: datetime


class AdminWhatsAppDraftResponse(WhatsAppDraftResponse):
    """Same as WhatsAppDraftResponse plus the business context an admin needs (S-053)."""

    business_id: UUID
    business_name: str


class AdminWhatsAppDraftQueueResponse(BaseModel):
    items: list[AdminWhatsAppDraftResponse]
    total: int
    page: int
    page_size: int


class AdminWhatsAppDraftApproveRequest(BaseModel):
    """Optional admin-edited field values; omitted keys fall back to the AI extraction (S-053)."""

    fields: dict[str, Any] | None = None


class WhatsAppWebhookAck(BaseModel):
    ok: bool = True
    processed: int = 0


class SupportContactResponse(BaseModel):
    email: str
    support_path: str = "/support"


class SupportTicketCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    phone: str = Field(min_length=8, max_length=50)
    issue: str = Field(min_length=10, max_length=4000)
    business_id: UUID | None = None


class SupportTicketResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    phone: str
    issue: str
    business_id: UUID | None = None
    reporter_id: UUID | None = None
    status: str
    admin_response: str | None = None
    created_at: datetime
    updated_at: datetime


class SupportTicketAdminUpdate(BaseModel):
    status: str | None = None
    admin_response: str | None = Field(default=None, max_length=4000)


class BusinessReportCreate(BaseModel):
    reason: str = Field(min_length=10, max_length=4000)


class BusinessReportMessageCreate(BaseModel):
    body: str = Field(min_length=1, max_length=4000)


class BusinessReportMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    report_id: UUID
    author_id: UUID
    body: str
    created_at: datetime


class BusinessReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    reporter_id: UUID
    reason: str
    status: str
    created_at: datetime
    updated_at: datetime
    business_name: str | None = None
    messages: list[BusinessReportMessageResponse] = Field(default_factory=list)
    report_count: int | None = None
    is_repeat: bool = False


class BusinessReportAdminUpdate(BaseModel):
    status: str
