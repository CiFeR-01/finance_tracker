import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../viewmodels/add_income_view_model.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _totalIncomeController = TextEditingController();
  final _epfController = TextEditingController();
  final _socsoController = TextEditingController();
  final _pcbController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddIncomeViewModel>().clearData();
    });

    _epfController.addListener(_onInputChanged);
    _socsoController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    context.read<AddIncomeViewModel>().updateInputs(
      _epfController.text,
      _socsoController.text,
    );
  }

  @override
  void dispose() {
    _epfController.dispose();
    _socsoController.dispose();
    _totalIncomeController.dispose();
    _pcbController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(AddIncomeViewModel viewModel) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      viewModel.setImagePath(savedImage.path);
    }
  }

  Future<void> _selectDate(BuildContext context, AddIncomeViewModel viewModel) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      viewModel.setDate(picked);
    }
  }

  void _saveIncome(AddIncomeViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.saveIncome(
        totalIncomeStr: _totalIncomeController.text,
        epfStr: _epfController.text,
        socsoStr: _socsoController.text,
        pcbStr: _pcbController.text,
        description: _descriptionController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income saved successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save income. Check login status.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddIncomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 48.0),
                        child: Text(
                          'Add Incomes',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Total Income'),
                    _buildTextField(_totalIncomeController, '0.0', isNumber: true),

                    _buildLabel('EPF'),
                    _buildTextField(_epfController, 'RM1000', isNumber: true),
                    if (viewModel.isEpfLimitReached)
                      _buildLimitWarning('Note: You have already reached the RM ${AddIncomeViewModel.EPF_LIMIT.toInt()} EPF relief limit; this entry won\'t further reduce your tax.'),

                    _buildLabel('Socso'),
                    _buildTextField(_socsoController, 'RM30', isNumber: true),
                    if (viewModel.isSocsoLimitReached)
                      _buildLimitWarning('Note: You have already reached the RM ${AddIncomeViewModel.SOCSO_LIMIT.toInt()} SOCSO relief limit; this entry won\'t further reduce your tax.'),

                    _buildLabel('PCB'),
                    _buildTextField(_pcbController, 'RM1000', isNumber: true),

                    _buildLabel('Category'),
                    DropdownButtonFormField<String>(
                      value: viewModel.selectedCategory,
                      decoration: _inputDecoration(''),
                      items: viewModel.categories.map((String category) {
                        return DropdownMenuItem(value: category, child: Text(category));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          viewModel.setCategory(newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Descriptions'),
                    _buildTextField(_descriptionController, 'Examples...'),
                    _buildLabel('Date'),
                    InkWell(
                      onTap: () => _selectDate(context, viewModel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(viewModel.selectedDate)),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Proof'),
                    GestureDetector(
                      onTap: () => _pickImage(viewModel),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: viewModel.proofImagePath == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Capture payslip/proof', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(viewModel.proofImagePath!), fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => _saveIncome(viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Save Income', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildLimitWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        message,
        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: _inputDecoration(hint),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (isNumber && double.tryParse(value) == null) return 'Invalid number';
          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
