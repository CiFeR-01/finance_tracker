import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data model representing the result of a single network diagnostic test.
class DiagnosticTestResult {
  final String url;
  final bool success;
  final int? statusCode;
  final String? responseMessage;
  final String? error;
  final String? errorClass;
  final bool isCleartextBlocked;
  final bool isDnsOrTimeout;

  DiagnosticTestResult({
    required this.url,
    required this.success,
    this.statusCode,
    this.responseMessage,
    this.error,
    this.errorClass,
    required this.isCleartextBlocked,
    required this.isDnsOrTimeout,
  });

  factory DiagnosticTestResult.fromMap(String url, Map<dynamic, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    final statusCode = map['statusCode'] as int?;
    final responseMessage = map['responseMessage'] as String?;
    final error = map['error'] as String?;
    final errorClass = map['errorClass'] as String?;
    final isCleartextBlocked = map['isCleartextBlocked'] as bool? ?? false;

    bool isDnsOrTimeout = false;
    if (error != null) {
      final lower = error.toLowerCase();
      if (lower.contains('unknownhostexception') ||
          lower.contains('unable to resolve host') ||
          lower.contains('sockettimeoutexception') ||
          lower.contains('timed out') ||
          lower.contains('connectexception') ||
          lower.contains('connection refused') ||
          lower.contains('network is unreachable')) {
        isDnsOrTimeout = true;
      }
    }

    return DiagnosticTestResult(
      url: url,
      success: success,
      statusCode: statusCode,
      responseMessage: responseMessage,
      error: error,
      errorClass: errorClass,
      isCleartextBlocked: isCleartextBlocked,
      isDnsOrTimeout: isDnsOrTimeout,
    );
  }
}

/// Executes a native HttpURLConnection test for the given URL.
Future<DiagnosticTestResult> runSingleNetworkTest(String url) async {
  const channel = MethodChannel('com.example.finance_tracker/network_test');
  try {
    final result = await channel.invokeMethod('testUrl', {'url': url});
    if (result is Map) {
      return DiagnosticTestResult.fromMap(url, Map<dynamic, dynamic>.from(result));
    } else {
      return DiagnosticTestResult(
        url: url,
        success: true,
        responseMessage: result.toString(),
        isCleartextBlocked: false,
        isDnsOrTimeout: false,
      );
    }
  } on PlatformException catch (e) {
    final errMsg = e.message ?? e.toString();
    final lower = errMsg.toLowerCase();
    final isCleartext = lower.contains('cleartext') ||
        lower.contains('not permitted by network security policy');
    final isDnsOrTimeout = lower.contains('unknownhost') ||
        lower.contains('unable to resolve host') ||
        lower.contains('timeout') ||
        lower.contains('refused');

    return DiagnosticTestResult(
      url: url,
      success: false,
      error: errMsg,
      errorClass: e.code,
      isCleartextBlocked: isCleartext,
      isDnsOrTimeout: isDnsOrTimeout,
    );
  } catch (e) {
    final errMsg = e.toString();
    final lower = errMsg.toLowerCase();
    final isCleartext = lower.contains('cleartext') ||
        lower.contains('not permitted by network security policy');
    final isDnsOrTimeout = lower.contains('unknownhost') ||
        lower.contains('unable to resolve host') ||
        lower.contains('timeout') ||
        lower.contains('refused');

    return DiagnosticTestResult(
      url: url,
      success: false,
      error: errMsg,
      errorClass: e.runtimeType.toString(),
      isCleartextBlocked: isCleartext,
      isDnsOrTimeout: isDnsOrTimeout,
    );
  }
}

/// Console test runner retained for backward compatibility.
Future<void> runNetworkDiagnostic() async {
  if (kDebugMode) {
    debugPrint('=== NETWORK COMMUNICATION HARDENING RUNTIME DIAGNOSTIC ===');
    final httpRes = await runSingleNetworkTest('http://example.com');
    debugPrint('[TEST 1 HTTP] Success: ${httpRes.success}, Code: ${httpRes.statusCode}, Error: ${httpRes.error}, CleartextBlocked: ${httpRes.isCleartextBlocked}');
    final httpsRes = await runSingleNetworkTest('https://example.com');
    debugPrint('[TEST 2 HTTPS] Success: ${httpsRes.success}, Code: ${httpsRes.statusCode}, Error: ${httpsRes.error}');
    debugPrint('=== END NETWORK DIAGNOSTIC ===');
  }
}

