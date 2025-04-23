import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@Injectable(as: IUserRepository)
class UserRepository extends IUserRepository {
  UserRepository(super.firestore);

  @override
  FirebaseResult<UserModel> addCustomer(
      {String? name,
      String? email,
      String? mobileNumber,
      String? villNumber,
      String? line,
      String? role,
      String? password}) {
    return Result<UserModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final customerCollection = FirebaseFirestore.instance.users;
        final customerDoc = customerCollection.doc();

        // Create user document
        await customerDoc.set({
          'id': customerDoc.id,
          'name': name,
          'email': email,
          'mobile_number': mobileNumber,
          'villa_number': villNumber,
          'line_number': line,
          'role': role,
          'password': password,
          'createdAt': now.toDate(),
          'updatedAt': now.toDate(),
        });

        // Update dashboard stats - increment total members
        final statsRef = FirebaseFirestore.instance.dashboardStats.doc('stats');
        final statsDoc = await statsRef.get();

        if (!statsDoc.exists) {
          // Create initial stats document if it doesn't exist
          await statsRef.set({
            'total_members': 1,
            'total_expenses': 0.0,
            'updated_at': now,
          });
        } else {
          // Increment total members count
          final currentCount = statsDoc.data()?['total_members'] as int? ?? 0;
          await statsRef.update({
            'total_members': currentCount + 1,
            'updated_at': now,
          });
        }

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🧾 New user added: ${name ?? 'Unknown'} (${role ?? 'Member'})',
          'type': 'user',
          'timestamp': now,
        });

        return UserModel(
          id: customerDoc.id,
          name: name,
          email: email,
          mobileNumber: mobileNumber,
          villNumber: villNumber,
          lineNumber: line,
          role: role,
          password: password,
          createdAt: now.toDate().toString(),
          updatedAt: now.toDate().toString(),
        );
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
        final customerCollection = FirebaseFirestore.instance.users;
        final userDoc = await customerCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        await customerCollection.doc(userId).delete();
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
