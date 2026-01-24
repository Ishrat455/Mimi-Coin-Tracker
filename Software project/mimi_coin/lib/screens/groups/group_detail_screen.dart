import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/group_model.dart';
import '../../models/expense_model.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import 'create_group_screen.dart';
import 'add_group_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final CurrencyService _currencyService = CurrencyService();
  
  late TabController _tabController;
  late GroupModel _group;
  List<GroupMember> _members = [];
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      await _currencyService.loadRates(_group.currency);
      
      final members = await _supabaseService.getGroupMembers(_group.id);
      final expenses = await _supabaseService.getGroupExpenses(_group.id);

      setState(() {
        _members = members;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  bool get _isAdmin => _group.adminId == _supabaseService.userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      appBar: AppBar(
        title: Text(_group.name),
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editGroup();
                    break;
                  case 'invite':
                    _showInviteDialog();
                    break;
                  case 'delete':
                    _deleteGroup();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.textDark),
                      SizedBox(width: 8),
                      Text('Edit Group'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: AppTheme.textDark),
                      SizedBox(width: 8),
                      Text('Invite Members'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('Delete Group', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildExpensesTab(),
                _buildMembersTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddGroupExpenseScreen(group: _group, members: _members),
            ),
          );
          if (result == true) {
            _loadGroupData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return RefreshIndicator(
      onRefresh: _loadGroupData,
      color: AppTheme.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group,
                            size: 30,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _group.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_group.description != null)
                                Text(
                                  _group.description!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.people,
                          '${_members.length}',
                          'Members',
                        ),
                        _buildStatItem(
                          Icons.receipt,
                          '${_expenses.length}',
                          'Expenses',
                        ),
                        _buildStatItem(
                          Icons.currency_exchange,
                          _group.currency,
                          'Currency',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total expenses card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Group Expenses',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyService.formatCurrency(
                            totalExpenses,
                            _group.currency,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Balances card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member Balances',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_members.isEmpty)
                      const Text('No members yet')
                    else
                      ..._members.map((member) => _buildBalanceItem(member)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryPink),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceItem(GroupMember member) {
    final isPositive = member.balance >= 0;
    final isCurrentUser = member.userId == _supabaseService.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.mediumPink,
            child: Text(
              (member.userName ?? member.userEmail ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.userName ?? member.userEmail ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                if (member.isAdmin)
                  Text(
                    'Admin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${_currencyService.formatCurrency(member.balance, _group.currency)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.mediumPink.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text('No expenses yet'),
            const SizedBox(height: 8),
            const Text(
              'Add your first group expense',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroupData,
      color: AppTheme.primaryPink,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return _buildExpenseCard(expense);
        },
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final iconCode = AppConstants.categoryIcons[expense.category] ?? 0xe5d3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              child: Icon(
                IconData(iconCode, fontFamily: 'MaterialIcons', matchTextDirection: true),
                color: AppTheme.primaryPink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description ?? expense.category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dateFormat.format(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _currencyService.formatCurrency(expense.amount, expense.currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return RefreshIndicator(
      onRefresh: _loadGroupData,
      color: AppTheme.primaryPink,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length + (_isAdmin ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isAdmin && index == _members.length) {
            return Card(
              child: InkWell(
                onTap: _showInviteDialog,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Invite Member',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final member = _members[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member) {
    final isCurrentUser = member.userId == _supabaseService.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.mediumPink,
              child: Text(
                (member.userName ?? member.userEmail ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.userName ?? member.userEmail ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (member.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isAdmin && !member.isAdmin)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMemberOptions(member),
              ),
          ],
        ),
      ),
    );
  }

  void _showMemberOptions(GroupMember member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Make Admin'),
            onTap: () {
              Navigator.pop(context);
              // Make admin logic
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle, color: AppTheme.error),
            title: const Text(
              'Remove from Group',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _removeMember(member);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.userName ?? member.userEmail} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.removeGroupMember(_group.id, member.userId);
        _loadGroupData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed'),
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

  void _showInviteDialog() {
    final inviteCode = _group.id.substring(0, 8).toUpperCase();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with people you want to invite:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inviteCode,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editGroup() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(group: _group),
      ),
    );
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? All expenses and data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteGroup(_group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group deleted'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context, true);
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
