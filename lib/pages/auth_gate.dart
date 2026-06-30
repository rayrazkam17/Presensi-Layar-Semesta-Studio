import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  Future<Widget> checkSession() async {

    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    if (profile['role'] == 'admin') {
      return const DashboardAdminPage();
    }

    return const DashboardUserPage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkSession(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data!;
      },
    );
  }
}