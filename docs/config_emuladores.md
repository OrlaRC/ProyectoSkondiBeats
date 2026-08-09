# Configuración de Emuladores (SA.6.B)

## Emulador de teléfono
- Modelo: Pixel 6
- API Level: 34 (Android 14) — verificado con `flutter devices`
- RAM: 4 GB
- Resolución: 1080x2400

## Emulador Wear OS
- Forma: Round (Wear OS Large Round)
- API Level: 33 (Android 13) — verificado con `flutter devices`
- RAM: 2 GB
- Resolución: 454x454 (round)

## Emulación de Smart TV en Chrome DevTools
- Resolución: 1920x1080 (verificado con layout a escala 1:1)
- User Agent: Mozilla/5.0 (Linux; Tizen 5.0) AppleWebKit/537.36
- Device mode: Landscape, sin scroll (safe zone 5% = 54px v / 96px h)

## Capturas de emuladores
- [ ] Screenshot del emulador Wear OS corriendo (wearable_app en emulator-5556)
- [ ] Screenshot del emulador de teléfono corriendo (phone_app en emulator-5554)
- [ ] Screenshot de la PWA en Chrome DevTools 1920x1080
(Agregar capturas aquí como evidencia.)

## Troubleshooting (problemas reales encontrados y solución)
1. **El emulador Wear OS no arranca / se queda lento**: aumentar la RAM del AVD a 2 GB (se corrigió de 1 GB a 2 GB).
2. **BLE entre dos AVDs no se descubre (advertising no transmitido por la radio virtual)**: se implementó un segundo transporte Bluetooth Classic (SPP/RFCOMM) bridado por netsimd entre los AVDs; el teléfono prioriza SPP en emulador y BLE en hardware real.
3. **Diálogo "Make visible to other Bluetooth devices" al iniciar transmisión**: aceptar "OK" en el reloj; no es fatal si el dispositivo ya está emparejado.
4. **La PWA servía una versión vieja (SW cache)**: al cambiar código, incrementar `CACHE_NAME` en `sw.js` (v10 → v11) para forzar la reinstalación del Service Worker.
5. **Tabla de sincronización inexistente (404)**: ejecutar `docs/now_playing_table.sql` en el SQL Editor de Supabase.
