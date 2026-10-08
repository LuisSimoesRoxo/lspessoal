import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SMTPClient } from "https://deno.land/x/denomailer@1.0.0/mod.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

function getSupabase() {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  return createClient(url, key);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "Método não suportado" }, 405);
  }

  try {
    const { destinatarios, assunto, corpo } = await req.json();

    if (!destinatarios || !assunto || !corpo) {
      return jsonResponse(
        { ok: false, error: "destinatarios, assunto e corpo são obrigatórios" },
        400
      );
    }

    const supabase = getSupabase();

    // Busca configurações SMTP da tabela config
    const { data: config, error: configError } = await supabase
      .from("config")
      .select("email_remetente, gmail_app_password, smtp_host, smtp_port")
      .single();

    if (configError || !config) {
      return jsonResponse(
        { ok: false, error: "Erro ao obter configurações de email: " + (configError?.message ?? "config não encontrada") },
        500
      );
    }

    const { email_remetente, gmail_app_password, smtp_host, smtp_port } = config;

    if (!email_remetente || !gmail_app_password || !smtp_host || !smtp_port) {
      return jsonResponse(
        { ok: false, error: "Configurações SMTP incompletas na tabela config" },
        500
      );
    }

    // Constrói lista de destinatários
    const listaDestinatarios = destinatarios
      .split(",")
      .map((d: string) => d.trim())
      .filter((d: string) => d.length > 0);

    if (listaDestinatarios.length === 0) {
      return jsonResponse({ ok: false, error: "Nenhum destinatário válido" }, 400);
    }

    // Envia email via SMTP
    const client = new SMTPClient({
      connection: {
        hostname: smtp_host,
        port: Number(smtp_port),
        tls: true,
        auth: {
          username: email_remetente,
          password: gmail_app_password,
        },
      },
    });

    await client.send({
      from: email_remetente,
      to: listaDestinatarios,
      subject: assunto,
      content: corpo,
      html: corpo,
    });

    await client.close();

    return jsonResponse({ ok: true });
  } catch (err) {
    console.error("Erro na função send-email:", err);
    const message = err instanceof Error ? err.message : String(err);
    return jsonResponse({ ok: false, error: "Erro ao enviar email: " + message }, 500);
  }
});
