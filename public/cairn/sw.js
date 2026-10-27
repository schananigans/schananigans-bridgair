const SHELL_CACHE = 'cairn-shell-v1';
const RUNTIME_CACHE = 'cairn-runtime-v1';
const SHELL_FILES = ['./', './index.html', './cairn-config.js', './manifest.webmanifest', './icon.svg'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(SHELL_CACHE).then(cache => cache.addAll(SHELL_FILES)));
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(
    keys.filter(key => ![SHELL_CACHE, RUNTIME_CACHE].includes(key)).map(key => caches.delete(key))
  )));
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  const supabaseLibrary = url.hostname === 'cdn.jsdelivr.net' && url.pathname.includes('/@supabase/supabase-js');

  if (supabaseLibrary) {
    event.respondWith(caches.open(RUNTIME_CACHE).then(async cache => {
      const cached = await cache.match(request);
      if (cached) return cached;
      try {
        const response = await fetch(request);
        cache.put(request, response.clone());
        return response;
      } catch {
        return Response.error();
      }
    }));
    return;
  }

  if (url.origin !== self.location.origin) return;
  event.respondWith((async () => {
    const cached = await caches.match(request);
    if (cached) return cached;
    try {
      const response = await fetch(request);
      if (response.ok) {
        const cache = await caches.open(RUNTIME_CACHE);
        cache.put(request, response.clone());
      }
      return response;
    } catch {
      if (request.mode === 'navigate') return caches.match('./');
      return Response.error();
    }
  })());
});
