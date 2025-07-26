import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/users/model/user_model.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.user,
  });
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Login failed. Please try again.',
        );
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();

      if (userDoc.docs.isEmpty) {
        // Check if this is the default admin trying to log in
        if (email == 'admin@kdv.com') {
          // Create the admin user in Firestore
          try {
            final userId = userCredential.user!.uid;
            final timestamp = DateTime.now().toIso8601String();

            final newAdminUser = UserModel(
              id: userId,
              name: 'Admin',
              email: email,
              password: password, // Note: Storing password in plaintext is not secure
              role: AppConstants.admin,
              createdAt: timestamp,
              updatedAt: timestamp,
            );

            await _firestore.collection('users').doc(userId).set(newAdminUser.toJson());

            // Log activity
            await _firestore.collection('activities').add({
              'message': '👤 Default admin user created',
              'type': 'user_create',
              'timestamp': FieldValue.serverTimestamp(),
            });

            return AuthResult(
              isSuccess: true,
              user: newAdminUser,
            );
          } catch (e) {
            return AuthResult(
              isSuccess: false,
              errorMessage: 'Failed to create admin user: $e',
            );
          }
        } else {
          return AuthResult(
            isSuccess: false,
            errorMessage: 'User data not found.',
          );
        }
      }

      final userData = userDoc.docs.first.data();
      final user = UserModel.fromJson(userData);

      return AuthResult(
        isSuccess: true,
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
          break;
      }
      return AuthResult(
        isSuccess: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Get current user
  User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  // Get current user data from Firestore
  Future<AuthResult> getCurrentUserData() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'No user is currently signed in.',
        );
      }

      final userDoc = await _firestore.collection('users').where('email', isEqualTo: currentUser.email).limit(1).get();

      if (userDoc.docs.isEmpty) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'User data not found.',
        );
      }

      final userData = userDoc.docs.first.data();
      final user = UserModel.fromJson(userData);

      return AuthResult(
        isSuccess: true,
        user: user,
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'An error occurred: $e',
      );
    }
  }

  // Create a new user with email and password
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? lineNumber,
    String? villNumber,
    String? mobileNumber,
    String? creatorId,
  }) async {
    try {
      // Check if user already exists
      final existingUsers = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();

      if (existingUsers.docs.isNotEmpty) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'A user with this email already exists.',
        );
      }

      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Failed to create user. Please try again.',
        );
      }

      // Create user document in Firestore
      final userId = userCredential.user!.uid;
      final timestamp = DateTime.now().toIso8601String();

      // Validate role based on business rules
      String validatedRole = role;
      if (role != AppConstants.admin &&
          role != AppConstants.lineLead &&
          role != AppConstants.lineMember &&
          role != AppConstants.lineHeadAndMember) {
        // Default to line member if invalid role provided
        validatedRole = AppConstants.lineMember;
      }

      final newUser = UserModel(
        id: userId,
        name: name,
        email: email,
        password: password, // Note: Storing password in plaintext is not secure
        role: validatedRole,
        lineNumber: lineNumber,
        villNumber: villNumber,
        mobileNumber: mobileNumber,
        isVillaOpen: '1',
        createdAt: timestamp,
        updatedAt: timestamp,
        createdBy: creatorId,
      );

      await _firestore.collection('users').doc(userId).set(newUser.toJson());

      // Update dashboard stats
      final statsRef = _firestore.collection('dashboard_stats').doc('stats');
      final statsDoc = await statsRef.get();

      if (statsDoc.exists) {
        final currentCount = statsDoc.data()?['total_members'] as int? ?? 0;
        await statsRef.update({
          'total_members': currentCount + 1,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await statsRef.set({
          'total_members': 1,
          'total_expenses': 0.0,
          'maintenance_collected': 0.0,
          'maintenance_pending': 0.0,
          'active_maintenance': 0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Log activity
      await _firestore.collection('activities').add({
        'message':
            '👤 New user created: $name (${_getRoleDisplayName(validatedRole)}) for Villa: ${villNumber ?? 'N/A'}',
        'type': 'user_create',
        'timestamp': FieldValue.serverTimestamp(),
        'created_by': creatorId,
      });

      return AuthResult(
        isSuccess: true,
        user: newUser,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
          break;
      }
      return AuthResult(
        isSuccess: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }

  // Create default admin user if it doesn't exist
  Future<void> createDefaultAdminIfNotExists() async {
    try {
      const defaultAdminEmail = 'admin@kdv.com';
      const defaultAdminPassword = 'admin123';

      // Check if admin user already exists in Firestore
      final existingUsers =
          await _firestore.collection('users').where('email', isEqualTo: defaultAdminEmail).limit(1).get();

      if (existingUsers.docs.isNotEmpty) {
        // Admin already exists in Firestore
        return;
      }

      // Check if admin exists in Firebase Auth
      try {
        // Try to sign in with admin credentials
        await _firebaseAuth.signInWithEmailAndPassword(
          email: defaultAdminEmail,
          password: defaultAdminPassword,
        );

        // If sign in succeeds, admin exists in Auth but not in Firestore
        // Get the current user
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          // Create admin in Firestore
          final timestamp = DateTime.now().toIso8601String();
          final newAdminUser = UserModel(
            id: currentUser.uid,
            name: 'Admin',
            email: defaultAdminEmail,
            password: defaultAdminPassword,
            role: AppConstants.admin,
            createdAt: timestamp,
            updatedAt: timestamp,
          );

          await _firestore.collection('users').doc(currentUser.uid).set(newAdminUser.toJson());

          // Log activity
          await _firestore.collection('activities').add({
            'message': '👤 Default admin user created',
            'type': 'user_create',
            'timestamp': FieldValue.serverTimestamp(),
          });

          // Sign out after creating the admin
          await _firebaseAuth.signOut();
        }
      } catch (authError) {
        // Admin doesn't exist in Auth either, create a new admin user
        await createUserWithEmailAndPassword(
          email: defaultAdminEmail,
          password: defaultAdminPassword,
          name: 'Admin',
          role: AppConstants.admin,
          // No creatorId for default admin
        );
      }
    } catch (e) {
      // Use a more appropriate logging mechanism in production
      debugPrint('Error creating default admin: $e');
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.admin:
        return 'Admin';
      case AppConstants.lineLead:
        return 'Line Head';
      case AppConstants.lineMember:
        return 'Line Member';
      default:
        return role;
    }
  }
}