/// A temporary diagnostic UI screen displaying network hardening evidence for screenshots.
class NetworkDiagnosticScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const NetworkDiagnosticScreen({super.key, this.onContinue});

  @override
  State<NetworkDiagnosticScreen> createState() => _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  bool _isLoading = false;
  DiagnosticTestResult? _httpResult;
  DiagnosticTestResult? _httpsResult;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _httpResult = null;
      _httpsResult = null;
    });

    final httpRes = await runSingleNetworkTest('http://example.com');
    final httpsRes = await runSingleNetworkTest('https://example.com');

    if (mounted) {
      setState(() {
        _httpResult = httpRes;
        _httpsResult = httpsRes;
        _isLoading = false;
      });
    }
  }

  bool get _isHardeningVerified {
    if (_httpResult == null || _httpsResult == null) return false;
    final httpBlockedByPolicy = !_httpResult!.success && _httpResult!.isCleartextBlocked && !_httpResult!.isDnsOrTimeout;
    final httpsSucceeded = _httpsResult!.success && (_httpsResult!.statusCode == 200 || _httpsResult!.statusCode == 301 || _httpsResult!.statusCode == 302);
    return httpBlockedByPolicy && httpsSucceeded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text(
              'Security Diagnostic',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Re-run Tests',
            onPressed: _isLoading ? null : _runTests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purpleAccent),
                  SizedBox(height: 20),
                  Text(
                    'Executing Native Network Diagnostic...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Testing HttpURLConnection on Background Thread',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverallStatusBanner(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('1. Cleartext Protection Test (HTTP)'),
                  const SizedBox(height: 8),
                  _buildHttpResultCard(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('2. Secure Connection Test (HTTPS)'),
                  const SizedBox(height: 8),
                  _buildHttpsResultCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _runTests,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Re-run Diagnostic'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purpleAccent,
                            side: const BorderSide(color: Colors.purpleAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (widget.onContinue != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onContinue,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Proceed to App'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallStatusBanner() {
    final isVerified = _isHardeningVerified;
    final color = isVerified ? Colors.green : Colors.orangeAccent;
    final icon = isVerified ? Icons.verified_user : Icons.warning_amber_rounded;
    final title = isVerified
        ? 'NETWORK HARDENING VERIFIED PASS'
        : 'DIAGNOSTIC VERIFICATION PENDING / INCOMPLETE';
    final description = isVerified
        ? 'Cleartext HTTP traffic is explicitly blocked by Android Network Security Policy. Secure HTTPS communication is functional.'
        : 'Ensure device has active internet connection and HTTP cleartext protection is active.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildHttpResultCard() {
    final res = _httpResult;
    if (res == null) return const SizedBox.shrink();

    final bool isSuccess = res.success;
    final bool isCleartextBlocked = res.isCleartextBlocked;
    final bool isDnsOrTimeout = res.isDnsOrTimeout;

    Color badgeColor;
    String badgeText;

    if (isCleartextBlocked && !isSuccess) {
      badgeColor = Colors.green;
      badgeText = 'PASS: BLOCKED BY OS CLEARTEXT POLICY';
    } else if (isSuccess) {
      badgeColor = Colors.red;
      badgeText = 'FAIL: HTTP CLEARTEXT TRAFFIC PERMITTED';
    } else if (isDnsOrTimeout) {
      badgeColor = Colors.orange;
      badgeText = 'INCONCLUSIVE: NETWORK / TIMEOUT / DNS ERROR';
    } else {
      badgeColor = Colors.orange;
      badgeText = 'FAILED WITH UNKNOWN ERROR';
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('URL', res.url),
            _buildDetailRow('Client Engine', 'Android HttpURLConnection (Background Thread)'),
            _buildDetailRow(
              'HTTP Status Code',
              res.statusCode != null ? '${res.statusCode}' : 'N/A (Blocked before transmission)',
            ),
            if (res.errorClass != null) _buildDetailRow('Exception Class', res.errorClass!),
            if (res.error != null) _buildDetailRow('Error Message', res.error!, isErrorText: true),
            const Divider(color: Colors.white24, height: 24),
            _buildProofCheckRow(
              'Explicit Cleartext Policy Rejection',
              isCleartextBlocked,
              isCleartextBlocked
                  ? 'Confirmed: OS blocked connection before socket creation.'
                  : 'Not detected.',
            ),
            _buildProofCheckRow(
              'DNS / Timeout Rejection Check',
              !isDnsOrTimeout,
              isDnsOrTimeout
                  ? 'INVALID PROOF: Rejection caused by DNS or timeout.'
                  : 'PASS: Rejection is NOT due to DNS or timeout.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHttpsResultCard() {
    final res = _httpsResult;
    if (res == null) return const SizedBox.shrink();

    final bool isSuccess = res.success && (res.statusCode == 200 || res.statusCode == 301 || res.statusCode == 302);
    final Color badgeColor = isSuccess ? Colors.green : Colors.red;
    final String badgeText = isSuccess
        ? 'PASS: HTTPS SUCCESS (${res.statusCode ?? 200} OK)'
        : 'FAIL: HTTPS CONNECTION FAILED';

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('URL', res.url),
            _buildDetailRow('Client Engine', 'Android HttpURLConnection (Background Thread)'),
            _buildDetailRow(
              'Response Code',
              res.statusCode != null
                  ? '${res.statusCode} ${res.responseMessage ?? ''}'
                  : 'N/A',
            ),
            if (res.error != null) _buildDetailRow('Error Message', res.error!, isErrorText: true),
            const Divider(color: Colors.white24, height: 24),
            _buildProofCheckRow(
              'TLS Security Validation',
              isSuccess,
              isSuccess
                  ? 'Confirmed: HTTPS request succeeded using system trust anchors.'
                  : 'Failed to complete TLS HTTPS request.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isErrorText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isErrorText ? Colors.redAccent.shade100 : Colors.white,
                fontSize: 13,
                fontFamily: isErrorText ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofCheckRow(String checkLabel, bool isPassed, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isPassed ? Colors.greenAccent : Colors.orangeAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                children: [
                  TextSpan(
                    text: '$checkLabel: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
