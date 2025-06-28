import 'package:society_management/meetings/model/meeting_model.dart';

abstract class IMeetingRepository {
  /// Create a new meeting
  Future<String> createMeeting(MeetingModel meeting);

  /// Get all meetings (for admin)
  Future<List<MeetingModel>> getAllMeetings();

  /// Get meetings for a specific line (for line heads)
  Future<List<MeetingModel>> getMeetingsForLine(String lineNumber);

  /// Get upcoming meetings
  Future<List<MeetingModel>> getUpcomingMeetings({String? lineNumber});

  /// Get past meetings
  Future<List<MeetingModel>> getPastMeetings({String? lineNumber});

  /// Get meeting by ID
  Future<MeetingModel?> getMeetingById(String meetingId);

  /// Update meeting
  Future<void> updateMeeting(MeetingModel meeting);

  /// Delete meeting
  Future<void> deleteMeeting(String meetingId);

  /// Add agenda item to meeting
  Future<void> addAgendaItem(String meetingId, AgendaItem agendaItem);

  /// Update agenda item status
  Future<void> updateAgendaItem(String meetingId, AgendaItem agendaItem);

  /// Delete agenda item
  Future<void> deleteAgendaItem(String meetingId, String agendaItemId);

  /// Mark attendance for a user
  Future<void> markAttendance(String meetingId, AttendanceRecord attendance);

  /// Get all society members for attendance
  Future<List<AttendanceRecord>> getSocietyMembersForAttendance(String? targetLine);

  /// Update multiple attendance records
  Future<void> updateMultipleAttendance(String meetingId, List<AttendanceRecord> attendanceRecords);
}
