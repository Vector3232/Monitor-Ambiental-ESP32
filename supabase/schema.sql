-- Ejecutar en el SQL Editor de un proyecto de Supabase exclusivo para este sistema.
create table if not exists public.lecturas_ambientales (
  id bigint generated always as identity primary key,
  dispositivo text not null check (length(dispositivo) between 1 and 64),
  temperatura numeric(5,2) not null check (temperatura between -40 and 80),
  humedad numeric(5,2) not null check (humedad between 0 and 100),
  simulada boolean not null default false,
  creada_en timestamptz not null default now()
);

create index if not exists lecturas_ambientales_fecha_idx
  on public.lecturas_ambientales (creada_en desc);

alter table public.lecturas_ambientales enable row level security;

-- Solo lectura pública: no se concede INSERT, UPDATE ni DELETE a visitantes.
grant usage on schema public to anon;
grant select on public.lecturas_ambientales to anon;
revoke insert, update, delete on public.lecturas_ambientales from anon;

-- El panel de demostración es público, por lo que las mediciones NO son privadas.
drop policy if exists "Lectura publica de mediciones" on public.lecturas_ambientales;
create policy "Lectura publica de mediciones"
  on public.lecturas_ambientales
  for select to anon
  using (true);

-- Validación (SQL Editor):
-- select * from public.lecturas_ambientales order by creada_en desc limit 5;
