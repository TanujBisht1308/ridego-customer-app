class TransactionItem {
  final String title;
  final String subtitle;
  final String amount;
  final String status; // Completed | Cancelled

  const TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.status = 'Completed',
  });
}
