import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/expense_model.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final CurrencyService _currencyService = CurrencyService();
  late ExpenseModel _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    _loadCurrencyRates();
  }

  Future<void> _loadCurrencyRates() async {
    await _currencyService.loadRates(_expense.currency);
    setState(() {});
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteExpense(_expense.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconCode = AppConstants.categoryIcons[_expense.category] ?? 0xe5d3;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(expense: _expense),
                ),
              );
              if (result == true) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteExpense,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(iconCode, fontFamily: 'MaterialIcons', matchTextDirection: true),
                        size: 40,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currencyService.formatCurrency(
                        _expense.amount,
                        _expense.currency,
                      ),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mediumPink.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _expense.category,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.darkPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: dateFormat.format(_expense.date),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: timeFormat.format(_expense.date),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.payment,
                      label: 'Payment Method',
                      value: _expense.paymentMethod,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.currency_exchange,
                      label: 'Currency',
                      value: _expense.currency,
                    ),
                    if (_expense.description != null &&
                        _expense.description!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        icon: Icons.notes,
                        label: 'Description',
                        value: _expense.description!,
                        isMultiline: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetadataRow(
                      'Created',
                      DateFormat('MMM d, yyyy h:mm a').format(_expense.createdAt),
                    ),
                    if (_expense.updatedAt != null)
                      _buildMetadataRow(
                        'Last Updated',
                        DateFormat('MMM d, yyyy h:mm a').format(_expense.updatedAt!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(expense: _expense),
                        ),
                      );
                      if (result == true) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.lightPink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryPink,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
