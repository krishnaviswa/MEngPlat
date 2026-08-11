import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for BusinessesApi
void main() {
  final instance = MerchanthubApi().getBusinessesApi();

  group(BusinessesApi, () {
    // Approve Business
    //
    // Admin: approve a pending business.
    //
    //Future<BusinessResponse> approveBusinessApiV1BusinessesBusinessIdApprovePost(String businessId) async
    test('test approveBusinessApiV1BusinessesBusinessIdApprovePost', () async {
      // TODO
    });

    // Create Business
    //
    // Register a new business (merchant only). Status starts as pending.
    //
    //Future<BusinessResponse> createBusinessApiV1BusinessesPost(BusinessCreate businessCreate) async
    test('test createBusinessApiV1BusinessesPost', () async {
      // TODO
    });

    // Create Category
    //
    // Admin: create a new category.
    //
    //Future<CategoryResponse> createCategoryApiV1BusinessesCategoriesPost(CategoryCreate categoryCreate) async
    test('test createCategoryApiV1BusinessesCategoriesPost', () async {
      // TODO
    });

    // Get Business
    //
    // Get business profile by slug.
    //
    //Future<BusinessResponse> getBusinessApiV1BusinessesSlugGet(String slug) async
    test('test getBusinessApiV1BusinessesSlugGet', () async {
      // TODO
    });

    // List Businesses
    //
    // List businesses with optional city filter. Non-approved status filters require admin.
    //
    //Future<BuiltList<BusinessResponse>> listBusinessesApiV1BusinessesGet({ String city, BusinessStatus statusFilter }) async
    test('test listBusinessesApiV1BusinessesGet', () async {
      // TODO
    });

    // List Categories
    //
    // List all business categories.
    //
    //Future<BuiltList<CategoryResponse>> listCategoriesApiV1BusinessesCategoriesAllGet() async
    test('test listCategoriesApiV1BusinessesCategoriesAllGet', () async {
      // TODO
    });

    // List Cities
    //
    // Distinct city names for approved businesses (search filter chips).
    //
    //Future<BuiltList<String>> listCitiesApiV1BusinessesCitiesGet() async
    test('test listCitiesApiV1BusinessesCitiesGet', () async {
      // TODO
    });

    // List My Businesses
    //
    // List businesses owned by the current merchant (any status).
    //
    //Future<BuiltList<BusinessResponse>> listMyBusinessesApiV1BusinessesMineGet() async
    test('test listMyBusinessesApiV1BusinessesMineGet', () async {
      // TODO
    });

    // Public Stats Summary
    //
    // Public platform counts for the home page. Excludes admin-only signals (users, pending, reported).
    //
    //Future<PublicPlatformStats> publicStatsSummaryApiV1BusinessesStatsSummaryGet() async
    test('test publicStatsSummaryApiV1BusinessesStatsSummaryGet', () async {
      // TODO
    });

    // Suspend Business
    //
    // Admin: suspend a business.
    //
    //Future<MessageResponse> suspendBusinessApiV1BusinessesBusinessIdSuspendPost(String businessId) async
    test('test suspendBusinessApiV1BusinessesBusinessIdSuspendPost', () async {
      // TODO
    });

    // Update Business
    //
    // Update business details.
    //
    //Future<BusinessResponse> updateBusinessApiV1BusinessesBusinessIdPatch(String businessId, BusinessUpdate businessUpdate) async
    test('test updateBusinessApiV1BusinessesBusinessIdPatch', () async {
      // TODO
    });

  });
}
