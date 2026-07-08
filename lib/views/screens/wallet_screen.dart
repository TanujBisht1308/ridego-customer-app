import 'package:flutter/material.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/transaction_item.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/section_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _controller = RideController.instance;

  @override
  void initState() {
    super.initState();
    _controller.fetchWallet().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _addMoney() async {
    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Enter amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.black),
            onPressed: () => Navigator.pop(context, double.tryParse(amountController.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      final success = await _controller.addMoneyToWallet(amount);
      if (!mounted) return;
      if (success) {
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add money. Try again.')),
        );
      }
    }
  }     

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'My Wallet'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Balance', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('₹${_controller.walletBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: Responsive.font(context, 30), fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addMoney,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.card, foregroundColor: AppColors.black, elevation: 0),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Money'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent Transactions', style: TextStyle(fontSize: Responsive.font(context, 16), fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              ..._controller.transactions.map((item) => _TransactionCard(item: item)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionItem item;
  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final positive = item.amount.startsWith('+');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(color: positive ? AppColors.success.withValues(alpha: .10) : AppColors.primary.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
              child: Icon(positive ? Icons.add_card : Icons.local_taxi, color: positive ? AppColors.success : AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(item.amount, style: TextStyle(color: positive ? AppColors.success : AppColors.textPrimary, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
