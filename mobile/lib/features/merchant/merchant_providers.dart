import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import '../businesses/business_list_provider.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

final ownedBusinessesProvider = FutureProvider.autoDispose<List<BusinessResponse>>((ref) async {
  final user = await ref.watch(authControllerProvider.future);
  if (user?.role != UserRole.merchant) return [];
  return ref.watch(businessRepositoryProvider).listMine();
});
