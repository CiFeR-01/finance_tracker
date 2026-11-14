import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.sendPasswordResetEmail(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('If this email is registered, a reset link will be sent.'),
            ),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'If this email is registered, a reset link will be sent.',
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          final message = e.code == 'invalid-email'
              ? 'Please enter a valid email address.'
              : e.code == 'network-request-failed'
              ? 'Connection failed. Please check your internet.'
              : e.code == 'too-many-requests'
              ? 'Too many attempts. Please try again later.'
              : 'Unable to process your request. Please try again later.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to process your request. Please try again later.',
            ),
          ),
        );
      }
      finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      showBrand: false,
      title: 'Reset password',
      subtitle: "Enter your account email and we'll send you a link to reset your password.",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space5),
            LoadingButton(label: 'Send reset link', loading: _isLoading, onPressed: _resetPassword),
          ],
        ),
      ),
    );
  }
}
