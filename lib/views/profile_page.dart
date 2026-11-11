import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/page_header.dart';
import '../theme/app_theme.dart';
import '../widgets/reminders_card.dart';
import '../theme/theme_controller.dart';

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
      if (!mounted) return;
      setState(() {
        _userModel = updatedUser;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    final colors = context.colors;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Profile',
            actions: [
              IconButton(
                tooltip: _isEditing ? 'Save' : 'Edit',
                icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined),
                style: _isEditing ? IconButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.onPrimary) : null,
                onPressed: () {
                  if (_isEditing) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _authService.logout(),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
              children: [
                // Identity
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        _userModel!.name.isNotEmpty ? _userModel!.name[0].toUpperCase() : '?',
                        style: context.text.headlineSmall?.copyWith(color: colors.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userModel!.name, style: context.text.titleLarge, overflow: TextOverflow.ellipsis),
                          Text(_userModel!.email,
                              style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space5),
                _buildSectionHeader('Personal information'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space4),
                    child: Column(
                      children: [
                        _buildInfoField(
                          icon: Icons.person_outline_rounded,
                          label: 'Full name',
                          controller: _nameController,
                          isEditable: _isEditing,
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.space3), child: Divider()),
                        _buildInfoField(
                          icon: Icons.email_outlined,
                          label: 'Email address',
                          controller: TextEditingController(text: _userModel!.email),
                          isEditable: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                _buildSectionHeader('Malaysian tax relief profile'),
                if (!_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.space1, bottom: AppTheme.space2),
                    child: Text('Tap the edit button to change these.',
                        style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                Card(
                  child: Column(
                    children: [
                      _buildTaxSwitch(
                        'Individual & dependent relatives',
                        _userModel!.taxProfile.isIndividualDependentRelatives,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isIndividual: val)),
                      ),
                      _buildTaxSwitch(
                        'Disabled individual',
                        _userModel!.taxProfile.isDisabledIndividual,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isDisabled: val)),
                      ),
                      _buildTaxSwitch(
                        'Husband / wife / alimony',
                        _userModel!.taxProfile.isHusbandWifeAlimony,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isSpouse: val)),
                      ),
                      _buildTaxSwitch(
                        'Disabled husband / wife',
                        _userModel!.taxProfile.isDisabledHusbandWife,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isDisabledSpouse: val)),
                      ),
                      const Divider(indent: AppTheme.space4, endIndent: AppTheme.space4),
                      _buildCounter(
                        'Children',
                        _userModel!.taxProfile.childReliefCount,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(childCount: val)),
                      ),
                      _buildCounter(
                        'Disabled children',
                        _userModel!.taxProfile.disabledChildCount,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(disabledChildCount: val)),
                      ),
                      const Divider(indent: AppTheme.space4, endIndent: AppTheme.space4),
                      _buildTaxSwitch(
                        'Parents / grandparents medical',
                        _userModel!.taxProfile.isParentsGrandparentsMedical,
                        (val) => setState(() => _userModel = _userModel!.copyWithTaxProfile(isParentsMedical: val)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                _buildSectionHeader('Appearance'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space4),
                    child: Builder(builder: (context) {
                      final theme = context.watch<ThemeController>();
                      return SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Auto')),
                          ],
                          selected: {theme.mode},
                          onSelectionChanged: (v) => theme.setMode(v.first),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                _buildSectionHeader('Reminders'),
                const RemindersCard(),
                const SizedBox(height: AppTheme.space5),
                _buildSectionHeader('Security'),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space1),
                    leading: CircleAvatar(
                      backgroundColor: colors.secondaryContainer,
                      child: Icon(Icons.lock_reset_rounded, color: colors.onSecondaryContainer),
                    ),
                    title: const Text('Reset password'),
                    subtitle: const Text('Send a reset link to your email'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _sendResetEmail(),
                  ),
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
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space1, bottom: AppTheme.space2),
      child: Text(title, style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, color: colors.onSurfaceVariant, size: 22),
        const SizedBox(width: AppTheme.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
              TextField(
                controller: controller,
                enabled: isEditable,
                style: context.text.bodyLarge,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
                  border: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  enabledBorder: isEditable
                      ? UnderlineInputBorder(borderSide: BorderSide(color: colors.primary))
                      : InputBorder.none,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primary, width: 2)),
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
      title: Text(title, style: context.text.bodyLarge),
      value: value,
      onChanged: _isEditing ? onChanged : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
    );
  }

  Widget _buildCounter(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space2),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.bodyLarge)),
          IconButton.filledTonal(
            tooltip: 'Decrease',
            onPressed: (_isEditing && value > 0) ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 36,
            child: Text('$value', textAlign: TextAlign.center, style: context.text.titleMedium),
          ),
          IconButton.filledTonal(
            tooltip: 'Increase',
            onPressed: _isEditing ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
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
