import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../reviews/review_card.dart';
import '../reviews/review_providers.dart';
import 'admin_back_app_bar.dart';

/// Admin browse of reviews across businesses (M-60).
class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: adminBackAppBar(context, title: 'All reviews'),
      body: FutureBuilder<List<ReviewResponse>>(
        future: ref.read(reviewRepositoryProvider).listAdminAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No reviews'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => ReviewCard(review: items[index], showActions: false),
          );
        },
      ),
    );
  }
}
