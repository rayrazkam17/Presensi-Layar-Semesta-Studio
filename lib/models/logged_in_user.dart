class LoggedInUser {
  final String id;
  final String email;
  final String nama;
  final String role;

  const LoggedInUser({
    required this.id,
    required this.email,
    required this.nama,
    required this.role,
  });

  bool get isAdmin {
    return role.toLowerCase() == 'admin';
  }

  bool get isUser {
    return role.toLowerCase() == 'user';
  }

  @override
  String toString() {
    return 'LoggedInUser('
        'id: $id, '
        'email: $email, '
        'nama: $nama, '
        'role: $role'
        ')';
  }
}