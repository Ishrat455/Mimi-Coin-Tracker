import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'currency_rates';
  static const String _cacheTimeKey = 'currency_rates_time';
  
  Map<String, double> _rates = {};
  DateTime? _lastUpdate;

  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  Future<void> loadRates(String baseCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check cache
    final cachedTime = prefs.getString(_cacheTimeKey);
    if (cachedTime != null) {
      _lastUpdate = DateTime.parse(cachedTime);
      final hoursSinceUpdate = DateTime.now().difference(_lastUpdate!).inHours;
      
      if (hoursSinceUpdate < 24) {
        final cachedRates = prefs.getString(_cacheKey);
        if (cachedRates != null) {
          _rates = Map<String, double>.from(
            jsonDecode(cachedRates).map((k, v) => MapEntry(k, (v as num).toDouble())),
          );
          return;
        }
      }
    }

    // Fetch new rates
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$baseCurrency'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _rates = Map<String, double>.from(
          (data['rates'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        );
        _lastUpdate = DateTime.now();
        
        // Cache the rates
        await prefs.setString(_cacheKey, jsonEncode(_rates));
        await prefs.setString(_cacheTimeKey, _lastUpdate!.toIso8601String());
      }
    } catch (e) {
      // Use cached rates if available, or set defaults
      if (_rates.isEmpty) {
        _rates = {'USD': 1.0, 'EUR': 0.85, 'GBP': 0.73, 'JPY': 110.0, 'BDT': 110.0};
      }
    }
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final fromRate = _rates[fromCurrency] ?? 1.0;
    final toRate = _rates[toCurrency] ?? 1.0;
    
    // Convert to base currency first, then to target
    final inBase = amount / fromRate;
    return inBase * toRate;
  }

  String formatCurrency(double amount, String currencyCode) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'KRW': '₩',
      'NGN': '₦',
      'BDT': '৳',
    };

    final symbol = symbols[currencyCode] ?? currencyCode;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  Map<String, double> get rates => _rates;
  DateTime? get lastUpdate => _lastUpdate;
}
