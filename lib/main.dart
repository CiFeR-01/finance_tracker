import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';
import 'views/network_diagnostic_screen.dart';
import 'widgets/app_lock.dart';
import 'services/finance_service.dart';
import 'services/auth_service.dart';
import 'services/temp_file_cleaner.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/tax_view_model.dart';
import 'viewmodels/add_expense_view_model.dart';
import 'viewmodels/add_income_view_model.dart';

/// The entry point of the Finance Tracker application.
/// 
/// This file initializes Firebase, sets up the global services, 
/// and configures the main application widget tree with [MultiProvider] 
/// for state management.

// Global finance service instance that provides access to the backend data.
late FinanceService financeService;

// Light/dark choice from the Profile tab, shared across logins.
final ThemeController themeController = ThemeController();

/// The main function initializes the Flutter framework, Firebase, 
/// and the global finance service before launching the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Security: remove any exported files or camera photos left in the cache
  // from a previous session (e.g. if the app was closed mid-share).
  await TempFileCleaner.purgeSensitiveCache();
  // Instantiate the shared FinanceService.
  financeService = FinanceService();
  await themeController.load();

  runApp(const FinanceTrackerApp());
}

/// The root widget of the Finance Tracker application.
/// 
/// It uses a [StreamBuilder] to listen to authentication state changes 
/// and provides various ViewModels to the widget tree using [MultiProvider].
/// Supports network security diagnostic when launched with --dart-define=SHOW_NETWORK_DIAGNOSTIC=true.
class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  bool _showDiagnostic = const bool.fromEnvironment(
    'SHOW_NETWORK_DIAGNOSTIC',
    defaultValue: false,
  );

  @override
  Widget build(BuildContext context) {
    if (_showDiagnostic) {
      return MaterialApp(
        title: 'FinanceTracker - Diagnostic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: NetworkDiagnosticScreen(
          onProceed: () {
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
            ChangeNotifierProvider.value(value: themeController),
          ],
          child: ListenableBuilder(
            listenable: themeController,
            builder: (context, _) => MaterialApp(
              title: 'FinanceTracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeController.mode, // Set in Profile > Appearance.
              home: _buildHome(snapshot),
            ),
          ),
        );
      },
    );
  }

  /// Determines which screen to show based on the authentication [snapshot].
  /// 
  /// Displays a loading indicator while waiting, the [HomePage] if logged in, 
  /// or the [LoginPage] if not authenticated.
  Widget _buildHome(AsyncSnapshot<User?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (snapshot.hasData) {
      // Re-authenticate with biometrics or device PIN before showing financial data.
      return const AppLockGate(child: HomePage());
    }
    return const LoginPage();
  }
}
