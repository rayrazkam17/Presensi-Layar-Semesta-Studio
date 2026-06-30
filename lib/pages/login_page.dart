import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();

  bool loading = false;

  Future<void> login() async {
  try {
    setState(() {
      loading = true;
    });

    await authService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final role = await authService.getUserRole();

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardAdminPage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardUserPage(),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  } finally {
    setState(() {
      loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 350,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "LOGIN ABSENSI",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text("LOGIN"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}