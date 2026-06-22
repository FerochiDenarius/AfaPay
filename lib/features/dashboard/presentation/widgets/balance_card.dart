import 'package:flutter/material.dart';

import '../../models/wallet_balance.dart';

const _gold = Color(0xFFF5B81F);

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
    required this.onFundWallet,
    required this.onRetry,
    this.errorMessage,
  });

  final WalletBalance? balance;
  final bool isLoading;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onFundWallet;
  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final value = balance == null
        ? '₦0.00'
        : _formatCurrency(balance!.balance, balance!.currency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF112A55), Color(0xFF071326), Color(0xFF050A12)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF263B58)),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AFA Balance',
                  style: TextStyle(color: Color(0xFFA9ABB2), fontSize: 15),
                ),
              ),
              IconButton(
                tooltip: isBalanceVisible ? 'Hide Balance' : 'Show Balance',
                onPressed: onToggleVisibility,
                icon: Icon(
                  isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const _BalanceSkeleton()
          else if (errorMessage != null)
            _BalanceError(message: errorMessage!, onRetry: onRetry)
          else
            Text(
              isBalanceVisible ? value : '••••••••',
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onFundWallet,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text(
                'Fund Wallet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceError extends StatelessWidget {
  const _BalanceError({required this.message, required this.onRetry});

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

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonBox(width: 190, height: 36);
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.1, 0.5, 0.9],
              colors: const [
                Color(0xFF111A27),
                Color(0xFF243149),
                Color(0xFF111A27),
              ],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}

String _formatCurrency(double amount, String currency) {
  final symbol = switch (currency.toUpperCase()) {
    'NGN' => '₦',
    'GHS' => 'GH₵',
    'USD' => r'$',
    _ => '$currency ',
  };
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < whole.length; index++) {
    final remaining = whole.length - index;
    buffer.write(whole[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '$symbol${buffer.toString()}.${parts.last}';
}
