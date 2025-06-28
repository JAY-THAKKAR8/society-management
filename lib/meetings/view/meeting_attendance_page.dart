import 'package:flutter/material.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/meetings/model/meeting_model.dart';
import 'package:society_management/meetings/repository/i_meeting_repository.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_gradient_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

// Data model for attendance state
class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final bool hasChanges;
  final String? errorMessage;

  const AttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.hasChanges = false,
    this.errorMessage,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    bool? hasChanges,
    String? errorMessage,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      hasChanges: hasChanges ?? this.hasChanges,
      errorMessage: errorMessage,
    );
  }
}

class MeetingAttendancePage extends StatefulWidget {
  final MeetingModel meeting;

  const MeetingAttendancePage({
    super.key,
    required this.meeting,
  });

  @override
  State<MeetingAttendancePage> createState() => _MeetingAttendancePageState();
}

class _MeetingAttendancePageState extends State<MeetingAttendancePage> {
  final IMeetingRepository _meetingRepository = getIt<IMeetingRepository>();
  late final ValueNotifier<AttendanceState> _attendanceNotifier;

  @override
  void initState() {
    super.initState();
    _initializeAttendance();
  }

  void _initializeAttendance() {
    try {
      // Filter out admin users from attendance records
      final filteredRecords = widget.meeting.attendance
          .where((record) => record.userRole.toLowerCase() != 'admin' && record.userRole.toLowerCase() != 'admins')
          .toList();

      _attendanceNotifier = ValueNotifier(AttendanceState(records: filteredRecords));

      // If no records found, show helpful error message
      if (filteredRecords.isEmpty) {
        _attendanceNotifier.value = _attendanceNotifier.value.copyWith(
          errorMessage:
              'No line members found for this meeting. The meeting may not have been created properly or no members are assigned to this line.',
        );
      }
    } catch (e) {
      _attendanceNotifier = ValueNotifier(AttendanceState(
        errorMessage: 'Error loading attendance data: $e',
      ));
    }
  }

  @override
  void dispose() {
    _attendanceNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AttendanceState>(
      valueListenable: _attendanceNotifier,
      builder: (context, state, child) {
        final presentCount = state.records.where((a) => a.status == AttendanceStatus.present).length;
        final absentCount = state.records.where((a) => a.status == AttendanceStatus.absent).length;
        final notMarkedCount = state.records.where((a) => a.status == AttendanceStatus.notMarked).length;

        return Scaffold(
          appBar: CommonAppBar(
            title: 'Mark Attendance',
            actions: [
              if (state.hasChanges)
                TextButton(
                  onPressed: state.isLoading ? null : _saveAttendance,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
            ],
          ),
          body: Column(
            children: [
              // Error Message
              if (state.errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Summary Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: ThemeAwareCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Attendance Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('Present', presentCount, Colors.green),
                            _buildSummaryItem('Absent', absentCount, Colors.red),
                            _buildSummaryItem('Not Marked', notMarkedCount, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Actions
              if (state.records.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Colors.lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _markAllAttendance(AttendanceStatus.present),
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text(
                              'Mark All Present',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _markAllAttendance(AttendanceStatus.absent),
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text(
                              'Mark All Absent',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Attendance List
              Expanded(
                child: state.records.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.records.length,
                        itemBuilder: (context, index) {
                          final attendance = state.records[index];
                          return _buildAttendanceItem(attendance, index);
                        },
                      ),
              ),

              // Save Button
              if (state.hasChanges)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CommonGradientButton(
                      text: state.isLoading ? 'Saving...' : 'Save Attendance',
                      onPressed: state.isLoading ? null : _saveAttendance,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No line members found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This meeting may not have been created properly\nor no members are assigned to this line.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(AttendanceRecord attendance, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ThemeAwareCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.userName.isNotEmpty ? attendance.userName : 'Unknown User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatUserRole(attendance.userRole),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    if (attendance.userLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Line ${_formatLineNumber(attendance.userLine)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                    if (attendance.userVilla != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Villa: ${attendance.userVilla}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Attendance Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAttendanceButton(
                    icon: Icons.check,
                    label: 'Present',
                    color: Colors.green,
                    isSelected: attendance.status == AttendanceStatus.present,
                    onPressed: () => _updateAttendance(index, AttendanceStatus.present),
                  ),
                  const SizedBox(width: 8),
                  _buildAttendanceButton(
                    icon: Icons.close,
                    label: 'Absent',
                    color: Colors.red,
                    isSelected: attendance.status == AttendanceStatus.absent,
                    onPressed: () => _updateAttendance(index, AttendanceStatus.absent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateAttendance(int index, AttendanceStatus status) {
    try {
      final currentState = _attendanceNotifier.value;
      final updatedRecords = List<AttendanceRecord>.from(currentState.records);

      updatedRecords[index] = updatedRecords[index].copyWith(
        status: status,
        markedAt: DateTime.now(),
        markedBy: 'Current User', // TODO: Get current user ID
      );

      _attendanceNotifier.value = currentState.copyWith(
        records: updatedRecords,
        hasChanges: true,
        errorMessage: null, // Clear any previous errors
      );
    } catch (e) {
      _attendanceNotifier.value = _attendanceNotifier.value.copyWith(
        errorMessage: 'Error updating attendance: $e',
      );
    }
  }

  void _markAllAttendance(AttendanceStatus status) {
    try {
      final currentState = _attendanceNotifier.value;
      final updatedRecords = currentState.records.map((record) {
        return record.copyWith(
          status: status,
          markedAt: DateTime.now(),
          markedBy: 'Current User', // TODO: Get current user ID
        );
      }).toList();

      _attendanceNotifier.value = currentState.copyWith(
        records: updatedRecords,
        hasChanges: true,
        errorMessage: null, // Clear any previous errors
      );
    } catch (e) {
      _attendanceNotifier.value = _attendanceNotifier.value.copyWith(
        errorMessage: 'Error marking all attendance: $e',
      );
    }
  }

  String _formatUserRole(String role) {
    if (role.isEmpty) return 'Member';

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
    if (lineNumber == null || lineNumber.isEmpty) return 'Unknown';

    switch (lineNumber.toUpperCase()) {
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

  Future<void> _saveAttendance() async {
    final currentState = _attendanceNotifier.value;

    if (currentState.records.isEmpty) {
      Utility.toast(message: 'No attendance records to save');
      return;
    }

    _attendanceNotifier.value = currentState.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _meetingRepository.updateMultipleAttendance(
        widget.meeting.id!,
        currentState.records,
      );

      Utility.toast(message: 'Attendance saved successfully!');

      _attendanceNotifier.value = currentState.copyWith(
        isLoading: false,
        hasChanges: false,
        errorMessage: null,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _attendanceNotifier.value = currentState.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save attendance: $e',
      );
      Utility.toast(message: 'Error saving attendance: $e');
    }
  }
}
