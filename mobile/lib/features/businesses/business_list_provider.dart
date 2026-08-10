import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/business.dart';
import '../auth/auth_provider.dart';
import 'business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(apiClientProvider)),
);

final businessListProvider = FutureProvider.autoDispose<List<Business>>((ref) {
  return ref.watch(businessRepositoryProvider).searchBusinesses();
});
