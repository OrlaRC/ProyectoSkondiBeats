# Configuración de Herramientas (SA.6.A)

## Versiones de SDK (verificadas 2026-08)
```bash
flutter --version
# Flutter 3.44.0 • channel stable
# Dart 3.12.0 • DevTools 2.57.0
```

## Android Studio
- Versión: Android Studio Hedgehog | 2023.1.1
- Plugins: Flutter, Dart

## VS Code (Unidad 3)
- Versión: 1.90+
- Extensiones: Flutter, Dart, Live Server, Thunder Client
- ffmpeg versión: 6.0

## Dependencias clave (pubspec.yaml, versiones reales)
- `phone_app`: flutter_blue_plus ^1.32.0, flutter_bluetooth_serial ^0.4.0, permission_handler ^11.3.1, provider ^6.1.2, http ^1.2.1, audioplayers ^6.0.0
- `wearable_app`: ble_peripheral ^2.4.0, permission_handler ^11.3.1, flutter_bluetooth_serial ^0.4.0

## Credenciales (NUNCA en el repositorio)
- PWA: copiar `smart_tv_pwa/js/config.example.js` → `smart_tv_pwa/js/config.js` y llenar credenciales (config.js está en .gitignore).
- Phone: pasar credenciales en tiempo de compilación con `--dart-define` (no están en el código).

## Pasos de instalación reproducibles
1. Clonar repositorio.
2. `flutter pub get` en `phone_app/` y `wearable_app/`.
3. Crear `smart_tv_pwa/js/config.js` (ver Credenciales).
4. Crear la tabla `now_playing` en Supabase (SQL Editor) con el script `docs/now_playing_table.sql` (sync teléfono → TV).
5. Abrir `smart_tv_pwa/` con Live Server o `python -m http.server 8080`.
6. Correr el teléfono con las credenciales:
   ```bash
   cd phone_app
   flutter run -d emulator-5554 \
     --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
     --dart-define=SUPABASE_KEY=sb_publishable_TU_KEY \
     --dart-define=USER_ID=tu-user-uuid
   ```
7. Correr el wearable:
   ```bash
   cd wearable_app
   flutter run -d emulator-5556
   ```
