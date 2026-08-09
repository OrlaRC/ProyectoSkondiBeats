# Documentación de Seguridad (SA.4)

## Validación de event.origin en mensajes
La PWA no usa BroadcastChannel entre orígenes: todos los scripts se sirven del
mismo origen (`script-src 'self'` en la CSP). En el Service Worker los
`message` de clientes se validan por origen antes de procesarlos:
```js
self.addEventListener('message', (e) => {
  if (e.origin && e.origin !== self.location.origin) return; // solo mismo origen
  // procesar mensaje
});
```
Las únicas conexiones externas permitidas son `https://*.supabase.co` y
`https://*.vercel.app`, listadas explícitamente en `connect-src`.

## LFPDPPP - Datos personales identificados
| Dato | Base legal | Finalidad |
|------|-----------|-----------|
| Nombre | Consentimiento | Identificación del usuario |
| Correo electrónico | Consentimiento | Autenticación y comunicación |
| Contraseña (cifrada) | Consentimiento | Seguridad de acceso |
| ID de usuario (UUID) | Consentimiento | Consulta de compras del catálogo |

## Aviso de Privacidad
**Responsable**: SkonditBeats (desarrollador)
**Datos recabados**: nombre, correo electrónico, contraseña cifrada, ID de usuario
**Finalidad**: autenticación, gestión de compras, sincronización de reproducción
**Derechos ARCO**: el usuario puede solicitar acceso, rectificación, cancelación u
oposición escribiendo al responsable.

## Plan de retención de datos
- Sesiones de reproducción: se eliminan automáticamente 24h después de finalizar
- Datos de usuario: se conservan mientras la cuenta esté activa
- Eliminación: el usuario puede solicitar la baja definitiva y se eliminarán todos
  sus datos en 30 días hábiles

## Checklist de seguridad PWA
- [x] CSP configurado en meta tag (default-src, connect-src, media-src, img-src, script-src, style-src)
- [x] HTTPS obligatorio en producción (Vercel/ngrok para servir la PWA)
- [x] SRI: no se usan scripts externos de CDN; todos los scripts son `'self'` (si se agregara un CDN, usar `integrity=`)
- [x] Validación de origen en mensajes (ver arriba)
- [x] API keys fuera del repositorio: `smart_tv_pwa/js/config.js` (gitignored) y `--dart-define` en Flutter; solo se usa la key pública (anon/publishable) protegida por RLS
- [x] `.gitignore` raíz excluye `.env`, `config.js`, `*.jks`, `*.keystore`, `key.properties`

## Inicio de sesión (06/2026)
- Login de demo con credenciales **fijas** en la app: `s@gmail.com` / `707601Orc!` (prellenadas).
- No se valida contra la BD (evita exponer la tabla compartida `users`). La función RPC
  `skondit_auth_user` que se creó queda disponible para validar en el futuro sin exponer `users`.
- Los beats comprados de Sara se cargan del catálogo `orders → beats` filtrado por USER_ID
  (catálogo real, no hardcodeado).

## Evitar doble reproducción (target)
- Columna `target` en `now_playing`: `'app'` (el teléfono reproduce) o `'tv'` (la Smart TV/PWA reproduce).
- El phone publica `target`; la TV solo reproduce audio cuando `target === 'tv'`.
