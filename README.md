# Painel Pessoal do Luís Simões

Dashboard pessoal com gestão de lembretes, marcadores, aquários e mais.

## Tecnologias
- **Frontend**: HTML/CSS/JS estático (GitHub Pages)
- **Backend**: Supabase (PostgreSQL + Auth + RLS + 1 Edge Function para email)
- **DNS**: Cloudflare

## Autenticação

Usa o **Supabase Auth** nativo — sem tabela de passwords própria, sem bcrypt manual.
O acesso de escrita (criar/editar/eliminar registos) está restrito ao email
`lmrsig@gmail.com` através de Row Level Security (função `is_owner()` no schema).
A leitura (dashboard público) é livre, sem login.

## Configuração inicial

### 1. Supabase — schema
1. Abrir o SQL Editor no Supabase Dashboard
2. Colar o conteúdo de `supabase/schema.sql` e clicar **Run**

### 2. Supabase — criar o utilizador
1. Authentication → Users → **Add user**
2. Email: `lmrsig@gmail.com` | define uma password
3. Confirma o email automaticamente (marca "Auto Confirm User" se aparecer essa opção)

Pronto — já podes fazer login no painel com este email e password.

### 3. Edge Function de email (única que resta)
```bash
# Instalar Supabase CLI
npm install -g supabase

# Login
supabase login

# Link ao projeto
supabase link --project-ref hihkpowrvsfufmgmtfch

# Configurar a service_role key (nunca entra no frontend)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<a_tua_service_role_key>

# Deploy
supabase functions deploy send-email
```

### 4. GitHub Pages
1. Settings → Pages → Source: Deploy from branch → main → /public
2. Adicionar domínio em `public/CNAME`

### 5. Cloudflare DNS
Adicionar 4 registos A apontando para GitHub Pages:
- 185.199.108.153
- 185.199.109.153
- 185.199.110.153
- 185.199.111.153

E 1 registo CNAME:
- www → luissimoes.github.io (ou o teu username.github.io)

## Segurança
- A `anon key` do Supabase (no código JS) é pública por design
- Escrita nas tabelas só é possível autenticado como `lmrsig@gmail.com` (RLS)
- A `service_role key` NUNCA entra no frontend — só na Edge Function `send-email`, via variável de ambiente Supabase
- Para autorizar outro email no futuro, edita a função `is_owner()` no `schema.sql` e corre novamente no SQL Editor
