import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/tax_view_model.dart';

class TaxPage extends StatelessWidget {
  const TaxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaxViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view tax data.')));
    }

    if (viewModel.userModel == null) {
      return const Scaffold(body: Center(child: Text('User profile not found.')));
    }

    if (viewModel.hasNoRecords) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tax Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/add'),
                  child: const Text('Add a Record'),
                )
              ],
            ),
          ),
        ),
      );
    }

    final claimedReliefs = viewModel.claimedReliefs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tax Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Tax Relief Claimed:',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${viewModel.totalReliefClaimed.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (claimedReliefs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No tax reliefs claimed yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: claimedReliefs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final item = claimedReliefs[index];
                          return _buildReliefItem(
                            item['title'],
                            item['amount'],
                            item['limit'],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (viewModel.totalDonations > 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Donations & Gifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              ),
              const SizedBox(height: 12),
              _buildSimpleInfoCard('Total Donations', viewModel.totalDonations),
              const SizedBox(height: 24),
            ],
            if (viewModel.totalZakat > 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Tax Rebates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              ),
              const SizedBox(height: 12),
              _buildSimpleInfoCard('Zakat', viewModel.totalZakat, isRebate: true),
              const SizedBox(height: 24),
            ],
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Update your Profile to change fixed relief settings.')),
                  );
                },
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Adjust Fixed Reliefs in Profile'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReliefItem(String title, double current, double limit) {
    double progress = (current / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: progress >= 1.0 ? Colors.orange : Colors.purple,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'RM ${current.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13, 
              color: progress >= 1.0 ? Colors.orange.shade900 : Colors.black54,
              fontWeight: progress >= 1.0 ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfoCard(String title, double amount, {bool isRebate = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRebate ? Colors.green.shade700 : Colors.black),
        ),
      ),
    );
  }
}
