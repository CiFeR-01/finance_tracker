import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';
import '../theme/app_theme.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 1) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      }
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final user = await _authService.checkVerification();
      if (!mounted) return;
      if (user != null && user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully! Access granted.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is not verified yet. Please check your inbox or spam folder.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking verification: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authService.sendVerificationEmail();
      if (!mounted) return;
      _startCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent! Please check your inbox.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'too-many-requests') {
        _startCooldown(60);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Too many requests. Please wait a moment before trying again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to send verification email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send verification email. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    _cooldownTimer?.cancel();
    await _authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return PopScope(
      canPop: false,
      child: AuthLayout(
        title: 'Verify your email',
        subtitle: 'We sent a verification link to $userEmail. Please verify your email to access your financial dashboard.',
        footer: TextButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colors.primaryContainer,
                      child: Icon(Icons.mark_email_unread_rounded, color: context.colors.onPrimaryContainer),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verification status', style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                          Text(
                            'Pending verification',
                            style: context.text.titleSmall?.copyWith(color: context.colors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space5),
            LoadingButton(
              label: 'Check verification',
              loading: _isChecking,
              onPressed: _checkVerification,
            ),
            const SizedBox(height: AppTheme.space3),
            OutlinedButton(
              onPressed: (_cooldownSeconds > 0 || _isResending) ? null : _resendVerificationEmail,
              child: _isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_cooldownSeconds > 0 ? 'Resend email (${_cooldownSeconds}s)' : 'Resend email'),
            ),
          ],
        ),
      ),
    );
  }
}
