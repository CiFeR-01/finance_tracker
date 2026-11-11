import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/services/network_diagnostic_service.dart';

void main() {
  group('NetworkDiagnosticResult parsing', () {
    test('HTTP cleartext blocked should return PASS', () {
      final map = {
        'success': false,
        'statusCode': null,
        'errorType': 'CLEARTEXT_BLOCKED',
        'errorMessage': 'Cleartext HTTP traffic to example.com not permitted by network security policy',
        'exceptionClass': 'java.io.IOException',
      };

      final result = EndpointDiagnosticResult.fromMap('http://example.com', map, true);

      expect(result.status, DiagnosticStatus.pass);
      expect(result.errorType, 'CLEARTEXT_BLOCKED');
      expect(result.explanation, contains('blocked by Android Network Security Policy'));
    });

    test('HTTP cleartext permitted should return FAIL', () {
      final map = {
        'success': true,
        'statusCode': 200,
        'errorType': null,
        'errorMessage': null,
        'exceptionClass': null,
      };

      final result = EndpointDiagnosticResult.fromMap('http://example.com', map, true);

      expect(result.status, DiagnosticStatus.fail);
      expect(result.statusCode, 200);
      expect(result.explanation, contains('Security Policy Violation'));
    });

    test('HTTP timeout should return INCONCLUSIVE', () {
      final map = {
        'success': false,
        'statusCode': null,
        'errorType': 'TIMEOUT',
        'errorMessage': 'Read timed out',
        'exceptionClass': 'java.net.SocketTimeoutException',
      };

      final result = EndpointDiagnosticResult.fromMap('http://example.com', map, true);

      expect(result.status, DiagnosticStatus.inconclusive);
      expect(result.errorType, 'TIMEOUT');
      expect(result.explanation, contains('Inconclusive'));
    });

    test('HTTPS success should return PASS', () {
      final map = {
        'success': true,
        'statusCode': 200,
        'errorType': null,
        'errorMessage': null,
        'exceptionClass': null,
      };

      final result = EndpointDiagnosticResult.fromMap('https://example.com', map, false);

      expect(result.status, DiagnosticStatus.pass);
      expect(result.statusCode, 200);
    });
  });
}
