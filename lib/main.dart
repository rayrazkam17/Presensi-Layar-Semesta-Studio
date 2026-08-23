import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(
    'id_ID',
    null,
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey:
        SupabaseConfig.publishableKey,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,

      title:
          'Presensi Layar Semesta',

      theme:
          ThemeData(
        useMaterial3:
            true,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              Colors.blue,
        ),
      ),

      home:
          const AuthGate(),
    );
  }
}