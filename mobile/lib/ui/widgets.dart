import 'package:flutter/material.dart';

import 'friendly_error.dart';
import 'tokens.dart';

export 'tokens.dart';

class MhCanvas extends StatelessWidget {
  const MhCanvas({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0B1220), Color(0xFF122033), Color(0xFF0B1220)]
              : const [Color(0xFFE0F2FE), Color(0xFFFFF7ED), Color(0xFFF0FDF4)],
        ),
      ),
      child: child,
    );
  }
}

class MhCard extends StatelessWidget {
  const MhCard({required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.accent, super.key});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final MhAccent? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent?.wash ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final card = Material(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MhTokens.radiusLg),
        side: BorderSide(color: (accent?.bold ?? Theme.of(context).colorScheme.outline).withValues(alpha: 0.22)),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MhTokens.radiusLg),
      child: card,
    );
  }
}

class MhStatTile extends StatelessWidget {
  const MhStatTile({
    required this.label,
    required this.value,
    this.onTap,
    this.extra,
    this.accent = MhAccent.sky,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? extra;
  final MhAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: accent.wash,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MhTokens.radiusMd),
        side: BorderSide(color: accent.bold.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MhTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: accent.ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: accent.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ?extra,
            ],
          ),
        ),
      ),
    );
  }
}

class MhJobTile extends StatelessWidget {
  const MhJobTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = MhAccent.sky,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final MhAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MhCard(
      accent: accent,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.bold,
              borderRadius: BorderRadius.circular(MhTokens.radiusMd),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: accent.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: accent.ink),
        ],
      ),
    );
  }
}

class MhEmpty extends StatelessWidget {
  const MhEmpty({
    required this.title,
    this.body,
    this.action,
    super.key,
  });

  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [MhTokens.brand400, MhTokens.violet]),
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class MhError extends StatelessWidget {
  const MhError({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MhTokens.coralWash,
          borderRadius: BorderRadius.circular(MhTokens.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                friendlyMessage(error),
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFBE123C)),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MhSkeleton extends StatelessWidget {
  const MhSkeleton({this.height = 16, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _bar(context, height, MhTokens.brand100),
          const SizedBox(height: 12),
          _bar(context, height, MhTokens.amberWash),
          const SizedBox(height: 12),
          _bar(context, height * 2, MhTokens.mintWash),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, double h, Color color) {
    return Container(
      height: h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    );
  }
}

class MhStatusChip extends StatelessWidget {
  const MhStatusChip({required this.label, this.tone = MhTone.neutral, super.key});

  final String label;
  final MhTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      MhTone.positive => (MhTokens.mintWash, const Color(0xFF166534)),
      MhTone.warning => (MhTokens.amberWash, const Color(0xFF92400E)),
      MhTone.danger => (MhTokens.coralWash, const Color(0xFF991B1B)),
      MhTone.brand => (MhTokens.brand100, MhTokens.brand700),
      MhTone.neutral => (Theme.of(context).colorScheme.surfaceContainerHighest, Theme.of(context).colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

enum MhTone { positive, warning, danger, brand, neutral }

class MhAuthHeader extends StatelessWidget {
  const MhAuthHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MhTokens.brand400, MhTokens.violet, MhTokens.coral],
            ),
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
