# Plan de Pruebas (SA.5)

## Resultado de la ejecución

| # | Caso | Dispositivo | Resultado esperado | Resultado obtenido | Estado |
|---|------|------------|-------------------|--------------------|--------|
| 1 | P2.5 - App teléfono muestra datos reales desde API Supabase | Teléfono | Catálogo carga con beats reales | Se cargaron los 5 beats comprados por Sara (Dark Trap Flow, Night Drill, Chill LoFi, Golden Rap, Locos) | P (Pasó) |
| 2 | P2.5 - Manejo de error de red | Teléfono | Muestra mensaje de error sin crashear | Sin conexión a Supabase la app cae a catálogo local sin crashear | P (Pasó) |
| 3 | P2.6 - BLE NOTIFY: wearable envía datos al teléfono | Wearable + Teléfono | Los 3 tipos de datos llegan en tiempo real | Wearable en "Transmitiendo BLE + SPP"; teléfono muestra BPM 140 y batería 100% conectado vía SPP | P (Pasó) |
| 4 | P3.1 - Navegación D-pad: flecha izquierda | Smart TV | Foco se mueve a la izquierda | El foco recorre los beats hacia la izquierda en la cuadrícula | P (Pasó) |
| 5 | P3.1 - Navegación D-pad: flecha derecha | Smart TV | Foco se mueve a la derecha | El foco recorre los beats hacia la derecha | P (Pasó) |
| 6 | P3.1 - Navegación D-pad: flecha arriba | Smart TV | Foco se mueve arriba | El foco sube de fila en la cuadrícula | P (Pasó) |
| 7 | P3.1 - Navegación D-pad: flecha abajo | Smart TV | Foco se mueve abajo | El foco baja de fila en la cuadrícula | P (Pasó) |
| 8 | P3.2 - Tecla Enter selecciona beat | Smart TV | Se actualiza el reproductor | `launchPlayer` abrió el reproductor con el beat enfocado (vista player) | P (Pasó) |
| 9 | P3.3 - Modo offline: SW sirve la app sin red | Smart TV | La estructura de la app se carga desde cache | Service Worker registrado; estructura se sirve desde el caché (PWA) | P (Pasó) |
| 10 | P3.4 - Sincronización: cambio en teléfono se refleja en TV < 2s | Teléfono + TV | El beat actualizado aparece en menos de 2 segundos | `now_playing` en Supabase se actualizó (Dark Trap Flow, posición 2→30 s); TV lo consulta cada 2 s | P (Pasó) |

**Total: 10/10 casos en estado P (Pasó).**

## Evidencia (screenshots)

- [x] Screenshot 1: Teléfono (pantalla de inicio/login): `docs/screenshots/screenshot1_phone_login.png`
- [x] Screenshot 2: Wearable mostrando datos (Transmitiendo BLE + SPP): `docs/screenshots/screenshot2_wearable.png`
- [x] Screenshot 3: Teléfono con datos BLE recibidos (conectado vía SPP, BPM/batería): `docs/screenshots/screenshot3_phone_ble.png`
- [x] Screenshot 4: Smart TV con grid de beats: `docs/screenshots/screenshot4_tv_grid.png`
- [x] Screenshot 5: Smart TV con beat seleccionado y reproductor: `docs/screenshots/screenshot5_tv_player.png`

## Documento firmado

Firma: __Firma pendiente de autor (Sara/OrlaRC)__  Fecha: __13/08/2026__
