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
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userModel == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.purple),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _authService.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.purple.shade100,
                    child: Text(
                      _userModel!.name.isNotEmpty ? _userModel!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 15),
            _buildInfoTile('Name', _nameController, isEditable: _isEditing),
            _buildInfoTile('Email', TextEditingController(text: _userModel!.email), isEditable: false),
            
            const SizedBox(height: 30),
            const Text('Malaysian Tax Relief Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 10),
            
            _buildTaxSwitch('Individual & Dependent', _userModel!.taxProfile.isIndividualDependentRelatives, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(isIndividual: val);
              });
            }),
            _buildTaxSwitch('Disabled Individual', _userModel!.taxProfile.isDisabledIndividual, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(isDisabled: val);
              });
            }),
            _buildTaxSwitch('Husband/Wife/Alimony', _userModel!.taxProfile.isHusbandWifeAlimony, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(isSpouse: val);
              });
            }),
            _buildTaxSwitch('Disabled Husband/Wife', _userModel!.taxProfile.isDisabledHusbandWife, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(isDisabledSpouse: val);
              });
            }),
            
            _buildCounter('Child Relief Count', _userModel!.taxProfile.childReliefCount, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(childCount: val);
              });
            }),
            _buildCounter('Disabled Child Count', _userModel!.taxProfile.disabledChildCount, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(disabledChildCount: val);
              });
            }),
            
            _buildTaxSwitch('Parents/Grandparents Medical', _userModel!.taxProfile.isParentsGrandparentsMedical, (val) {
              setState(() {
                _userModel = _userModel!.copyWithTaxProfile(isParentsMedical: val);
              });
            }),

            const SizedBox(height: 30),
            const Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 15),
            ListTile(
              title: const Text('Reset Password'),
              subtitle: const Text('Send a password reset link to your email'),
              leading: const Icon(Icons.lock_outline, color: Colors.purple),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: () => _sendResetEmail(),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoTile(String label, TextEditingController controller, {required bool isEditable}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.purple),
          disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
        ),
      ),
    );
  }

  Widget _buildTaxSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: Colors.purple,
      onChanged: _isEditing ? onChanged : null,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCounter(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Row(
            children: [
              IconButton(
                onPressed: (_isEditing && value > 0) ? () => onChanged(value - 1) : null, 
                icon: const Icon(Icons.remove_circle_outline)
              ),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _isEditing ? () => onChanged(value + 1) : null, 
                icon: const Icon(Icons.add_circle_outline)
              ),
            ],
          )
        ],
      ),
    );
  }
}

// Add copyWith to UserModel for easier state updates
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
