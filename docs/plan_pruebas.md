# Plan de Pruebas (SA.5)

## Casos de prueba (mínimo 10)

| # | Caso | Dispositivo | Resultado esperado |
|---|------|------------|-------------------|
| 1 | P2.5 - App teléfono muestra datos reales desde API Supabase | Teléfono | Catálogo carga con beats reales |
| 2 | P2.5 - Manejo de error de red | Teléfono | Muestra mensaje de error sin crashear |
| 3 | P2.6 - BLE NOTIFY: wearable envía datos al teléfono | Wearable + Teléfono | Los 3 tipos de datos llegan en tiempo real |
| 4 | P3.1 - Navegación D-pad: flecha izquierda | Smart TV | Foco se mueve a la izquierda |
| 5 | P3.1 - Navegación D-pad: flecha derecha | Smart TV | Foco se mueve a la derecha |
| 6 | P3.1 - Navegación D-pad: flecha arriba | Smart TV | Foco se mueve arriba |
| 7 | P3.1 - Navegación D-pad: flecha abajo | Smart TV | Foco se mueve abajo |
| 8 | P3.2 - Tecla Enter selecciona beat | Smart TV | Se actualiza el reproductor |
| 9 | P3.3 - Modo offline: SW sirve la app sin red | Smart TV | La estructura de la app se carga desde cache |
| 10 | P3.4 - Sincronización: cambio en teléfono se refleja en TV < 2s | Teléfono + TV | El beat actualizado aparece en menos de 2 segundos |

## Evidencia
- [ ] Screenshot 1: Wearable mostrando datos
- [ ] Screenshot 2: Teléfono con datos BLE recibidos
- [ ] Screenshot 3: Smart TV con grid de beats
- [ ] Screenshot 4: Smart TV con beat seleccionado y reproductor
- [ ] Screenshot 5: Los 3 dispositivos funcionando simultáneamente

## Documento firmado
Firma: ___________________  Fecha: ___________________
