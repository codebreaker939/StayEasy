import { jsonResponse, preflight } from './cors.ts';

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test('public AI CORS headers cover preflight and JSON responses', () => {
  const optionsRequest = new Request('https://example.test', {
    method: 'OPTIONS',
    headers: {
      origin: 'http://localhost:8081',
      'access-control-request-method': 'POST',
      'access-control-request-headers': 'apikey,content-type,x-client-info',
    },
  });
  const options = preflight(optionsRequest);
  assert(options?.status === 204, 'preflight status');
  assert(options.headers.get('access-control-allow-origin') === '*', 'preflight origin header');

  const response = jsonResponse(
    new Request('https://example.test', { headers: { origin: 'http://localhost:8081' } }),
    { error: 'INVALID_API_KEY' },
    401,
  );
  assert(response.status === 401, 'error status');
  assert(response.headers.get('access-control-allow-origin') === '*', 'JSON origin header');
});
