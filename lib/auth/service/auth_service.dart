import 'package:shared_preferences/shared_preferences.dart';
import 'package:society_management/auth/repository/auth_repository.dart';
import 'package:society_management/users/model/user_model.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  final AuthRepository _authRepository = AuthRepository();

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Save login state
  Future<void> saveLoginState(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, user.email ?? '');
    await prefs.setString(_userRoleKey, user.role ?? '');
    await prefs.setString(_userIdKey, user.id ?? '');
  }

  // Clear login state
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final result = await _authRepository.getCurrentUserData();
      if (result.isSuccess && result.user != null) {
        return result.user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
    await clearLoginState();
  }

  // Login with email and password
  Future<AuthResult> login({required String email, required String password}) async {
    final result = await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.isSuccess && result.user != null) {
      await saveLoginState(result.user!);
    }

    return result;
  }
}
