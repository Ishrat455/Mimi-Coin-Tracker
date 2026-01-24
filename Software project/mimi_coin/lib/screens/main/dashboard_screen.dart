import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/expense_model.dart';
import '../../models/reminder_model.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import '../expenses/add_expense_screen.dart';
import '../../widgets/category_chart.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final CurrencyService _currencyService = CurrencyService();
  
  bool _isLoading = true;
  double _monthlyTotal = 0;
  double _weeklyTotal = 0;
  double? _monthlyBudget;
  Map<String, double> _categoryBreakdown = {};
  List<ExpenseModel> _recentExpenses = [];
  List<ReminderModel> _upcomingReminders = [];
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _supabaseService.getUserProfile();
      if (user != null) {
        _currency = user.baseCurrency;
        _monthlyBudget = user.monthlyBudget;
        await _currencyService.loadRates(_currency);
      }

      final stats = await _supabaseService.getDashboardStats();
      
      setState(() {
        _monthlyTotal = stats['monthlyTotal'] as double;
        _weeklyTotal = stats['weeklyTotal'] as double;
        _categoryBreakdown = stats['categoryBreakdown'] as Map<String, double>;
        _recentExpenses = stats['recentExpenses'] as List<ExpenseModel>;
        _upcomingReminders = stats['upcomingReminders'] as List<ReminderModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppTheme.primaryPink,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryPink),
                )
              : CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMMM yyyy').format(now),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: _loadDashboardData,
                              icon: const Icon(Icons.refresh),
                              color: AppTheme.primaryPink,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stats Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'This Month',
                                value: _currencyService.formatCurrency(
                                  _monthlyTotal,
                                  _currency,
                                ),
                                icon: Icons.calendar_month,
                                color: AppTheme.primaryPink,
                                subtitle: _monthlyBudget != null
                                    ? 'Budget: ${_currencyService.formatCurrency(_monthlyBudget!, _currency)}'
                                    : null,
                                progress: _monthlyBudget != null && _monthlyBudget! > 0
                                    ? _monthlyTotal / _monthlyBudget!
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'This Week',
                                value: _currencyService.formatCurrency(
                                  _weeklyTotal,
                                  _currency,
                                ),
                                icon: Icons.date_range,
                                color: AppTheme.darkPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Category Chart
                    if (_categoryBreakdown.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spending by Category',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: CategoryChart(
                                      data: _categoryBreakdown,
                                      currency: _currency,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Upcoming Reminders
                    if (_upcomingReminders.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Upcoming Reminders',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to reminders
                                },
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _upcomingReminders.length,
                            itemBuilder: (context, index) {
                              final reminder = _upcomingReminders[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < _upcomingReminders.length - 1 ? 12 : 0,
                                ),
                                child: _buildReminderCard(reminder),
                              );
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    // Recent Expenses
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Expenses',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to expenses tab
                              },
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_recentExpenses.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: AppTheme.mediumPink.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No expenses yet',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start tracking by adding your first expense',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: ExpenseCard(
                                expense: _recentExpenses[index],
                                baseCurrency: _currency,
                                onTap: () {
                                  // Navigate to expense details
                                },
                              ),
                            );
                          },
                          childCount: _recentExpenses.length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) {
            _loadDashboardData();
          }
        },
        backgroundColor: AppTheme.primaryPink,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.primaryPink,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reminder.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            DateFormat('MMM d, h:mm a').format(reminder.reminderDate),
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
