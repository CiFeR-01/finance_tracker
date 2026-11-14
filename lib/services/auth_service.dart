import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../widgets/app_lock.dart';
import 'audit_log_service.dart';
import 'temp_file_cleaner.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _auth.userChanges().listen((user) async {
      if (user != null && !user.emailVerified) {
        try {
          await user.reload();
          final updatedUser = _auth.currentUser;
          if (updatedUser != null && updatedUser.emailVerified) {
            notifyListeners();
          }
        } catch (_) {
          if (kDebugMode) {
            debugPrint('Reload user failed: unable to refresh verification status.');
          }
        }
      }
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get userStream => _auth.userChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Send initial or resend email verification link to currently signed in user
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    }
  }

  // Reload user and refresh ID token to check one-time email verification status
  Future<User?> checkVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      await user.getIdToken(true);
      user = _auth.currentUser;
      notifyListeners();
      return user;
    }
    return null;
  }

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
        // Write initial profile document before verification
        await _db.collection('users').doc(user.uid).set(userModel.toMap());
        AppLockGate.markFreshSignIn();
        AuditLogService.instance.record(AuditEvent.register);

        try {
          await user.sendEmailVerification();
        } catch (_) {
          if (kDebugMode) {
            debugPrint('Verification email failed to send during registration.');
          }
        }
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

  // Standard Email/Password Login
  Future<UserCredential> login(String email, String password) async {
    try {
      AppLockGate.markFreshSignIn();
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = credential.user;

      if (user != null) {
        // Force reload user profile from server to get fresh emailVerified status
        await user.reload();
        await user.getIdToken(true);
        user = _auth.currentUser;

        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification();
          } catch (_) {}
        }
      }
      AuditLogService.instance.record(AuditEvent.loginSuccess);
      notifyListeners();
      return credential;
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
    notifyListeners();
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
