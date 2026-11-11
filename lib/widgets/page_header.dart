import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard top-of-page header used by every main tab.
///
/// A large left-aligned title on the plain surface colour (no gradient),
/// with an optional subtitle, trailing actions and a widget below.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.space5, AppTheme.space3, AppTheme.space4, AppTheme.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            if (bottom != null) ...[
              const SizedBox(height: AppTheme.space3),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A tonal pill that opens a month picker, e.g. "Nov 2026 ▾".
class PeriodPill<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const PeriodPill({
    super.key,
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.secondaryContainer,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.only(left: AppTheme.space4, right: AppTheme.space2),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
            dropdownColor: colors.surfaceContainerHigh,
            icon: Icon(Icons.expand_more_rounded, color: colors.onSecondaryContainer),
            style: context.text.labelLarge?.copyWith(color: colors.onSecondaryContainer),
            selectedItemBuilder: (context) => options
                .map((o) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(label(o), style: context.text.labelLarge?.copyWith(color: colors.onSecondaryContainer)),
                    ))
                .toList(),
            items: options
                .map((o) => DropdownMenuItem<T>(
                      value: o,
                      child: Text(label(o), style: context.text.bodyLarge),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

/// A rounded card section with an optional title row; the standard
/// container for dashboard content.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space5 - 4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    Expanded(child: Text(title!, style: context.text.titleMedium)),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: AppTheme.space4),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
