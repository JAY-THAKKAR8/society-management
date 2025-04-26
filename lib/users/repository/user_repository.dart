import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/auth/repository/auth_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';
import 'package:society_management/utility/utility.dart';

@Injectable(as: IUserRepository)
class UserRepository extends IUserRepository {
  UserRepository(super.firestore);

  final AuthRepository _authRepository = AuthRepository();

  @override
  FirebaseResult<UserModel> addUser(
      {String? name,
      String? email,
      String? mobileNumber,
      String? villNumber,
      String? line,
      String? role,
      String? password}) {
    return Result<UserModel>().tryCatch(
      run: () async {
        // Get current user to use as creator
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No user is currently logged in');
        }

        // Use AuthRepository to create user in Firebase Auth and Firestore
        final result = await _authRepository.createUserWithEmailAndPassword(
          email: email ?? '',
          password: password ?? '',
          name: name ?? '',
          role: role ?? '',
          lineNumber: line,
          villNumber: villNumber,
          mobileNumber: mobileNumber,
          creatorId: currentUser.uid, // Pass current user as creator
        );

        if (!result.isSuccess || result.user == null) {
          throw Exception(result.errorMessage ?? 'Failed to create user');
        }

        // Add the new user to all active maintenance periods
        try {
          final maintenanceRepository = getIt<IMaintenanceRepository>();
          await maintenanceRepository.addUserToActiveMaintenancePeriods(
            userId: result.user!.id!,
            userName: result.user!.name ?? 'Unknown',
            userVillaNumber: result.user!.villNumber,
            userLineNumber: result.user!.lineNumber,
            userRole: result.user!.role,
          );
        } catch (e) {
          // Log error but don't fail the user creation
          Utility.toast(message: 'Error adding user to maintenance periods: $e');
        }

        return result.user!;
      },
    );
  }

  @override
  FirebaseResult<List<UserModel>> getAllUsers() {
    return Result<List<UserModel>>().tryCatch(
      run: () async {
        final users = await FirebaseFirestore.instance.users.get();

        final userModels = users.docs.map((e) => UserModel.fromJson(e.data())).toList();

        return userModels;
      },
    );
  }

  @override
  FirebaseResult<UserModel> updateCustomer({
    required String userId,
    String? name,
    String? mobileNumber,
    String? line,
    String? role,
    String? villNumber,
    String? isVillaOpen,
  }) {
    return Result<UserModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final customerCollection = FirebaseFirestore.instance.users;
        final firebaseAuth = FirebaseAuth.instance;
        final currentUser = firebaseAuth.currentUser;
        if (currentUser != null && name != null) {
          await currentUser.updateDisplayName(name);
        }

        await customerCollection.doc(userId).update({
          if (name != null) 'name': name,
          if (mobileNumber != null) 'mobile_number': mobileNumber,
          'updatedAt': now.toDate(),
          if (role != null) 'role': role,
          if (line != null) 'line_number': line,
          if (villNumber != null) 'villa_number': villNumber,
          if (isVillaOpen != null) 'is_villa_open': isVillaOpen,
        });

        final updatedUser = await customerCollection.doc(userId).get();
        return UserModel.fromJson(updatedUser.data()!);
      },
    );
  }

  @override
  FirebaseResult<UserModel> getUser({required String userId}) {
    return Result<UserModel>().tryCatch(
      run: () async {
        final customerCollection = FirebaseFirestore.instance.users;
        final userDoc = await customerCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        return UserModel.fromJson(userDoc.data()!);
      },
    );
  }

  @override
  FirebaseResult<void> deleteCustomer({required String userId}) {
    return Result<void>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final customerCollection = FirebaseFirestore.instance.users;
        final userDoc = await customerCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        // Get user data before deleting
        final userData = userDoc.data()!;
        final userName = userData['name'] as String? ?? 'Unknown';
        final userRole = userData['role'] as String? ?? 'Member';

        // Delete the user document
        await customerCollection.doc(userId).delete();

        // Update dashboard stats - decrement total members
        final statsRef = FirebaseFirestore.instance.dashboardStats.doc('stats');
        final statsDoc = await statsRef.get();

        if (statsDoc.exists) {
          // Decrement total members count
          final currentCount = statsDoc.data()?['total_members'] as int? ?? 0;
          // Ensure we don't go below zero
          final newCount = currentCount > 0 ? currentCount - 1 : 0;
          await statsRef.update({
            'total_members': newCount,
            'updated_at': now,
          });
        }

        // Log activity for deletion
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🗑️ User deleted: $userName ($userRole)',
          'type': 'user_delete',
          'timestamp': now,
        });
      },
    );
  }

  @override
  FirebaseResult<UserModel> getCurrentUser() {
    return Result<UserModel>().tryCatch(
      run: () async {
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          throw Exception('No user is currently logged in');
        }

        final userDoc = await FirebaseFirestore.instance.users.doc(currentUser.uid).get();

        if (!userDoc.exists) {
          throw Exception('User data not found');
        }

        return UserModel.fromJson(userDoc.data()!);
      },
    );
  }
}
