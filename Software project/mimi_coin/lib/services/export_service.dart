import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import 'currency_service.dart';

class ExportService {
  final CurrencyService _currencyService = CurrencyService();

  Future<File> exportToCsv(
    List<ExpenseModel> expenses,
    String fileName,
  ) async {
    List<List<dynamic>> rows = [
      ['Date', 'Category', 'Description', 'Amount', 'Currency', 'Payment Method'],
    ];

    for (var expense in expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.category,
        expense.description ?? '',
        expense.amount.toStringAsFixed(2),
        expense.currency,
        expense.paymentMethod,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csv);
    
    return file;
  }

  Future<File> exportToPdf(
    List<ExpenseModel> expenses,
    String fileName, {
    Map<String, double>? categoryTotals,
    double? totalAmount,
    DateTime? startDate,
    DateTime? endDate,
    String currency = 'USD',
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Mimi Coin Tracker - Expense Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Date range
          if (startDate != null && endDate != null)
            pw.Text(
              'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          pw.SizedBox(height: 20),
          
          // Summary
          if (totalAmount != null)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.pink50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Expenses',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _currencyService.formatCurrency(totalAmount, currency),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.pink900,
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 20),
          
          // Category breakdown
          if (categoryTotals != null && categoryTotals.isNotEmpty) ...[
            pw.Text(
              'Category Breakdown',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...categoryTotals.entries.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key),
                    pw.Text(_currencyService.formatCurrency(entry.value, currency)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
          ],
          
          // Expense table
          pw.Text(
            'Expense Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.pink100),
                children: [
                  _tableHeader('Date'),
                  _tableHeader('Category'),
                  _tableHeader('Description'),
                  _tableHeader('Amount'),
                ],
              ),
              ...expenses.map(
                (expense) => pw.TableRow(
                  children: [
                    _tableCell(dateFormat.format(expense.date)),
                    _tableCell(expense.category),
                    _tableCell(expense.description ?? '-'),
                    _tableCell(
                      _currencyService.formatCurrency(expense.amount, expense.currency),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Generated on ${dateFormat.format(DateTime.now())} - Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<String> exportToJson(List<ExpenseModel> expenses) async {
    final List<Map<String, dynamic>> jsonList =
        expenses.map((e) => e.toJson()).toList();
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/expenses_export.json');
    
    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toIso8601String(),
      'total_expenses': expenses.length,
      'expenses': jsonList,
    });
    
    await file.writeAsString(jsonString);
    return file.path;
  }
}

class JsonEncoder {
  final String? indent;
  const JsonEncoder.withIndent(this.indent);
  
  String convert(Object? object) {
    return object.toString();
  }
}
