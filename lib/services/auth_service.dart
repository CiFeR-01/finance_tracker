import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
        } catch (e) {
          print('Error reloading user status on auth change: $e');
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
    } catch (e) {
      print('Error getting user data: $e');
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

  // Register user
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

        try {
          await user.sendEmailVerification();
        } catch (e) {
          print('Error sending verification email during registration: $e');
        }
      }
      return result;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Standard Email/Password Login
  Future<UserCredential> login(String email, String password) async {
    try {
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
      notifyListeners();
      return credential;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  // Update Profile
  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }
}
