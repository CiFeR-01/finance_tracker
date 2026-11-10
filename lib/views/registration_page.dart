import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

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
        return 'The password is too weak.';
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
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
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
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C), Color(0xFF212121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Join us to start tracking your finances',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  
                  // Glassmorphic Form Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('BASIC INFO'),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Enter your email';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (val) => val!.length < 6 ? 'Password too short (min 6 chars)' : null,
                              ),
                              
                              const SizedBox(height: 30),
                              _buildSectionTitle('MALAYSIAN TAX PROFILE'),
                              const Text(
                                'This helps us automate your tax relief calculations.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              
                              _buildSwitchTile('Individual & Dependent', _isIndividual, (val) => setState(() => _isIndividual = val)),
                              _buildSwitchTile('Disabled Individual', _isDisabledIndividual, (val) => setState(() => _isDisabledIndividual = val)),
                              _buildSwitchTile('Husband / Wife / Alimony', _isHusbandWifeAlimony, (val) => setState(() => _isHusbandWifeAlimony = val)),
                              _buildSwitchTile('Disabled Husband / Wife', _isDisabledHusbandWife, (val) => setState(() => _isDisabledHusbandWife = val)),
                              
                              _buildCounterTile('Child Relief Count', _childReliefCount, (val) => setState(() => _childReliefCount = val)),
                              _buildCounterTile('Disabled Child Count', _disabledChildCount, (val) => setState(() => _disabledChildCount = val)),
                              
                              _buildSwitchTile('Parents Medical Expenses', _isParentsGrandparentsMedical, (val) => setState(() => _isParentsGrandparentsMedical = val)),
                              
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.purple.shade900,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading 
                                    ? const CircularProgressIndicator()
                                    : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Theme(
      data: ThemeData(unselectedWidgetColor: Colors.white30),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        value: value,
        activeColor: Colors.white,
        activeTrackColor: Colors.purpleAccent,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  Widget _buildCounterTile(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
                ),
                Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => onChanged(value + 1),
                  icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
