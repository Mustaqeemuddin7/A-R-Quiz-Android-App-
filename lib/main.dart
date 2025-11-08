import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/progress_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Pre-load fonts for web
  if (kIsWeb) {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
    ]);
  }
  
  runApp(const ARQuizApp());
}

class ARQuizApp extends StatelessWidget {
  const ARQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => ProgressService()),
      ],
      child: MaterialApp(
        title: 'A & R Quiz App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFE53935),
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            primary: const Color(0xFFE53935),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFFE53935)),
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE53935),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
