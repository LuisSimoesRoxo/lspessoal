-- =============================================================================
-- PAINEL PESSOAL DO LUÍS SIMÕES
-- Schema PostgreSQL para Supabase
-- Colar integralmente no SQL Editor do Supabase e clicar "Run"
-- Autenticação: Supabase Auth nativo (ver GUIA_INSTALACAO.md para criar o utilizador)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- EXTENSÕES
-- -----------------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- FUNÇÃO: is_owner()
-- Devolve true apenas se o utilizador autenticado (via Supabase Auth) for um
-- dos emails autorizados. Para autorizar outro email no futuro, basta correr
-- novamente este "create or replace function" com o email adicional na lista.
-- -----------------------------------------------------------------------------
create or replace function is_owner()
returns boolean language sql stable as $$
  select auth.jwt() ->> 'email' in ('lmrsig@gmail.com');
$$;

-- -----------------------------------------------------------------------------
-- TABELA: config
-- Configurações globais do painel (uma única linha)
-- -----------------------------------------------------------------------------
create table if not exists config (
  id            integer primary key default 1 check (id = 1), -- só 1 linha
  titulo        text    not null default 'Painel Pessoal do Luís Simões',
  subtitulo     text    not null default 'Painel Pessoal',
  logo_url      text,
  email_remetente    text,
  gmail_app_password text,
  smtp_host     text    not null default 'smtp.gmail.com',
  smtp_port     integer not null default 587,
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

-- Inserir linha de configuração inicial (só na primeira vez)
insert into config (id) values (1) on conflict do nothing;

-- -----------------------------------------------------------------------------
-- TABELA: lembretes
-- -----------------------------------------------------------------------------
create table if not exists lembretes (
  id              uuid        primary key default uuid_generate_v4(),
  descricao       text        not null,
  data_validade   date,
  alertar_email   boolean     not null default false,
  destinatarios   text,        -- e-mails separados por vírgula
  resolvido       boolean     not null default false,
  resolvido_em    timestamptz,
  data_criacao    timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- TABELA: marcadores (links rápidos)
-- -----------------------------------------------------------------------------
create table if not exists marcadores (
  id          uuid  primary key default uuid_generate_v4(),
  url         text  not null,
  descricao   text  not null,
  subtitulo   text,            -- ex: Associação, Particular, Trabalho
  favicon_url text,
  ordem       integer not null default 0,
  criado_em   timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- TABELA: peixes
-- -----------------------------------------------------------------------------
create table if not exists peixes (
  id              uuid  primary key default uuid_generate_v4(),
  nome_comum      text  not null,
  nome_cientifico text,
  origem          text,
  data_aquisicao  date,
  foto_url        text,
  ph_min          numeric(4,1),
  ph_max          numeric(4,1),
  temp_min        numeric(4,1),
  temp_max        numeric(4,1),
  tipo_agua       text  check (tipo_agua in ('Água Doce','Água Salgada','Salobra')),
  nivel_agua      text  check (nivel_agua in ('Superfície','Intermédio','Fundo')),
  agressividade   text  check (agressividade in ('Baixa','Média','Alta')),
  reproducao      text  check (reproducao in ('Simples','Moderada','Complicada')),
  observacoes     text,
  data_criacao    timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- TABELA: plantas
-- -----------------------------------------------------------------------------
create table if not exists plantas (
  id                  uuid  primary key default uuid_generate_v4(),
  nome_comum          text  not null,
  nome_cientifico     text,
  origem              text,
  data_aquisicao      date,
  foto_url            text,
  tamanho             text,   -- ex: 20–40 cm
  temp_min            numeric(4,1),
  temp_max            numeric(4,1),
  luminosidade        text  check (luminosidade in ('Baixa','Média','Alta')),
  plantio             text  check (plantio in ('Solta','Atada','Substrato')),
  resistencia_peixes  boolean not null default false,
  truques             text,
  data_criacao        timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- TABELA: electronica
-- -----------------------------------------------------------------------------
create table if not exists electronica (
  id          uuid  primary key default uuid_generate_v4(),
  nome        text  not null,
  descricao   text,
  foto_url    text,
  volt_min    numeric(6,2),
  volt_max    numeric(6,2),
  tensao_min  numeric(6,3),
  tensao_max  numeric(6,3),
  utilidade   text,
  data_criacao timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- TABELA: bricolagem
-- -----------------------------------------------------------------------------
create table if not exists bricolagem (
  id          uuid  primary key default uuid_generate_v4(),
  nome        text  not null,
  descricao   text,
  foto_url    text,
  utilidade   text,
  data_criacao timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- TABELA: auditoria
-- Preenchida automaticamente pelos triggers (INSERT/UPDATE/DELETE) e
-- directamente pelo frontend no momento do LOGIN (ver RLS mais abaixo)
-- -----------------------------------------------------------------------------
create table if not exists auditoria (
  id              uuid  primary key default uuid_generate_v4(),
  data_hora       timestamptz not null default now(),
  ip              text,
  sistema         text,
  acao            text  not null,  -- LOGIN, INSERT, UPDATE, DELETE
  tabela          text,
  campo_alterado  text,
  valor_antes     text,
  valor_depois    text
);

-- -----------------------------------------------------------------------------
-- TRIGGER: atualizar "atualizado_em" na config
-- -----------------------------------------------------------------------------
create or replace function touch_atualizado_em()
returns trigger language plpgsql as $$
begin
  new.atualizado_em = now();
  return new;
end;
$$;

create trigger config_touch
  before update on config
  for each row execute function touch_atualizado_em();

-- -----------------------------------------------------------------------------
-- TRIGGER: registar alterações na auditoria (peixes, plantas, electronica, bricolagem, marcadores, lembretes)
-- SECURITY DEFINER: corre com privilégios elevados, por isso o INSERT na
-- auditoria funciona mesmo sem policy de INSERT genérica para o trigger.
-- -----------------------------------------------------------------------------
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
      (new::json->>'nome_comum'), (new::json->>'nome'), (new::json->>'descricao'), (new::json->>'url'), '(novo registo)'
    ));
  elsif TG_OP = 'DELETE' then
    insert into auditoria (acao, tabela, campo_alterado, valor_antes, valor_depois)
    values ('DELETE', TG_TABLE_NAME, '—', coalesce(
      (old::json->>'nome_comum'), (old::json->>'nome'), (old::json->>'descricao'), '(registo eliminado)'
    ), '—');
  elsif TG_OP = 'UPDATE' then
    -- registar cada campo alterado separadamente
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

-- Aplicar trigger a todas as tabelas relevantes
create trigger audit_peixes      after insert or update or delete on peixes      for each row execute function audit_changes();
create trigger audit_plantas     after insert or update or delete on plantas     for each row execute function audit_changes();
create trigger audit_electronica after insert or update or delete on electronica for each row execute function audit_changes();
create trigger audit_bricolagem  after insert or update or delete on bricolagem  for each row execute function audit_changes();
create trigger audit_marcadores  after insert or update or delete on marcadores  for each row execute function audit_changes();
create trigger audit_lembretes   after insert or update or delete on lembretes   for each row execute function audit_changes();

-- -----------------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS)
-- Leitura: pública (anon key) nas tabelas de conteúdo.
-- Escrita: só o(s) email(s) autenticado(s) autorizado(s) em is_owner().
-- -----------------------------------------------------------------------------
alter table config      enable row level security;
alter table lembretes   enable row level security;
alter table marcadores  enable row level security;
alter table peixes      enable row level security;
alter table plantas     enable row level security;
alter table electronica enable row level security;
alter table bricolagem  enable row level security;
alter table auditoria   enable row level security;

-- --- Leitura pública (SELECT) ---
create policy "publico_le_marcadores"   on marcadores   for select using (true);
create policy "publico_le_lembretes"    on lembretes    for select using (true);
create policy "publico_le_peixes"       on peixes       for select using (true);
create policy "publico_le_plantas"      on plantas      for select using (true);
create policy "publico_le_electronica"  on electronica  for select using (true);
create policy "publico_le_bricolagem"   on bricolagem   for select using (true);
create policy "publico_le_auditoria"    on auditoria    for select using (true);
-- config: SEM policy de select público — só o owner (ver abaixo) a lê.

-- --- Escrita (INSERT/UPDATE/DELETE) — só is_owner() ---
create policy "owner_escreve_lembretes"   on lembretes   for all using (is_owner()) with check (is_owner());
create policy "owner_escreve_marcadores"  on marcadores  for all using (is_owner()) with check (is_owner());
create policy "owner_escreve_peixes"      on peixes      for all using (is_owner()) with check (is_owner());
create policy "owner_escreve_plantas"     on plantas     for all using (is_owner()) with check (is_owner());
create policy "owner_escreve_electronica" on electronica for all using (is_owner()) with check (is_owner());
create policy "owner_escreve_bricolagem"  on bricolagem  for all using (is_owner()) with check (is_owner());

-- auditoria: owner pode inserir (registo de LOGIN feito pelo frontend) e eliminar (limpar auditoria)
-- mas nunca "actualizar" (o histórico não se edita)
create policy "owner_insere_auditoria"   on auditoria for insert with check (is_owner());
create policy "owner_elimina_auditoria"  on auditoria for delete using (is_owner());

-- config: owner pode ler e actualizar (as Edge Functions de email também usam service_role, que ignora RLS)
create policy "owner_le_config"          on config for select using (is_owner());
create policy "owner_atualiza_config"    on config for update using (is_owner()) with check (is_owner());
