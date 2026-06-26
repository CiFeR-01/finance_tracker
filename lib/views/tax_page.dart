import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../viewmodels/tax_view_model.dart';
import 'add_tax_exemption_page.dart';

class TaxPage extends StatelessWidget {
  const TaxPage({super.key});

  void _showTransactions(BuildContext context, String title, List<dynamic> transactions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ),
            const Divider(),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text('No transactions found'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  if (tx is IncomeRecord) {
                    double amount = 0;
                    if (title == 'Life Insurance and EPF') amount = tx.epfAmount;
                    if (title == 'SOCSO Contribution') amount = tx.socsoAmount;

                    return ListTile(
                      title: Text(tx.category),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(tx.incomeDate)),
                      trailing: Text('RM ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    );
                  } else if (tx is ExpenseRecord) {
                    return ListTile(
                      title: Text(tx.category),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(tx.expenseDate)),
                      trailing: Text('RM ${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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

    final fixedReliefs = viewModel.userModel!.taxProfile.getFixedReliefItems();
    final fixedTitles = fixedReliefs.map((e) => e['title'] as String).toList();

    bool checkIfFixed(String title) {
      if (fixedTitles.contains(title)) return true;
      if (title.startsWith('Child Relief')) return true;
      if (title.startsWith('Disabled Child')) return true;
      return false;
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddTaxExemptionPage()),
                    );
                  },
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
                          final title = item['title'] as String;
                          final isFixed = checkIfFixed(title);

                          return InkWell(
                            onTap: isFixed ? null : () {
                              final txs = viewModel.getTransactionsForRelief(title);
                              _showTransactions(context, title, txs);
                            },
                            child: _buildReliefItem(
                              title,
                              item['amount'],
                              item['limit'],
                              isClickable: !isFixed,
                            ),
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
              _buildSimpleInfoCard(
                'Total Donations',
                viewModel.totalDonations,
                onTap: () {
                  final txs = viewModel.getTransactionsForRelief('Total Donations');
                  _showTransactions(context, 'Donations & Gifts', txs);
                },
              ),
              const SizedBox(height: 24),
            ],
            if (viewModel.totalZakat > 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Tax Rebates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              ),
              const SizedBox(height: 12),
              _buildSimpleInfoCard(
                'Zakat',
                viewModel.totalZakat,
                isRebate: true,
                onTap: () {
                  final txs = viewModel.getTransactionsForRelief('Zakat');
                  _showTransactions(context, 'Zakat', txs);
                },
              ),
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

  Widget _buildReliefItem(String title, double current, double limit, {bool isClickable = false}) {
    double progress = (current / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              if (isClickable) const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
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
      ),
    );
  }

  Widget _buildSimpleInfoCard(String title, double amount, {bool isRebate = false, VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRebate ? Colors.green.shade700 : Colors.black),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}