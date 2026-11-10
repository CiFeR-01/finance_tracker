import 'package:flutter/services.dart';

enum DiagnosticStatus {
  pass,
  fail,
  inconclusive,
}

class EndpointDiagnosticResult {
  final String url;
  final bool success;
  final int? statusCode;
  final String? errorType;
  final String? errorMessage;
  final String? exceptionClass;
  final DiagnosticStatus status;
  final String explanation;

  EndpointDiagnosticResult({
    required this.url,
    required this.success,
    this.statusCode,
    this.errorType,
    this.errorMessage,
    this.exceptionClass,
    required this.status,
    required this.explanation,
  });

  factory EndpointDiagnosticResult.fromMap(String url, Map<dynamic, dynamic> map, bool isHttp) {
    final success = map['success'] as bool? ?? false;
    final statusCode = map['statusCode'] as int?;
    final errorType = map['errorType'] as String?;
    final errorMessage = map['errorMessage'] as String?;
    final exceptionClass = map['exceptionClass'] as String?;

    DiagnosticStatus status;
    String explanation;

    if (isHttp) {
      // For HTTP (http://example.com)
      if (errorType == 'CLEARTEXT_BLOCKED') {
        status = DiagnosticStatus.pass;
        explanation = 'Cleartext HTTP traffic was explicitly blocked by Android Network Security Policy (usesCleartextTraffic="false"), as expected.';
      } else if (success) {
        status = DiagnosticStatus.fail;
        explanation = 'Security Policy Violation! Cleartext HTTP traffic succeeded with status code $statusCode. Cleartext should be blocked.';
      } else if (errorType == 'TIMEOUT' || errorType == 'DNS_FAILURE' || errorType == 'CONNECTION_REFUSED') {
        status = DiagnosticStatus.inconclusive;
        explanation = 'Inconclusive: Connection failed due to network environment issues ($errorType). Timeouts, DNS failures, and connection refusals cannot be taken as a security pass.';
      } else {
        status = DiagnosticStatus.inconclusive;
        explanation = 'Inconclusive: HTTP request failed with error: ${errorMessage ?? "Unknown error"}.';
      }
    } else {
      // For HTTPS (https://example.com)
      if (success) {
        status = DiagnosticStatus.pass;
        explanation = 'Encrypted HTTPS connection established successfully (Status Code: $statusCode).';
      } else if (errorType == 'TIMEOUT' || errorType == 'DNS_FAILURE' || errorType == 'CONNECTION_REFUSED') {
        status = DiagnosticStatus.inconclusive;
        explanation = 'Inconclusive: HTTPS request failed due to network availability ($errorType).';
      } else {
        status = DiagnosticStatus.fail;
        explanation = 'HTTPS request failed: ${errorMessage ?? "Unknown error"}.';
      }
    }

    return EndpointDiagnosticResult(
      url: url,
      success: success,
      statusCode: statusCode,
      errorType: errorType,
      errorMessage: errorMessage,
      exceptionClass: exceptionClass,
      status: status,
      explanation: explanation,
    );
  }
}

class NetworkDiagnosticReport {
  final EndpointDiagnosticResult httpResult;
  final EndpointDiagnosticResult httpsResult;

  NetworkDiagnosticReport({
    required this.httpResult,
    required this.httpsResult,
  });
}

class NetworkDiagnosticService {
  static const MethodChannel _channel = MethodChannel('com.example.finance_tracker/network_diagnostic');

  Future<NetworkDiagnosticReport> runDiagnostic() async {
    try {
      final Map<dynamic, dynamic> res = await _channel.invokeMethod('runNetworkDiagnostic');
      final httpMap = Map<dynamic, dynamic>.from(res['http'] as Map? ?? {});
      final httpsMap = Map<dynamic, dynamic>.from(res['https'] as Map? ?? {});

      final httpResult = EndpointDiagnosticResult.fromMap('http://example.com', httpMap, true);
      final httpsResult = EndpointDiagnosticResult.fromMap('https://example.com', httpsMap, false);

      return NetworkDiagnosticReport(
        httpResult: httpResult,
        httpsResult: httpsResult,
      );
    } on PlatformException catch (e) {
      return NetworkDiagnosticReport(
        httpResult: EndpointDiagnosticResult(
          url: 'http://example.com',
          success: false,
          errorType: 'PLATFORM_ERROR',
          errorMessage: e.message,
          status: DiagnosticStatus.inconclusive,
          explanation: 'MethodChannel platform error: ${e.message}',
        ),
        httpsResult: EndpointDiagnosticResult(
          url: 'https://example.com',
          success: false,
          errorType: 'PLATFORM_ERROR',
          errorMessage: e.message,
          status: DiagnosticStatus.inconclusive,
          explanation: 'MethodChannel platform error: ${e.message}',
        ),
      );
    } catch (e) {
      return NetworkDiagnosticReport(
        httpResult: EndpointDiagnosticResult(
          url: 'http://example.com',
          success: false,
          errorType: 'UNKNOWN_ERROR',
          errorMessage: e.toString(),
          status: DiagnosticStatus.inconclusive,
          explanation: 'Unexpected error running diagnostic: $e',
        ),
        httpsResult: EndpointDiagnosticResult(
          url: 'https://example.com',
          success: false,
          errorType: 'UNKNOWN_ERROR',
          errorMessage: e.toString(),
          status: DiagnosticStatus.inconclusive,
          explanation: 'Unexpected error running diagnostic: $e',
        ),
      );
    }
  }
}
