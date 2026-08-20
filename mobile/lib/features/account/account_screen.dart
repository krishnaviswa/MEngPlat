import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/media_url.dart';
import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';
import '../merchant/merchant_providers.dart';
import '../merchant/share_review_link_sheet.dart';
import '../theme/theme_toggle_button.dart';

/// Identity + logout (S-027 / M-49). Profile edit is S-029 / M-48.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final avatarUrl = user?.avatarUrl;
    final theme = Theme.of(context);
    final owned = user?.role == UserRole.merchant ? ref.watch(ownedBusinessesProvider).valueOrNull : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          const ThemeToggleButton(),
          TextButton(
            key: const Key('brandHomeLink'),
            onPressed: () => context.go('/home'),
            child: const Text('MerchantHub AI'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view your account'))
          : MhCanvas(
              child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MhCard(
                  accent: MhAccent.sky,
                  child: Row(
                    key: const Key('accountIdentity'),
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(resolveMediaUrl(avatarUrl))
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(_initials(user.fullName), style: theme.textTheme.titleMedium)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(user.email ?? user.phone ?? '', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MhJobTile(
                  key: const Key('profileLink'),
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Name, contact, and photo',
                  accent: MhAccent.violet,
                  onTap: () => context.push('/account/profile'),
                ),
                if (user.role == UserRole.merchant) ...[
                  const SizedBox(height: 8),
                  MhJobTile(
                    key: const Key('myShopLink'),
                    icon: Icons.storefront_outlined,
                    title: 'My shop',
                    subtitle: 'Insights, reviews, listing status',
                    accent: MhAccent.mint,
                    onTap: () => context.go('/merchant'),
                  ),
                  const SizedBox(height: 8),
                  MhJobTile(
                    key: const Key('listBusinessLink'),
                    icon: Icons.add_business_outlined,
                    title: 'List a business',
                    subtitle: 'Create or add a shop',
                    accent: MhAccent.sky,
                    onTap: () => context.push('/merchant/businesses/new'),
                  ),
                  const SizedBox(height: 8),
                  MhJobTile(
                    key: const Key('shareQrLink'),
                    icon: Icons.qr_code_2,
                    title: 'Share review QR',
                    subtitle: 'Customer collect link',
                    accent: MhAccent.amber,
                    onTap: () {
                      final shops = owned ?? const <BusinessResponse>[];
                      if (shops.isEmpty) {
                        context.go('/merchant');
                        return;
                      }
                      final shop = shops.first;
                      ShareReviewLinkSheet.show(context, businessName: shop.name, slug: shop.slug);
                    },
                  ),
                  const SizedBox(height: 8),
                  MhJobTile(
                    key: const Key('growLink'),
                    icon: Icons.rocket_launch_outlined,
                    title: 'Grow / payments',
                    subtitle: 'Featured, Google, WhatsApp',
                    accent: MhAccent.coral,
                    onTap: () => context.push('/merchant/grow'),
                  ),
                ],
                const SizedBox(height: 8),
                MhJobTile(
                  key: const Key('supportLink'),
                  icon: Icons.support_agent_outlined,
                  title: 'Support',
                  subtitle: 'Contact and tickets',
                  accent: MhAccent.coral,
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('logoutButton'),
                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
