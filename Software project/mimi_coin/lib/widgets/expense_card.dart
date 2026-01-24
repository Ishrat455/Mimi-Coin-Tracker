import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/expense_model.dart';
import '../services/currency_service.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String? baseCurrency;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
    this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService();
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(
                    AppConstants.categoryIcons[expense.category] ?? 0xe5d3,
                    fontFamily: 'MaterialIcons',
                    matchTextDirection: true,
                  ),
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description ?? expense.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(expense.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mediumPink.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            expense.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyService.formatCurrency(
                      expense.amount,
                      expense.currency,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  if (expense.paymentMethod.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          _getPaymentIcon(expense.paymentMethod),
                          size: 12,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expense.paymentMethod,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Debit Card':
        return Icons.credit_card_outlined;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Mobile Payment':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }
}
