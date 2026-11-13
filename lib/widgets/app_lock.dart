import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/audit_log_service.dart';

/// Requires device authentication (fingerprint, face or device PIN) before
/// showing [child], and again whenever the app returns from the background
/// after [timeout]. Protects a signed-in session on a lost, shared or
/// unlocked phone.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 60),
  });

  final Widget child;
  final Duration timeout;

  static bool _freshSignIn = false;

  /// Call after a successful password sign-in so the user is not asked to
  /// authenticate twice in a row.
  static void markFreshSignIn() => _freshSignIn = true;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _authenticating = false;
  bool _deviceSupported = true;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AppLockGate._freshSignIn) {
      AppLockGate._freshSignIn = false;
      _unlocked = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final away = DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (_unlocked && away >= widget.timeout) {
        setState(() => _unlocked = false);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || _unlocked) return;
    _authenticating = true;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // No screen lock is set on the device, so there is nothing to verify against.
        setState(() {
          _deviceSupported = false;
          _unlocked = true;
        });
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Finance Tracker to view your financial records',
        persistAcrossBackgrounding: true,
      );
      AuditLogService.instance.record(ok ? AuditEvent.appUnlocked : AuditEvent.appUnlockFailed);
      if (mounted) setState(() => _unlocked = ok);
    } on LocalAuthException catch (e) {
      AuditLogService.instance.record(AuditEvent.appUnlockFailed, details: {'reason': e.code.name});
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      if (!_deviceSupported) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_deviceSupported) return;
          _deviceSupported = true; // Show the hint once per session.
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content: Text('Set a screen lock on this device to protect the app with fingerprint or PIN.'),
          ));
        });
      }
      return widget.child;
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: scheme.primary),
                const SizedBox(height: 16),
                Text('Finance Tracker is locked', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Use your fingerprint, face or device PIN to continue.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
