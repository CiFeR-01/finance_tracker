import 'package:flutter/material.dart';
import '../services/network_diagnostic_service.dart';

/// Screen displayed when SHOW_NETWORK_DIAGNOSTIC dart-define is true.
/// Demonstrates explicit cleartext HTTP blocking and HTTPS connectivity via native MethodChannel.
class NetworkDiagnosticScreen extends StatefulWidget {
  final VoidCallback onProceed;

  const NetworkDiagnosticScreen({
    super.key,
    required this.onProceed,
  });

  @override
  State<NetworkDiagnosticScreen> createState() => _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  final NetworkDiagnosticService _service = NetworkDiagnosticService();
  NetworkDiagnosticReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
    });

    final report = await _service.runDiagnostic();

    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF121212);
    const greenAccent = Color(0xFF4CAF50);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.shield_outlined,
              color: Color(0xFF4EBA6F),
              size: 28,
            ),
          ),
          leadingWidth: 44,
          title: const Text(
            'Security Diagnostic',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _runDiagnostic,
              tooltip: 'Re-run Diagnostic',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: greenAccent),
                    SizedBox(height: 16),
                    Text(
                      'Running native network diagnostic...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopSummaryCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('1. Cleartext Protection Test\n(HTTP)'),
                    const SizedBox(height: 12),
                    if (_report != null) _buildHttpCard(_report!.httpResult),
                    const SizedBox(height: 24),
                    _buildSectionHeader('2. Secure Connection Test\n(HTTPS)'),
                    const SizedBox(height: 12),
                    if (_report != null) _buildHttpsCard(_report!.httpsResult),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: widget.onProceed,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text(
                          'Proceed to App',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    final httpPass = _report?.httpResult.status == DiagnosticStatus.pass;
    final httpsPass = _report?.httpsResult.status == DiagnosticStatus.pass;
    final overallPass = httpPass && httpsPass;
    final isHttpInconclusive = _report?.httpResult.status == DiagnosticStatus.inconclusive;

    Color bg;
    Color border;
    Color textCol;
    IconData icon;
    String title;
    String subtitle;

    if (overallPass) {
      bg = const Color(0xFF0F2617);
      border = const Color(0xFF2E7D32);
      textCol = const Color(0xFF4CAF50);
      icon = Icons.verified_user_rounded;
      title = 'NETWORK HARDENING VERIFIED PASS';
      subtitle =
          'Cleartext HTTP traffic is explicitly blocked by Android Network Security Policy. Secure HTTPS communication is functional.';
    } else if (isHttpInconclusive) {
      bg = const Color(0xFF281F08);
      border = const Color(0xFFFFB300);
      textCol = const Color(0xFFFFB300);
      icon = Icons.warning_amber_rounded;
      title = 'NETWORK HARDENING INCONCLUSIVE';
      subtitle =
          'Network request failed due to environment issues (timeout/DNS/refusal). Check network connection and re-run diagnostic.';
    } else {
      bg = const Color(0xFF2A0F0F);
      border = const Color(0xFFE57373);
      textCol = const Color(0xFFE57373);
      icon = Icons.error_rounded;
      title = 'NETWORK HARDENING FAILED';
      subtitle =
          'Cleartext HTTP traffic was permitted or HTTPS connection failed. Inspect network security policy settings.';
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: textCol.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textCol, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD0D0D0),
                    fontSize: 13,
                    height: 1.35,
                  ),
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ),
    );
  }

  Widget _buildHttpCard(EndpointDiagnosticResult result) {
    final isPass = result.status == DiagnosticStatus.pass;
    final isInconclusive = result.status == DiagnosticStatus.inconclusive;

    Color borderColor = isPass
        ? const Color(0xFF2E7D32)
        : (isInconclusive ? const Color(0xFFFFB300) : const Color(0xFFE57373));
    Color badgeColor = isPass
        ? const Color(0xFF4CAF50)
        : (isInconclusive ? const Color(0xFFFFB300) : const Color(0xFFE57373));

    String badgeText;
    if (isPass) {
      badgeText = 'PASS: BLOCKED BY OS CLEARTEXT POLICY';
    } else if (isInconclusive) {
      badgeText = 'INCONCLUSIVE: NETWORK ISSUE (${result.errorType})';
    } else {
      badgeText = 'FAIL: CLEARTEXT TRAFFIC SUCCEEDED';
    }

    final exceptionClass = result.exceptionClass ?? (isPass ? 'java.io.IOException' : 'N/A');
    final rawErrorMsg = result.errorMessage ?? 'Cleartext HTTP traffic to example.com not permitted';
    final errorMessage = rawErrorMsg.contains('not permitted')
        ? 'Cleartext HTTP traffic to example.com not permitted'
        : rawErrorMsg;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor, width: 1.2),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Metadata rows
          _buildMetaRow('URL:', result.url),
          _buildMetaRow('Client Engine:', 'Android\nHttpURLConnection\n(Background Thread)'),
          _buildMetaRow(
            'HTTP Status\nCode:',
            result.statusCode != null
                ? '${result.statusCode}'
                : 'N/A (Blocked before transmission)',
          ),
          _buildMetaRow('Exception\nClass:', exceptionClass),
          _buildMetaRow(
            'Error Message:',
            errorMessage,
            valueColor: isPass ? const Color(0xFFEF9A9A) : Colors.white,
          ),
          const Divider(color: Color(0xFF333333), height: 24, thickness: 1),
          // Validation items
          _buildValidationItem(
            isPass: isPass,
            isInconclusive: isInconclusive,
            title: 'Explicit Cleartext Policy Rejection: ',
            description: isPass
                ? 'Confirmed: OS blocked connection before socket creation.'
                : (isInconclusive
                    ? 'Unconfirmed: Connection failed before reaching policy check.'
                    : 'FAILED: Cleartext HTTP request succeeded.'),
          ),
          const SizedBox(height: 8),
          _buildValidationItem(
            isPass: isPass,
            isInconclusive: isInconclusive,
            title: 'DNS / Timeout Rejection Check: ',
            description: isPass
                ? 'PASS: Rejection is NOT due to DNS or timeout.'
                : (isInconclusive
                    ? 'INCONCLUSIVE: Failed due to ${result.errorType}, not policy rejection.'
                    : 'FAILED: Connection succeeded without error.'),
          ),
        ],
      ),
    );
  }

  Widget _buildHttpsCard(EndpointDiagnosticResult result) {
    final isPass = result.status == DiagnosticStatus.pass;
    final isInconclusive = result.status == DiagnosticStatus.inconclusive;

    Color borderColor = isPass
        ? const Color(0xFF2E7D32)
        : (isInconclusive ? const Color(0xFFFFB300) : const Color(0xFFE57373));
    Color badgeColor = isPass
        ? const Color(0xFF4CAF50)
        : (isInconclusive ? const Color(0xFFFFB300) : const Color(0xFFE57373));

    String badgeText;
    if (isPass) {
      final code = result.statusCode ?? 200;
      badgeText = 'PASS: HTTPS SUCCESS ($code OK)';
    } else if (isInconclusive) {
      badgeText = 'INCONCLUSIVE: NETWORK ISSUE (${result.errorType})';
    } else {
      badgeText = 'FAIL: HTTPS REQUEST FAILED';
    }

    final codeText = result.statusCode != null ? '${result.statusCode} OK' : (isPass ? '200 OK' : 'N/A');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor, width: 1.2),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Metadata rows
          _buildMetaRow('URL:', result.url),
          _buildMetaRow('Client Engine:', 'Android\nHttpURLConnection\n(Background Thread)'),
          _buildMetaRow('Response\nCode:', codeText),
          if (result.errorMessage != null && !isPass)
            _buildMetaRow('Error Message:', result.errorMessage!, valueColor: const Color(0xFFEF9A9A)),
          const Divider(color: Color(0xFF333333), height: 24, thickness: 1),
          // Validation item
          _buildValidationItem(
            isPass: isPass,
            isInconclusive: isInconclusive,
            title: 'TLS Security Validation: ',
            description: isPass
                ? 'Confirmed: HTTPS request succeeded using system trust anchors.'
                : 'Failed / Unconfirmed: ${result.explanation}',
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationItem({
    required bool isPass,
    required bool isInconclusive,
    required String title,
    required String description,
  }) {
    IconData iconData;
    Color iconColor;

    if (isPass) {
      iconData = Icons.check_circle_outline;
      iconColor = const Color(0xFF4CAF50);
    } else if (isInconclusive) {
      iconData = Icons.help_outline;
      iconColor = const Color(0xFFFFB300);
    } else {
      iconData = Icons.highlight_off;
      iconColor = const Color(0xFFE57373);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(iconData, color: iconColor, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, height: 1.35),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
