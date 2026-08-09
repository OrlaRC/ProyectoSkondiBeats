-- Ejecutar en Supabase Dashboard -> SQL Editor
-- Cambios 06/08/2026: login (RPC) + columna target en now_playing.
-- Reutiliza tu tabla `users` existente (donde ya está Sara).

-- 1) Función RPC de login: valida email+password y devuelve ok + nombre.
--    NO toca la tabla `users` (solo la lee dentro de la función) y no expone
--    sus filas ni contraseñas a la key anon. Es 100% aditiva.
--    Soporta contraseña hasheada (bcrypt, vía pgcrypto) y texto plano.
create extension if not exists pgcrypto;

create or replace function public.skondit_auth_user(p_email text, p_password text)
returns table(ok boolean, nombre text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre text;
begin
  select u.nombre into v_nombre
  from public.users u
  where lower(u.email) = lower(p_email)
    and (
      u."password" = p_password
      or u."password" = crypt(p_password, u."password")
    )
  limit 1;

  if v_nombre is null then
    return query select false::boolean, null::text;
  else
    return query select true::boolean, v_nombre;
  end if;
end;
$$;

revoke all on function public.skondit_auth_user(text, text) from public;
grant execute on function public.skondit_auth_user(text, text) to anon, authenticated;

-- 2) Columna target en now_playing: 'tv' (reproduce la Smart TV/PWA)
--    o 'app' (reproduce el teléfono). Evita la doble reproducción.
--    Aditivo: solo agrega una columna con default; no borra ni cambia datos.
alter table public.now_playing add column if not exists target text default 'app';
update public.now_playing set target = 'app' where target is null;