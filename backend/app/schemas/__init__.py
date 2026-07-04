from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models import BusinessStatus, ReviewStatus, Sentiment, UserRole


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserBase(BaseModel):
    email: EmailStr
    full_name: str


class UserRegister(UserBase):
    password: str = Field(min_length=8)
    role: UserRole = UserRole.CUSTOMER


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    role: UserRole
    is_active: bool
    avatar_url: str | None = None
    created_at: datetime


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
    phone: str | None = None
    email: str | None = None
    website: str | None = None
    business_hours: dict[str, Any] | None = None
    category_ids: list[UUID] = []


class BusinessUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    address: str | None = None
    city: str | None = None
    state: str | None = None
    postal_code: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    phone: str | None = None
    email: str | None = None
    website: str | None = None
    business_hours: dict[str, Any] | None = None
    category_ids: list[UUID] | None = None


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


class ReviewCreate(BaseModel):
    business_id: UUID
    rating: int = Field(ge=1, le=5)
    title: str | None = None
    body: str = Field(min_length=10)


class ReviewUpdate(BaseModel):
    rating: int | None = Field(default=None, ge=1, le=5)
    title: str | None = None
    body: str | None = Field(default=None, min_length=10)


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


class ReplyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    body: str
    created_at: datetime


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


class DashboardStats(BaseModel):
    total_reviews: int
    average_rating: float
    sentiment_breakdown: dict[str, int]
    recent_reviews: list[ReviewResponse]
    review_volume_by_month: list[dict[str, Any]]


class PlatformAnalytics(BaseModel):
    total_users: int
    total_businesses: int
    pending_businesses: int
    total_reviews: int
    reported_reviews: int


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    type: str
    title: str
    message: str
    is_read: bool
    extra_data: dict[str, Any] | None = None
    created_at: datetime


class MessageResponse(BaseModel):
    message: str


class OAuthCallbackRequest(BaseModel):
    provider: str
    code: str
    redirect_uri: str


class NearbyBusinessRequest(BaseModel):
    lat: float
    lng: float
    radius_km: float = 10.0
