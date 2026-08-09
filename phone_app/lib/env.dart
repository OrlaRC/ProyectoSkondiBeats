/// Credenciales inyectadas en tiempo de compilación con --dart-define.
/// No se versionan en el código; si faltan, la app usa datos locales.
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
  static const String userId = String.fromEnvironment('USER_ID', defaultValue: '');
  static bool get configured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
