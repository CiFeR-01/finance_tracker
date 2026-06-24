import 'package:flutter/material.dart';
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

  // Tax Profile State
  bool _isIndividual = true;
  bool _isDisabledIndividual = false;
  bool _isHusbandWifeAlimony = false;
  bool _isDisabledHusbandWife = false;
  int _childReliefCount = 0;
  int _disabledChildCount = 0;
  bool _isParentsGrandparentsMedical = false;

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
        
        if (mounted) Navigator.pop(context); // Go back to login/home
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 10),
              _buildTextField(_nameController, 'Full Name', Icons.person_outline),
              _buildTextField(_emailController, 'Email', Icons.email_outlined),
              _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
              
              const SizedBox(height: 20),
              const Text('Malaysian Tax Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const Text('This helps us calculate your tax reliefs.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              
              _buildSwitchTile('Individual and dependent relatives', _isIndividual, (val) => setState(() => _isIndividual = val)),
              _buildSwitchTile('Disabled individual', _isDisabledIndividual, (val) => setState(() => _isDisabledIndividual = val)),
              _buildSwitchTile('Husband / wife / alimony', _isHusbandWifeAlimony, (val) => setState(() => _isHusbandWifeAlimony = val)),
              _buildSwitchTile('Disabled husband / wife', _isDisabledHusbandWife, (val) => setState(() => _isDisabledHusbandWife = val)),
              
              _buildCounterTile('Child relief (No. of children)', _childReliefCount, (val) => setState(() => _childReliefCount = val)),
              _buildCounterTile('Disabled child relief (No. of children)', _disabledChildCount, (val) => setState(() => _disabledChildCount = val)),
              
              _buildSwitchTile('Parents / grandparents medical expenses', _isParentsGrandparentsMedical, (val) => setState(() => _isParentsGrandparentsMedical = val)),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: Colors.purple,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCounterTile(String title, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Row(
            children: [
              IconButton(onPressed: value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
            ],
          )
        ],
      ),
    );
  }
}
