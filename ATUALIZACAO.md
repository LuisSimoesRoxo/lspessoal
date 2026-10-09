# Actualização do Painel Pessoal — correcção dos registos a serem substituídos

## O que estava a acontecer

- **Lembretes**: criavas um lembrete, dizia "guardado", mas não aparecia em lado nenhum.
- **Marcadores, Peixes, Plantas, Eletrónica, Bricolagem**: ao criar um novo registo, em vez de o adicionar, por vezes **substituía** um registo já existente.
- **Peixes**: ao clicar em "Editar", o formulário abria mas vinha com o Nome Comum, Nome Científico, Foto (URL) e Observações em branco.

## Causa

Eram duas falhas, e a dos registos substituídos era sempre a mesma:

1. O botão "+ Novo" e o botão "Cancelar" só *alternavam* (mostravam/escondiam) o formulário, sem nunca o limpar. Se em qualquer altura tivesses aberto um registo para "Editar" (mesmo só para ver) e depois cancelado, o formulário ficava internamente "agarrado" ao `id` desse registo. A próxima vez que gravasses, pensando que estavas a criar um registo novo, o sistema na realidade **actualizava** esse registo antigo com os dados novos — por isso parecia que um substituía o outro.

2. Em "Peixes", a função que preenche o formulário de edição tinha um erro a montar os nomes dos campos (afectava Nome Comum, Nome Científico, Foto URL e Observações), por isso esses quatro campos ficavam sempre em branco ao editar, mesmo que os outros (Origem, pH, Temperatura, Tipo de Água, etc.) aparecessem bem.

## O que foi corrigido

- "+ Novo" agora **força sempre** um formulário em branco (limpa todos os campos, incluindo o `id` escondido).
- "Cancelar" e "Guardar" agora **fecham e limpam sempre** o formulário correctamente, nunca deixando nada residual para a próxima vez.
- Em "Peixes", o formulário de edição foi corrigido para preencher sempre todos os campos correctamente.

Isto aplica-se a Lembretes, Marcadores, Peixes, Plantas, Eletrónica e Bricolagem.

Não há alterações à base de dados nesta actualização — só ao `docs/index.html`.

---

## PASSO 1 — Substituir o ficheiro no teu computador

1. Descarrega e extrai o novo `lspessoal.zip`
2. Copia o ficheiro `docs/index.html` de dentro do ZIP, substituindo o que está em `~/Transferências/lspessoal/docs/index.html`

(Os restantes ficheiros não mudaram — não precisas de os substituir.)

---

## PASSO 2 — Enviar a actualização para o GitHub

Abre o terminal na pasta do projecto:

```bash
cd ~/Transferências/lspessoal
git add -A
git commit -m "Corrigir registos substituídos ao criar novos e pré-preenchimento da edição de peixes"
git push
```

Espera 1-2 minutos e testa o site (faz um refresh forçado — Ctrl+F5 — para garantir que não fica com a versão antiga em cache).

**Para testar:**
1. Cria 3 marcadores seguidos — os três devem aparecer, nenhum deve desaparecer.
2. Em Peixes, cria um peixe, depois clica em "Editar" nesse peixe e confirma que TODOS os campos aparecem preenchidos (incluindo Nome Comum, Nome Científico e Observações).
3. Cria um lembrete e confirma que aparece de imediato na lista e no dashboard.
