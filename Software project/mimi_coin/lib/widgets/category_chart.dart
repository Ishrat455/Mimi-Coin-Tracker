import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../services/currency_service.dart';

class CategoryChart extends StatefulWidget {
  final Map<String, double> data;
  final String currency;
  final bool showLegend;

  const CategoryChart({
    super.key,
    required this.data,
    this.currency = 'USD',
    this.showLegend = true,
  });

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int touchedIndex = -1;
  final CurrencyService _currencyService = CurrencyService();

  final List<Color> _colors = [
    AppTheme.primaryPink,
    AppTheme.darkPink,
    AppTheme.mediumPink,
    const Color(0xFFAB47BC), // Purple
    const Color(0xFF26A69A), // Teal
    const Color(0xFFFF7043), // Deep Orange
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFFCA28), // Amber
    const Color(0xFF78909C), // Blue Grey
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textLight,
          ),
        ),
      );
    }

    final total = widget.data.values.reduce((a, b) => a + b);
    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _buildSections(sortedEntries, total),
            ),
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: sortedEntries.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildLegendItem(
                item.key,
                _colors[index % _colors.length],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, double>> entries,
    double total,
  ) {
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item.value / total * 100);
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 80.0 : 70.0;
      final fontSize = isTouched ? 14.0 : 12.0;

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: item.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  _currencyService.formatCurrency(item.value, widget.currency),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildLegendItem(String category, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          category,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
