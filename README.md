# Centro Multimedia

Menú para ver Netflix, HBO Max, Disney+, YouTube y más, con buscador de películas y series.
Online en: https://licbongiorno.github.io/seriepeli/

## En la PC
Abrí `abrir.ps1`: abre el centro a pantalla completa en Edge y arranca el ayudante de enlaces directos.
Se maneja con teclado, mouse o control de Xbox (flechas para moverse, Enter para abrir, Escape para volver).

## En el celular
1. Abrí https://licbongiorno.github.io/seriepeli/ (o, en la PC, **⚙ → 📱 Usarlo en el celular → 🔳 Mostrar código QR** y apuntá la cámara).
2. En el navegador del celular: menú → **Agregar a pantalla de inicio** para tenerlo como una app.
   Manteniendo apretado el ícono aparecen atajos: Buscar, ¿Qué veo hoy? y Mi lista.

## Funciones
- **▶ Ver en…** abre la app de la plataforma directo en el título (enlaces exactos de JustWatch y Wikidata).
- **✎ Mis plataformas** (en la fila de filtros): elegí en qué plataformas busca. Solo cuentan las suscripciones
  propias, no los "canales" dentro de otra tienda (por ejemplo "Max Amazon Channel").
- Búsqueda por título, actor, director, género, tema o país; también **por voz** (🎤).
- Banner con los 5 más vistos del día, rankings, estrenos, "¿Qué veo hoy?", perfiles con Mi lista,
  "Ya la vi", 👍/👎, "voy por" de cada serie y aviso de episodios nuevos.
- **🌙 Esta noche para vos**: 3 sugerencias del día según tus 👍 (cambian a la medianoche).
- **▶ Seguir viendo** y, en el menú, **A continuación**: las series en curso y tu lista.
- **Tráiler dentro del centro** (en la versión online) y **vista previa** al dejar el mouse sobre un póster (PC).
- La ficha de cada título toma el **color de su póster**.
- **👨‍👩‍👧 Para ver juntos**: una lista de toda la familia, compartida entre perfiles.
- **🧸 Perfil para chicos**: ese perfil solo muestra títulos para chicos.
- **🔔 Avisos de episodios nuevos** de las series que seguís (⚙ → Activar avisos). Revisan al abrir el centro
  y cada unas horas mientras está abierto. En Android, con el centro **instalado como app**, avisan también
  con el centro cerrado: el teléfono lo despierta solo cada algunas horas (el sistema elige cuándo).
- **Sincronizar PC y celular**: ⚙ → 🔄 Activar sincronización, y mandá el enlace (WhatsApp o QR) al celular.
  Perfiles, listas, vistas y plataformas se comparten solos (se guardan en jsonblob.com, sin la clave de TMDB).
- **Sin conexión**: una vez abierto desde internet, abre aunque no haya señal y muestra lo último guardado.
- **Copia de seguridad**: ⚙ → Exportar / Importar copia.

## Archivos
- `index.html`: todo el centro (una sola página).
- `sw.js`: guarda el centro para usarlo sin conexión. `manifest.webmanifest`: datos para instalarlo como app.
- `icono.svg` y `icono-*.png`, `apple-touch-icon.png`, `centro.ico`: el ícono en todos los tamaños.
- `qrcode.js`: genera el código QR (Kazuhiko Arase, licencia MIT).
- `abrir.ps1`, `ayudante.ps1`: arranque en la PC y ayudante local de enlaces directos.
