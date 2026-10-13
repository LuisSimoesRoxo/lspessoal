-- =============================================================================
-- MIGRAÇÃO v3
-- Correr no SQL Editor do Supabase, no projecto LSPessoal, DEPOIS de já teres
-- corrido a migracao_v2.sql.
--
-- O que esta migração faz:
--   1. Converte "Luminosidade" (plantas) de texto livre de volta para um
--      conjunto fixo de 4 valores: Escuro, Sombra, Meio-Sol, Sol Pleno
--      (precisos para os novos ícones — lua / árvore com sombra / meio sol /
--      sol pleno — aparecerem correctamente no Dashboard e nas listagens).
--   2. Migra automaticamente os valores antigos (Baixa/Baixa-Média/Média/
--      Média-Alta/Alta) para os 4 novos termos. Um valor que não seja
--      reconhecido (ex: texto livre que escreveste entretanto e não
--      corresponda a nenhum destes) fica em branco — podes voltar a
--      escolher no formulário.
--   3. Volta a adicionar a restrição (CHECK) para impedir valores fora
--      destes 4, já que voltou a ser uma lista fechada (dropdown).
--
-- É seguro correr isto mais do que uma vez (todos os passos são idempotentes).
-- =============================================================================

-- Mapeia o vocabulário antigo (5 termos) para o novo (4 termos)
update plantas set luminosidade = case luminosidade
  when 'Baixa'        then 'Escuro'
  when 'Baixa-Média'   then 'Sombra'
  when 'Média'         then 'Meio-Sol'
  when 'Média-Alta'    then 'Sol Pleno'
  when 'Alta'          then 'Sol Pleno'
  else luminosidade
end
where luminosidade in ('Baixa','Baixa-Média','Média','Média-Alta','Alta');

-- Qualquer outro valor que não seja já um dos 4 novos termos fica em branco
-- (evita que a restrição abaixo rebente a migração)
update plantas set luminosidade = null
where luminosidade is not null
  and luminosidade not in ('Escuro','Sombra','Meio-Sol','Sol Pleno');

alter table plantas drop constraint if exists plantas_luminosidade_check;
alter table plantas add constraint plantas_luminosidade_check
  check (luminosidade is null or luminosidade in ('Escuro','Sombra','Meio-Sol','Sol Pleno'));
