import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/meetings/model/meeting_model.dart';
import 'package:society_management/meetings/repository/i_meeting_repository.dart';
import 'package:society_management/meetings/view/meeting_attendance_page.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_gradient_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class MeetingDetailsPage extends StatefulWidget {
  final MeetingModel meeting;

  const MeetingDetailsPage({
    super.key,
    required this.meeting,
  });

  @override
  State<MeetingDetailsPage> createState() => _MeetingDetailsPageState();
}

class _MeetingDetailsPageState extends State<MeetingDetailsPage> with SingleTickerProviderStateMixin {
  final IMeetingRepository _meetingRepository = getIt<IMeetingRepository>();
  final AuthService _authService = getIt<AuthService>();

  late TabController _tabController;
  late MeetingModel _meeting;
  final bool _isLoading = false;
  String? _currentUserRole;
  String? _currentUserId;

  final _agendaTitleController = TextEditingController();
  final _agendaDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meeting = widget.meeting;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _agendaTitleController.dispose();
    _agendaDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserRole = user.role;
        _currentUserId = user.id;
      });
    }
  }

  bool _canEditMeeting() {
    return _currentUserRole?.toLowerCase() == 'admin' ||
        _currentUserRole?.toLowerCase() == 'admins' ||
        _meeting.createdBy == _currentUserId;
  }

  bool _canEditAttendance() {
    // Only the meeting creator (line head who created the meeting) can edit attendance
    // Admin can also edit attendance for any meeting
    return _currentUserRole?.toLowerCase() == 'admin' ||
        _currentUserRole?.toLowerCase() == 'admins' ||
        _meeting.createdBy == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Meeting Details',
        actions: [
          if (_canEditMeeting())
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Meeting'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Meeting', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Meeting Info Header
          _buildMeetingHeader(),

          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  text: 'Agenda',
                  icon: Icon(Icons.list_alt),
                ),
                Tab(
                  text: 'Attendance',
                  icon: Icon(Icons.people),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAgendaTab(),
                _buildAttendanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingHeader() {
    return ThemeAwareCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Type
            Row(
              children: [
                Expanded(
                  child: Text(
                    _meeting.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMeetingTypeColor(_meeting.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMeetingTypeText(_meeting.type),
                    style: TextStyle(
                      color: _getMeetingTypeColor(_meeting.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (_meeting.description.isNotEmpty)
              Text(
                _meeting.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(_meeting.dateTime),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat('hh:mm a').format(_meeting.dateTime),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Target Line and Creator
            Row(
              children: [
                if (_meeting.targetLine != null) ...[
                  Icon(
                    Icons.location_city,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Line ${_formatLineNumber(_meeting.targetLine)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(
                  Icons.person,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Created by ${_meeting.creatorName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaTab() {
    return Column(
      children: [
        // Add Agenda Button
        if (_canEditMeeting())
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: CommonGradientButton(
                text: 'Add Agenda Item',
                onPressed: _showAddAgendaDialog,
                icon: Icons.add,
              ),
            ),
          ),

        // Agenda List
        Expanded(
          child: _meeting.agenda.isEmpty
              ? _buildEmptyAgenda()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: _meeting.agenda.length,
                  itemBuilder: (context, index) {
                    final agendaItem = _meeting.agenda[index];
                    return _buildAgendaItem(agendaItem, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyAgenda() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No agenda items yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          if (_canEditMeeting()) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showAddAgendaDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add First Agenda Item'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgendaItem(AgendaItem agendaItem, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ThemeAwareCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAgendaStatusColor(agendaItem.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getAgendaStatusText(agendaItem.status),
                    style: TextStyle(
                      color: _getAgendaStatusColor(agendaItem.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (_canEditMeeting())
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAgendaAction(value, agendaItem),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'pending',
                        child: Text('Mark as Pending'),
                      ),
                      const PopupMenuItem(
                        value: 'inProgress',
                        child: Text('Mark as In Progress'),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Mark as Completed'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              agendaItem.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            // Description
            if (agendaItem.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                agendaItem.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    // Filter out admin users from attendance counts
    final nonAdminAttendance = _meeting.attendance.where((a) => a.userRole.toLowerCase() != 'admin').toList();
    final presentCount = nonAdminAttendance.where((a) => a.status == AttendanceStatus.present).length;
    final absentCount = nonAdminAttendance.where((a) => a.status == AttendanceStatus.absent).length;
    final notMarkedCount = nonAdminAttendance.where((a) => a.status == AttendanceStatus.notMarked).length;

    return Column(
      children: [
        // Attendance Summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: ThemeAwareCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttendanceStat('Present', presentCount, Colors.green),
                  _buildAttendanceStat('Absent', absentCount, Colors.red),
                  _buildAttendanceStat('Not Marked', notMarkedCount, Colors.orange),
                ],
              ),
            ),
          ),
        ),

        // Mark Attendance Button - Only for meeting creator
        if (_canEditAttendance())
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: CommonGradientButton(
                text: 'Mark Attendance',
                onPressed: _navigateToAttendance,
                icon: Icons.how_to_reg,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Attendance List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nonAdminAttendance.length,
            itemBuilder: (context, index) {
              final attendance = nonAdminAttendance[index];
              return _buildAttendanceItem(attendance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(AttendanceRecord attendance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ThemeAwareCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getAttendanceStatusColor(attendance.status),
            child: Icon(
              _getAttendanceStatusIcon(attendance.status),
              color: Colors.white,
            ),
          ),
          title: Text(attendance.userName),
          subtitle: Text(_formatUserRole(attendance.userRole)),
          trailing: Text(
            _getAttendanceStatusText(attendance.status),
            style: TextStyle(
              color: _getAttendanceStatusColor(attendance.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatUserRole(String role) {
    // Convert role to proper format
    switch (role.toLowerCase()) {
      case 'line_head_member':
        return 'Line Head Member';
      case 'line_member':
        return 'Line Member';
      case 'admin':
        return 'Admin';
      default:
        // Handle other cases by capitalizing each word
        return role
            .split('_')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
            .join(' ');
    }
  }

  String _formatLineNumber(String? lineNumber) {
    if (lineNumber == null) return '';

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

  // Helper methods for colors and text
  Color _getMeetingTypeColor(MeetingType type) {
    switch (type) {
      case MeetingType.general:
        return Colors.blue;
      case MeetingType.emergency:
        return Colors.red;
      case MeetingType.financial:
        return Colors.green;
      case MeetingType.maintenance:
        return Colors.orange;
      case MeetingType.committee:
        return Colors.purple;
      case MeetingType.social:
        return Colors.pink;
    }
  }

  String _getMeetingTypeText(MeetingType type) {
    switch (type) {
      case MeetingType.general:
        return 'General';
      case MeetingType.emergency:
        return 'Emergency';
      case MeetingType.financial:
        return 'Financial';
      case MeetingType.maintenance:
        return 'Maintenance';
      case MeetingType.committee:
        return 'Committee';
      case MeetingType.social:
        return 'Social';
    }
  }

  Color _getAgendaStatusColor(AgendaStatus status) {
    switch (status) {
      case AgendaStatus.pending:
        return Colors.orange;
      case AgendaStatus.inProgress:
        return Colors.blue;
      case AgendaStatus.completed:
        return Colors.green;
    }
  }

  String _getAgendaStatusText(AgendaStatus status) {
    switch (status) {
      case AgendaStatus.pending:
        return 'Pending';
      case AgendaStatus.inProgress:
        return 'In Progress';
      case AgendaStatus.completed:
        return 'Completed';
    }
  }

  Color _getAttendanceStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.notMarked:
        return Colors.orange;
    }
  }

  IconData _getAttendanceStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check;
      case AttendanceStatus.absent:
        return Icons.close;
      case AttendanceStatus.notMarked:
        return Icons.help;
    }
  }

  String _getAttendanceStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.notMarked:
        return 'Not Marked';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit meeting page
        Utility.toast(message: 'Edit meeting feature coming soon');
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _handleAgendaAction(String action, AgendaItem agendaItem) async {
    if (action == 'delete') {
      _deleteAgendaItem(agendaItem);
    } else {
      AgendaStatus newStatus;
      switch (action) {
        case 'pending':
          newStatus = AgendaStatus.pending;
          break;
        case 'inProgress':
          newStatus = AgendaStatus.inProgress;
          break;
        case 'completed':
          newStatus = AgendaStatus.completed;
          break;
        default:
          return;
      }

      _updateAgendaStatus(agendaItem, newStatus);
    }
  }

  void _showAddAgendaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Agenda Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _agendaTitleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _agendaDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addAgendaItem,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addAgendaItem() async {
    if (_agendaTitleController.text.trim().isEmpty) {
      Utility.toast(message: 'Please enter a title');
      return;
    }

    final agendaItem = AgendaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _agendaTitleController.text.trim(),
      description: _agendaDescriptionController.text.trim(),
      status: AgendaStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _meetingRepository.addAgendaItem(_meeting.id!, agendaItem);
      setState(() {
        _meeting = _meeting.copyWith(
          agenda: [..._meeting.agenda, agendaItem],
        );
      });
      _agendaTitleController.clear();
      _agendaDescriptionController.clear();
      if (mounted) Navigator.pop(context);
      Utility.toast(message: 'Agenda item added successfully');
    } catch (e) {
      Utility.toast(message: 'Error adding agenda item: $e');
    }
  }

  void _updateAgendaStatus(AgendaItem agendaItem, AgendaStatus newStatus) async {
    final updatedItem = agendaItem.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    try {
      await _meetingRepository.updateAgendaItem(_meeting.id!, updatedItem);
      setState(() {
        final index = _meeting.agenda.indexWhere((item) => item.id == agendaItem.id);
        if (index != -1) {
          final updatedAgenda = List<AgendaItem>.from(_meeting.agenda);
          updatedAgenda[index] = updatedItem;
          _meeting = _meeting.copyWith(agenda: updatedAgenda);
        }
      });
      Utility.toast(message: 'Agenda status updated');
    } catch (e) {
      Utility.toast(message: 'Error updating agenda: $e');
    }
  }

  void _deleteAgendaItem(AgendaItem agendaItem) async {
    try {
      await _meetingRepository.deleteAgendaItem(_meeting.id!, agendaItem.id);
      setState(() {
        _meeting = _meeting.copyWith(
          agenda: _meeting.agenda.where((item) => item.id != agendaItem.id).toList(),
        );
      });
      Utility.toast(message: 'Agenda item deleted');
    } catch (e) {
      Utility.toast(message: 'Error deleting agenda item: $e');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: const Text('Are you sure you want to delete this meeting? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _deleteMeeting,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteMeeting() async {
    Navigator.pop(context); // Close dialog

    try {
      await _meetingRepository.deleteMeeting(_meeting.id!);
      Utility.toast(message: 'Meeting deleted successfully');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Utility.toast(message: 'Error deleting meeting: $e');
    }
  }

  void _navigateToAttendance() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingAttendancePage(meeting: _meeting),
      ),
    );

    if (result == true) {
      // Refresh meeting data
      try {
        final meetingResult = await _meetingRepository.getMeetingById(_meeting.id!);
        if (meetingResult != null) {
          setState(() => _meeting = meetingResult);
        }
      } catch (e) {
        Utility.toast(message: 'Error refreshing meeting: $e');
      }
    }
  }
}
