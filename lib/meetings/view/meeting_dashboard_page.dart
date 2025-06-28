import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/meetings/model/meeting_model.dart';
import 'package:society_management/meetings/repository/i_meeting_repository.dart';
import 'package:society_management/meetings/view/create_meeting_page.dart';
import 'package:society_management/meetings/view/meeting_details_page.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class MeetingDashboardPage extends StatefulWidget {
  const MeetingDashboardPage({super.key});

  @override
  State<MeetingDashboardPage> createState() => _MeetingDashboardPageState();
}

class _MeetingDashboardPageState extends State<MeetingDashboardPage> with SingleTickerProviderStateMixin {
  final IMeetingRepository _meetingRepository = getIt<IMeetingRepository>();
  final AuthService _authService = getIt<AuthService>();

  late TabController _tabController;
  List<MeetingModel> _upcomingMeetings = [];
  List<MeetingModel> _pastMeetings = [];
  bool _isLoading = true;
  String? _currentUserRole;
  String? _currentUserLine;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
    _loadMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserRole = user.role;
        _currentUserLine = user.lineNumber;
      });
    }
  }

  Future<void> _loadMeetings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // All users can see all meetings - no role restrictions
      _upcomingMeetings = await _meetingRepository.getUpcomingMeetings();
      _pastMeetings = await _meetingRepository.getPastMeetings();
    } catch (e) {
      if (mounted) {
        Utility.toast(message: 'Error loading meetings: $e');
        // Set empty lists on error to prevent null issues
        _upcomingMeetings = [];
        _pastMeetings = [];
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isAdmin() {
    return _currentUserRole?.toLowerCase() == 'admin' || _currentUserRole?.toLowerCase() == 'admins';
  }

  bool _canCreateMeeting() {
    // Only admin and line heads can create meetings, not line members
    return _isAdmin() || _currentUserRole?.toLowerCase().contains('head') == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Meeting Management',
        actions: [
          // log( 'Can create meeting: ${_canCreateMeeting()}');
          if (_canCreateMeeting())
            IconButton(
              onPressed: () => _navigateToCreateMeeting(),
              icon: const Icon(Icons.add),
              tooltip: 'Create Meeting',
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'Upcoming (${_upcomingMeetings.length})',
                  icon: const Icon(Icons.schedule),
                ),
                Tab(
                  text: 'Past (${_pastMeetings.length})',
                  icon: const Icon(Icons.history),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMeetingsList(_upcomingMeetings, isUpcoming: true),
                      _buildMeetingsList(_pastMeetings, isUpcoming: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsList(List<MeetingModel> meetings, {required bool isUpcoming}) {
    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming meetings' : 'No past meetings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            if (isUpcoming && _canCreateMeeting()) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _navigateToCreateMeeting(),
                icon: const Icon(Icons.add),
                label: const Text('Create First Meeting'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          final meeting = meetings[index];
          return _buildMeetingCard(meeting, isUpcoming: isUpcoming);
        },
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, {required bool isUpcoming}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ThemeAwareCard(
        child: InkWell(
          onTap: () => _navigateToMeetingDetails(meeting),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMeetingTypeColor(meeting.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getMeetingTypeText(meeting.type),
                        style: TextStyle(
                          color: _getMeetingTypeColor(meeting.type),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isUpcoming ? Icons.schedule : Icons.history,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(meeting.dateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  meeting.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Description
                if (meeting.description.isNotEmpty)
                  Text(
                    meeting.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Time and attendance info
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              DateFormat('hh:mm a').format(meeting.dateTime),
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${_getNonAdminMemberCount(meeting)} members',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (meeting.agenda.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.list_alt,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${meeting.agenda.length} agenda${meeting.agenda.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Target line info
                if (meeting.targetLine != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Line ${_formatLineNumber(meeting.targetLine)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  int _getNonAdminMemberCount(MeetingModel meeting) {
    // Filter out admin users from attendance count
    return meeting.attendance
        .where((attendance) =>
            attendance.userRole.toLowerCase() != 'admin' && attendance.userRole.toLowerCase() != 'admins')
        .length;
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

  void _navigateToCreateMeeting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateMeetingPage(),
      ),
    );

    if (result == true) {
      _loadMeetings();
    }
  }

  void _navigateToMeetingDetails(MeetingModel meeting) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailsPage(meeting: meeting),
      ),
    );

    if (result == true) {
      _loadMeetings();
    }
  }
}
