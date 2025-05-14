import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';

/// Service to handle maintenance-related updates when user data changes
class MaintenanceUpdateService {
  /// Update maintenance payments when a user's line number changes
  static Future<void> updateUserLineInPayments({
    required String userId,
    required String oldLineNumber,
    required String newLineNumber,
    required String userName,
  }) async {
    try {
      // Validate input parameters
      if (userId.isEmpty) {
        debugPrint('Cannot update payments: userId is empty');
        return;
      }

      if (oldLineNumber.isEmpty || newLineNumber.isEmpty) {
        debugPrint('Cannot update payments: line numbers cannot be empty');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      int updatedRecords = 0;

      // 1. Update maintenance payments
      final paymentsSnapshot = await firestore.maintenancePayments.where('user_id', isEqualTo: userId).get();
      for (final doc in paymentsSnapshot.docs) {
        batch.update(doc.reference, {
          'user_line_number': newLineNumber,
        });
        updatedRecords++;
      }

      // 2. Update complaints
      final complaintsSnapshot = await firestore.complaints.where('user_id', isEqualTo: userId).get();
      for (final doc in complaintsSnapshot.docs) {
        batch.update(doc.reference, {
          'user_line_number': newLineNumber,
        });
        updatedRecords++;
      }

      // 3. Update events where user is creator
      final eventsSnapshot = await firestore.events.where('creator_id', isEqualTo: userId).get();
      for (final doc in eventsSnapshot.docs) {
        batch.update(doc.reference, {
          'line_number': newLineNumber,
        });
        updatedRecords++;
      }

      // 4. Update expenses added by this user
      final expensesSnapshot = await firestore.expenses.where('added_by', isEqualTo: userId).get();
      for (final doc in expensesSnapshot.docs) {
        batch.update(doc.reference, {
          'line_number': newLineNumber,
        });
        updatedRecords++;
      }

      // Commit all updates in a single batch
      if (updatedRecords > 0) {
        await batch.commit();
        debugPrint('Updated line number in $updatedRecords records for user $userId');
      } else {
        debugPrint('No records found to update for user $userId');
      }

      // Log activity
      final activityDoc = firestore.activities.doc();
      await activityDoc.set({
        'id': activityDoc.id,
        'message': '🔄 User $userName moved from Line $oldLineNumber to Line $newLineNumber',
        'type': 'user_line_changed',
        'timestamp': Timestamp.now(),
      });

      // Update dashboard stats for both lines
      try {
        final statsRepository = getIt<IDashboardStatsRepository>();
        await statsRepository.updateLineStats(oldLineNumber);
        await statsRepository.updateLineStats(newLineNumber);
        await statsRepository.updateAdminDashboardStats();
      } catch (statsError) {
        // Log error but don't fail the entire operation
        debugPrint('Error updating dashboard stats: $statsError');
      }

      debugPrint('Successfully updated line number for user $userId in all collections');
    } catch (e) {
      debugPrint('Error updating user line information: $e');
    }
  }

  /// Update all maintenance-related data when a user is updated
  static Future<void> handleUserUpdate(UserModel oldUser, UserModel updatedUser) async {
    try {
      // Check if user ID is valid
      if (updatedUser.id == null) {
        debugPrint('Cannot update user with null ID');
        return;
      }

      // Check if line number has changed
      if (oldUser.lineNumber != null &&
          updatedUser.lineNumber != null &&
          oldUser.lineNumber != updatedUser.lineNumber) {
        await updateUserLineInPayments(
          userId: updatedUser.id!,
          oldLineNumber: oldUser.lineNumber!,
          newLineNumber: updatedUser.lineNumber!,
          userName: updatedUser.name ?? 'Unknown',
        );
      }

      // Update dashboard stats regardless of what changed
      try {
        final statsRepository = getIt<IDashboardStatsRepository>();
        await statsRepository.updateAdminDashboardStats();

        // If line number changed, update both old and new line stats
        if (oldUser.lineNumber != updatedUser.lineNumber) {
          if (oldUser.lineNumber != null) {
            await statsRepository.updateLineStats(oldUser.lineNumber!);
          }
          if (updatedUser.lineNumber != null) {
            await statsRepository.updateLineStats(updatedUser.lineNumber!);
          }
        }
        // Otherwise just update the current line stats
        else if (updatedUser.lineNumber != null) {
          await statsRepository.updateLineStats(updatedUser.lineNumber!);
        }
      } catch (statsError) {
        // Log error but don't fail the entire operation
        debugPrint('Error updating dashboard stats in handleUserUpdate: $statsError');
      }
    } catch (e) {
      debugPrint('Error in handleUserUpdate: $e');
    }
  }

  /// Fix inconsistencies for a specific user
  /// This can be called manually to fix users whose line numbers were changed
  /// but their related records weren't updated
  static Future<void> fixUserLineInconsistencies(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get the user's current line number
      final userDoc = await firestore.users.doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('User $userId not found');
        return;
      }

      final userData = userDoc.data()!;
      final currentLineNumber = userData['line_number'] as String?;
      final userName = userData['name'] as String? ?? 'Unknown';

      if (currentLineNumber == null || currentLineNumber.isEmpty) {
        debugPrint('User $userId has no line number');
        return;
      }

      // Find all records with this user ID and update them
      final batch = firestore.batch();
      int updatedRecords = 0;

      // 1. Update maintenance payments
      final paymentsSnapshot = await firestore.maintenancePayments.where('user_id', isEqualTo: userId).get();
      for (final doc in paymentsSnapshot.docs) {
        final oldLineNumber = doc.data()['user_line_number'] as String?;
        if (oldLineNumber != currentLineNumber) {
          batch.update(doc.reference, {
            'user_line_number': currentLineNumber,
          });
          updatedRecords++;
        }
      }

      // 2. Update complaints
      final complaintsSnapshot = await firestore.complaints.where('user_id', isEqualTo: userId).get();
      for (final doc in complaintsSnapshot.docs) {
        final oldLineNumber = doc.data()['user_line_number'] as String?;
        if (oldLineNumber != currentLineNumber) {
          batch.update(doc.reference, {
            'user_line_number': currentLineNumber,
          });
          updatedRecords++;
        }
      }

      // 3. Update events where user is creator
      final eventsSnapshot = await firestore.events.where('creator_id', isEqualTo: userId).get();
      for (final doc in eventsSnapshot.docs) {
        final oldLineNumber = doc.data()['line_number'] as String?;
        if (oldLineNumber != currentLineNumber) {
          batch.update(doc.reference, {
            'line_number': currentLineNumber,
          });
          updatedRecords++;
        }
      }

      // 4. Update expenses added by this user
      final expensesSnapshot = await firestore.expenses.where('added_by', isEqualTo: userId).get();
      for (final doc in expensesSnapshot.docs) {
        final oldLineNumber = doc.data()['line_number'] as String?;
        if (oldLineNumber != currentLineNumber) {
          batch.update(doc.reference, {
            'line_number': currentLineNumber,
          });
          updatedRecords++;
        }
      }

      // Commit all updates in a single batch
      if (updatedRecords > 0) {
        await batch.commit();
        debugPrint('Fixed $updatedRecords inconsistent records for user $userId');

        // Log activity
        final activityDoc = firestore.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🔧 Fixed line number inconsistencies for user $userName',
          'type': 'user_line_fixed',
          'timestamp': Timestamp.now(),
        });

        // Update stats for the current line
        final statsRepository = getIt<IDashboardStatsRepository>();
        await statsRepository.updateLineStats(currentLineNumber);
        await statsRepository.updateAdminDashboardStats();
      } else {
        debugPrint('No inconsistent records found for user $userId');
      }
    } catch (e) {
      debugPrint('Error fixing user line inconsistencies: $e');
    }
  }

  /// Fix inconsistencies for all users
  /// This can be called to fix all users whose line numbers were changed
  /// but their related records weren't updated
  static Future<void> fixAllUserLineInconsistencies() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get all users
      final usersSnapshot = await firestore.users.get();
      int fixedUsers = 0;

      // Process each user
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        await fixUserLineInconsistencies(userId);
        fixedUsers++;
      }

      debugPrint('Processed $fixedUsers users for line inconsistencies');
    } catch (e) {
      debugPrint('Error fixing all user line inconsistencies: $e');
    }
  }
}
