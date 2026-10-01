import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.95.0';

export async function hasAuthenticatedUser(request: Request): Promise<boolean> {
  try {
    const authorization = request.headers.get('authorization') ?? '';
    const token = authorization.match(/^Bearer\s+(.+)$/i)?.[1];
    const url = Deno.env.get('SUPABASE_URL');
    const apiKey = request.headers.get('apikey');
    if (!token || !apiKey || !url) return false;
    const client = createClient(url, apiKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data, error } = await client.auth.getUser(token);
    return !error && data.user != null;
  } catch {
    return false;
  }
}
