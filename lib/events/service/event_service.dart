import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/events/constants/event_constants.dart';
import 'package:society_management/events/model/event_model.dart';
import 'package:society_management/events/repository/event_repository_interface.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

/// Service class for event-related operations
class EventService {
  final IEventRepository _eventRepository;

  EventService({IEventRepository? eventRepository}) : _eventRepository = eventRepository ?? getIt<IEventRepository>();

  /// Get all events
  FirebaseResult<List<EventModel>> getAllEvents() {
    return _eventRepository.getAllEvents();
  }

  /// Get events for a specific line
  FirebaseResult<List<EventModel>> getEventsByLine(String lineNumber) {
    return _eventRepository.getEventsByLine(lineNumber);
  }

  /// Get upcoming events
  FirebaseResult<List<EventModel>> getUpcomingEvents({int limit = 10}) {
    return _eventRepository.getUpcomingEvents(limit: limit);
  }

  /// Get upcoming events for a specific line
  FirebaseResult<List<EventModel>> getUpcomingEventsByLine(String lineNumber, {int limit = 10}) {
    return _eventRepository.getUpcomingEventsByLine(lineNumber, limit: limit);
  }

  /// Get event by ID
  FirebaseResult<EventModel> getEventById(String eventId) {
    return _eventRepository.getEventById(eventId);
  }

