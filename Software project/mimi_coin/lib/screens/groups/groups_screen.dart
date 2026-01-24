import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/group_model.dart';
import '../../services/supabase_service.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      final groups = await _supabaseService.getGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: ${e.toString()}'),
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
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showJoinGroupDialog,
            tooltip: 'Join Group',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            )
          : _groups.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  color: AppTheme.primaryPink,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return _buildGroupCard(group);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          if (result == true) {
            _loadGroups();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.mediumPink.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_outlined,
                size: 60,
                color: AppTheme.primaryPink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Groups Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to split expenses with friends, family, or roommates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
                if (result == true) {
                  _loadGroups();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final isAdmin = group.adminId == _supabaseService.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(group: group),
            ),
          );
          if (result == true) {
            _loadGroups();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPink,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (group.description != null &&
                            group.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              group.description!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGroupInfo(
                    Icons.people_outline,
                    '${group.members?.length ?? 0} members',
                  ),
                  const SizedBox(width: 16),
                  _buildGroupInfo(
                    Icons.currency_exchange,
                    group.currency,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the invite code or link shared by the group admin.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter code or paste link',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Join group logic
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group join feature coming soon!'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
