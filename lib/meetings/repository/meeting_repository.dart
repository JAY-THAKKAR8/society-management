import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/core/extensions/firestore_extensions.dart';
import 'package:society_management/meetings/model/meeting_model.dart';
import 'package:society_management/meetings/repository/i_meeting_repository.dart';

@Injectable(as: IMeetingRepository)
class MeetingRepository implements IMeetingRepository {
  final FirebaseFirestore _firestore;

  MeetingRepository(this._firestore);

  @override
  Future<String> createMeeting(MeetingModel meeting) async {
    try {
      final members = await getSocietyMembersForAttendance(meeting.targetLine);

      final meetingWithAttendance = meeting.copyWith(
        attendance: members,
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.meetings.add(meetingWithAttendance.toJson());
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create meeting: $e');
    }
  }

  @override
  Future<List<MeetingModel>> getAllMeetings() async {
    try {
      final snapshot = await _firestore.meetings.orderBy('dateTime', descending: true).get();
      return snapshot.docs.map((doc) => MeetingModel.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get meetings: $e');
    }
  }

  @override
  Future<List<MeetingModel>> getMeetingsForLine(String lineNumber) async {
    try {
      // Get meetings for specific line and general meetings (targetLine is null)
      final specificLineQuery =
          _firestore.meetings.where('targetLine', isEqualTo: lineNumber).orderBy('dateTime', descending: true);

      final generalMeetingsQuery =
          _firestore.meetings.where('targetLine', isNull: true).orderBy('dateTime', descending: true);

      final specificLineSnapshot = await specificLineQuery.get();
      final generalMeetingsSnapshot = await generalMeetingsQuery.get();

      final allMeetings = <MeetingModel>[];

      // Add specific line meetings
      allMeetings.addAll(specificLineSnapshot.docs.map((doc) => MeetingModel.fromJson(doc.data())).toList());

      // Add general meetings
      allMeetings.addAll(generalMeetingsSnapshot.docs.map((doc) => MeetingModel.fromJson(doc.data())).toList());

      // Sort by dateTime descending
      allMeetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return allMeetings;
    } catch (e) {
      throw Exception('Failed to get meetings for line: $e');
    }
  }

  @override
  Future<List<MeetingModel>> getUpcomingMeetings({String? lineNumber}) async {
    try {
      final now = Timestamp.now();

      // All users see all upcoming meetings - no line filtering
      final query = _firestore.meetings.where('dateTime', isGreaterThan: now).orderBy('dateTime');

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => MeetingModel.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get upcoming meetings: $e');
    }
  }

  @override
  Future<List<MeetingModel>> getPastMeetings({String? lineNumber}) async {
    try {
      final now = Timestamp.now();

      // All users see all past meetings - no line filtering
      final query = _firestore.meetings.where('dateTime', isLessThan: now).orderBy('dateTime', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => MeetingModel.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get past meetings: $e');
    }
  }

  @override
  Future<MeetingModel?> getMeetingById(String meetingId) async {
    try {
      final doc = await _firestore.meetings.doc(meetingId).get();

      if (!doc.exists) {
        return null;
      }

      return MeetingModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get meeting: $e');
    }
  }

  @override
  Future<void> updateMeeting(MeetingModel meeting) async {
    try {
      if (meeting.id == null) {
        throw Exception('Meeting ID is required for update');
      }

      final updatedMeeting = meeting.copyWith(updatedAt: DateTime.now());
      await _firestore.meetings.doc(meeting.id).update(updatedMeeting.toJson());
    } catch (e) {
      throw Exception('Failed to update meeting: $e');
    }
  }

  @override
  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _firestore.meetings.doc(meetingId).delete();
    } catch (e) {
      throw Exception('Failed to delete meeting: $e');
    }
  }

  @override
  Future<void> addAgendaItem(String meetingId, AgendaItem agendaItem) async {
    try {
      final meeting = await getMeetingById(meetingId);
      if (meeting == null) {
        throw Exception('Meeting not found');
      }

      final updatedAgenda = [...meeting.agenda, agendaItem];
      final updatedMeeting = meeting.copyWith(
        agenda: updatedAgenda,
        updatedAt: DateTime.now(),
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      throw Exception('Failed to add agenda item: $e');
    }
  }

  @override
  Future<void> updateAgendaItem(String meetingId, AgendaItem agendaItem) async {
    try {
      final meeting = await getMeetingById(meetingId);
      if (meeting == null) {
        throw Exception('Meeting not found');
      }

      final updatedAgenda = meeting.agenda.map((item) {
        return item.id == agendaItem.id ? agendaItem : item;
      }).toList();

      final updatedMeeting = meeting.copyWith(
        agenda: updatedAgenda,
        updatedAt: DateTime.now(),
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      throw Exception('Failed to update agenda item: $e');
    }
  }

  @override
  Future<void> deleteAgendaItem(String meetingId, String agendaItemId) async {
    try {
      final meeting = await getMeetingById(meetingId);
      if (meeting == null) {
        throw Exception('Meeting not found');
      }

      final updatedAgenda = meeting.agenda.where((item) => item.id != agendaItemId).toList();
      final updatedMeeting = meeting.copyWith(
        agenda: updatedAgenda,
        updatedAt: DateTime.now(),
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      throw Exception('Failed to delete agenda item: $e');
    }
  }

  @override
  Future<void> markAttendance(String meetingId, AttendanceRecord attendance) async {
    try {
      final meeting = await getMeetingById(meetingId);
      if (meeting == null) {
        throw Exception('Meeting not found');
      }

      final updatedAttendance = meeting.attendance.map((record) {
        return record.userId == attendance.userId ? attendance : record;
      }).toList();

      final updatedMeeting = meeting.copyWith(
        attendance: updatedAttendance,
        updatedAt: DateTime.now(),
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  @override
  Future<List<AttendanceRecord>> getSocietyMembersForAttendance(String? targetLine) async {
    try {
      Query query = _firestore.users;

      if (targetLine != null) {
        // Use the correct field name for line number
        query = query.where('line_number', isEqualTo: targetLine);
      }

      final snapshot = await query.get();

      // Filter out admin users and create attendance records
      final attendanceRecords = <AttendanceRecord>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userRole = data['role'] ?? 'Member';

        // Skip admin users
        if (userRole.toLowerCase() == 'admin' || userRole.toLowerCase() == 'admins') {
          continue;
        }

        attendanceRecords.add(AttendanceRecord(
          userId: data['id'] ?? doc.id,
          userName: data['name'] ?? 'Unknown User',
          userRole: userRole,
          userLine: data['line_number'],
          userVilla: data['villa_number'],
          status: AttendanceStatus.notMarked,
        ));
      }

      return attendanceRecords;
    } catch (e) {
      throw Exception('Failed to get society members: $e');
    }
  }

  @override
  Future<void> updateMultipleAttendance(String meetingId, List<AttendanceRecord> attendanceRecords) async {
    try {
      final meeting = await getMeetingById(meetingId);
      if (meeting == null) {
        throw Exception('Meeting not found');
      }

      final updatedMeeting = meeting.copyWith(
        attendance: attendanceRecords,
        updatedAt: DateTime.now(),
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }
}
