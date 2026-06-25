import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      if (data == null) {
        await _authService.logout();
        return;
      }
      
      if (mounted) {
        setState(() {
          _userModel = data;
          _nameController.text = data.name;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_userModel == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = UserModel(
        uid: _userModel!.uid,
        email: _userModel!.email,
        name: _nameController.text.trim(),
        taxProfile: _userModel!.taxProfile,
      );
      await _authService.updateProfile(updatedUser);
      setState(() {
        _userModel = updatedUser;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0))),
      );
    }

    if (_userModel == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching Login/Register
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C), Color(0xFF212121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Modern Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isEditing ? Icons.check_circle : Icons.edit_note,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              if (_isEditing) {
                                _updateProfile();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                            onPressed: () => _authService.logout(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Glass Profile Header Card
                        _buildGlassContainer(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    child: Text(
                                      _userModel!.name.isNotEmpty ? _userModel!.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (_isEditing)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF6A1B9A)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (!_isEditing) ...[
                                Text(
                                  _userModel!.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _userModel!.email,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ] else
                                _buildGlassTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader('MALAYSIAN TAX RELIEF'),
                        
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              _buildGlassSwitch(
                                'Individual & Dependent',
                                _userModel!.taxProfile.isIndividualDependentRelatives,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isIndividual: val)),
                              ),
                              _buildGlassSwitch(
                                'Disabled Individual',
                                _userModel!.taxProfile.isDisabledIndividual,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isDisabled: val)),
                              ),
                              _buildGlassSwitch(
                                'Husband / Wife / Alimony',
                                _userModel!.taxProfile.isHusbandWifeAlimony,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isSpouse: val)),
                              ),
                              _buildGlassSwitch(
                                'Disabled Husband / Wife',
                                _userModel!.taxProfile.isDisabledHusbandWife,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isDisabledSpouse: val)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(color: Colors.white.withOpacity(0.1)),
                              ),
                              _buildGlassCounter(
                                'Child Relief Count',
                                _userModel!.taxProfile.childReliefCount,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(childCount: val)),
                              ),
                              _buildGlassCounter(
                                'Disabled Child Count',
                                _userModel!.taxProfile.disabledChildCount,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(disabledChildCount: val)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(color: Colors.white.withOpacity(0.1)),
                              ),
                              _buildGlassSwitch(
                                'Parents Medical Expenses',
                                _userModel!.taxProfile.isParentsGrandparentsMedical,
                                (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isParentsMedical: val)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader('SECURITY & ACCOUNT'),
                        
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.lock_reset_rounded, color: Colors.white70),
                                title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 14)),
                                subtitle: Text('Receive a reset link via email', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                                onTap: _sendResetEmail,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(color: Colors.white.withOpacity(0.1)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                                subtitle: Text('Permanently remove your data', style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 12)),
                                onTap: () {
                                  // Implementation for delete account
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildGlassSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: value,
      activeColor: Colors.white,
      activeTrackColor: Colors.purpleAccent,
      onChanged: _isEditing ? onChanged : null,
      dense: true,
    );
  }

  Widget _buildGlassCounter(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: (_isEditing && value > 0) ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
                ),
                Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _isEditing ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendResetEmail() async {
    try {
      await _authService.sendPasswordResetEmail(_userModel!.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset link sent to your email!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

extension UserModelExtension on UserModel {
  UserModel copyWithTaxProfile({
    bool? isIndividual,
    bool? isDisabled,
    bool? isSpouse,
    bool? isDisabledSpouse,
    int? childCount,
    int? disabledChildCount,
    bool? isParentsMedical,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name,
      taxProfile: TaxProfile(
        isIndividualDependentRelatives: isIndividual ?? taxProfile.isIndividualDependentRelatives,
        isDisabledIndividual: isDisabled ?? taxProfile.isDisabledIndividual,
        isHusbandWifeAlimony: isSpouse ?? taxProfile.isHusbandWifeAlimony,
        isDisabledHusbandWife: isDisabledSpouse ?? taxProfile.isDisabledHusbandWife,
        childReliefCount: childCount ?? taxProfile.childReliefCount,
        disabledChildCount: disabledChildCount ?? taxProfile.disabledChildCount,
        isParentsGrandparentsMedical: isParentsMedical ?? taxProfile.isParentsGrandparentsMedical,
      ),
    );
  }
}
