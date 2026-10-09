// Centro Multimedia: guarda la página en el equipo para que abra sin internet.
const VERSION = 'centro-v7';
const APP = ['./', 'index.html', 'manifest.webmanifest', 'icono.svg', 'icono-192.png', 'icono-512.png', 'apple-touch-icon.png', 'centro.ico', 'qrcode.js'];
const IMAGES = 'centro-img';

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(APP)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== VERSION && k !== IMAGES).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // La página del centro: primero internet (para tener siempre la última versión); si no hay, la guardada
  if (url.origin === location.origin) {
    e.respondWith(fetch(req).then(r => {
      if (r.ok) { const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy)); }
      return r;
    }).catch(() => caches.match(req, { ignoreSearch: true }).then(r => r || caches.match('index.html'))));
    return;
  }
  // Pósters y fotos de TMDB: se guardan para verlos sin internet (máximo 400)
  if (url.hostname === 'image.tmdb.org') {
    e.respondWith(caches.open(IMAGES).then(async c => {
      const hit = await c.match(req);
      if (hit) return hit;
      const r = await fetch(req);
      if (r.ok || r.type === 'opaque') {
        c.put(req, r.clone());
        c.keys().then(k => { if (k.length > 400) k.slice(0, k.length - 400).forEach(x => c.delete(x)); });
      }
      return r;
    }));
  }
});

// Al tocar un aviso de episodio nuevo: abre el centro (o lo trae al frente si ya estaba abierto)
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
    const open = list.find(c => c.url.includes(self.registration.scope));
    return open ? open.focus() : self.clients.openWindow((e.notification.data && e.notification.data.url) || './');
  }));
});
