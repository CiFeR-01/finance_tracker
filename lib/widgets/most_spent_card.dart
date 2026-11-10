import 'package:flutter/material.dart';

class MostSpentCard extends StatelessWidget {
  final String category;
  final String amount;

  const MostSpentCard({
    super.key,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white, // Clean white background to match the dashboard
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E5F5), width: 1.5), // Much softer, subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Matches the new Summary Card shadows exactly
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded, // Visual cue for "burning" money
                  color: Color(0xFF9C27B0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Most Spent Category',
                style: TextStyle(
                  color: Color(0xFF7B1FA2),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Colors.black87, // High contrast for better readability
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFFC62828), // Deep red to subtly indicate high expense
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}