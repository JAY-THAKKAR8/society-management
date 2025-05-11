import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/events/constants/event_constants.dart';
import 'package:society_management/events/model/event_model.dart';
import 'package:society_management/events/service/event_service.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';
import 'package:society_management/widget/gradient_button.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventService _eventService = getIt<EventService>();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isAttending = false;
  bool _isActionLoading = false;

  EventModel? _event;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current user
      final user = await _authService.getCurrentUser();

      // Load event details
      final result = await _eventService.getEventById(widget.eventId);

      result.fold(
        (failure) {
          Utility.toast(message: 'Failed to load event: ${failure.message}');
          setState(() {
            _isLoading = false;
          });
        },
        (event) {
          setState(() {
            _event = event;
            _currentUser = user;
            _isAttending = user != null && event.attendees.contains(user.id);
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error loading event: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAttendance() async {
    if (_currentUser == null || _event == null) {
      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      final result = _isAttending
          ? await _eventService.removeAttendee(
              eventId: _event!.id,
              userId: _currentUser!.id ?? '',
            )
          : await _eventService.addAttendee(
              eventId: _event!.id,
              userId: _currentUser!.id ?? '',
            );

      result.fold(
        (failure) {
          Utility.toast(
            message: 'Failed to ${_isAttending ? 'remove' : 'add'} attendance: ${failure.message}',
          );
        },
        (_) {
          setState(() {
            _isAttending = !_isAttending;
          });

          Utility.toast(
            message: _isAttending ? 'You are now attending this event' : 'You are no longer attending this event',
          );
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error updating attendance: $e');
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _cancelEvent() async {
    if (_event == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text('Are you sure you want to cancel this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      final result = await _eventService.cancelEvent(_event!.id);

      result.fold(
        (failure) {
          Utility.toast(message: 'Failed to cancel event: ${failure.message}');
        },
        (_) {
          Utility.toast(message: 'Event cancelled successfully');
          Navigator.pop(context, true);
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error cancelling event: $e');
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _deleteEvent() async {
    if (_event == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      final result = await _eventService.deleteEvent(_event!.id);

      result.fold(
        (failure) {
          Utility.toast(message: 'Failed to delete event: ${failure.message}');
        },
        (_) {
          Utility.toast(message: 'Event deleted successfully');
          Navigator.pop(context, true);
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error deleting event: $e');
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonGradientAppBar(
          title: 'Event Details',
          gradientColors: AppColors.gradientPurplePink,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return const Scaffold(
        appBar: CommonGradientAppBar(
          title: 'Event Details',
          gradientColors: AppColors.gradientPurplePink,
        ),
        body: Center(
          child: Text('Event not found'),
        ),
      );
    }

    final categoryColor = Color(EventConstants.getCategoryColor(_event!.category));
    final isCancelled = _event!.status == EventConstants.statusCancelled;
    final canEdit = _currentUser != null && _eventService.canUserEditEvent(_currentUser!, _event!);
    final canDelete = _currentUser != null && _eventService.canUserDeleteEvent(_currentUser!, _event!);

    // Format date and time
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final startDate = dateFormat.format(_event!.startDateTime);
    final endDate = dateFormat.format(_event!.endDateTime);

    final startTime = timeFormat.format(_event!.startDateTime);
    final endTime = timeFormat.format(_event!.endDateTime);

    // Determine if it's a multi-day event
    final isMultiDay = _event!.startDateTime.day != _event!.endDateTime.day ||
        _event!.startDateTime.month != _event!.endDateTime.month ||
        _event!.startDateTime.year != _event!.endDateTime.year;

    return Scaffold(
      appBar: CommonGradientAppBar(
        title: 'Event Details',
        gradientColors: AppColors.gradientPurplePink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    _event!.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                      color: isCancelled ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'Cancelled',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(16),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: categoryColor),
              ),
              child: Text(
                _event!.category,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(16),

            // Date and time
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const Gap(8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMultiDay ? 'From: $startDate' : 'Date: $startDate',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (isMultiDay)
                                Text(
                                  'To: $endDate',
                                  style: const TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_event!.isAllDay) ...[
                      const Gap(8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange),
                          const Gap(8),
                          Text(
                            isMultiDay ? 'Starts: $startTime / Ends: $endTime' : 'Time: $startTime - $endTime',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                    if (_event!.isRecurring) ...[
                      const Gap(8),
                      Row(
                        children: [
                          const Icon(Icons.repeat, color: Colors.green),
                          const Gap(8),
                          Text(
                            'Recurring: ${_event!.recurringPattern!.substring(0, 1).toUpperCase()}${_event!.recurringPattern!.substring(1)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Location
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            _event!.location,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Description
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      _event!.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Organizer
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organizer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.purple),
                        const Gap(8),
                        Text(
                          _event!.creatorName,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Action buttons
            if (!isCancelled) ...[
              SizedBox(
                width: double.infinity,
                child: _isActionLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        onPressed: _toggleAttendance,
                        text: _isAttending ? 'Cancel Attendance' : 'Attend Event',
                        gradientColors:
                            _isAttending ? [Colors.red.shade300, Colors.red.shade700] : AppColors.gradientGreenTeal,
                      ),
              ),
              const Gap(16),
            ],

            // Admin actions
            if (canEdit && !isCancelled) ...[
              SizedBox(
                width: double.infinity,
                child: _isActionLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        onPressed: _cancelEvent,
                        text: 'Cancel Event',
                        gradientColors: [Colors.orange.shade300, Colors.orange.shade700],
                      ),
              ),
              const Gap(16),
            ],

            if (canDelete) ...[
              SizedBox(
                width: double.infinity,
                child: _isActionLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton(
                        onPressed: _deleteEvent,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Delete Event'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
