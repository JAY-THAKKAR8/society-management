import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/events/model/event_model.dart';
import 'package:society_management/events/repository/event_repository_interface.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

/// Implementation of the event repository
class EventRepository implements IEventRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _eventsCollection;
  final CollectionReference _activitiesCollection;

  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _eventsCollection = (firestore ?? FirebaseFirestore.instance).collection('events'),
        _activitiesCollection = (firestore ?? FirebaseFirestore.instance).collection('activities');

  @override
  FirebaseResult<List<EventModel>> getAllEvents() {
    return Result<List<EventModel>>().tryCatch(
      run: () async {
        final querySnapshot = await _eventsCollection.orderBy('start_date_time', descending: false).get();

        return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  FirebaseResult<List<EventModel>> getEventsByLine(String lineNumber) {
    return Result<List<EventModel>>().tryCatch(
      run: () async {
        final querySnapshot = await _eventsCollection
            .where('line_number', isEqualTo: lineNumber)
            .orderBy('start_date_time', descending: false)
            .get();

        return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  FirebaseResult<List<EventModel>> getUpcomingEvents({int limit = 10}) {
    return Result<List<EventModel>>().tryCatch(
      run: () async {
        final now = Timestamp.now();

        final querySnapshot = await _eventsCollection
            .where('start_date_time', isGreaterThanOrEqualTo: now)
            .where('status', isEqualTo: 'upcoming')
            .orderBy('start_date_time', descending: false)
            .limit(limit)
            .get();

        return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  FirebaseResult<List<EventModel>> getUpcomingEventsByLine(String lineNumber, {int limit = 10}) {
    return Result<List<EventModel>>().tryCatch(
      run: () async {
        final now = Timestamp.now();

        final querySnapshot = await _eventsCollection
            .where('line_number', isEqualTo: lineNumber)
            .where('start_date_time', isGreaterThanOrEqualTo: now)
            .where('status', isEqualTo: 'upcoming')
            .orderBy('start_date_time', descending: false)
            .limit(limit)
            .get();

        return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  FirebaseResult<EventModel> getEventById(String eventId) {
    return Result<EventModel>().tryCatch(
      run: () async {
        final docSnapshot = await _eventsCollection.doc(eventId).get();

        if (!docSnapshot.exists) {
          throw Exception('Event not found');
        }

        return EventModel.fromJson(docSnapshot.data() as Map<String, dynamic>);
      },
    );
  }

  @override
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
  }) {
    return Result<EventModel>().tryCatch(
      run: () async {
        final now = DateTime.now();
        final eventDoc = _eventsCollection.doc();

        final event = EventModel(
          id: eventDoc.id,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          location: location,
          category: category,
          creatorId: creatorId,
          creatorName: creatorName,
          lineNumber: lineNumber,
          isAllDay: isAllDay,
          isRecurring: isRecurring,
          recurringPattern: recurringPattern,
          status: 'upcoming',
          approvalStatus: approvalStatus,
          visibility: visibility,
          rejectionReason: rejectionReason,
          createdAt: now,
          updatedAt: now,
        );

        await eventDoc.set(event.toJson());

        // Log activity
        await _activitiesCollection.add({
          'message': '📅 New event created: $title',
          'type': 'event_create',
          'timestamp': Timestamp.now(),
        });

        return event;
      },
    );
  }

  @override
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
  }) {
    return Result<EventModel>().tryCatch(
      run: () async {
        final docSnapshot = await _eventsCollection.doc(eventId).get();

        if (!docSnapshot.exists) {
          throw Exception('Event not found');
        }

        final existingEvent = EventModel.fromJson(docSnapshot.data() as Map<String, dynamic>);
        final now = DateTime.now();

        final updatedEvent = existingEvent.copyWith(
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
          approvalStatus: approvalStatus,
          visibility: visibility,
          rejectionReason: rejectionReason,
          updatedAt: now,
        );

        await _eventsCollection.doc(eventId).update(updatedEvent.toJson());

        // Log activity
        await _activitiesCollection.add({
          'message': '📝 Event updated: ${updatedEvent.title}',
          'type': 'event_update',
          'timestamp': Timestamp.now(),
        });

        return updatedEvent;
      },
    );
  }

  @override
  FirebaseResult<void> deleteEvent(String eventId) {
    return Result<void>().tryCatch(
      run: () async {
        final docSnapshot = await _eventsCollection.doc(eventId).get();

        if (!docSnapshot.exists) {
          throw Exception('Event not found');
        }

        final event = EventModel.fromJson(docSnapshot.data() as Map<String, dynamic>);

        await _eventsCollection.doc(eventId).delete();

        // Log activity
        await _activitiesCollection.add({
          'message': '🗑️ Event deleted: ${event.title}',
          'type': 'event_delete',
          'timestamp': Timestamp.now(),
        });
      },
    );
  }

  @override
  FirebaseResult<void> addAttendee({
    required String eventId,
    required String userId,
  }) {
    return Result<void>().tryCatch(
      run: () async {
        await _eventsCollection.doc(eventId).update({
          'attendees': FieldValue.arrayUnion([userId]),
          'updated_at': Timestamp.now(),
        });
      },
    );
  }

  @override
  FirebaseResult<void> removeAttendee({
    required String eventId,
    required String userId,
  }) {
    return Result<void>().tryCatch(
      run: () async {
        await _eventsCollection.doc(eventId).update({
          'attendees': FieldValue.arrayRemove([userId]),
          'updated_at': Timestamp.now(),
        });
      },
    );
  }

  @override
  FirebaseResult<List<EventModel>> getEventsForMonth(int year, int month) {
    return Result<List<EventModel>>().tryCatch(
      run: () async {
        final startOfMonth = DateTime(year, month, 1);
        final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

        final querySnapshot = await _eventsCollection
            .where('start_date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('start_date_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .orderBy('start_date_time', descending: false)
            .get();

        return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  FirebaseResult<List<EventModel>> getPendingEvents() {
    return Result<List<EventModel>>().tryCatch(
      run: () async {
        final querySnapshot = await _eventsCollection
            .where('approval_status', isEqualTo: 'pending')
            .orderBy('created_at', descending: true)
            .get();

        return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  FirebaseResult<void> cancelEvent(String eventId) {
    return Result<void>().tryCatch(
      run: () async {
        final docSnapshot = await _eventsCollection.doc(eventId).get();

        if (!docSnapshot.exists) {
          throw Exception('Event not found');
        }

        final event = EventModel.fromJson(docSnapshot.data() as Map<String, dynamic>);

        await _eventsCollection.doc(eventId).update({
          'status': 'cancelled',
          'updated_at': Timestamp.now(),
        });

        // Log activity
        await _activitiesCollection.add({
          'message': '❌ Event cancelled: ${event.title}',
          'type': 'event_cancel',
          'timestamp': Timestamp.now(),
        });
      },
    );
  }
}
