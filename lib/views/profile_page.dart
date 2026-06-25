import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        // If the user document doesn't exist in Firestore, log out immediately
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
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userModel == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // 1. Header with Gradient and Profile Info
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.check_circle : Icons.edit_note,
                                color: Colors.white,
                                size: 28,
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
                              icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                              onPressed: () => _authService.logout(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            _userModel!.name.isNotEmpty ? _userModel!.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userModel!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userModel!.email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // 2. Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Personal Information'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoField(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            controller: _nameController,
                            isEditable: _isEditing,
                          ),
                          const Divider(height: 24),
                          _buildInfoField(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            controller: TextEditingController(text: _userModel!.email),
                            isEditable: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Malaysian Tax Relief Profile'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildTaxSwitch(
                          'Individual & Dependent',
                          _userModel!.taxProfile.isIndividualDependentRelatives,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isIndividual: val)),
                        ),
                        _buildTaxSwitch(
                          'Disabled Individual',
                          _userModel!.taxProfile.isDisabledIndividual,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isDisabled: val)),
                        ),
                        _buildTaxSwitch(
                          'Husband/Wife/Alimony',
                          _userModel!.taxProfile.isHusbandWifeAlimony,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isSpouse: val)),
                        ),
                        _buildTaxSwitch(
                          'Disabled Husband/Wife',
                          _userModel!.taxProfile.isDisabledHusbandWife,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isDisabledSpouse: val)),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildCounter(
                          'Child Relief Count',
                          _userModel!.taxProfile.childReliefCount,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(childCount: val)),
                        ),
                        _buildCounter(
                          'Disabled Child Count',
                          _userModel!.taxProfile.disabledChildCount,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(disabledChildCount: val)),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildTaxSwitch(
                          'Parents/Grandparents Medical',
                          _userModel!.taxProfile.isParentsGrandparentsMedical,
                          (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isParentsMedical: val)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Security & Settings'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF3E5F5),
                        child: Icon(Icons.lock_reset, color: Colors.purple),
                      ),
                      title: const Text(
                        'Reset Password',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text('Send reset link to your email'),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _sendResetEmail(),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
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
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple.shade300, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              TextField(
                controller: controller,
                enabled: isEditable,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                  enabledBorder: isEditable
                      ? const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple, width: 0.5),
                        )
                      : InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      value: value,
      activeThumbColor: Colors.purple,
      onChanged: _isEditing ? onChanged : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildCounter(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: (_isEditing && value > 0) ? () => onChanged(value - 1) : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: (_isEditing && value > 0) ? Colors.purple : Colors.grey.shade400,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$value',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: _isEditing ? () => onChanged(value + 1) : null,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: _isEditing ? Colors.purple : Colors.grey.shade400,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
