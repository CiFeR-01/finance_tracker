import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../widgets/app_lock.dart';
import 'audit_log_service.dart';
import 'temp_file_cleaner.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Get user data failed: unable to load profile.');
      }
    }
    return null;
  }

  // Watch user data changes
  Stream<UserModel?> watchUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Register
  Future<UserCredential?> register(String email, String password, String name, TaxProfile taxProfile) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          taxProfile: taxProfile,
        );
        await _db.collection('users').doc(user.uid).set(userModel.toMap());
        AppLockGate.markFreshSignIn();
        AuditLogService.instance.record(AuditEvent.register);
      }
      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Registration failed: ${e.code}');
      }
      rethrow;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Registration failed: unexpected error');
      }
      rethrow;
    }
  }

  // Login
  Future<UserCredential?> login(String email, String password) async {
    try {
      AppLockGate.markFreshSignIn();
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      AuditLogService.instance.record(AuditEvent.loginSuccess);
      return result;
    } on FirebaseAuthException catch (e) {
      AuditLogService.instance.record(AuditEvent.loginFailed, details: {'reason': e.code});
      if (kDebugMode) {
        debugPrint('Login failed: ${e.code}');
      }
      rethrow;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Login failed: unexpected error');
      }
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await AuditLogService.instance.record(AuditEvent.logout);
    // Security: clear exported files and camera photos from the cache so
    // the next person using this device cannot find them.
    await TempFileCleaner.purgeSensitiveCache();
    await _auth.signOut();
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AuditLogService.instance.record(AuditEvent.passwordResetRequested);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Password reset failed: ${e.code}');
      }
      rethrow;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Password reset failed: unexpected error');
      }
      rethrow;
    }
  }

  // Update Profile
  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }
}
