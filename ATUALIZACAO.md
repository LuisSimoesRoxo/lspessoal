# Actualização do Painel Pessoal — Quantidade, campos simplificados e Experiências

## O que há de novo

### 0. Clicar numa foto para a ampliar
Em qualquer miniatura (Peixes, Plantas, Eletrónica, Bricolagem, registos de Experiências e nas pré-visualizações do Dashboard), clicar na foto abre-a em grande, com fundo escuro por cima do resto da página. Para fechar: clica outra vez na foto (ou em qualquer lado à volta), ou pressiona Esc. Sem X nenhum no canto.

### 1. Campo "Quantidade"
Peixes, Plantas, Eletrónica e Bricolagem têm agora um campo **Quantidade** (número), visível também como coluna nas listagens.

### 2. Campo "Foto URL" removido dos formulários
Em Peixes, Plantas, Eletrónica e Bricolagem já não há o campo de texto "Foto URL" — só o upload direto do PC. (Mantive o da Logo nas Configurações, porque não falaste dele.)

### 3. Campos mín/máx fundidos num só
Escreves o intervalo directamente, texto livre:

| Onde | Antes | Agora |
|---|---|---|
| Peixes | pH Mín + pH Máx | **pH** — ex: `6.4-7.5` |
| Peixes | Temp. Mín + Temp. Máx | **Temperatura** — ex: `24-28` |
| Plantas | Temp. Mín + Temp. Máx | **Temperatura** — ex: `20-28` |
| Plantas | Tamanho | continua um só campo, só mudei a legenda para **"Tamanho (cm)"** |
| Eletrónica | Voltagem Mín + Máx | **Voltagem** — ex: `5-12` |
| Eletrónica | Tensão Mín + Máx | **Tensão** — ex: `0.5-2` |

### 4. Dropdowns (Tipo de Água, Nível, Agressividade, Reprodução, Luminosidade, Plantio) agora são texto livre com sugestões
Perguntaste como adicionar valores novos a estas listas (ex: "Baixa-Média"). Resposta: **já não precisas de tocar em código nenhum.** Deixaram de ser `<select>` fixos — passaram a campos de texto com sugestões (o que já lá estava continua a aparecer enquanto escreves, incluindo exemplos novos como "Baixa-Média"/"Média-Alta"), mas podes escrever **qualquer valor**, incluindo um que nunca tenha existido antes. A base de dados também deixou de ter a restrição fixa (CHECK) nestes campos.

### 5. Nova página: 🧪 Experiências — o "livro de experiências"
Como pediste:
- **+ Nova Experiência** → só pedes um título (ex: "Experiência com ovos de peixe"); a data de abertura é automática.
- Abres a experiência (⊕) e vês os **Registos**: cada um com a sua data, o texto que escreveres, e uma foto opcional — vais acumulando um por dia (ou quantos quiseres).
- Enquanto não preenches a **Data de Fecho**, a experiência aparece como "Aberta". Assim que preenches essa data (e, se quiseres, um resumo final), fecha-se automaticamente e passa a "Fechada" — exactamente como descreveste.
- Dá também para **reabrir** uma experiência fechada por engano, e eliminar registos ou a experiência toda (as fotos associadas são limpas do Storage).

Sugestões que fui pensando enquanto construía isto, caso queiras que adicione a seguir — diz-me quais:
- Um pequeno "número do dia" automático em cada registo (Dia 1, Dia 2, …) a partir da data de abertura.
- Mostrar nas Experiências abertas um aviso tipo "há X dias sem novo registo", para te lembrares de ir lá.
- Um resumo das experiências no Dashboard (tipo "3 experiências em curso").
- Permitir marcar o resultado final como "Sucesso" / "Insucesso" / "Inconclusivo", além do texto livre, para depois conseguires filtrar.

Nenhuma destas foi feita agora — só avança se quiseres.

---

## PASSO 1 — Supabase: correr a migração

1. Abre o Supabase Dashboard → projecto **LSPessoal** → **SQL Editor** → "New query"
2. Copia o conteúdo de `supabase/migracao_v2.sql` e clica **Run**

Isto adiciona a Quantidade, funde os campos mín/máx (sem perder o que já tinhas guardado), remove as restrições fixas dos dropdowns, e cria as tabelas novas das Experiências.

---

## PASSO 2 — Substituir o ficheiro no teu computador

1. Descarrega e extrai o novo `lspessoal.zip`
2. Copia `docs/index.html` de dentro do ZIP, substituindo o que está em `~/Transferências/lspessoal/docs/index.html`
3. Copia também `supabase/migracao_v2.sql` para `~/Transferências/lspessoal/supabase/migracao_v2.sql` (fica como registo, não precisa de correr de novo depois do Passo 1)

---

## PASSO 3 — Enviar para o GitHub

```bash
cd ~/Transferências/lspessoal
git add -A
git commit -m "Adicionar Quantidade, simplificar campos min/max e dropdowns, criar pagina Experiencias"
git push
```

Espera 1-2 minutos e testa (Ctrl+F5 para não ficar com a versão antiga em cache).

**Para testar:**
1. Cria um peixe com Quantidade, pH "6.4-7.5" e Temperatura "24-28" — confirma que aparece tudo certo na listagem e ao editar.
2. Escreve um valor novo em "Agressividade" (ex: "Média-Alta") que não estava na lista antiga — confirma que grava sem erro.
3. Vai a Experiências → cria uma nova → adiciona 2-3 registos com datas e fotos → preenche a Data de Fecho → confirma que passa a "Fechada" e mostra o resumo.
