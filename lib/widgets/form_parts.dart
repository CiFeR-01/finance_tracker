import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Shared pieces for the Add Income / Add Expense forms.

/// A field label above an input.
class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space1, bottom: AppTheme.space2),
      child: Text(text, style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
    );
  }
}

/// A required text/number input with the app's standard validation.
class FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isNumber;
  final bool isMoney;

  /// Overrides the default "required" check.
  final String? Function(String?)? validator;

  const FormInput({
    super.key,
    required this.controller,
    required this.hint,
    this.isNumber = false,
    this.isMoney = false,
    this.validator,
  });

  /// Money field check: required, a number, not negative, and (unless
  /// [allowZero]) more than zero.
  static String? Function(String?) amount(String fieldName, {bool allowZero = true}) => (value) {
        if (value == null || value.isEmpty) return 'Required';
        final n = double.tryParse(value);
        if (n == null) return 'Enter a valid number';
        if (n < 0) return '$fieldName cannot be negative';
        if (!allowZero && n == 0) return '$fieldName must be more than zero';
        return null;
      };

  /// Optional text, up to [max] characters.
  static String? Function(String?) maxLength(int max) =>
      (value) => (value != null && value.length > max) ? 'Too long (max $max characters)' : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: isMoney ? 'RM ' : null,
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (isNumber && double.tryParse(value) == null) return 'Enter a valid number';
              return null;
            },
      ),
    );
  }
}

/// Shows the chosen date and opens a picker on tap.
class DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const DateField({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: InputDecorator(
          decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_rounded, size: 20)),
          child: Text(DateFormat('EEE, d MMM yyyy').format(date), style: context.text.bodyLarge),
        ),
      ),
    );
  }
}

/// Tap-to-attach area for a receipt or payslip photo, with preview.
class ProofPicker extends StatelessWidget {
  final String? imagePath;
  final String emptyLabel;
  final VoidCallback onTap;
  const ProofPicker({super.key, required this.imagePath, required this.emptyLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 150,
          child: imagePath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 36, color: colors.onSurfaceVariant),
                    const SizedBox(height: AppTheme.space2),
                    Text(emptyLabel, style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                )
              : Image.file(File(imagePath!), fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// A full-width primary button pinned above the keyboard / system bar.
class BottomActionBar extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const BottomActionBar({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space4),
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// "Repeat monthly" switch for the add forms.
class RepeatMonthlyTile extends StatelessWidget {
  final bool value;
  final int dayOfMonth;
  final ValueChanged<bool> onChanged;
  const RepeatMonthlyTile({super.key, required this.value, required this.dayOfMonth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.event_repeat_rounded),
        title: const Text('Repeat monthly'),
        subtitle: Text(value ? 'Added automatically on day $dayOfMonth of every month' : 'For salary, rent, bills and subscriptions'),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
