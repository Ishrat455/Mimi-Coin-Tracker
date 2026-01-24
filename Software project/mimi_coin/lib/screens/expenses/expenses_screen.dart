import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/expense_model.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import '../../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  bool _isLoading = true;
  String _currency = 'USD';
  
  // Filters
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTimeRange? _dateRange;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    try {
      final user = await _supabaseService.getUserProfile();
      if (user != null) {
        _currency = user.baseCurrency;
        await _currencyService.loadRates(_currency);
      }

      final expenses = await _supabaseService.getExpenses(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        limit: 200,
      );

      setState(() {
        _expenses = expenses;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expenses: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredExpenses = List.from(_expenses);

    // Apply search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      _filteredExpenses = _filteredExpenses.where((e) {
        return e.description?.toLowerCase().contains(query) == true ||
            e.category.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    _filteredExpenses.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        default:
          comparison = a.date.compareTo(b.date);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedPaymentMethod: _selectedPaymentMethod,
        dateRange: _dateRange,
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        onApply: (category, paymentMethod, dateRange, sortBy, sortAscending) {
          setState(() {
            _selectedCategory = category;
            _selectedPaymentMethod = paymentMethod;
            _dateRange = dateRange;
            _sortBy = sortBy;
            _sortAscending = sortAscending;
          });
          _loadExpenses();
        },
        onReset: () {
          setState(() {
            _selectedCategory = null;
            _selectedPaymentMethod = null;
            _dateRange = null;
            _sortBy = 'date';
            _sortAscending = false;
          });
          _loadExpenses();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedCategory != null ||
                    _selectedPaymentMethod != null ||
                    _dateRange != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilters());
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _applyFilters());
              },
            ),
          ),

          // Summary card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_filteredExpenses.length} expenses',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${_currencyService.formatCurrency(total, _currency)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                      ],
                    ),
                    if (_dateRange != null)
                      Chip(
                        label: Text(
                          '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () {
                          setState(() => _dateRange = null);
                          _loadExpenses();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Expense list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryPink),
                  )
                : _filteredExpenses.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadExpenses,
                        color: AppTheme.primaryPink,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = _filteredExpenses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ExpenseCard(
                                expense: expense,
                                baseCurrency: _currency,
                                onTap: () => _navigateToDetail(expense),
                                onDelete: () => _deleteExpense(expense),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) {
            _loadExpenses();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppTheme.mediumPink.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No matching expenses'
                  : 'No expenses yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Tap the + button to add your first expense',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(ExpenseModel expense) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expense: expense),
      ),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
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
        await _supabaseService.deleteExpense(expense.id);
        _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted'),
              backgroundColor: AppTheme.success,
            ),
          );
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
}

class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedPaymentMethod;
  final DateTimeRange? dateRange;
  final String sortBy;
  final bool sortAscending;
  final Function(String?, String?, DateTimeRange?, String, bool) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    this.selectedCategory,
    this.selectedPaymentMethod,
    this.dateRange,
    required this.sortBy,
    required this.sortAscending,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _category;
  late String? _paymentMethod;
  late DateTimeRange? _dateRange;
  late String _sortBy;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _paymentMethod = widget.selectedPaymentMethod;
    _dateRange = widget.dateRange;
    _sortBy = widget.sortBy;
    _sortAscending = widget.sortAscending;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumPink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onReset();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category filter
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (selected) {
                        setState(() => _category = null);
                      },
                    ),
                    ...AppConstants.expenseCategories.map(
                      (cat) => FilterChip(
                        label: Text(cat),
                        selected: _category == cat,
                        onSelected: (selected) {
                          setState(() => _category = selected ? cat : null);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Payment method filter
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _paymentMethod == null,
                      onSelected: (selected) {
                        setState(() => _paymentMethod = null);
                      },
                    ),
                    ...AppConstants.paymentMethods.map(
                      (method) => FilterChip(
                        label: Text(method),
                        selected: _paymentMethod == method,
                        onSelected: (selected) {
                          setState(() => _paymentMethod = selected ? method : null);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date range
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (range != null) {
                      setState(() => _dateRange = range);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumPink),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: AppTheme.primaryPink),
                        const SizedBox(width: 12),
                        Text(
                          _dateRange != null
                              ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                              : 'Select date range',
                        ),
                        const Spacer(),
                        if (_dateRange != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() => _dateRange = null);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sort options
                Text(
                  'Sort By',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(value: 'amount', child: Text('Amount')),
                          DropdownMenuItem(value: 'category', child: Text('Category')),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: AppTheme.primaryPink,
                      ),
                      onPressed: () {
                        setState(() => _sortAscending = !_sortAscending);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _category,
                        _paymentMethod,
                        _dateRange,
                        _sortBy,
                        _sortAscending,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
