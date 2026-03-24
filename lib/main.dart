import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/login_page.dart';
import 'screens/swipe_screen.dart';

void main() async {
  // 1. On s'assure que les widgets sont bien liés avant d'init Supabase
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('fr_FR');
  // 2. Initialisation de Supabase
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const TechFlowApp());
}
 
class TechFlowApp extends StatelessWidget {
  const TechFlowApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Couleurs cohérentes avec le design
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          background: const Color(0xFFF5F5F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        // Typographie Nunito (ajoute la police dans pubspec.yaml)
        fontFamily: 'Nunito',
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
 
/// AuthGate vérifie l'état d'authentification au démarrage
/// et redirige vers la bonne page.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
 
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
 
    // Si une session existe déjà -> SwipeScreen directement
    if (supabase.auth.currentUser != null) {
      return const SwipeScreen();
    }
 
    // Sinon on écoute les changements d'état d'auth en temps réel
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
 
        final session = snapshot.data?.session;
 
        if (session != null) {
          return const SwipeScreen();
        }
 
        return const LoginPage();
      },
    );
  }
}
 
/// Écran de démarrage minimal pendant l'initialisation
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
 
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 48,
              color: Color(0xFF6C63FF),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
/* ─────────────────────────────────────────────────────────────
   CONFIGURATION REQUISE dans pubspec.yaml :
 
   dependencies:
     flutter:
       sdk: flutter
     supabase_flutter: ^2.0.0
 
   flutter:
     fonts:
       - family: Nunito
         fonts:
           - asset: assets/fonts/Nunito-Regular.ttf
           - asset: assets/fonts/Nunito-Medium.ttf
             weight: 500
           - asset: assets/fonts/Nunito-SemiBold.ttf
             weight: 600
           - asset: assets/fonts/Nunito-Bold.ttf
             weight: 700
           - asset: assets/fonts/Nunito-ExtraBold.ttf
             weight: 800
           - asset: assets/fonts/Nunito-Black.ttf
             weight: 900
 
   Télécharge Nunito sur : https://fonts.google.com/specimen/Nunito
──────────────────────────────────────────────────────────────── */