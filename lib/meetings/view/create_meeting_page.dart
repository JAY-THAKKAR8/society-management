import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/meetings/model/meeting_model.dart';
import 'package:society_management/meetings/repository/i_meeting_repository.dart';
import 'package:society_management/notifications/service/notification_service.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_gradient_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({super.key});

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final IMeetingRepository _meetingRepository = getIt<IMeetingRepository>();
  final AuthService _authService = getIt<AuthService>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  MeetingType _selectedType = MeetingType.general;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String? _selectedLine;
  bool _isLoading = false;
  String? _currentUserRole;
  String? _currentUserLine;

  final List<String> _lineOptions = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserRole = user.role;
        _currentUserLine = user.lineNumber;

        // If user is line head, automatically set their line as selected
        if (_isLineHead() && _currentUserLine != null) {
          _selectedLine = _currentUserLine;
        }
      });
    }
  }

  bool _isAdmin() {
    return _currentUserRole?.toLowerCase() == 'admin' || _currentUserRole?.toLowerCase() == 'admins';
  }

  bool _isLineHead() {
    return _currentUserRole?.toLowerCase().contains('head') == true;
  }

  String _formatLineNumber(String? lineNumber) {
    if (lineNumber == null) return 'Unknown';

    switch (lineNumber) {
      case 'FIRST_LINE':
        return '1';
      case 'SECOND_LINE':
        return '2';
      case 'THIRD_LINE':
        return '3';
      case 'FOURTH_LINE':
        return '4';
      case 'FIFTH_LINE':
        return '5';
      default:
        return lineNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Create Meeting',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              _buildTitleField(),
              const SizedBox(height: 16),

              // Description Field
              _buildDescriptionField(),
              const SizedBox(height: 16),

              // Meeting Type
              _buildMeetingTypeField(),
              const SizedBox(height: 16),

              // Date and Time
              _buildDateTimeFields(),
              const SizedBox(height: 16),

              // Target Line Selection
              _buildTargetLineField(),
              const SizedBox(height: 32),

              // Create Button
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Title',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter meeting title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a meeting title';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Enter meeting description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a meeting description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingTypeField() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MeetingType>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: MeetingType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getMeetingTypeText(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLineField() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Audience',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isLineHead()) ...[
              // Line heads can only create meetings for their own line
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Line ${_formatLineNumber(_currentUserLine)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Line heads can only create meetings for their own line',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ] else ...[
              // Admins can select any line or all lines
              DropdownButtonFormField<String?>(
                value: _selectedLine,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select target line (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Lines'),
                  ),
                  ..._lineOptions.map((line) {
                    return DropdownMenuItem<String?>(
                      value: line,
                      child: Text('Line $line'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedLine = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Leave empty to invite all society members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: CommonGradientButton(
        text: _isLoading ? 'Creating Meeting...' : 'Create Meeting',
        onPressed: _isLoading ? null : _createMeeting,
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  String _getMeetingTypeText(MeetingType type) {
    switch (type) {
      case MeetingType.general:
        return 'General Meeting';
      case MeetingType.emergency:
        return 'Emergency Meeting';
      case MeetingType.financial:
        return 'Financial Meeting';
      case MeetingType.maintenance:
        return 'Maintenance Meeting';
      case MeetingType.committee:
        return 'Committee Meeting';
      case MeetingType.social:
        return 'Social Meeting';
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        Utility.toast(message: 'User not found');
        return;
      }

      final meetingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final meeting = MeetingModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: meetingDateTime,
        type: _selectedType,
        targetLine: _selectedLine,
        createdBy: currentUser.id!,
        creatorName: currentUser.name ?? 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _meetingRepository.createMeeting(meeting);

      // Send push notification about new meeting
      try {
        await NotificationService.sendMeetingCreatedNotification(
          meetingTitle: meeting.title,
          meetingDate:
              '${meeting.dateTime.day}/${meeting.dateTime.month}/${meeting.dateTime.year} at ${meeting.dateTime.hour}:${meeting.dateTime.minute.toString().padLeft(2, '0')}',
          creatorName: currentUser.name ?? 'Unknown',
          targetLine: meeting.targetLine,
        );
      } catch (e) {
        // Don't fail meeting creation if notification fails
        // Failed to send notification, but continue with meeting creation
      }

      Utility.toast(message: 'Meeting created successfully!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Utility.toast(message: 'Error creating meeting: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
