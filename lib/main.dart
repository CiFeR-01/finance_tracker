import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';
import 'services/finance_service.dart';
import 'services/auth_service.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/tax_view_model.dart';
import 'viewmodels/add_expense_view_model.dart';
import 'viewmodels/add_income_view_model.dart';
import 'network_diagnostic.dart';

/// Compile-time Flutter environment flag to enable/disable network diagnostic on launch.
const bool kShowNetworkDiagnostic = bool.fromEnvironment('SHOW_NETWORK_DIAGNOSTIC', defaultValue: false);

/// Global finance service instance that provides access to the backend data.
late FinanceService financeService;

/// The main function initializes the Flutter framework, Firebase, 
/// and the global finance service before launching the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Instantiate the shared FinanceService.
  financeService = FinanceService();

  runApp(const FinanceTrackerApp());
}

/// The root widget of the Finance Tracker application.
class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  // Flag initialized from compile-time environment flag (default: false).
  bool _showDiagnostic = kShowNetworkDiagnostic;

  @override
  Widget build(BuildContext context) {
    if (_showDiagnostic) {
      return MaterialApp(
        title: 'Network Diagnostic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: NetworkDiagnosticScreen(
          onContinue: () {
            setState(() {
              _showDiagnostic = false;
            });
          },
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        // Unique key based on user ID to force provider recreation on logout/login.
        final uid = snapshot.data?.uid;

        return MultiProvider(
          key: ValueKey(uid),
          providers: [
            ChangeNotifierProvider(create: (_) => HomeViewModel(financeService)),
            ChangeNotifierProvider(create: (_) => TaxViewModel(financeService, AuthService())),
            ChangeNotifierProvider(create: (_) => AddExpenseViewModel(financeService)),
            ChangeNotifierProvider(create: (_) => AddIncomeViewModel(financeService)),
          ],
          child: MaterialApp(
            title: 'FinanceTracker',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
              useMaterial3: true,
              fontFamily: 'Roboto', // Modern, readable font choice.
            ),
            home: _buildHome(snapshot),
          ),
        );
      },
    );
  }

  /// Determines which screen to show based on the authentication [snapshot].
  Widget _buildHome(AsyncSnapshot<User?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (snapshot.hasData) {
      return const HomePage();
    }
    return const LoginPage();
  }
}
