import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/income_record.dart';
import '../viewmodels/add_income_view_model.dart';
import '../widgets/form_parts.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key, this.existing});

  /// When set, the form edits this record instead of adding a new one.
  final IncomeRecord? existing;

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
    final existing = widget.existing;
    if (existing != null) {
      String money(double v) => v.toStringAsFixed(2);
      _totalIncomeController.text = money(existing.totalIncome);
      _epfController.text = money(existing.epfAmount);
      _socsoController.text = money(existing.socsoAmount);
      _pcbController.text = money(existing.pcbAmount);
      _descriptionController.text = existing.description ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AddIncomeViewModel>();
      final existing = widget.existing;
      if (existing == null) {
        vm.clearData();
      } else {
        vm.loadForEdit(existing);
      }
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
      double v(TextEditingController c) => double.tryParse(c.text) ?? 0;
      // Deductions come out of gross income, so together they can't exceed it.
      if (v(_epfController) + v(_socsoController) + v(_pcbController) > v(_totalIncomeController)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EPF, SOCSO and PCB together can\'t be more than gross income.')),
        );
        return;
      }
      final success = await viewModel.saveIncome(
        totalIncomeStr: _totalIncomeController.text,
        epfStr: _epfController.text,
        socsoStr: _socsoController.text,
        pcbStr: _pcbController.text,
        description: _descriptionController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existing == null ? 'Income saved' : 'Income updated')),
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
      appBar: AppBar(title: Text(viewModel.isEditing ? 'Edit income' : 'Add income')),
      bottomNavigationBar: BottomActionBar(label: viewModel.isEditing ? 'Save changes' : 'Save income', onPressed: () => _saveIncome(viewModel)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
          children: [
            const FormLabel('Gross income'),
            FormInput(
              controller: _totalIncomeController,
              hint: '0.00',
              isNumber: true,
              isMoney: true,
              validator: FormInput.amount('Gross income', allowZero: false),
            ),
            const FormLabel('EPF'),
            FormInput(
              controller: _epfController,
              hint: '0.00',
              isNumber: true,
              isMoney: true,
              validator: FormInput.amount('EPF'),
            ),
            if (viewModel.isEpfLimitReached)
              _buildLimitWarning(
                  'You have reached the ${formatRM(AddIncomeViewModel.EPF_LIMIT, whole: true)} EPF relief limit, so this entry won\'t lower your tax further.'),
            const FormLabel('SOCSO'),
            FormInput(
              controller: _socsoController,
              hint: '0.00',
              isNumber: true,
              isMoney: true,
              validator: FormInput.amount('SOCSO'),
            ),
            if (viewModel.isSocsoLimitReached)
              _buildLimitWarning(
                  'You have reached the ${formatRM(AddIncomeViewModel.SOCSO_LIMIT, whole: true)} SOCSO relief limit, so this entry won\'t lower your tax further.'),
            const FormLabel('PCB'),
            FormInput(
              controller: _pcbController,
              hint: '0.00',
              isNumber: true,
              isMoney: true,
              validator: FormInput.amount('PCB'),
            ),
            const FormLabel('Category'),
            DropdownButtonFormField<String>(
              value: viewModel.selectedCategory,
              isExpanded: true,
              items: viewModel.categories.map((String category) {
                return DropdownMenuItem(value: category, child: Text(category, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  viewModel.setCategory(newValue);
                }
              },
            ),
            const SizedBox(height: AppTheme.space4),
            const FormLabel('Description'),
            FormInput(controller: _descriptionController, hint: 'e.g. November salary', validator: FormInput.maxLength(100)),
            const FormLabel('Date'),
            DateField(date: viewModel.selectedDate, onTap: () => _selectDate(context, viewModel)),
            if (!viewModel.isEditing)
              RepeatMonthlyTile(
              value: viewModel.repeatMonthly,
              dayOfMonth: viewModel.selectedDate.day,
              onChanged: viewModel.setRepeatMonthly,
            ),
            const SizedBox(height: AppTheme.space4),
            const FormLabel('Payslip'),
            ProofPicker(
              imagePath: viewModel.proofImagePath,
              emptyLabel: 'Add a photo of the payslip',
              onTap: () => _pickImage(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitWarning(String message) {
    final app = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(color: app.warningContainer, borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: app.onWarningContainer),
          const SizedBox(width: AppTheme.space2),
          Expanded(child: Text(message, style: context.text.bodySmall?.copyWith(color: app.onWarningContainer))),
        ],
      ),
    );
  }
}
