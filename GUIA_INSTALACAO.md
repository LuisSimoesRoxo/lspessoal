# Guia de Instalação — Painel Pessoal do Luís Simões

---

## PASSO 1 — Supabase: Schema da Base de Dados

1. Abre o [Supabase Dashboard](https://supabase.com/dashboard)
2. Entra no projeto **LSPessoal**
3. Menu esquerdo → **SQL Editor** → "New query"
4. Copia o conteúdo do ficheiro `supabase/schema.sql` e clica **Run**

Isto cria todas as tabelas, triggers de auditoria, e as políticas de segurança
(RLS) que restringem a escrita ao teu email.

> Se já tinhas corrido uma versão anterior deste schema (com `username`/`password_hash`
> na tabela `config`), corre este `schema.sql` outra vez — os `create table if not exists`
> não tocam nas tabelas já criadas, mas as novas policies de RLS vão ser adicionadas.
> Se a coluna `password_hash` ainda existir na tua tabela `config` e quiseres removê-la:
> ```sql
> alter table config drop column if exists username;
> alter table config drop column if exists password_hash;
> ```

---

## PASSO 2 — Supabase: Criar o teu utilizador de acesso

Já não há password manual nem Edge Function de login — usamos o **Supabase Auth**
nativo, que já vem incluído em qualquer projecto Supabase.

1. No Dashboard → **Authentication** → **Users**
2. Clica **Add user** → **Create new user**
3. Email: `lmrsig@gmail.com`
4. Define uma password à tua escolha
5. Marca **Auto Confirm User** (se a opção aparecer) para não precisares de confirmar por email

Pronto — o login no painel já funciona com este email e esta password.

> Só este email tem permissão de escrita (ver função `is_owner()` no `schema.sql`).
> Se no futuro quiseres autorizar outro email, edita essa função no SQL Editor:
> ```sql
> create or replace function is_owner()
> returns boolean language sql stable as $$
>   select auth.jwt() ->> 'email' in ('lmrsig@gmail.com', 'outro@email.com');
> $$;
> ```
> e cria esse utilizador da mesma forma em Authentication → Users.

---

## PASSO 3 — Supabase: Edge Function de email (a única que resta)

Esta função só é usada para o envio automático de alertas por email — não tem
nada a ver com login.

### 3a. Instalar o Supabase CLI (se ainda não tiveres)

```bash
npm install -g supabase
```

### 3b. Login e link ao projeto

```bash
supabase login
supabase link --project-ref hihkpowrvsfufmgmtfch
```

### 3c. Configurar a Service Role Key (SECRET — nunca entra no código)

No Supabase Dashboard → **Project Settings** → **API** → copia a **service_role key** (começa por `ey...`)

Depois no terminal:
```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<cola_aqui_a_service_role_key>
```

### 3d. Deploy

A partir da pasta `lspessoal/`:
```bash
supabase functions deploy send-email
```

---

## PASSO 4 — GitHub: Criar o repositório e fazer push

### 4a. Inicializar o repositório local

Abre o terminal na pasta onde guardaste o projecto (onde está a pasta `lspessoal/`):

```bash
cd lspessoal
git init
git add .
git commit -m "Primeiro commit — Painel Pessoal"
```

### 4b. Ligar ao repositório do GitHub

```bash
git remote add origin https://github.com/LuisSimoesRoxo/lspessoal.git
git branch -M main
git push -u origin main
```

> Quando pedir username: `LuisSimoesRoxo`
> Quando pedir password: usa o **Personal Access Token** que já tens (o mesmo que usaste noutro projecto)

### 4c. Configurar o GitHub Pages

1. Vai a https://github.com/LuisSimoesRoxo/lspessoal
2. **Settings** → **Pages**
3. Source: **Deploy from a branch**
4. Branch: `main` | Folder: `/public`
5. Clica **Save**

O site fica disponível em: `https://luissimoesroxo.github.io/lspessoal`
(demora 1-2 minutos na primeira vez)

---

## PASSO 5 — Cloudflare: Apontar o teu domínio

Se quiseres usar o teu domínio (ex: `painel.luissimoes.pt`):

### 5a. Edita o ficheiro `public/CNAME`
Substitui o conteúdo por apenas o teu domínio:
```
painel.luissimoes.pt
```
(ou o domínio que escolheres — sem `https://`)

Faz push:
```bash
git add public/CNAME
git commit -m "Adicionar domínio Cloudflare"
git push
```

### 5b. No Cloudflare Dashboard

Vai ao teu domínio → **DNS** → **Records** → adiciona:

| Tipo | Nome | Conteúdo | TTL |
|------|------|----------|-----|
| A | painel | 185.199.108.153 | Auto |
| A | painel | 185.199.109.153 | Auto |
| A | painel | 185.199.110.153 | Auto |
| A | painel | 185.199.111.153 | Auto |

> **Importante:** Desactiva o proxy Cloudflare (laranja → cinzento) para estes registos, para o GitHub Pages verificar o domínio.

### 5c. Verificar o domínio no GitHub

1. GitHub → Settings → Pages → Custom domain: `painel.luissimoes.pt` → Save
2. Espera alguns minutos → fica verde "DNS check successful"
3. Podes reactivar o proxy no Cloudflare depois

---

## PASSO 6 — Primeiro Login

1. Abre o painel no browser
2. Clica **Entrar** no canto superior (ou vai para o login)
3. Email: `lmrsig@gmail.com` | Password: a que definiste no Passo 2
4. Explora o painel — já tens acesso total às áreas privadas

---

## Estrutura do Projecto

```
lspessoal/
├── .nojekyll                    ← necessário para GitHub Pages
├── README.md
├── public/
│   ├── CNAME                    ← domínio Cloudflare (preencher!)
│   ├── index.html               ← aplicação completa (SPA)
│   ├── css/                     ← (vazio — CSS está inline no index.html)
│   └── js/
│       ├── lib/
│       │   ├── supabase.js      ← cliente Supabase
│       │   └── ui.js            ← utilitários UI partilhados
│       └── pages/               ← (lógica de cada página — inline no index.html)
└── supabase/
    ├── schema.sql               ← schema principal + RLS + is_owner()
    └── functions/
        └── send-email/index.ts  ← alertas automáticos por email
```

---

## Resolução de Problemas

**Site não carrega após push:**
→ Verifica Settings → Pages → está a servir `/public`? Aguarda 2 min.

**Login diz "Credenciais inválidas":**
→ Confirma em Authentication → Users que o utilizador `lmrsig@gmail.com` existe e está confirmado
→ Confirma que a password está correcta (podes repor via "Reset password" no mesmo painel)

**Entro mas não consigo criar/editar/eliminar nada:**
→ Confirma que correste o `schema.sql` completo (as políticas RLS com `is_owner()` têm de existir)
→ Confirma no SQL Editor: `select auth.jwt() ->> 'email';` depois de autenticado deve devolver `lmrsig@gmail.com`

**Emails não chegam:**
→ Configura o `email_remetente` e `gmail_app_password` nas Configurações do painel
→ O Gmail App Password é diferente da password normal — gera em: [myaccount.google.com → Security → App passwords](https://myaccount.google.com/apppasswords)

**Erro "Failed to fetch" na Edge Function de email:**
→ Confirma que a `SUPABASE_SERVICE_ROLE_KEY` foi configurada com `supabase secrets set`
→ Verifica no Dashboard → Edge Functions se `send-email` aparece deployed
