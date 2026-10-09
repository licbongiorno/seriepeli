// Centro Multimedia: guarda la página en el equipo para que abra sin internet.
const VERSION = 'centro-v8';
const APP = ['./', 'index.html', 'manifest.webmanifest', 'icono.svg', 'icono-192.png', 'icono-512.png', 'apple-touch-icon.png', 'centro.ico', 'qrcode.js'];
const IMAGES = 'centro-img';
const NOTIFY = 'centro-notify'; // series que seguís, para avisar con el centro cerrado

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(APP)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== VERSION && k !== IMAGES && k !== NOTIFY).map(k => caches.delete(k))))
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

/* ===== Avisos de episodios nuevos con el centro cerrado =====
   En Android, con el centro instalado como app, el sistema despierta este código cada algunas horas
   ("periodic background sync"). Lee las series que seguís (las deja guardadas la página), le pregunta
   a TMDB por el último episodio y avisa si salió en los últimos 3 días. */
const CFG_URL = './__avisos.json';
async function readCfg() {
  const r = await (await caches.open(NOTIFY)).match(CFG_URL);
  return r ? r.json() : null;
}
async function checkInBackground() {
  const cfg = await readCfg();
  if (!cfg || !cfg.on || !cfg.key || !(cfg.follows || []).length) return [];
  const done = new Set(cfg.notified || []), sent = [];
  for (const f of cfg.follows.slice(0, 60)) {
    try {
      const url = new URL(`https://api.themoviedb.org/3/tv/${f.id}`);
      url.searchParams.set('language', cfg.lang || 'es-AR');
      const headers = { accept: 'application/json' };
      if (cfg.key.startsWith('eyJ')) headers.Authorization = 'Bearer ' + cfg.key; else url.searchParams.set('api_key', cfg.key);
      const d = await (await fetch(url, { headers })).json();
      const e = d && d.last_episode_to_air;
      if (!e || !e.air_date) continue;
      const age = (Date.now() - new Date(e.air_date + 'T12:00')) / 864e5;
      const tag = `${f.id}:${e.season_number}x${e.episode_number}`;
      if (age < -0.5 || age > 3 || done.has(tag)) continue;
      done.add(tag);
      const title = `🆕 ${d.name || f.name}`, body = `Salió T${e.season_number} E${e.episode_number}${e.name ? ' · ' + e.name : ''}`;
      sent.push(title + ' · ' + body);
      try { await self.registration.showNotification(title, { body, tag, icon: 'icono-192.png', badge: 'icono-192.png', data: { url: './' } }); } catch (err) {}
    } catch (err) {}
  }
  // Se guarda qué ya se avisó, para no repetir (la página también lo lee)
  cfg.notified = [...done].slice(-200);
  await (await caches.open(NOTIFY)).put(CFG_URL, new Response(JSON.stringify(cfg), { headers: { 'content-type': 'application/json' } }));
  return sent;
}
self.addEventListener('periodicsync', e => { if (e.tag === 'episodios') e.waitUntil(checkInBackground()); });
// La página también puede pedir una revisión (y recibe qué se avisó)
self.addEventListener('message', e => {
  if (e.data === 'revisar-episodios') e.waitUntil(checkInBackground().then(sent => e.ports[0] && e.ports[0].postMessage(sent)));
});
