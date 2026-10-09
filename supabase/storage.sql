-- =============================================================================
-- STORAGE: bucket "uploads" para fotos de peixes, plantas, eletrónica,
-- bricolagem e logo das configurações
-- Correr no SQL Editor do Supabase, no projecto LSPessoal
-- =============================================================================

-- Criar o bucket público "uploads" (se ainda não existir)
insert into storage.buckets (id, name, public)
values ('uploads', 'uploads', true)
on conflict (id) do nothing;

-- Leitura pública (para as fotos aparecerem no dashboard público e na área privada)
create policy "publico_le_uploads"
  on storage.objects for select
  using (bucket_id = 'uploads');

-- Só o(s) email(s) autorizado(s) em is_owner() pode(m) enviar/substituir/eliminar ficheiros
create policy "owner_insere_uploads"
  on storage.objects for insert
  with check (bucket_id = 'uploads' and is_owner());

create policy "owner_atualiza_uploads"
  on storage.objects for update
  using (bucket_id = 'uploads' and is_owner());

create policy "owner_elimina_uploads"
  on storage.objects for delete
  using (bucket_id = 'uploads' and is_owner());
