import 'package:intl/date_symbol_data_local.dart';
import 'package:asset_pt_timah/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://xghswlkqdopfgfsleztu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhnaHN3bGtxZG9wZmdmc2xlenR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MzY2MzcsImV4cCI6MjA2NjQxMjYzN30.b3RRbi8V3GYi_gGLwOhoC4_ds5LA7xL8yN0CLw-LIII',
  );

  runApp(
    Phoenix(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4A6572);
    return MaterialApp(
      title: 'Asset PT Timah',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // Asumsikan AuthWrapper menangani login
    );
  }
}