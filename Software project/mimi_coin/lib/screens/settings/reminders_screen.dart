import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/reminder_model.dart';
import '../../services/supabase_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);

    try {
      final reminders = await _supabaseService.getReminders();
      setState(() {
        _reminders = reminders;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightPink,
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            )
          : _reminders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  color: AppTheme.primaryPink,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      return _buildReminderCard(_reminders[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.mediumPink.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 50,
                color: AppTheme.primaryPink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reminders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Set reminders for bills, budgets, or settlements',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final isPast = reminder.reminderDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getReminderColor(reminder.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getReminderIcon(reminder.type),
                    color: _getReminderColor(reminder.type),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isPast ? AppTheme.error : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(reminder.reminderDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPast ? AppTheme.error : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isActive,
                  onChanged: (value) => _toggleReminder(reminder, value),
                  activeColor: AppTheme.primaryPink,
                ),
              ],
            ),
            if (reminder.description != null && reminder.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                reminder.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        reminder.type,
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(
                        reminder.recurrence,
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  onPressed: () => _deleteReminder(reminder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReminderIcon(String type) {
    switch (type) {
      case 'Bill Payment':
        return Icons.receipt;
      case 'Budget Alert':
        return Icons.account_balance_wallet;
      case 'Settlement':
        return Icons.handshake;
      default:
        return Icons.notifications;
    }
  }

  Color _getReminderColor(String type) {
    switch (type) {
      case 'Bill Payment':
        return AppTheme.error;
      case 'Budget Alert':
        return AppTheme.warning;
      case 'Settlement':
        return AppTheme.success;
      default:
        return AppTheme.primaryPink;
    }
  }

  Future<void> _toggleReminder(ReminderModel reminder, bool value) async {
    try {
      await _supabaseService.toggleReminderActive(reminder.id, value);
      _loadReminders();
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

  Future<void> _deleteReminder(ReminderModel reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
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
        await _supabaseService.deleteReminder(reminder.id);
        _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder deleted'),
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

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = AppConstants.reminderTypes.first;
    String selectedRecurrence = AppConstants.recurrenceOptions.first;
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumPink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Reminder',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Reminder Title',
                            hintText: 'e.g., Pay electricity bill',
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Add more details...',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Type
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Reminder Type',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: AppConstants.reminderTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedType = value!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date and Time
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setModalState(() => selectedDate = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.mediumPink),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.primaryPink,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(selectedDate),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (time != null) {
                                    setModalState(() => selectedTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.mediumPink),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: AppTheme.primaryPink,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(selectedTime.format(context)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Recurrence
                        DropdownButtonFormField<String>(
                          value: selectedRecurrence,
                          decoration: const InputDecoration(
                            labelText: 'Repeat',
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          items: AppConstants.recurrenceOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedRecurrence = value!);
                          },
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a title'),
                                    backgroundColor: AppTheme.warning,
                                  ),
                                );
                                return;
                              }

                              final reminderDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              try {
                                final userId = _supabaseService.userId;
                                if (userId == null) throw Exception('Not logged in');

                                final reminder = ReminderModel(
                                  id: const Uuid().v4(),
                                  userId: userId,
                                  title: titleController.text,
                                  description: descriptionController.text.isEmpty
                                      ? null
                                      : descriptionController.text,
                                  type: selectedType,
                                  reminderDate: reminderDateTime,
                                  recurrence: selectedRecurrence,
                                  createdAt: DateTime.now(),
                                );

                                await _supabaseService.createReminder(reminder);
                                Navigator.pop(context);
                                _loadReminders();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reminder added'),
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
                            },
                            child: const Text('Save Reminder'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
