import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Security events recorded in the `audit_logs` collection.
enum AuditEvent {
  loginSuccess('login_success'),
  loginFailed('login_failed'),
  logout('logout'),
  register('register'),
  passwordResetRequested('password_reset_requested'),
  recordDeleted('record_deleted'),
  exportCsv('export_csv'),
  exportReceipts('export_receipts'),
  appUnlocked('app_unlocked'),
  appUnlockFailed('app_unlock_failed');

  const AuditEvent(this.value);
  final String value;
}

/// Writes structured, append-only security audit records to Firestore.
///
/// Entries hold the user id, event name, a small map of non-sensitive
/// details and a server timestamp. Amounts, descriptions, emails and
/// passwords are never logged, so the log itself does not leak personal
/// financial data. Firestore rules allow clients to create entries only;
/// reading, editing and deleting are denied, so logs are reviewed through
/// the Firebase console by project members with an IAM role.
class AuditLogService {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  final CollectionReference<Map<String, dynamic>> _logs =
      FirebaseFirestore.instance.collection('audit_logs');

  /// Records [event]. Never throws, because logging must not break the
  /// action being logged.
  Future<void> record(AuditEvent event, {Map<String, String> details = const {}}) async {
    try {
      await _logs.add({
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'event': event.value,
        'details': details,
        'platform': defaultTargetPlatform.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Offline or denied writes are dropped silently by design.
    }
  }
}
