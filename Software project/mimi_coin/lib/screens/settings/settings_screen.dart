import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import '../auth/login_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final CurrencyService _currencyService = CurrencyService();
  
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = await _supabaseService.getUserProfile();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile card
                  Card(
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: _user!),
                          ),
                        );
                        if (result == true) {
                          _loadUserProfile();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.primaryPink,
                              child: Text(
                                (_user?.name ?? _user?.email ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.name ?? 'User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    _user?.email ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textLight,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings sections
                  _buildSection(
                    'Preferences',
                    [
                      _buildSettingItem(
                        Icons.currency_exchange,
                        'Currency',
                        _user?.baseCurrency ?? 'USD',
                        onTap: _showCurrencyPicker,
                      ),
                      _buildSettingItem(
                        Icons.account_balance_wallet,
                        'Monthly Budget',
                        _user?.monthlyBudget != null
                            ? _currencyService.formatCurrency(
                                _user!.monthlyBudget!,
                                _user!.baseCurrency,
                              )
                            : 'Not set',
                        onTap: _showBudgetDialog,
                      ),
                      _buildSettingItem(
                        Icons.flag,
                        'Financial Goal',
                        _user?.financialGoal != null
                            ? _currencyService.formatCurrency(
                                _user!.financialGoal!,
                                _user!.baseCurrency,
                              )
                            : 'Not set',
                        onTap: _showGoalDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    'Features',
                    [
                      _buildSettingItem(
                        Icons.notifications_outlined,
                        'Reminders',
                        'Manage reminders',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RemindersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.category_outlined,
                        'Categories',
                        'Manage categories',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Custom categories coming soon!'),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    'Data',
                    [
                      _buildSettingItem(
                        Icons.download,
                        'Export Data',
                        'Download your data',
                        onTap: _showExportOptions,
                      ),
                      _buildSettingItem(
                        Icons.backup,
                        'Backup',
                        'Cloud backup enabled',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    'About',
                    [
                      _buildSettingItem(
                        Icons.info_outline,
                        'About App',
                        'Version 1.0.0',
                        onTap: _showAboutDialog,
                      ),
                      _buildSettingItem(
                        Icons.privacy_tip_outlined,
                        'Privacy Policy',
                        '',
                        onTap: () {},
                      ),
                      _buildSettingItem(
                        Icons.description_outlined,
                        'Terms of Service',
                        '',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: AppTheme.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppTheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delete account
                  TextButton(
                    onPressed: _showDeleteAccountDialog,
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryPink, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textLight,
                ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Currency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: AppConstants.currencies.length,
              itemBuilder: (context, index) {
                final currency = AppConstants.currencies[index];
                final isSelected = currency['code'] == _user?.baseCurrency;

                return ListTile(
                  leading: Text(
                    currency['symbol']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(currency['name']!),
                  subtitle: Text(currency['code']!),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.primaryPink)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (_user != null) {
                      final updatedUser = _user!.copyWith(
                        baseCurrency: currency['code'],
                      );
                      await _supabaseService.updateUserProfile(updatedUser);
                      _loadUserProfile();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(
      text: _user?.monthlyBudget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget Amount',
            prefixText: _currencyService.formatCurrency(0, _user?.baseCurrency ?? 'USD').replaceAll('0.00', ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final budget = double.tryParse(controller.text);
              if (_user != null) {
                final updatedUser = _user!.copyWith(monthlyBudget: budget);
                await _supabaseService.updateUserProfile(updatedUser);
                _loadUserProfile();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    final controller = TextEditingController(
      text: _user?.financialGoal?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Financial Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set a savings goal to track your progress',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Goal Amount',
                prefixText: _currencyService.formatCurrency(0, _user?.baseCurrency ?? 'USD').replaceAll('0.00', ''),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final goal = double.tryParse(controller.text);
              if (_user != null) {
                final updatedUser = _user!.copyWith(financialGoal: goal);
                await _supabaseService.updateUserProfile(updatedUser);
                _loadUserProfile();
              }
            },
            child: const Text('Save'),
          ),
        ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF export started...'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: AppTheme.success),
            title: const Text('Export as CSV'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV export started...'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.code, color: AppTheme.primaryPink),
            title: const Text('Export as JSON'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('JSON export started...'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Mimi Coin Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: AppTheme.primaryPink,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
        ),
      ),
      children: [
        const Text(
          'A comprehensive expense tracking application to help you manage your finances, track group expenses, and visualize your spending patterns.',
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _supabaseService.deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
