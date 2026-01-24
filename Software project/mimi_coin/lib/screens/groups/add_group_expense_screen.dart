import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/group_model.dart';
import '../../models/expense_model.dart';
import '../../services/supabase_service.dart';

class AddGroupExpenseScreen extends StatefulWidget {
  final GroupModel group;
  final List<GroupMember> members;

  const AddGroupExpenseScreen({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  State<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends State<AddGroupExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _supabaseService = SupabaseService();

  String _selectedCategory = AppConstants.expenseCategories.first;
  String _selectedPaymentMethod = AppConstants.paymentMethods.first;
  DateTime _selectedDate = DateTime.now();
  String _splitMethod = 'Equal';
  Map<String, bool> _selectedMembers = {};
  Map<String, double> _customAmounts = {};
  Map<String, double> _percentages = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Select all members by default
    for (var member in widget.members) {
      _selectedMembers[member.userId] = true;
      _percentages[member.userId] = 100.0 / widget.members.length;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _selectedMemberCount =>
      _selectedMembers.values.where((v) => v).length;

  double get _totalAmount => double.tryParse(_amountController.text) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Group Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.members.length} members • ${widget.group.currency}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPink,
                        ),
                        decoration: InputDecoration(
                          prefixText: _getCurrencySymbol(),
                          hintText: '0.00',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: AppConstants.expenseCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'What was this expense for?',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightPink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryPink,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Split method
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.splitMethods.map((method) {
                          final isSelected = _splitMethod == method;
                          return ChoiceChip(
                            label: Text(method),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _splitMethod = method);
                            },
                            selectedColor: AppTheme.primaryPink,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Members selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Split Between',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_selectedMemberCount selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.members.map((member) {
                        return _buildMemberTile(member);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Split preview
              if (_totalAmount > 0 && _selectedMemberCount > 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Preview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildSplitPreview(),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Expense'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member) {
    final isSelected = _selectedMembers[member.userId] ?? false;
    final isCurrentUser = member.userId == _supabaseService.userId;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          _selectedMembers[member.userId] = value!;
          _updatePercentages();
        });
      },
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.mediumPink,
            child: Text(
              (member.userName ?? member.userEmail ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.userName ?? member.userEmail ?? 'Unknown',
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'You',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      secondary: _splitMethod == 'Percentage' && isSelected
          ? SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _percentages[member.userId]?.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: '%',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                onChanged: (value) {
                  _percentages[member.userId] = double.tryParse(value) ?? 0;
                  setState(() {});
                },
              ),
            )
          : _splitMethod == 'Custom Amount' && isSelected
              ? SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: _customAmounts[member.userId]?.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      prefixText: _getCurrencySymbol(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) {
                      _customAmounts[member.userId] = double.tryParse(value) ?? 0;
                      setState(() {});
                    },
                  ),
                )
              : null,
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.primaryPink,
    );
  }

  void _updatePercentages() {
    final selectedCount = _selectedMemberCount;
    if (selectedCount > 0) {
      final equalPercentage = 100.0 / selectedCount;
      for (var userId in _selectedMembers.keys) {
        if (_selectedMembers[userId] == true) {
          _percentages[userId] = equalPercentage;
        }
      }
    }
  }

  List<Widget> _buildSplitPreview() {
    final List<Widget> widgets = [];
    final splitAmount = _splitMethod == 'Equal'
        ? _totalAmount / _selectedMemberCount
        : 0.0;

    for (var member in widget.members) {
      if (_selectedMembers[member.userId] != true) continue;

      double amount;
      switch (_splitMethod) {
        case 'Equal':
          amount = splitAmount;
          break;
        case 'Percentage':
          amount = _totalAmount * (_percentages[member.userId] ?? 0) / 100;
          break;
        case 'Custom Amount':
          amount = _customAmounts[member.userId] ?? 0;
          break;
        default:
          amount = splitAmount;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(member.userName ?? member.userEmail ?? 'Unknown'),
              Text(
                '${_getCurrencySymbol()}${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  String _getCurrencySymbol() {
    final currency = AppConstants.currencies.firstWhere(
      (c) => c['code'] == widget.group.currency,
      orElse: () => {'symbol': '\$'},
    );
    return currency['symbol'] ?? '\$';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMemberCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 members to split the expense'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabaseService.userId;
      if (userId == null) throw Exception('User not logged in');

      final expense = ExpenseModel(
        id: const Uuid().v4(),
        userId: userId,
        amount: _totalAmount,
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        groupId: widget.group.id,
        isGroupExpense: true,
        currency: widget.group.currency,
        createdAt: DateTime.now(),
      );

      await _supabaseService.createExpense(expense);

      // Create splits
      final splits = <ExpenseSplit>[];
      for (var member in widget.members) {
        if (_selectedMembers[member.userId] != true) continue;

        double amount;
        double? percentage;

        switch (_splitMethod) {
          case 'Equal':
            amount = _totalAmount / _selectedMemberCount;
            break;
          case 'Percentage':
            percentage = _percentages[member.userId] ?? 0;
            amount = _totalAmount * percentage / 100;
            break;
          case 'Custom Amount':
            amount = _customAmounts[member.userId] ?? 0;
            break;
          default:
            amount = _totalAmount / _selectedMemberCount;
        }

        splits.add(ExpenseSplit(
          id: const Uuid().v4(),
          expenseId: expense.id,
          userId: member.userId,
          userName: member.userName,
          amount: amount,
          percentage: percentage,
          isPaid: member.userId == userId,
          createdAt: DateTime.now(),
        ));
      }

      await _supabaseService.createExpenseSplits(splits);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group expense added'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
