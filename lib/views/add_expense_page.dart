import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../viewmodels/add_expense_view_model.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      context.read<AddExpenseViewModel>().setAmount(_amountController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddExpenseViewModel>().clearData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(AddExpenseViewModel viewModel) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      viewModel.setImagePath(savedImage.path);
    }
  }

  Future<void> _selectDate(BuildContext context, AddExpenseViewModel viewModel) async {
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

  void _saveExpense(AddExpenseViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.saveExpense(
        _amountController.text,
        _descriptionController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save expense. Check login status.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddExpenseViewModel>();

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
                colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
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
                          'Add Expenses',
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
                    _buildLabel('Amount'),
                    _buildTextField(
                      controller: _amountController,
                      hint: '0.0',
                      isNumber: true,
                      validator: (val) => _validateAmount(val, 'Amount', allowZero: false),
                    ),

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

                    if (viewModel.isLimitExceeded)
                      _buildLimitWarning('Note: You have already reached the RM ${viewModel.getLimitForCategory(viewModel.selectedCategory).toInt()} relief limit for ${viewModel.selectedCategory}; this entry won\'t further reduce your tax.'),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: viewModel.isCategoryDeductible ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: viewModel.isCategoryDeductible ? Colors.green.shade300 : Colors.red.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: viewModel.isTaxDeductible,
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (!viewModel.isCategoryDeductible) return Colors.red.shade200;
                              if (states.contains(WidgetState.selected)) return Colors.red;
                              return Colors.white;
                            }),
                            onChanged: viewModel.isCategoryDeductible
                                ? (value) => viewModel.setTaxDeductible(value ?? false)
                                : null,
                            activeColor: Colors.red,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tax Deductible',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: viewModel.isCategoryDeductible ? Colors.black : Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  viewModel.isCategoryDeductible
                                      ? 'This category qualifies for tax relief'
                                      : 'Not eligible for Malaysian tax relief',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: viewModel.isCategoryDeductible ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                                viewModel.isCategoryDeductible ? Icons.check_circle : Icons.error_outline,
                                color: viewModel.isCategoryDeductible ? Colors.green : Colors.red,
                                size: 24
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Descriptions'),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Examples...',
                      validator: (val) => (val != null && val.length > 100) ? 'Description too long (max 100 chars)' : null,
                    ),

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
                            Text('Capture receipt/proof', style: TextStyle(color: Colors.grey)),
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
                        onPressed: () => _saveExpense(viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

  String? _validateAmount(String? value, String fieldName, {bool allowZero = true}) {
    if (value == null || value.isEmpty) return 'Required';
    final n = double.tryParse(value);
    if (n == null) return 'Invalid number';
    if (n < 0) return '$fieldName cannot be negative';
    if (!allowZero && n == 0) return '$fieldName must be greater than zero';
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: _inputDecoration(hint),
        validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Required' : null,
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
