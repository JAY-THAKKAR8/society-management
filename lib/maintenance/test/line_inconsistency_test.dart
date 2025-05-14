import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:society_management/maintenance/service/maintenance_update_service.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/utility.dart';

/// A simple test script to verify the line inconsistency fix works correctly
/// This is not a unit test, but a manual test script that can be run from the app
class LineInconsistencyTest {
  static Future<void> runTest() async {
    try {
      debugPrint('Starting line inconsistency test...');
      
      // Get all users
      final userRepository = getIt<IUserRepository>();
      final usersResult = await userRepository.getAllUsers();
      
      usersResult.fold(
        (failure) {
          debugPrint('Failed to get users: ${failure.message}');
          Utility.toast(message: 'Test failed: ${failure.message}');
        },
        (users) async {
          // Find a user with a line number
          final testUser = users.firstWhere(
            (user) => user.lineNumber != null && user.id != null,
            orElse: () => const UserModel(),
          );
          
          if (testUser.id == null || testUser.lineNumber == null) {
            debugPrint('No suitable test user found');
            Utility.toast(message: 'Test failed: No suitable test user found');
            return;
          }
          
          debugPrint('Found test user: ${testUser.name} (${testUser.id}) in line ${testUser.lineNumber}');
          
          // Create a test maintenance payment with incorrect line number
          final firestore = FirebaseFirestore.instance;
          final incorrectLineNumber = testUser.lineNumber == 'Line 1' ? 'Line 2' : 'Line 1';
          
          // Create a test payment with incorrect line number
          final paymentDoc = firestore.collection('maintenance_payments').doc();
          await paymentDoc.set({
            'id': paymentDoc.id,
            'period_id': 'test_period',
            'user_id': testUser.id,
            'user_name': testUser.name,
            'user_villa_number': testUser.villNumber,
            'user_line_number': incorrectLineNumber, // Incorrect line number
            'amount': 1000.0,
            'amount_paid': 0.0,
            'status': 'pending',
            'created_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
          });
          
          debugPrint('Created test payment with incorrect line number: $incorrectLineNumber');
          
          // Create a test complaint with incorrect line number
          final complaintDoc = firestore.collection('complaints').doc();
          await complaintDoc.set({
            'id': complaintDoc.id,
            'user_id': testUser.id,
            'user_name': testUser.name,
            'user_villa_number': testUser.villNumber,
            'user_line_number': incorrectLineNumber, // Incorrect line number
            'title': 'Test Complaint',
            'description': 'This is a test complaint',
            'status': 'pending',
            'created_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
          });
          
          debugPrint('Created test complaint with incorrect line number: $incorrectLineNumber');
          
          // Run the fix for this user
          await MaintenanceUpdateService.fixUserLineInconsistencies(testUser.id!);
          
          // Verify the fix worked
          final updatedPaymentDoc = await paymentDoc.get();
          final updatedComplaintDoc = await complaintDoc.get();
          
          final paymentLineNumber = updatedPaymentDoc.data()?['user_line_number'];
          final complaintLineNumber = updatedComplaintDoc.data()?['user_line_number'];
          
          if (paymentLineNumber == testUser.lineNumber && complaintLineNumber == testUser.lineNumber) {
            debugPrint('Test passed! Line numbers were corrected:');
            debugPrint('Payment line number: $paymentLineNumber');
            debugPrint('Complaint line number: $complaintLineNumber');
            Utility.toast(message: 'Test passed! Line numbers were corrected');
          } else {
            debugPrint('Test failed! Line numbers were not corrected:');
            debugPrint('Payment line number: $paymentLineNumber (should be ${testUser.lineNumber})');
            debugPrint('Complaint line number: $complaintLineNumber (should be ${testUser.lineNumber})');
            Utility.toast(message: 'Test failed! Line numbers were not corrected');
          }
          
          // Clean up test data
          await paymentDoc.delete();
          await complaintDoc.delete();
          debugPrint('Test data cleaned up');
        },
      );
    } catch (e) {
      debugPrint('Error running line inconsistency test: $e');
      Utility.toast(message: 'Test error: $e');
    }
  }
}
