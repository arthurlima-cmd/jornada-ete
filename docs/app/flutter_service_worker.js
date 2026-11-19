// Remove o cache antigo do Jornada ETEADC e desinstala este service worker.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const chaves = await caches.keys();
    await Promise.all(chaves.map((c) => caches.delete(c)));
    await self.registration.unregister();
    const janelas = await self.clients.matchAll({ type: 'window' });
    janelas.forEach((j) => j.navigate(j.url));
  })());
});
