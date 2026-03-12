import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/swipe_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // On pointe vers l'écran de Swipe (Phase 2 du plan)
      home: const SwipeScreen(),
    );
  }
}