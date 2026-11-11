import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared layout for login, registration and password reset: brand mark,
/// heading and the form on the plain themed surface (works in dark mode).
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;
  final bool showBrand;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBack = false,
    this.showBrand = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5, vertical: AppTheme.space5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBrand) ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: colors.onPrimaryContainer, size: 30),
                    ),
                    const SizedBox(height: AppTheme.space5),
                  ],
                  Text(title, style: context.text.headlineMedium),
                  const SizedBox(height: AppTheme.space1),
                  Text(subtitle, style: context.text.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: AppTheme.space6),
                  child,
                  if (footer != null) ...[
                    const SizedBox(height: AppTheme.space5),
                    Center(child: footer!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A primary button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const LoadingButton({super.key, required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.onSurfaceVariant),
            )
          : Text(label),
    );
  }
}
