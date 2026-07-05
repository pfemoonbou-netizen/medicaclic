// Supabase Edge Function: analyze-report
// Reçoit un recordId, télécharge le document médical (image/PDF) depuis le
// bucket privé, l'envoie à Claude (Anthropic) pour explication, enregistre le
// rapport dans medical_records.ai_report et le renvoie à l'app.
//
// Secrets requis (Supabase → Edge Functions → Secrets) :
//   ANTHROPIC_API_KEY   -> ta clé API Anthropic (console.anthropic.com)
// (SUPABASE_URL, SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY sont fournis
//  automatiquement par Supabase.)

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { encodeBase64 } from 'jsr:@std/encoding@1/base64'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(obj: unknown, status: number) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...cors, 'content-type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const { recordId } = await req.json().catch(() => ({}))
    if (!recordId) return json({ error: 'recordId requis' }, 400)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicKey) return json({ error: 'ANTHROPIC_API_KEY non configurée sur le serveur' }, 500)

    // 1) Vérifier l'identité de l'appelant via son JWT
    const authHeader = req.headers.get('Authorization') ?? ''
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user } } = await userClient.auth.getUser()
    if (!user) return json({ error: 'Non authentifié' }, 401)

    // 2) Client admin (service role) pour lire le dossier + le fichier privé
    const admin = createClient(supabaseUrl, serviceKey)
    const { data: record, error: recErr } = await admin
      .from('medical_records')
      .select('*')
      .eq('id', recordId)
      .single()
    if (recErr || !record) return json({ error: 'Document introuvable' }, 404)
    if (record.user_id !== user.id) return json({ error: 'Accès refusé' }, 403)
    if (!record.file_path) return json({ error: 'Aucun fichier à analyser' }, 400)

    // Rapport déjà généré ? On le renvoie tel quel (économise un appel IA)
    if (record.ai_report && String(record.ai_report).trim().length > 0) {
      return json({ report: record.ai_report, cached: true }, 200)
    }

    // 3) Télécharger le fichier depuis le bucket privé
    const { data: fileData, error: dlErr } = await admin
      .storage.from('medical-documents').download(record.file_path)
    if (dlErr || !fileData) return json({ error: 'Téléchargement du fichier impossible' }, 500)
    const bytes = new Uint8Array(await fileData.arrayBuffer())
    const b64 = encodeBase64(bytes)

    const isPdf = record.file_type === 'pdf'
    const mediaBlock = isPdf
      ? { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: b64 } }
      : { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: b64 } }

    const system = `Tu es un assistant médical qui explique des résultats d'analyses médicales (prises de sang, bilans biologiques, imagerie) à des patients en Algérie, en français simple et bienveillant.

Consignes:
- Explique les valeurs ou observations importantes: ce qu'elles mesurent, si elles semblent normales, basses ou élevées, et ce que cela peut signifier de manière générale.
- Utilise un langage clair, sans jargon médical. Structure ta réponse avec des titres courts.
- Ne pose aucun diagnostic définitif et n'indique aucun médicament ni dosage précis.
- Si le document est illisible ou n'est pas une analyse médicale, dis-le simplement.
- Termine TOUJOURS ta réponse par exactement cette ligne:
"⚠️ Ceci est une explication informative générée automatiquement et ne remplace pas l'avis de votre médecin."`

    // 4) Appel à l'API Claude (clé secrète, côté serveur uniquement)
    const aiResp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-opus-4-8',
        max_tokens: 1500,
        system,
        messages: [
          {
            role: 'user',
            content: [
              mediaBlock,
              { type: 'text', text: "Analyse ce document médical et explique-moi les résultats en français simple." },
            ],
          },
        ],
      }),
    })

    if (!aiResp.ok) {
      const errText = await aiResp.text()
      return json({ error: 'Erreur IA (' + aiResp.status + '): ' + errText }, 502)
    }

    const aiData = await aiResp.json()
    const report = (aiData.content ?? [])
      .filter((b: { type: string }) => b.type === 'text')
      .map((b: { text: string }) => b.text)
      .join('\n')
      .trim()

    if (!report) return json({ error: "L'IA n'a pas renvoyé de texte" }, 502)

    // 5) Sauvegarder le rapport
    await admin.from('medical_records').update({ ai_report: report }).eq('id', recordId)

    return json({ report }, 200)
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
