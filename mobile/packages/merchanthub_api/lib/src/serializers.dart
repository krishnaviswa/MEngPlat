//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:merchanthub_api/src/date_serializer.dart';
import 'package:merchanthub_api/src/model/date.dart';

import 'package:merchanthub_api/src/model/ai_analysis_response.dart';
import 'package:merchanthub_api/src/model/business_create.dart';
import 'package:merchanthub_api/src/model/business_response.dart';
import 'package:merchanthub_api/src/model/business_status.dart';
import 'package:merchanthub_api/src/model/business_update.dart';
import 'package:merchanthub_api/src/model/category_create.dart';
import 'package:merchanthub_api/src/model/category_response.dart';
import 'package:merchanthub_api/src/model/dashboard_stats.dart';
import 'package:merchanthub_api/src/model/favorite_create.dart';
import 'package:merchanthub_api/src/model/favorite_response.dart';
import 'package:merchanthub_api/src/model/geocode_response.dart';
import 'package:merchanthub_api/src/model/google_auth_request.dart';
import 'package:merchanthub_api/src/model/http_validation_error.dart';
import 'package:merchanthub_api/src/model/location_inner.dart';
import 'package:merchanthub_api/src/model/login_result.dart';
import 'package:merchanthub_api/src/model/logout_request.dart';
import 'package:merchanthub_api/src/model/merchant_insights_response.dart';
import 'package:merchanthub_api/src/model/message_response.dart';
import 'package:merchanthub_api/src/model/mfa_token_request.dart';
import 'package:merchanthub_api/src/model/mfa_totp_code_request.dart';
import 'package:merchanthub_api/src/model/national_id_type.dart';
import 'package:merchanthub_api/src/model/nearby_business_request.dart';
import 'package:merchanthub_api/src/model/notification_response.dart';
import 'package:merchanthub_api/src/model/photo_response.dart';
import 'package:merchanthub_api/src/model/platform_analytics.dart';
import 'package:merchanthub_api/src/model/public_platform_stats.dart';
import 'package:merchanthub_api/src/model/reply_create.dart';
import 'package:merchanthub_api/src/model/reply_response.dart';
import 'package:merchanthub_api/src/model/review_create.dart';
import 'package:merchanthub_api/src/model/review_report_create.dart';
import 'package:merchanthub_api/src/model/review_response.dart';
import 'package:merchanthub_api/src/model/review_status.dart';
import 'package:merchanthub_api/src/model/review_update.dart';
import 'package:merchanthub_api/src/model/sentiment.dart';
import 'package:merchanthub_api/src/model/token_response.dart';
import 'package:merchanthub_api/src/model/totp_setup_response.dart';
import 'package:merchanthub_api/src/model/user_login.dart';
import 'package:merchanthub_api/src/model/user_profile_update.dart';
import 'package:merchanthub_api/src/model/user_register.dart';
import 'package:merchanthub_api/src/model/user_response.dart';
import 'package:merchanthub_api/src/model/user_role.dart';
import 'package:merchanthub_api/src/model/validation_error.dart';

part 'serializers.g.dart';

@SerializersFor([
  AIAnalysisResponse,
  BusinessCreate,
  BusinessResponse,
  BusinessStatus,
  BusinessUpdate,
  CategoryCreate,
  CategoryResponse,
  DashboardStats,
  FavoriteCreate,
  FavoriteResponse,
  GeocodeResponse,
  GoogleAuthRequest,
  HTTPValidationError,
  LocationInner,
  LoginResult,
  LogoutRequest,
  MerchantInsightsResponse,
  MessageResponse,
  MfaTokenRequest,
  MfaTotpCodeRequest,
  NationalIdType,
  NearbyBusinessRequest,
  NotificationResponse,
  PhotoResponse,
  PlatformAnalytics,
  PublicPlatformStats,
  ReplyCreate,
  ReplyResponse,
  ReviewCreate,
  ReviewReportCreate,
  ReviewResponse,
  ReviewStatus,
  ReviewUpdate,
  Sentiment,
  TokenResponse,
  TotpSetupResponse,
  UserLogin,
  UserProfileUpdate,
  UserRegister,
  UserResponse,
  UserRole,
  ValidationError,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(BusinessResponse)]),
        () => ListBuilder<BusinessResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ReviewResponse)]),
        () => ListBuilder<ReviewResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PhotoResponse)]),
        () => ListBuilder<PhotoResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(CategoryResponse)]),
        () => ListBuilder<CategoryResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(NotificationResponse)]),
        () => ListBuilder<NotificationResponse>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
