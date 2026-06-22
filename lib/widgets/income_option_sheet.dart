import 'package:flutter/material.dart';

class IncomeOptionSheet extends StatelessWidget {
  final VoidCallback onEnterManually;

  const IncomeOptionSheet({super.key, required this.onEnterManually});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.purple),
            title: const Text('Enter Manually'),
            onTap: () {
              Navigator.pop(context);
              onEnterManually();
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: Colors.purple),
            title: const Text('Scan Payslip'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan payslip feature will be added later')),
              );
            },
          ),
        ],
      ),
    );
  }
}
