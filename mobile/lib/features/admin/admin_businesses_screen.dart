import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../businesses/business_list_provider.dart';
import 'admin_back_app_bar.dart';

/// Admin browse of every business status (M-60) with processing badge (M-81).
class AdminBusinessesScreen extends ConsumerWidget {
  const AdminBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: adminBackAppBar(context, title: 'All businesses'),
      body: FutureBuilder<List<BusinessResponse>>(
        future: ref.read(businessRepositoryProvider).listAdminAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No businesses'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final business = items[index];
              return ListTile(
                title: Text(business.name),
                subtitle: Text('${business.city} · ${business.status.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (business.status == BusinessStatus.processing)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          key: Key('processingBadge-${business.id}'),
                          label: const Text('Processing'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    Text(business.averageRating.toStringAsFixed(1)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
