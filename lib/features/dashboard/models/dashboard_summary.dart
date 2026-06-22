import 'transaction_preview.dart';
import 'user_profile.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.profile,
    required this.recentTransactions,
  });

  final UserProfile profile;
  final List<TransactionPreview> recentTransactions;
}
