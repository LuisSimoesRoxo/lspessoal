-- =============================================================================
-- MIGRAÇÃO v2
-- Correr no SQL Editor do Supabase, no projecto LSPessoal, DEPOIS de já teres
-- corrido o schema.sql e o storage.sql originais.
--
-- O que esta migração faz:
--   1. Adiciona "quantidade" a peixes, plantas, electronica, bricolagem
--   2. Funde pH mín/máx e Temp mín/máx (peixes) num só campo de texto cada
--   3. Funde Temp mín/máx (plantas) num só campo de texto
--   4. Funde Voltagem mín/máx e Tensão mín/máx (electronica) num só campo cada
--   5. Remove as restrições fixas (CHECK) de Tipo de Água, Nível, Agressividade,
--      Reprodução (peixes) e Luminosidade, Plantio (plantas) — passam a texto
--      livre, para poderes escrever valores novos sem precisar de alterar nada
--   6. Cria as tabelas novas "experiencias" e "experiencia_registos"
--
-- É seguro correr isto mais do que uma vez (todos os passos são idempotentes).
-- Os valores que já tinhas em min/máx são juntados automaticamente no novo
-- campo (ex: temp_min=24, temp_max=28 -> temperatura="24-28") antes de as
-- colunas antigas serem eliminadas — não perdes dados já guardados.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PEIXES
-- -----------------------------------------------------------------------------
alter table peixes add column if not exists quantidade integer not null default 1;

alter table peixes add column if not exists temperatura text;
update peixes set temperatura =
  coalesce(temp_min::text, '') ||
  (case when temp_min is not null and temp_max is not null then '-' else '' end) ||
  coalesce(temp_max::text, '')
  where temperatura is null and (temp_min is not null or temp_max is not null);
alter table peixes drop column if exists temp_min;
alter table peixes drop column if exists temp_max;

alter table peixes add column if not exists ph text;
update peixes set ph =
  coalesce(ph_min::text, '') ||
  (case when ph_min is not null and ph_max is not null then '-' else '' end) ||
  coalesce(ph_max::text, '')
  where ph is null and (ph_min is not null or ph_max is not null);
alter table peixes drop column if exists ph_min;
alter table peixes drop column if exists ph_max;

alter table peixes drop constraint if exists peixes_tipo_agua_check;
alter table peixes drop constraint if exists peixes_nivel_agua_check;
alter table peixes drop constraint if exists peixes_agressividade_check;
alter table peixes drop constraint if exists peixes_reproducao_check;

-- -----------------------------------------------------------------------------
-- PLANTAS
-- -----------------------------------------------------------------------------
alter table plantas add column if not exists quantidade integer not null default 1;

alter table plantas add column if not exists temperatura text;
update plantas set temperatura =
  coalesce(temp_min::text, '') ||
  (case when temp_min is not null and temp_max is not null then '-' else '' end) ||
  coalesce(temp_max::text, '')
  where temperatura is null and (temp_min is not null or temp_max is not null);
alter table plantas drop column if exists temp_min;
alter table plantas drop column if exists temp_max;

alter table plantas drop constraint if exists plantas_luminosidade_check;
alter table plantas drop constraint if exists plantas_plantio_check;

-- -----------------------------------------------------------------------------
-- ELETRÓNICA
-- -----------------------------------------------------------------------------
alter table electronica add column if not exists quantidade integer not null default 1;

alter table electronica add column if not exists voltagem text;
update electronica set voltagem =
  coalesce(volt_min::text, '') ||
  (case when volt_min is not null and volt_max is not null then '-' else '' end) ||
  coalesce(volt_max::text, '')
  where voltagem is null and (volt_min is not null or volt_max is not null);
alter table electronica drop column if exists volt_min;
alter table electronica drop column if exists volt_max;

alter table electronica add column if not exists tensao text;
update electronica set tensao =
  coalesce(tensao_min::text, '') ||
  (case when tensao_min is not null and tensao_max is not null then '-' else '' end) ||
  coalesce(tensao_max::text, '')
  where tensao is null and (tensao_min is not null or tensao_max is not null);
