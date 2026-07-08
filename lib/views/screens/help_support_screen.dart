import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/section_card.dart';
import '../widgets/yellow_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    ('How do I cancel a ride?', 'Open your active ride and tap "Cancel Ride" before the driver arrives. Cancellation fees may apply after a few minutes.'),
    ('How are fares calculated?', 'Fares are based on distance, estimated time, vehicle type and current demand in your area.'),
    ('How do I add money to my wallet?', 'Go to Wallet from the bottom navigation and tap "Add Money" to top up using UPI or a card.'),
    ('Is my trip data safe?', 'Yes. Your ride and location data is encrypted and only shared with your assigned driver during an active trip.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Help & Support'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.support_agent, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need urgent help?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 15))),
                          const SizedBox(height: 2),
                          const Text('Our support team is available 24/7', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ContactTile(
                      icon: Icons.call_outlined,
                      label: 'Call Us',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling 1800-123-4567 ...')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactTile(
                      icon: Icons.chat_bubble_outline,
                      label: 'Live Chat',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connecting you to a support agent ...')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactTile(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening support@ridego.com ...')),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 15))),
              const SizedBox(height: 10),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _faqs
                      .map((faq) => ExpansionTile(
                            title: Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            expandedAlignment: Alignment.centerLeft,
                            children: [Text(faq.$2, style: const TextStyle(color: AppColors.textSecondary))],
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              YellowButton(
                text: 'Report an Issue',
                icon: Icons.flag_outlined,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Report an issue'),
                    content: const TextField(
                      maxLines: 4,
                      decoration: InputDecoration(hintText: 'Describe the issue you faced...'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thanks! Your report has been submitted.')),
                          );
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryDark),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
