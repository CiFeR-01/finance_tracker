import 'package:flutter/material.dart';

class AddTaxExemptionPage extends StatefulWidget {
  const AddTaxExemptionPage({super.key});

  @override
  State<AddTaxExemptionPage> createState() => _AddTaxExemptionPageState();
}

class _AddTaxExemptionPageState extends State<AddTaxExemptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Helper widget to build labels with red asterisks like the wireframe
  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
          children: [
            if (isRequired)
              const TextSpan(
                  text: ' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tax Exemption',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Amount
              _buildLabel('Amount', isRequired: true),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.0',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Category
              _buildLabel('Category', isRequired: true),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  hintText: 'Salary',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Descriptions
              _buildLabel('Descriptions'),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Examples...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Date (with Calendar Picker)
              _buildLabel('Date', isRequired: true),
              TextFormField(
                controller: _dateController,
                readOnly: true, // Prevents typing, forces them to use the calendar
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    // Formats date to match wireframe exactly
                    String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                    setState(() {
                      _dateController.text = formattedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 5. Receipt Section
              _buildLabel('Receipt'),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                ),
                // This is a placeholder icon until you connect the phone's camera
                child: const Center(
                  child: Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),

              // Scan Again Button
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera connection coming soon!'))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Scan Again'),
              ),
              const SizedBox(height: 40),

              // 6. Bottom Add Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic to send data to Firebase will go here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}