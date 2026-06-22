import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final String amount;
  final String category;
  final String date;
  final Color borderColor;
  final Color amountColor;
  final VoidCallback onDelete;
  final String? taxTag;

  const TransactionCard({
    super.key,
    required this.amount,
    required this.category,
    required this.date,
    required this.borderColor,
    required this.amountColor,
    required this.onDelete,
    this.taxTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    if (taxTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          taxTag!,
                          style: TextStyle(color: Colors.purple.shade300, fontSize: 10),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
