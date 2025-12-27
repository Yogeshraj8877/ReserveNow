import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'views/main_navigation.dart';
import 'views/login_view.dart';
import 'views/profile_screen.dart';
import 'views/table_selection_view.dart';
import 'views/date_time_selection_view.dart';
import 'views/booking_confirmation_view.dart';
import 'views/booking_history_view.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase is automatically initialized from google-services.json
  // We need to configure the database URL after initialization
  await Firebase.initializeApp();
  
  // Update database URL
  FirebaseDatabase.instance.databaseURL = 'https://reserve-now-7e6d9-default-rtdb.firebaseio.com/';
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashView(),
      routes: {
        '/login': (context) => const LoginView(),
        '/main': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int initialIndex = 0;
          if (args is int) {
            initialIndex = args;
          }
          return MainNavigation(initialIndex: initialIndex);
        },
        '/profile': (context) => const ProfileScreen(),
        '/table_selection': (context) => const TableSelectionView(),
        '/date_time_selection': (context) => const DateTimeSelectionView(),
        '/booking_confirmation': (context) => const BookingConfirmationView(),
        '/booking_history': (context) => const BookingHistoryView(),
      },
    );
  }
}
