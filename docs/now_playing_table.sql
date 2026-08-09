-- Ejecutar en Supabase Dashboard → SQL Editor
-- Crea la tabla de sincronización teléfono → TV (P3.3).

create table if not exists public.now_playing (
  id integer primary key default 1 check (id = 1),
  beat_id text,
  beat_name text,
  genre text,
  bpm integer,
  position_sec integer,
  duration_sec integer,
  playing boolean default false,
  updated_at timestamptz default now()
);

alter table public.now_playing enable row level security;

create policy "now_playing_select_anon" on public.now_playing
  for select to anon using (true);

create policy "now_playing_insert_anon" on public.now_playing
  for insert to anon with check (true);

create policy "now_playing_update_anon" on public.now_playing
  for update to anon using (true);
