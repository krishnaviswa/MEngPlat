import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/merchant/business_editor_screen.dart';
import 'package:merchanthub_mobile/features/merchant/merchant_providers.dart';

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  BusinessCreate? created;
  BusinessUpdate? updated;
  int addressOtpRequests = 0;
  bool requireAddressOtp = false;

  @override
  Future<List<CategoryResponse>> listCategories({String? q}) async => [];

  @override
  Future<List<String>> listCities() async => [];

  @override
  Future<BusinessResponse> createBusiness(BusinessCreate payload) async {
    created = payload;
    return BusinessResponse((b) => b
      ..id = 'new-1'
      ..name = payload.name
      ..slug = 'new-1'
      ..address = payload.address
      ..city = payload.city
      ..country = payload.country ?? 'IN'
      ..status = BusinessStatus.pending
      ..averageRating = 0
      ..reviewCount = 0);
  }

  @override
  Future<BusinessResponse> updateBusiness({required String businessId, required BusinessUpdate payload}) async {
    if (requireAddressOtp && (payload.addressOtpCode == null || payload.addressOtpCode!.trim().isEmpty)) {
      throw ApiException('Verification code required to confirm this address change', statusCode: 400);
    }
    updated = payload;
    return BusinessResponse((b) => b
      ..id = businessId
      ..name = payload.name ?? 'Shop'
      ..slug = 'shop'
      ..address = payload.address ?? '1 Main'
      ..city = payload.city ?? 'Chennai'
      ..country = payload.country ?? 'IN'
      ..status = BusinessStatus.approved
      ..averageRating = 0
      ..reviewCount = 0);
  }

  @override
  Future<void> requestAddressOtp(String businessId) async {
    addressOtpRequests++;
  }
}

void main() {
  testWidgets('S-031 AC13: empty name/address/city blocks create', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pump();
    expect(repo.created, isNull);
    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('S-031 AC13: valid name/address/city posts create', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/new',
      routes: [
        GoRoute(path: '/new', builder: (context, state) => const BusinessEditorScreen()),
        GoRoute(path: '/merchant', builder: (context, state) => const Text('Merchant home')),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('businessNameField')), 'New Shop');
    await tester.enterText(find.byKey(const Key('businessAddressField')), '2 Oak');
    await tester.enterText(find.byKey(const Key('businessCityField')), 'Springfield');
    await tester.enterText(find.byKey(const Key('businessPhoneField')), '+919876543210');
    await tester.enterText(find.byKey(const Key('businessEmailField')), 'shop@example.com');
    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pump();
    expect(repo.created?.name, 'New Shop');
    expect(repo.created?.phone, '+919876543210');
    expect(repo.created?.email, 'shop@example.com');
    expect(repo.created?.latitude, isNull);
    expect(repo.created?.longitude, isNull);
  });

  testWidgets('has no manual Latitude/Longitude inputs -- no one used them by hand', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Latitude'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Longitude'), findsNothing);
  });

  testWidgets('S-072: blank phone/email blocks create', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('requiredFieldLegend')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('businessNameField')), 'New Shop');
    await tester.enterText(find.byKey(const Key('businessAddressField')), '2 Oak');
    await tester.enterText(find.byKey(const Key('businessCityField')), 'Springfield');
    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pump();

    expect(repo.created, isNull);
    expect(find.text('Phone number is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
  });

  testWidgets('S-072: malformed phone/email shows format errors', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('businessNameField')), 'New Shop');
    await tester.enterText(find.byKey(const Key('businessAddressField')), '2 Oak');
    await tester.enterText(find.byKey(const Key('businessCityField')), 'Springfield');
    await tester.enterText(find.byKey(const Key('businessPhoneField')), '123');
    await tester.enterText(find.byKey(const Key('businessEmailField')), 'not-an-email');
    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pump();

    expect(repo.created, isNull);
    expect(find.text('Enter a valid phone number.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('S-084: country, state, and city dropdowns are shown', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('businessCountryField')), findsOneWidget);
    expect(find.byKey(const Key('businessStateField')), findsOneWidget);
    expect(find.byKey(const Key('businessCityPicker')), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
  });

  testWidgets('S-073: address edit requests OTP then saves with the code', (tester) async {
    final repo = _FakeBusinessRepository()..requireAddressOtp = true;
    final existing = BusinessResponse((b) => b
      ..id = 'biz-1'
      ..name = 'Shop'
      ..slug = 'shop'
      ..address = '1 Main'
      ..city = 'Chennai'
      ..country = 'IN'
      ..state = 'TN'
      ..status = BusinessStatus.approved
      ..averageRating = 0
      ..reviewCount = 0);
    final container = ProviderContainer(
      overrides: [
        businessRepositoryProvider.overrideWithValue(repo),
        ownedBusinessesProvider.overrideWith((ref) async => [existing]),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(path: '/edit', builder: (context, state) => const BusinessEditorScreen(businessId: 'biz-1')),
        GoRoute(path: '/merchant', builder: (context, state) => const Text('Merchant home')),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pumpAndSettle();

    expect(repo.addressOtpRequests, 1);
    expect(find.byKey(const Key('addressOtpField')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('addressOtpField')), '123456');
    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pumpAndSettle();

    expect(repo.updated?.addressOtpCode, '123456');
    expect(find.text('Merchant home'), findsOneWidget);
  });
}