alter table electronica drop column if exists tensao_min;
alter table electronica drop column if exists tensao_max;

-- -----------------------------------------------------------------------------
-- BRICOLAGEM
-- -----------------------------------------------------------------------------
alter table bricolagem add column if not exists quantidade integer not null default 1;

-- -----------------------------------------------------------------------------
-- EXPERIÊNCIAS (novo) — "livro de experiências"
-- Uma "experiencia" é o livro/registo-mãe (ex: "Experiência com ovos de peixe").
-- Cada "experiencia_registo" é uma entrada datada dentro dessa experiência
-- (ex: "08/10 — ovos mantêm a cor"), opcionalmente com foto.
-- Fechar a experiência é só preencher "data_fecho" (e opcionalmente "resultado").
-- -----------------------------------------------------------------------------
create table if not exists experiencias (
  id            uuid primary key default uuid_generate_v4(),
  titulo        text not null,
  data_abertura timestamptz not null default now(),
  data_fecho    date,
  resultado     text,
  data_criacao  timestamptz not null default now()
);

create table if not exists experiencia_registos (
  id             uuid primary key default uuid_generate_v4(),
  experiencia_id uuid not null references experiencias(id) on delete cascade,
  data_registo   date not null default current_date,
  descricao      text not null,
  foto_url       text,
  data_criacao   timestamptz not null default now()
);

alter table experiencias         enable row level security;
alter table experiencia_registos enable row level security;

drop policy if exists "publico_le_experiencias" on experiencias;
create policy "publico_le_experiencias" on experiencias for select using (true);

drop policy if exists "publico_le_experiencia_registos" on experiencia_registos;
create policy "publico_le_experiencia_registos" on experiencia_registos for select using (true);

drop policy if exists "owner_escreve_experiencias" on experiencias;
create policy "owner_escreve_experiencias" on experiencias for all using (is_owner()) with check (is_owner());

drop policy if exists "owner_escreve_experiencia_registos" on experiencia_registos;
create policy "owner_escreve_experiencia_registos" on experiencia_registos for all using (is_owner()) with check (is_owner());

-- audit_changes() actualizado para também reconhecer "titulo" (experiências)
create or replace function audit_changes()
returns trigger language plpgsql security definer as $$
declare
  col text;
  old_val text;
  new_val text;
begin
  if TG_OP = 'INSERT' then
    insert into auditoria (acao, tabela, campo_alterado, valor_antes, valor_depois)
    values ('INSERT', TG_TABLE_NAME, 'nome', '—', coalesce(
      (row_to_json(new)->>'nome_comum'), (row_to_json(new)->>'nome'), (row_to_json(new)->>'titulo'),
      (row_to_json(new)->>'descricao'), (row_to_json(new)->>'url'), '(novo registo)'
    ));
  elsif TG_OP = 'DELETE' then
    insert into auditoria (acao, tabela, campo_alterado, valor_antes, valor_depois)
    values ('DELETE', TG_TABLE_NAME, '—', coalesce(
      (row_to_json(old)->>'nome_comum'), (row_to_json(old)->>'nome'), (row_to_json(old)->>'titulo'),
      (row_to_json(old)->>'descricao'), '(registo eliminado)'
    ), '—');
  elsif TG_OP = 'UPDATE' then
    for col in select key from json_each_text(row_to_json(new))
    loop
      old_val := (row_to_json(old)->>col)::text;
      new_val := (row_to_json(new)->>col)::text;
      if old_val is distinct from new_val
         and col not in ('data_criacao','atualizado_em') then
        insert into auditoria (acao, tabela, campo_alterado, valor_antes, valor_depois)
        values ('UPDATE', TG_TABLE_NAME, col, coalesce(old_val,'—'), coalesce(new_val,'—'));
      end if;
    end loop;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists audit_experiencias on experiencias;
create trigger audit_experiencias after insert or update or delete on experiencias
  for each row execute function audit_changes();

drop trigger if exists audit_experiencia_registos on experiencia_registos;
create trigger audit_experiencia_registos after insert or update or delete on experiencia_registos
  for each row execute function audit_changes();
