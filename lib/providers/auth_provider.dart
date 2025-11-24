import 'dart:math';
import 'package:flutter/material.dart';
import 'package:university_asset_maintenance/services/supabase_service.dart';
import 'package:university_asset_maintenance/core/supabase_client.dart';
import 'package:university_asset_maintenance/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:supabase/supabase.dart' show PostgrestException;

class AuthProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  // Holds pending OTP state
  String? _pendingOtp;
  String? _pendingMode; // 'register' or 'reset'
  User? _pendingUser;
  DateTime? _otpExpiry;
  String? _pendingPassword;

  // Existing login/register/etc...
  Future<String?> login(String email, String password) async {
    try {
      final res = await supabase.auth.signInWithPassword(email: email, password: password);
      final sess = res.session;
      if (sess == null || sess.user.email == null) return 'Invalid credentials';
      final uid = sess.user.id;
      var profile = await SupabaseService.getUserById(uid);
      if (profile == null) {
        final now = DateTime.now().toIso8601String();
        final temp = User(id: uid, name: email.split('@').first, email: email, role: 'teacher', createdAt: now, updatedAt: now);
        await SupabaseService.upsertUserFromAuth(temp);
        profile = temp;
      }
      _user = profile;
    } catch (e) {
      if (e is AuthException) return e.message;
      if (e is PostgrestException) return e.message ?? 'Login failed';
      return 'Login failed';
    }
    notifyListeners();
    return null;
  }

  Future<String?> register(User user, String password) async {
    try {
      await supabase.auth.signOut();
      final existing = await SupabaseService.getUserByEmail(user.email);
      if (existing != null) return 'Email already registered';
      final res = await supabase.auth.signUp(email: user.email, password: password);
      if (res.user == null) return 'Sign up failed';
      final now = DateTime.now().toIso8601String();
      user.id = res.user!.id;
      user.createdAt = now;
      user.updatedAt = now;
      await SupabaseService.upsertUserFromAuth(user);
    } catch (e) {
      if (e is AuthException) return e.message;
      if (e is PostgrestException) return e.message ?? 'Sign up failed';
      return 'Sign up failed';
    }
    return null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    if (_user == null) return 'No user logged in';
    _user!.updatedAt = DateTime.now().toIso8601String();
    notifyListeners();
    return null;
  }

  Future<String?> updateProfile(User updatedUser) async {
    if (_user == null) return 'No user logged in';
    updatedUser.id = _user!.id;
    updatedUser.createdAt = _user!.createdAt;
    updatedUser.updatedAt = DateTime.now().toIso8601String();
    await SupabaseService.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
    return null;
  }

  /// STEP 1: Generate a 6-digit OTP, store it in‐memory with a 5-minute expiry.
  /// Returns the OTP so the UI can display it (e.g. via SnackBar).
  Future<String> generateOtp({
    required String mode,
    User? tempUser,
    String? password,
    String? email,
  }) async {
    final otp = (Random().nextInt(900000) + 100000).toString();
    _pendingOtp    = otp;
    _pendingMode   = mode;
    _pendingUser   = tempUser;
    _pendingPassword = password;
    _otpExpiry     = DateTime.now().add(const Duration(minutes: 5));
    debugPrint('🕵️‍♂️ Generated OTP: $otp'); // for debugging
    return otp;
  }

  /// STEP 2: Verify the OTP the user entered.
  /// If it matches and hasn’t expired, perform the appropriate action:
  ///  - For 'register', complete registration
  ///  - For 'reset', leave it to the UI to navigate to the reset screen
  Future<String?> verifyOtp(String input) async {
    if (_pendingOtp == null || _pendingMode == null) {
      return 'No OTP requested';
    }
    if (DateTime.now().isAfter(_otpExpiry!)) {
      return 'OTP expired';
    }
    if (input.trim() != _pendingOtp) {
      return 'Invalid OTP';
    }

    // OTP is valid—if this was for registration, actually register:
    if (_pendingMode == 'register' && _pendingUser != null) {
      final err = await register(_pendingUser!, _pendingPassword ?? '');
      if (err != null) return err;
    }
    // For 'reset', the UI will take over and show ResetPasswordScreen

    // Clear OTP state:
    _pendingOtp    = null;
    _pendingMode   = null;
    _pendingUser   = null;
    _pendingPassword = null;
    _otpExpiry     = null;

    return null; // success
  }
}