  /// Create a new event
  FirebaseResult<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String location,
    required String category,
    required UserModel creator,
    String? lineNumber,
    bool isAllDay = false,
    bool isRecurring = false,
    String? recurringPattern,
    String? visibility,
  }) {
    // Determine the initial approval status based on creator's role
    final approvalStatus = getInitialApprovalStatus(creator);

    // If no visibility is specified, use the most appropriate default based on user role
    String eventVisibility = visibility ?? EventConstants.visibilitySociety;

    // For regular members, ensure they can only create events for their own line
    if (creator.role == AppConstants.lineMember) {
      // Force line number to be the creator's line
      lineNumber = creator.lineNumber;

      // If they try to create a society-wide event, downgrade to line visibility
      if (eventVisibility == EventConstants.visibilitySociety) {
        eventVisibility = EventConstants.visibilityLine;
      }
    }

    return _eventRepository.createEvent(
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      category: category,
      creatorId: creator.id ?? '',
      creatorName: creator.name ?? '',
      lineNumber: lineNumber,
      isAllDay: isAllDay,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      approvalStatus: approvalStatus,
      visibility: eventVisibility,
    );
  }

  /// Update an existing event
  FirebaseResult<EventModel> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? location,
    String? category,
    bool? isAllDay,
    bool? isRecurring,
    String? recurringPattern,
    String? status,
  }) {
    return _eventRepository.updateEvent(
      eventId: eventId,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      category: category,
      isAllDay: isAllDay,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      status: status,
    );
  }

  /// Delete an event
  FirebaseResult<void> deleteEvent(String eventId) {
    return _eventRepository.deleteEvent(eventId);
  }

  /// Add attendee to an event
  FirebaseResult<void> addAttendee({
    required String eventId,
    required String userId,
  }) {
    return _eventRepository.addAttendee(
      eventId: eventId,
      userId: userId,
    );
  }

  /// Remove attendee from an event
  FirebaseResult<void> removeAttendee({
    required String eventId,
    required String userId,
  }) {
    return _eventRepository.removeAttendee(
      eventId: eventId,
      userId: userId,
    );
  }

  /// Get events for a specific month
  FirebaseResult<List<EventModel>> getEventsForMonth(int year, int month) {
    return _eventRepository.getEventsForMonth(year, month);
  }

  /// Cancel an event
  FirebaseResult<void> cancelEvent(String eventId) {
    return _eventRepository.cancelEvent(eventId);
  }

  /// Check if user can create events
  bool canUserCreateEvents(UserModel user) {
    // Only allow admins and line heads to create events
    return user.role == AppConstants.admin ||
        user.role == AppConstants.lineLead ||
        user.role == AppConstants.lineHeadAndMember;
  }

  /// Determine the initial approval status for an event based on creator's role
  String getInitialApprovalStatus(UserModel creator) {
    // Events created by admins and line heads are automatically approved
    if (creator.role == AppConstants.admin ||
        creator.role == AppConstants.lineLead ||
        creator.role == AppConstants.lineHeadAndMember) {
      return EventConstants.approvalApproved;
    }

    // Events created by regular members need approval
    return EventConstants.approvalPending;
  }

  /// Determine the allowed visibility options for a user
  List<String> getAllowedVisibilityOptions(UserModel user) {
    // Admins can create events with any visibility
    if (user.role == AppConstants.admin) {
      return EventConstants.allVisibilityOptions;
    }

    // Line heads can create society-wide or line-specific events
    if (user.role == AppConstants.lineLead || user.role == AppConstants.lineHeadAndMember) {
      return [
        EventConstants.visibilitySociety,
        EventConstants.visibilityLine,
        EventConstants.visibilityPrivate,
      ];
    }

    // Regular members can only create line-specific or private events
    return [
      EventConstants.visibilityLine,
      EventConstants.visibilityPrivate,
    ];
  }

  /// Check if user can edit an event
  bool canUserEditEvent(UserModel user, EventModel event) {
    // Admin can edit any event
    if (user.role == AppConstants.admin) {
      return true;
    }

    // Line head can edit events for their line
    if ((user.role == AppConstants.lineLead || user.role == AppConstants.lineHeadAndMember) &&
        user.lineNumber == event.lineNumber) {
      return true;
    }

    // Creator can edit their own events
    if (event.creatorId == user.id) {
      return true;
    }

    return false;
  }

  /// Check if user can delete an event
  bool canUserDeleteEvent(UserModel user, EventModel event) {
    // Admin can delete any event
    if (user.role == AppConstants.admin) {
      return true;
    }

    // Line head can delete events for their line
    if ((user.role == AppConstants.lineLead || user.role == AppConstants.lineHeadAndMember) &&
        user.lineNumber == event.lineNumber) {
      return true;
    }

    // Creator can delete their own events
    if (event.creatorId == user.id) {
      return true;
    }

    return false;
  }

  /// Check if user can approve/reject events
  bool canUserModerateEvents(UserModel user) {
    // Only admins and line heads can approve/reject events
    return user.role == AppConstants.admin ||
        user.role == AppConstants.lineLead ||
        user.role == AppConstants.lineHeadAndMember;
  }

  /// Check if user can view an event based on visibility settings
  bool canUserViewEvent(UserModel user, EventModel event) {
    // Admins can view all events
    if (user.role == AppConstants.admin) {
      return true;
    }

    // Creator can always view their own events
    if (event.creatorId == user.id) {
      return true;
    }

    // Line heads can view all events in their line
    if ((user.role == AppConstants.lineLead || user.role == AppConstants.lineHeadAndMember) &&
        user.lineNumber == event.lineNumber) {
      return true;
    }

    // For society-wide events, all users can view
    if (event.visibility == EventConstants.visibilitySociety) {
      return true;
    }

    // For line-specific events, only members of that line can view
    if (event.visibility == EventConstants.visibilityLine && user.lineNumber == event.lineNumber) {
      return true;
    }

    // For private events, only attendees can view
    if (event.visibility == EventConstants.visibilityPrivate && event.attendees.contains(user.id)) {
      return true;
    }

    return false;
  }

  /// Approve a pending event
  FirebaseResult<EventModel> approveEvent(String eventId) {
    return _eventRepository.updateEvent(
      eventId: eventId,
      approvalStatus: EventConstants.approvalApproved,
    );
  }

  /// Reject a pending event with a reason
  FirebaseResult<EventModel> rejectEvent(String eventId, String rejectionReason) {
    return _eventRepository.updateEvent(
      eventId: eventId,
      approvalStatus: EventConstants.approvalRejected,
      rejectionReason: rejectionReason,
    );
  }

  /// Get all pending events that need approval
  FirebaseResult<List<EventModel>> getPendingEvents() {
    return _eventRepository.getPendingEvents();
  }
}
