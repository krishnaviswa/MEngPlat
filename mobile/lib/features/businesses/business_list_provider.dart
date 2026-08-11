import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(apiClientProvider)),
);

final businessListProvider = FutureProvider.autoDispose<List<BusinessResponse>>((ref) {
  return ref.watch(businessRepositoryProvider).searchBusinesses();
});
