import 'dart:math';
import 'package:flutter/material.dart';
import 'package:university_asset_maintenance/helpers/db_helper.dart';
import 'package:university_asset_maintenance/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  // Holds pending OTP state
  String? _pendingOtp;
  String? _pendingMode; // 'register' or 'reset'
  User? _pendingUser;
  String? _pendingEmail;
  DateTime? _otpExpiry;

  // Existing login/register/etc...
  Future<String?> login(String email, String password) async {
    User? u = await DBHelper.getUserByEmail(email);
    if (u == null) return 'User not found';
    if (u.password != password) return 'Incorrect password';
    _user = u;
    notifyListeners();
    return null;
  }

  Future<String?> register(User user) async {
    User? existing = await DBHelper.getUserByEmail(user.email);
    if (existing != null) return 'Email already registered';
    await DBHelper.insertUser(user);
    return null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    if (_user == null) return 'No user logged in';
    if (_user!.password != oldPass) return 'Old password is incorrect';
    _user!.password = newPass;
    await DBHelper.updateUser(_user!);
    notifyListeners();
    return null;
  }

  Future<String?> updateProfile(User updatedUser) async {
    if (_user == null) return 'No user logged in';
    updatedUser.id = _user!.id;
    await DBHelper.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
    return null;
  }

  /// STEP 1: Generate a 6-digit OTP, store it in‐memory with a 5-minute expiry.
  /// Returns the OTP so the UI can display it (e.g. via SnackBar).
  Future<String> generateOtp({
    required String mode,           // 'register' or 'reset'
    User? tempUser,                // for mode='register'
    String? email,                 // for mode='reset'
  }) async {
    final otp = (Random().nextInt(900000) + 100000).toString();
    _pendingOtp    = otp;
    _pendingMode   = mode;
    _pendingUser   = tempUser;
    _pendingEmail  = email;
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
      final err = await register(_pendingUser!);
      if (err != null) return err;
    }
    // For 'reset', the UI will take over and show ResetPasswordScreen

    // Clear OTP state:
    _pendingOtp    = null;
    _pendingMode   = null;
    _pendingUser   = null;
    _pendingEmail  = null;
    _otpExpiry     = null;

    return null; // success
  }
}
