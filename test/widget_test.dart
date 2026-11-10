import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/views/network_diagnostic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NetworkDiagnosticScreen renders correctly', (WidgetTester tester) async {
    const channel = MethodChannel('com.example.finance_tracker/network_diagnostic');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'runNetworkDiagnostic') {
        return {
          'http': {
            'success': false,
            'statusCode': null,
            'errorType': 'CLEARTEXT_BLOCKED',
            'errorMessage': 'Cleartext HTTP traffic to example.com not permitted by network security policy',
            'exceptionClass': 'java.io.IOException',
          },
          'https': {
            'success': true,
            'statusCode': 200,
            'errorType': null,
            'errorMessage': null,
            'exceptionClass': null,
          }
        };
      }
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkDiagnosticScreen(
          onProceed: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Security Diagnostic'), findsOneWidget);
    expect(find.text('Proceed to App'), findsOneWidget);
    expect(find.textContaining('PASS: BLOCKED BY OS CLEARTEXT POLICY'), findsOneWidget);
    expect(find.textContaining('PASS: HTTPS SUCCESS (200 OK)'), findsOneWidget);
  });
}
