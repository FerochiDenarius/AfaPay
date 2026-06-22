import 'package:flutter/material.dart';

import '../../models/transaction_preview.dart';

const _gold = Color(0xFFF5B81F);

class ActivityPreview extends StatelessWidget {
  const ActivityPreview({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final List<TransactionPreview> transactions;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07101C).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF22334A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Column(
              children: [
                _ActivitySkeleton(),
                SizedBox(height: 10),
                _ActivitySkeleton(),
                SizedBox(height: 10),
                _ActivitySkeleton(),
              ],
            )
          else if (errorMessage != null)
            _ActivityError(message: errorMessage!, onRetry: onRetry)
          else if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No recent transactions yet.',
                style: TextStyle(color: Color(0xFFA9ABB2)),
              ),
            )
          else
            ...transactions
                .take(3)
                .map(
                  (transaction) => _TransactionTile(transaction: transaction),
                ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionPreview transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForType(transaction.type), color: _gold),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleCase(transaction.type),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  _relativeTime(transaction.time),
                  style: const TextStyle(
                    color: Color(0xFFA9ABB2),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(transaction.amount, transaction.currency),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                _titleCase(transaction.status),
                style: TextStyle(
                  color: transaction.status.toLowerCase() == 'success'
                      ? const Color(0xFF55D98B)
                      : _gold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFFFF7373)),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF172334),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, color: const Color(0xFF172334)),
              const SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(height: 12, color: const Color(0xFF172334)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _iconForType(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('transfer')) return Icons.swap_horiz_rounded;
  if (normalized.contains('airtime')) return Icons.phone_android_rounded;
  if (normalized.contains('bill')) return Icons.receipt_long_rounded;
  return Icons.payments_outlined;
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[\s_]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

String _formatCurrency(double amount, String currency) {
  final symbol = switch (currency.toUpperCase()) {
    'NGN' => '₦',
    'GHS' => 'GH₵',
    'USD' => r'$',
    _ => '$currency ',
  };
  return '$symbol${amount.toStringAsFixed(2)}';
}
