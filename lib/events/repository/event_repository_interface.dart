import 'package:society_management/events/model/event_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

/// Interface for event repository
abstract class IEventRepository {
  /// Get all events
  FirebaseResult<List<EventModel>> getAllEvents();

  /// Get events by line number
  FirebaseResult<List<EventModel>> getEventsByLine(String lineNumber);

  /// Get upcoming events
  FirebaseResult<List<EventModel>> getUpcomingEvents({int limit = 10});

  /// Get upcoming events for a specific line
  FirebaseResult<List<EventModel>> getUpcomingEventsByLine(String lineNumber, {int limit = 10});

  /// Get event by ID
  FirebaseResult<EventModel> getEventById(String eventId);

  /// Create a new event
  FirebaseResult<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String location,
    required String category,
    required String creatorId,
    required String creatorName,
    String? lineNumber,
    bool isAllDay = false,
    bool isRecurring = false,
    String? recurringPattern,
    String approvalStatus = 'approved',
    String visibility = 'society',
    String? rejectionReason,
  });

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
    String? approvalStatus,
    String? visibility,
    String? rejectionReason,
  });

  /// Delete an event
  FirebaseResult<void> deleteEvent(String eventId);

  /// Add attendee to an event
  FirebaseResult<void> addAttendee({
    required String eventId,
    required String userId,
  });

  /// Remove attendee from an event
  FirebaseResult<void> removeAttendee({
    required String eventId,
    required String userId,
  });

  /// Get events for a specific month
  FirebaseResult<List<EventModel>> getEventsForMonth(int year, int month);

  /// Get all pending events that need approval
  FirebaseResult<List<EventModel>> getPendingEvents();

  /// Cancel an event
  FirebaseResult<void> cancelEvent(String eventId);
}
