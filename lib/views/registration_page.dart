import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/auth_layout.dart';
import '../theme/app_theme.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Tax Profile State
  bool _isIndividual = true;
  bool _isDisabledIndividual = false;
  bool _isHusbandWifeAlimony = false;
  bool _isDisabledHusbandWife = false;
  int _childReliefCount = 0;
  int _disabledChildCount = 0;
  bool _isParentsGrandparentsMedical = false;

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak. Must meet complexity requirements.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final taxProfile = TaxProfile(
          isIndividualDependentRelatives: _isIndividual,
          isDisabledIndividual: _isDisabledIndividual,
          isHusbandWifeAlimony: _isHusbandWifeAlimony,
          isDisabledHusbandWife: _isDisabledHusbandWife,
          childReliefCount: _childReliefCount,
          disabledChildCount: _disabledChildCount,
          isParentsGrandparentsMedical: _isParentsGrandparentsMedical,
        );

        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          taxProfile,
        );
        
        if (mounted) Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(e.code)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred.'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      showBrand: false,
      title: 'Create account',
      subtitle: 'Start tracking your finances and tax reliefs.',
      footer: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Already have an account?', style: context.text.bodyMedium),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Log in')),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Basic info'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (val) => val!.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: AppTheme.space4),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space4),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: '8+ characters with upper and lower case letters and a number',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter a password';
                if (val.length < 8) return 'Minimum 8 characters required';
                if (!val.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
                if (!val.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
                if (!val.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space6),
            _buildSectionTitle('Malaysian tax profile'),
            Text(
              'Used to work out your fixed tax reliefs. You can change this later in Profile.',
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.space3),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
                child: Column(
                  children: [
                    _buildSwitchTile('Individual & dependent relatives', _isIndividual, (val) => setState(() => _isIndividual = val)),
                    _buildSwitchTile('Disabled individual', _isDisabledIndividual, (val) => setState(() => _isDisabledIndividual = val)),
                    _buildSwitchTile('Husband / wife / alimony', _isHusbandWifeAlimony, (val) => setState(() => _isHusbandWifeAlimony = val)),
                    _buildSwitchTile('Disabled husband / wife', _isDisabledHusbandWife, (val) => setState(() => _isDisabledHusbandWife = val)),
                    _buildCounterTile('Children', _childReliefCount, (val) => setState(() => _childReliefCount = val)),
                    _buildCounterTile('Disabled children', _disabledChildCount, (val) => setState(() => _disabledChildCount = val)),
                    _buildSwitchTile('Parents medical expenses', _isParentsGrandparentsMedical, (val) => setState(() => _isParentsGrandparentsMedical = val)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space5),
            LoadingButton(label: 'Create account', loading: _isLoading, onPressed: _register),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Text(title, style: context.text.titleMedium),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: context.text.bodyLarge),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
    );
  }

  Widget _buildCounterTile(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space1),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.bodyLarge)),
          IconButton.filledTonal(
            tooltip: 'Decrease',
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: context.text.titleMedium)),
          IconButton.filledTonal(
            tooltip: 'Increase',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
