import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_providers.dart';
import 'package:merchanthub_mobile/features/notifications/notifications_repository.dart';
import 'package:merchanthub_mobile/router.dart';

/// S-055 (M-74) AC4: "on success I am signed in ... and routed the same way
/// any other successful sign-in routes (per postLoginPath)". Phone sign-in
/// flips `authControllerProvider` state exactly like `signInWithGoogle`
/// (same `state = AsyncValue.data(user)` pattern in `auth_provider.dart`),
/// but that shared mechanism deserves its own direct assertion against the
/// *full* app router rather than relying solely on the Google-flavored
/// coverage in register_google_auth_test.dart.
class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => null;

  @override
  Future<void> signInWithPhone({
    required String phone,
    required String code,
    String? fullName,
    UserRole? role,
  }) async {
    final user = UserResponse((b) => b
      ..id = 'user-phone-1'
      ..fullName = fullName ?? 'Phone User'
      ..role = role ?? UserRole.customer
      ..isActive = true
      ..phone = phone
      ..createdAt = DateTime.utc(2026, 1, 1));
    state = AsyncValue.data(user);
  }
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> searchBusinesses({
    SearchQuery query = const SearchQuery(),
    int page = 1,
    int pageSize = SearchQuery.pageSize,
  }) async =>
      [];

  @override
  Future<List<BusinessResponse>> listMine() async => [];
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(ApiClient());

  @override
  Future<List<NotificationResponse>> list({bool unreadOnly = false}) async => [];
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
  // A second settle round: `authControllerProvider`'s AsyncNotifier.build()
  // resolves one microtask after the first pump, which flips GoRouter's
  // `refreshListenable` and can leave a just-created ModalRoute transiently
  // `offstage` (Navigator/Hero bookkeeping) for one extra frame -- without
  // this, `tester.enterText` on a field inside that route intermittently
  // throws "Bad state: No element" even though the widget is really there.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _pumpRouter(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuthController();
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      businessRepositoryProvider.overrideWithValue(_FakeBusinessRepository()),
      notificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository()),
      favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: container.read(routerProvider)),
    ),
  );
  await _pumpFrames(tester);
  return container;
}

void main() {
  testWidgets('AC4: phone sign-in from login (customer, default role) lands on Explore, same as any sign-in',
      (tester) async {
    final container = await _pumpRouter(tester);

    await tester.enterText(find.byKey(const Key('phoneNumberField')), '9876543210');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendPhoneCodeButton')));
    await _pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('phoneCodeField')), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
    await _pumpFrames(tester);

    expect(find.text('Businesses'), findsOneWidget);
    expect(find.byKey(const Key('exploreTab')), findsOneWidget);
    expect(find.byKey(const Key('primaryNav')), findsOneWidget);

    container.dispose();
  });

  testWidgets('AC4: phone sign-in from register (merchant role) lands on the merchant home, same as any sign-in',
      (tester) async {
    final container = await _pumpRouter(tester);

    await tester.tap(find.byKey(const Key('createAccountLink')));
    await _pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('registerFullNameField')), 'Mina Merchant');
    await tester.pump();
    await tester.tap(find.byKey(const Key('roleDropdown')));
    await _pumpFrames(tester);
    await tester.tap(find.text('Merchant').last);
    await _pumpFrames(tester);

    await tester.enterText(find.byKey(const Key('phoneNumberField')), '9876543211');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendPhoneCodeButton')));
    await _pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('phoneCodeField')), '654321');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verifyPhoneCodeButton')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('merchantHomeTab')), findsOneWidget);
    expect(find.byKey(const Key('primaryNav')), findsOneWidget);

    container.dispose();
  });
}
