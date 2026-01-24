import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/reminder_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  String? get userId => currentUser?.id;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // ==================== AUTH ====================
  
  /// Returns a record with the AuthResponse and whether a session was created.
  /// If email confirmation is enabled, session will be null.
  Future<({AuthResponse response, bool hasSession})> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    
    final hasSession = response.session != null;
    
    // Check if user was created and session exists (email confirmation disabled)
    // If email confirmation is enabled, the trigger will create the profile
    // If disabled, we create it here since session is available
    if (response.user != null && hasSession) {
      try {
        await _createUserProfile(response.user!.id, email, name);
        debugPrint('User profile created successfully for ${response.user!.id}');
      } catch (e) {
        // Profile might already be created by database trigger, ignore error
        debugPrint('Profile creation skipped (may exist): $e');
      }
    } else if (response.user != null && !hasSession) {
      debugPrint('User created but no session - email confirmation may be required');
    }
    
    return (response: response, hasSession: hasSession);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('Sign in successful for user: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ==================== OTP VERIFICATION ====================
  
  /// Verify OTP code sent to email after signup
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      debugPrint('OTP verification successful for user: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      rethrow;
    }
  }

  /// Resend OTP code to email
  Future<void> resendOtp({required String email}) async {
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      debugPrint('OTP resent to $email');
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> _createUserProfile(String id, String email, String? name) async {
    await client.from('users').upsert({
      'id': id,
      'email': email,
      'name': name,
      'base_currency': 'USD',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== USER PROFILE ====================
  Future<UserModel?> getUserProfile() async {
    if (userId == null) return null;
    
    final response = await client
        .from('users')
        .select()
        .eq('id', userId!)
        .single();
    
    return UserModel.fromJson(response);
  }

  Future<void> updateUserProfile(UserModel user) async {
    await client.from('users').update({
      'name': user.name,
      'avatar_url': user.avatarUrl,
      'base_currency': user.baseCurrency,
      'monthly_budget': user.monthlyBudget,
      'financial_goal': user.financialGoal,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<void> deleteAccount() async {
    if (userId == null) return;
    
    // Delete all user data
    await client.from('expenses').delete().eq('user_id', userId!);
    await client.from('reminders').delete().eq('user_id', userId!);
    await client.from('group_members').delete().eq('user_id', userId!);
    await client.from('users').delete().eq('id', userId!);
    
    await signOut();
  }

  // ==================== EXPENSES ====================
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? paymentMethod,
    double? minAmount,
    double? maxAmount,
    int limit = 50,
    int offset = 0,
  }) async {
    if (userId == null) return [];

    // Build filters list
    List<String> filters = [];
    filters.add('user_id.eq.$userId');
    
    if (startDate != null) {
      filters.add('date.gte.${startDate.toIso8601String()}');
    }
    if (endDate != null) {
      filters.add('date.lte.${endDate.toIso8601String()}');
    }
    if (category != null) {
      filters.add('category.eq.$category');
    }
    if (paymentMethod != null) {
      filters.add('payment_method.eq.$paymentMethod');
    }

    final response = await client
        .from('expenses')
        .select()
        .or(filters.join(','))
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    
    List<ExpenseModel> expenses = (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (minAmount != null) {
      expenses = expenses.where((e) => e.amount >= minAmount).toList();
    }
    if (maxAmount != null) {
      expenses = expenses.where((e) => e.amount <= maxAmount).toList();
    }

    return expenses;
  }

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final response = await client
        .from('expenses')
        .insert(expense.toJson())
        .select()
        .single();
    
    return ExpenseModel.fromJson(response);
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await client.from('expenses').update({
      ...expense.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expense.id);
  }

  Future<void> deleteExpense(String expenseId) async {
    await client.from('expenses').delete().eq('id', expenseId);
  }

  Future<Map<String, double>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenses = await getExpenses(
      startDate: startDate,
      endDate: endDate,
      limit: 1000,
    );

    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenses = await getExpenses(
      startDate: startDate,
      endDate: endDate,
      limit: 10000,
    );

    double total = 0.0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenseTrend(int months) async {
    if (userId == null) return [];

    final now = DateTime.now();
    List<Map<String, dynamic>> trend = [];

    for (int i = months - 1; i >= 0; i--) {
      final startOfMonth = DateTime(now.year, now.month - i, 1);
      final endOfMonth = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

      final total = await getTotalExpenses(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      trend.add({
        'month': startOfMonth,
        'total': total,
      });
    }

    return trend;
  }

  // ==================== GROUPS ====================
  Future<List<GroupModel>> getGroups() async {
    if (userId == null) return [];

    final memberGroups = await client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId!);

    final groupIds = (memberGroups as List).map((m) => m['group_id']).toList();
    
    if (groupIds.isEmpty) return [];

    final response = await client
        .from('groups')
        .select()
        .inFilter('id', groupIds);

    return (response as List)
        .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<GroupModel> createGroup(GroupModel group) async {
    // Only send fields that exist in the database schema
    final groupData = {
      'name': group.name,
      'description': group.description,
      'created_by': group.createdBy,
      'currency': group.currency,
      'invite_code': group.inviteCode,
    };

    final response = await client
        .from('groups')
        .insert(groupData)
        .select()
        .single();
    
    final createdGroup = GroupModel.fromJson(response);
    
    // Add creator as admin member
    await client.from('group_members').insert({
      'group_id': createdGroup.id,
      'user_id': userId,
      'role': 'admin',
    });

    return createdGroup;
  }

  Future<void> updateGroup(GroupModel group) async {
    await client.from('groups').update({
      'name': group.name,
      'description': group.description,
      'currency': group.currency,
      'invite_code': group.inviteCode,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', group.id);
  }

  Future<void> deleteGroup(String groupId) async {
    await client.from('expense_splits').delete().eq('expense_id', groupId);
    await client.from('group_members').delete().eq('group_id', groupId);
    await client.from('expenses').delete().eq('group_id', groupId);
    await client.from('groups').delete().eq('id', groupId);
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await client
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    return (response as List)
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> addGroupMember(GroupMember member) async {
    await client.from('group_members').insert(member.toJson());
  }

  Future<void> removeGroupMember(String groupId, String memberId) async {
    await client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', memberId);
  }

  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final response = await client
        .from('expenses')
        .select()
        .eq('group_id', groupId)
        .order('date', ascending: false);

    return (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==================== EXPENSE SPLITS ====================
  Future<void> createExpenseSplits(List<ExpenseSplit> splits) async {
    final splitMaps = splits.map((s) => s.toJson()).toList();
    await client.from('expense_splits').insert(splitMaps);
  }

  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async {
    final response = await client
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);

    return (response as List)
        .map((s) => ExpenseSplit.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> markSplitAsPaid(String splitId) async {
    await client
        .from('expense_splits')
        .update({'is_paid': true})
        .eq('id', splitId);
  }

  // ==================== REMINDERS ====================
  Future<List<ReminderModel>> getReminders() async {
    if (userId == null) return [];

    final response = await client
        .from('reminders')
        .select()
        .eq('user_id', userId!)
        .order('reminder_date', ascending: true);

    return (response as List)
        .map((r) => ReminderModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReminderModel>> getUpcomingReminders({int days = 7}) async {
    if (userId == null) return [];

    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    final response = await client
        .from('reminders')
        .select()
        .eq('user_id', userId!)
        .eq('is_active', true)
        .gte('reminder_date', now.toIso8601String())
        .lte('reminder_date', endDate.toIso8601String())
        .order('reminder_date', ascending: true);

    return (response as List)
        .map((r) => ReminderModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    final response = await client
        .from('reminders')
        .insert(reminder.toJson())
        .select()
        .single();
    
    return ReminderModel.fromJson(response);
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    await client.from('reminders').update({
      ...reminder.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reminder.id);
  }

  Future<void> deleteReminder(String reminderId) async {
    await client.from('reminders').delete().eq('id', reminderId);
  }

  Future<void> toggleReminderActive(String reminderId, bool isActive) async {
    await client
        .from('reminders')
        .update({'is_active': isActive})
        .eq('id', reminderId);
  }

  // ==================== SEARCH ====================
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    if (userId == null) return [];

    final response = await client
        .from('expenses')
        .select()
        .eq('user_id', userId!)
        .or('description.ilike.%$query%,category.ilike.%$query%')
        .order('date', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==================== ANALYTICS ====================
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final monthlyTotal = await getTotalExpenses(
      startDate: startOfMonth,
      endDate: now,
    );

    final weeklyTotal = await getTotalExpenses(
      startDate: startOfWeek,
      endDate: now,
    );

    final categoryBreakdown = await getExpensesByCategory(
      startDate: startOfMonth,
      endDate: now,
    );

    final recentExpenses = await getExpenses(limit: 5);
    final upcomingReminders = await getUpcomingReminders(days: 7);

    return {
      'monthlyTotal': monthlyTotal,
      'weeklyTotal': weeklyTotal,
      'categoryBreakdown': categoryBreakdown,
      'recentExpenses': recentExpenses,
      'upcomingReminders': upcomingReminders,
    };
  }
}
