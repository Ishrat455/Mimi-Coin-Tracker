import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/expense_model.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import '../../services/export_service.dart';
import '../../widgets/category_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final CurrencyService _currencyService = CurrencyService();
  final ExportService _exportService = ExportService();
  
  late TabController _tabController;
  bool _isLoading = true;
  String _currency = 'USD';
  String _selectedPeriod = 'Monthly';
  DateTimeRange? _customRange;

  List<ExpenseModel> _expenses = [];
  Map<String, double> _categoryBreakdown = {};
  List<Map<String, dynamic>> _monthlyTrend = [];
  double _totalExpenses = 0;
  double _averageDaily = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Weekly':
        return DateTimeRange(
          start: now.subtract(Duration(days: now.weekday - 1)),
          end: now,
        );
      case 'Monthly':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'Yearly':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case 'Custom Range':
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            );
      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _supabaseService.getUserProfile();
      if (user != null) {
        _currency = user.baseCurrency;
        await _currencyService.loadRates(_currency);
      }

      final dateRange = _getDateRange();

      _expenses = await _supabaseService.getExpenses(
        startDate: dateRange.start,
        endDate: dateRange.end,
        limit: 1000,
      );

      _categoryBreakdown = await _supabaseService.getExpensesByCategory(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      _monthlyTrend = await _supabaseService.getMonthlyExpenseTrend(6);

      _totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);

      final days = dateRange.end.difference(dateRange.start).inDays + 1;
      _averageDaily = days > 0 ? _totalExpenses / days : 0;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.reportTypes.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) async {
                        if (period == 'Custom Range') {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: _customRange,
                          );
                          if (range != null) {
                            _customRange = range;
                            setState(() => _selectedPeriod = period);
                            _loadReportData();
                          }
                        } else {
                          setState(() => _selectedPeriod = period);
                          _loadReportData();
                        }
                      },
                      selectedColor: AppTheme.primaryPink,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryPink),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildCategoriesTab(),
                      _buildTrendsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final dateRange = _getDateRange();
    final dateFormat = DateFormat('MMM d, yyyy');

    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: AppTheme.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period info
            Text(
              '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Spent',
                    _currencyService.formatCurrency(_totalExpenses, _currency),
                    Icons.account_balance_wallet,
                    AppTheme.primaryPink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Daily Average',
                    _currencyService.formatCurrency(_averageDaily, _currency),
                    Icons.trending_up,
                    AppTheme.darkPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Transactions',
                    '${_expenses.length}',
                    Icons.receipt,
                    AppTheme.softPink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Categories',
                    '${_categoryBreakdown.length}',
                    Icons.category,
                    AppTheme.mediumPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top categories
            if (_categoryBreakdown.isNotEmpty) ...[
              Text(
                'Top Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _buildTopCategories(),
                  ),
                ),
              ),
            ],

            // Recent expenses
            if (_expenses.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Recent Expenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...(_expenses.take(5).map((expense) => _buildExpenseItem(expense))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopCategories() {
    final sortedCategories = _categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(5).map((entry) {
      final percentage = (_totalExpenses > 0)
          ? (entry.value / _totalExpenses * 100)
          : 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(
                          AppConstants.categoryIcons[entry.key] ?? 0xe5d3,
                          fontFamily: 'MaterialIcons',
                          matchTextDirection: true,
                        ),
                        size: 16,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(entry.key),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyService.formatCurrency(entry.value, _currency),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppTheme.mediumPink.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildExpenseItem(ExpenseModel expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryPink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            IconData(
              AppConstants.categoryIcons[expense.category] ?? 0xe5d3,
              fontFamily: 'MaterialIcons',
              matchTextDirection: true,
            ),
            color: AppTheme.primaryPink,
            size: 20,
          ),
        ),
        title: Text(
          expense.description ?? expense.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('MMM d').format(expense.date),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          _currencyService.formatCurrency(expense.amount, expense.currency),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPink,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_categoryBreakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: AppTheme.mediumPink.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text('No data for selected period'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: AppTheme.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Pie chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Spending Distribution',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: CategoryChart(
                        data: _categoryBreakdown,
                        currency: _currency,
                        showLegend: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildTopCategories(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_monthlyTrend.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: AppTheme.mediumPink.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text('Not enough data for trends'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: AppTheme.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Line chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Spending Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: _buildTrendChart(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Monthly breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_monthlyTrend.reversed.map((item) {
                      final month = item['month'] as DateTime;
                      final total = item['total'] as double;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMMM yyyy').format(month)),
                            Text(
                              _currencyService.formatCurrency(total, _currency),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    })),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_monthlyTrend.isEmpty) return const SizedBox();

    final spots = _monthlyTrend.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['total'] as double,
      );
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.mediumPink.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _currencyService.formatCurrency(value, _currency),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _monthlyTrend.length) {
                  return const Text('');
                }
                final month = _monthlyTrend[index]['month'] as DateTime;
                return Text(
                  DateFormat('MMM').format(month),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryPink,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: AppTheme.primaryPink,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryPink.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  _currencyService.formatCurrency(spot.y, _currency),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: AppTheme.error),
            title: const Text('Export as PDF'),
            onTap: () {
              Navigator.pop(context);
              _exportToPdf();
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: AppTheme.success),
            title: const Text('Export as CSV'),
            onTap: () {
              Navigator.pop(context);
              _exportToCsv();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      final dateRange = _getDateRange();
      final file = await _exportService.exportToPdf(
        _expenses,
        'expense_report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        categoryTotals: _categoryBreakdown,
        totalAmount: _totalExpenses,
        startDate: dateRange.start,
        endDate: dateRange.end,
        currency: _currency,
      );

      await _exportService.shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated!'),
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

  Future<void> _exportToCsv() async {
    try {
      final file = await _exportService.exportToCsv(
        _expenses,
        'expenses_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );

      await _exportService.shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV file generated!'),
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
