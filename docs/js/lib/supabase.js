// =============================================================================
// Configuração do cliente Supabase (anon/public key — só para leitura pública)
// Escrita/autenticação passa sempre pelas Edge Functions
// =============================================================================
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

export const SUPABASE_URL = 'https://hihkpowrvsfufmgmtfch.supabase.co';
export const SUPABASE_ANON = 'sb_publishable_tI0uiDyg_itquD9Wy8pGHA_adfQ_XEE';

export const db = createClient(SUPABASE_URL, SUPABASE_ANON);

// URL base das Edge Functions (mesmo domínio Supabase)
export const FN = `${SUPABASE_URL}/functions/v1`;
