class AppConstants {
  // Supabase Configuration - Replace with your own credentials
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills',
    'Healthcare',
    'Education',
    'Others',
  ];

  // Category Icons
  static const Map<String, int> categoryIcons = {
    'Food': 0xe532, // Icons.restaurant
    'Transportation': 0xe1d7, // Icons.directions_car
    'Shopping': 0xe59c, // Icons.shopping_bag
    'Entertainment': 0xe40f, // Icons.movie
    'Bills': 0xe8e5, // Icons.receipt
    'Healthcare': 0xe548, // Icons.local_hospital
    'Education': 0xe80c, // Icons.school
    'Others': 0xe5d3, // Icons.more_horiz
  };

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Digital Wallet',
    'Bank Transfer',
  ];

  // Currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'KRW', 'symbol': '₩', 'name': 'South Korean Won'},
    {'code': 'NGN', 'symbol': '₦', 'name': 'Nigerian Naira'},
    {'code': 'BDT', 'symbol': '৳', 'name': 'Bangladeshi Taka'},
  ];

  // Split Methods
  static const List<String> splitMethods = [
    'Equal',
    'Percentage',
    'Custom Amount',
  ];

  // Report Types
  static const List<String> reportTypes = [
    'Weekly',
    'Monthly',
    'Yearly',
    'Custom Range',
  ];

  // Reminder Types
  static const List<String> reminderTypes = [
    'Bill Payment',
    'Budget Alert',
    'Settlement',
    'Custom',
  ];

  // Recurrence Options
  static const List<String> recurrenceOptions = [
    'Once',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];
}
