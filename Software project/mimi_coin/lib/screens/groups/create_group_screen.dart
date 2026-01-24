import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/group_model.dart';
import '../../services/supabase_service.dart';

class CreateGroupScreen extends StatefulWidget {
  final GroupModel? group;

  const CreateGroupScreen({super.key, this.group});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _supabaseService = SupabaseService();

  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _isEditing = true;
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _selectedCurrency = widget.group!.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabaseService.userId;
      if (userId == null) throw Exception('User not logged in');

      final group = GroupModel(
        id: _isEditing ? widget.group!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdBy: _isEditing ? widget.group!.createdBy : userId,
        currency: _selectedCurrency,
        createdAt: _isEditing ? widget.group!.createdAt : DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
      );

      if (_isEditing) {
        await _supabaseService.updateGroup(group);
      } else {
        await _supabaseService.createGroup(group);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Group updated' : 'Group created'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop(true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Group' : 'Create Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group,
                    size: 50,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Group name
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Name',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Enter group name',
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a group name';
                          }
                          if (value.length < 2) {
                            return 'Name is too short';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'What is this group for?',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.description),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Currency selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currency',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.currency_exchange),
                        ),
                        items: AppConstants.currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency['code'],
                            child: Text(
                              '${currency['symbol']} ${currency['code']} - ${currency['name']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCurrency = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveGroup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_isEditing ? 'Update Group' : 'Create Group'),
              ),

              if (!_isEditing) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.mediumPink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryPink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'After creating the group',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• You can invite members via email or share link\n'
                        '• Add group expenses and split them equally or by percentage\n'
                        '• Track balances and settlements between members',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
