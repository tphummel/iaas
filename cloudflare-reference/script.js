async function handleRequest(request) {
  const kvKey = 'test-key';
  const kvValue = await KV_CF_REF.get(kvKey);
  const html = `<!DOCTYPE html>
<body>
  <h1>Hello World</h1>
  <p>This markup was generated by a Cloudflare Worker.</p>
  <p>a kv. key: ${kvKey}, value:${kvValue} </p>
</body>`;

  return new Response(html, {
    headers: {
      'content-type': 'text/html;charset=UTF-8',
    },
  });
}

addEventListener('fetch', event => {
  return event.respondWith(handleRequest(event.request));
});