# SkonditBeats Ecosystem

Plataforma de venta de instrumentales musicales (Rap, Trap, Drill) con ecosistema de 3 dispositivos: Smart TV + Wearable + Teléfono.

## Estructura del proyecto
- `wearable_app/` — Wear OS: simula sensores de reproducción y envía datos por BLE NOTIFY (GATT server con `ble_peripheral`)
- `phone_app/` — Flutter: recibe datos BLE del wearable, reproductor de instrumentales y catálogo (Supabase)
- `smart_tv_pwa/` — PWA Smart TV: biblioteca de beats, navegación D-pad y reproductor
- `docs/` — Documentación de seguridad, pruebas y configuración

## Cómo ejecutar

### 1. Emuladores
```bash
flutter emulators --launch Wear_OS_Large_Round   # emulador Wear OS (emulator-5556)
flutter emulators --launch Pixel_6               # emulador teléfono (emulator-5554)
flutter devices                                   # confirmar IDs
```

### 2. wearable_app
```bash
cd wearable_app
flutter pub get
flutter run -d emulator-5554
```
Presiona el botón Play (círculo amarillo) en el reloj → el status debe leer "Transmitiendo BLE".

### 3. phone_app
```bash
cd phone_app
flutter pub get
# Configuración previa: crear smart_tv_pwa/js/config.js (ver sección Credenciales)
# y crear la tabla now_playing en Supabase (docs/now_playing_table.sql)
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_KEY=sb_publishable_TU_KEY \
  --dart-define=USER_ID=tu-user-uuid
```
Escanea automáticamente al abrir. Pestañas: Monitor (datos BLE + alertas), Catálogo, Reproductor (reproduce los instrumentales).

## Credenciales (nunca en el repositorio)
- PWA: `cp js/config.example.js js/config.js` y llenar credenciales reales (`config.js` está en `.gitignore`).
- Phone: las credenciales se inyectan con `--dart-define` (no están en el código); si no se pasan, la app usa datos locales.

### 4. smart_tv_pwa
```bash
cd smart_tv_pwa
python -m http.server 8080
```
Abrir `http://localhost:8080` en Chrome → DevTools → Device Mode → 1920x1080.
Flechas: mover foco · Enter: reproducir · Espacio: play/pausa · N: siguiente · Clic: vista Reproductor.

## Sincronización teléfono → TV (P3.3)
1. Crear la tabla `now_playing` en Supabase (SQL Editor) con `docs/now_playing_table.sql`.
2. Correr el teléfono con `--dart-define` (ver paso 3). Al reproducir un beat, el teléfono publica beat + posición en `now_playing`.
3. En la TV, el botón **Sync: ON** (header) sigue al teléfono: cambia de beat y muestra el mismo temporizador en <2s. Con **Sync: OFF**, la TV es independiente. Si la TV está cerrada, el teléfono reproduce solo.

## Conexión BLE entre emuladores
1. Verifica que ambos emuladores tengan Bluetooth activado (Settings → Bluetooth).
2. En el reloj, presiona Play → debe mostrar "Transmitiendo BLE" (si muestra "Error", el emulador no soporta advertising).
3. En el teléfono, espera "Conectado". Si sale error, usa el botón ↻ del Monitor.
4. Si no se encuentran: abre Settings → Bluetooth en ambos emuladores y emparéjalos manualmente, luego reconecta.

## Demo simultánea
Los 3 dispositivos deben estar activos durante la demo de 5 minutos:
1. Wearable: presionar Play para iniciar generación de datos
2. Teléfono: recibe datos BLE y reproduce instrumentales
3. Smart TV: navegar grid con teclado direccional y reproducir

## Video demo
El video de demostración (`videoDemo/`) no se aloja en este repositorio por su tamaño. Disponible en:
- [Video de la demo](PON_AQUI_EL_ENLACE_DE_DRIVE_OR_YOUTUBE)

## Release
v1.0 - Ecosistema completo: wearable + teléfono + Smart TV
