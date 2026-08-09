class AuthResult {
  final bool ok;
  final String? name;
  final String? error;
  AuthResult({required this.ok, this.name, this.error});
}

/// Login de demo con credenciales fijas (Sara). Los beats comprados se
/// cargan del catálogo (orders → beats por USER_ID) tras el login.
class AuthService {
  static const String _email = 's@gmail.com';
  static const String _password = '707601Orc!';
  static const String _name = 'Sara';

  static AuthResult login(String email, String password) {
    if (email.trim().toLowerCase() == _email && password == _password) {
      return AuthResult(ok: true, name: _name);
    }
    return AuthResult(ok: false, error: 'Credenciales inválidas');
  }
}