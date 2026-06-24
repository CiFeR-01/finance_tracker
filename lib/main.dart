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


//test
// Global finance service instance
late FinanceService financeService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  financeService = FinanceService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel(financeService)),
        ChangeNotifierProvider(create: (_) => TaxViewModel(financeService, AuthService())),
        ChangeNotifierProvider(create: (_) => AddExpenseViewModel(financeService)),
        ChangeNotifierProvider(create: (_) => AddIncomeViewModel(financeService)),
      ],
      child: const FinanceTrackerApp(),
    ),
  );
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
