import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

Future<String?> getUserRole() async {
  final user = supabase.auth.currentUser;

  print('========== DEBUG ==========');
  print('Current User ID: ${user?.id}');

  final result = await supabase
      .from('profiles')
      .select()
      .eq('id', user!.id);

  print('Profile Result: $result');
  print('===========================');

  if (result.isEmpty) {
    return null;
  }

  return result.first['role'];
}
}