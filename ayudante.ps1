# Ayudante del Centro Multimedia (se ejecuta oculto, solo en esta PC).
# Busca en JustWatch el enlace EXACTO de cada titulo en Netflix, Disney+, HBO Max, etc.
# El centro le pregunta por http://localhost:47615/link?tmdb=862&type=movie&title=Toy%20Story
# Solo escucha en "localhost": no es accesible desde otras computadoras.

Add-Type -AssemblyName System.Web
$port = 47615
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try { $listener.Start() } catch { exit }   # ya hay otro ayudante funcionando

$cache = @{}
$query = 'query T($country: Country!, $language: Language!, $first: Int!, $filter: TitleFilter) { popularTitles(country: $country, first: $first, filter: $filter) { edges { node { objectType content(country: $country, language: $language) { title externalIds { tmdbId } } offers(country: $country, platform: WEB) { monetizationType standardWebURL package { clearName technicalName } } } } } }'

function Find-Links($tmdb, $type, $title) {
  $objType = if ($type -eq 'tv') { 'SHOW' } else { 'MOVIE' }
  $body = @{ query = $query; variables = @{ country = 'AR'; language = 'es'; first = 10; filter = @{ searchQuery = $title } } } | ConvertTo-Json -Depth 6 -Compress
  $bytes = [Text.Encoding]::UTF8.GetBytes($body)
  $r = Invoke-RestMethod 'https://apis.justwatch.com/graphql' -Method Post -Body $bytes -ContentType 'application/json; charset=utf-8' -TimeoutSec 15
  $node = $r.data.popularTitles.edges | ForEach-Object { $_.node } |
    Where-Object { $_.objectType -eq $objType -and "$($_.content.externalIds.tmdbId)" -eq "$tmdb" } | Select-Object -First 1
  if (-not $node) { return @() }
  $seen = @{}
  $out = @()
  foreach ($o in $node.offers) {
    if ($o.monetizationType -notin @('FLATRATE', 'FREE', 'ADS')) { continue }
    $k = $o.package.technicalName
    if ($seen.ContainsKey($k)) { continue }
    $seen[$k] = 1
    $out += @{ name = $o.package.clearName; tech = $k; url = $o.standardWebURL }
  }
  return $out
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  $res.Headers.Add('Access-Control-Allow-Origin', '*')
  $res.Headers.Add('Access-Control-Allow-Private-Network', 'true')
  $res.Headers.Add('Access-Control-Allow-Headers', '*')
  $json = '{}'
  try {
    if ($req.HttpMethod -eq 'OPTIONS') { $res.StatusCode = 204; $res.Close(); continue }
    $path = $req.Url.AbsolutePath
    if ($path -eq '/ping') { $json = '{"ok":true}' }
    elseif ($path -eq '/link') {
      # Se decodifica en UTF-8 para que lleguen bien las tildes y la enie
      $qs = [System.Web.HttpUtility]::ParseQueryString($req.Url.Query, [Text.Encoding]::UTF8)
      $tmdb = $qs['tmdb']; $type = $qs['type']
      $title = $qs['title']; $otitle = $qs['otitle']
      $key = "$type/$tmdb"
      if ($cache.ContainsKey($key)) { $links = $cache[$key] }
      else {
        $links = @()
        if ($title) { $links = @(Find-Links $tmdb $type $title) }
        if (-not $links.Count -and $otitle -and $otitle -ne $title) { $links = @(Find-Links $tmdb $type $otitle) }
        if ($links.Count) { $cache[$key] = $links }   # los resultados vacios no se guardan
      }
      $json = @{ found = ($links.Count -gt 0); offers = @($links) } | ConvertTo-Json -Depth 4 -Compress
    }
    else { $res.StatusCode = 404 }
  } catch { $res.StatusCode = 500; $json = '{"error":"' + ($_.Exception.Message -replace '"', "'") + '"}' }
  $buf = [Text.Encoding]::UTF8.GetBytes($json)
  $res.ContentType = 'application/json; charset=utf-8'
  $res.ContentLength64 = $buf.Length
  try { $res.OutputStream.Write($buf, 0, $buf.Length) } catch {}
  $res.Close()
}
