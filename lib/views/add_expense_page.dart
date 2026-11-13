import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/expense_record.dart';
import '../viewmodels/add_expense_view_model.dart';
import '../widgets/form_parts.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import '../services/receipt_scanner.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key, this.existing});

  /// When set, the form edits this record instead of adding a new one.
  final ExpenseRecord? existing;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(2);
      _descriptionController.text = existing.description ?? '';
    }
    _amountController.addListener(_onAmountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AddExpenseViewModel>();
      final existing = widget.existing;
      if (existing == null) {
        vm.clearData();
      } else {
        vm.loadForEdit(existing);
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    context.read<AddExpenseViewModel>().setAmount(_amountController.text);
  }

  /// Photograph (or pick) a receipt, read it with on-device OCR and fill in
  /// the amount, date and description. The photo is kept as proof.
  Future<void> _scanReceipt(AddExpenseViewModel viewModel) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 2000);
    if (picked == null || !mounted) return;

    setState(() => _scanning = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final saved = await File(picked.path).copy('${appDir.path}/${p.basename(picked.path)}');
      viewModel.setImagePath(saved.path);

      final data = await ReceiptScanner.scan(saved.path);
      if (!mounted) return;
      if (data.total != null) _amountController.text = data.total!.toStringAsFixed(2);
      if (data.date != null) viewModel.setDate(data.date!);
      if (data.merchant != null && _descriptionController.text.isEmpty) {
        _descriptionController.text = data.merchant!;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(data.isEmpty
            ? "Couldn't read this receipt. The photo is attached; please fill in the details."
            : 'Filled in from the receipt. Check the amount before saving.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Receipt scan failed: $e')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
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
          SnackBar(content: Text(widget.existing == null ? 'Expense saved' : 'Expense updated')),
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
      appBar: AppBar(title: Text(viewModel.isEditing ? 'Edit expense' : 'Add expense')),
      bottomNavigationBar: BottomActionBar(label: viewModel.isEditing ? 'Save changes' : 'Save expense', onPressed: () => _saveExpense(viewModel)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
          children: [
            FilledButton.tonalIcon(
              onPressed: _scanning ? null : () => _scanReceipt(viewModel),
              icon: _scanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_scanning ? 'Reading receipt…' : 'Scan receipt'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: AppTheme.space5),
            const FormLabel('Amount'),
            FormInput(
              controller: _amountController,
              hint: '0.00',
              isNumber: true,
              isMoney: true,
              validator: FormInput.amount('Amount', allowZero: false),
            ),
            const FormLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue: viewModel.selectedCategory,
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
            const SizedBox(height: AppTheme.space3),
            _buildTaxDeductibleSection(viewModel),
            const SizedBox(height: AppTheme.space4),
            const FormLabel('Description'),
            FormInput(controller: _descriptionController, hint: 'e.g. Clinic visit', validator: FormInput.maxLength(100)),
            const FormLabel('Date'),
            DateField(date: viewModel.selectedDate, onTap: () => _selectDate(context, viewModel)),
            if (!viewModel.isEditing)
              RepeatMonthlyTile(
              value: viewModel.repeatMonthly,
              dayOfMonth: viewModel.selectedDate.day,
              onChanged: viewModel.setRepeatMonthly,
            ),
            const SizedBox(height: AppTheme.space4),
            const FormLabel('Receipt'),
            ProofPicker(
              imagePath: viewModel.proofImagePath,
              emptyLabel: 'Add a photo of the receipt',
              onTap: () => _pickImage(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxDeductibleSection(AddExpenseViewModel viewModel) {
    final app = context.appColors;
    final isEligible = viewModel.isCategoryDeductible;
    final isLimitExceeded = viewModel.isLimitExceeded;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String message;
    if (!isEligible) {
      bg = context.colors.surfaceContainerHigh;
      fg = context.colors.onSurfaceVariant;
      icon = Icons.block_rounded;
      message = 'Not eligible for Malaysian tax relief';
    } else if (isLimitExceeded) {
      bg = app.warningContainer;
      fg = app.onWarningContainer;
      icon = Icons.warning_amber_rounded;
      message = 'Over the remaining ${formatRM(viewModel.getRemainingLimit(viewModel.selectedCategory), whole: true)} limit';
    } else {
      bg = app.taxContainer;
      fg = app.onTaxContainer;
      icon = Icons.verified_rounded;
      message = 'This category qualifies for tax relief';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space2, AppTheme.space2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4)),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tax deductible', style: context.text.titleSmall?.copyWith(color: fg)),
                Text(message, style: context.text.bodySmall?.copyWith(color: fg)),
              ],
            ),
          ),
          Switch(
            value: viewModel.isTaxDeductible,
            onChanged: (isEligible && !isLimitExceeded) ? (value) => viewModel.setTaxDeductible(value) : null,
          ),
        ],
      ),
    );
  }
}
