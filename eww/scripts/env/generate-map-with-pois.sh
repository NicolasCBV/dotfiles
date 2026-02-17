#!/usr/bin/env bash
set -euo pipefail

ENV_DATA="/tmp/environment-data.json"
POI_FILE="$HOME/.config/eww/map-pois.json"
MAP_FILE="/tmp/eww_map_with_pois.svg"
MAP_DATA_FILE="/tmp/eww_map_data.json"
FILTERED_POI_FILE="/tmp/filtered_pois.json"

MAP_CITY_RADIUS_MIN_METERS="${MAP_CITY_RADIUS_MIN_METERS:-8000}"
MAP_CITY_RADIUS_MAX_METERS="${MAP_CITY_RADIUS_MAX_METERS:-10000}"

MAP_WIDTH="${MAP_WIDTH:-650}"
MAP_HEIGHT="${MAP_HEIGHT:-650}"

MAP_SIDE_FADE_PX="${MAP_SIDE_FADE_PX:-250}"

mkdir -p "$(dirname "$POI_FILE")"
if [ ! -f "$POI_FILE" ]; then
  printf '%s\n' '{"points": []}' > "$POI_FILE"
fi
if [ ! -f "$ENV_DATA" ]; then
  echo "Erro: $ENV_DATA não encontrado" >&2
  exit 1
fi

python3 - "$ENV_DATA" "$POI_FILE" "$MAP_DATA_FILE" "$MAP_FILE" "$FILTERED_POI_FILE" \
  "$MAP_CITY_RADIUS_MIN_METERS" "$MAP_CITY_RADIUS_MAX_METERS" \
  "$MAP_WIDTH" "$MAP_HEIGHT" "$MAP_SIDE_FADE_PX" <<'PY'
#!/usr/bin/env python3
import sys, json, math, urllib.request, urllib.parse

(env_path, poi_path, map_data_file, svg_out, filtered_poi_file,
 min_radius_s, max_radius_s,
 width_s, height_s, side_fade_px_s) = sys.argv[1:11]

min_radius = float(min_radius_s)
max_radius = float(max_radius_s)

WIDTH = int(float(width_s))
HEIGHT = int(float(height_s))
SIDE_FADE_PX = int(float(side_fade_px_s))

def load_json(path, default=None):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return default

def esc_xml(s):
    if s is None:
        return ""
    return (str(s)
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace("'", '&apos;'))

env = load_json(env_path)
if not env or 'coord' not in env:
    sys.exit(1)

center_lat = float(env['coord']['lat'])
center_lon = float(env['coord']['lon'])

poi_data = load_json(poi_path, {"points": []}) or {"points": []}
pois = poi_data.get("points", [])

MPD_LAT = 111320.0
MPD_LON = MPD_LAT * math.cos(math.radians(center_lat))
if MPD_LON <= 0.0:
    MPD_LON = 1.0

included = []
max_distance_m = 0.0

for p in pois:
    try:
        plat = float(p.get('lat'))
        plon = float(p.get('lon'))
    except Exception:
        continue
    dy = (plat - center_lat) * MPD_LAT
    dx = (plon - center_lon) * MPD_LON
    d = math.hypot(dx, dy)
    if d <= max_radius:
        included.append(p)
        if d > max_distance_m:
            max_distance_m = d

if len(included) == 0:
    final_radius = min_radius
else:
    final_radius = min(max(max_distance_m, min_radius), max_radius)

lat_delta = final_radius / MPD_LAT
lon_delta = final_radius / MPD_LON

min_lat = center_lat - lat_delta
max_lat = center_lat + lat_delta
min_lon = center_lon - lon_delta
max_lon = center_lon + lon_delta

overpass_data = f"""[out:json][timeout:60];
(
  way["highway"]({min_lat},{min_lon},{max_lat},{max_lon});
);
out geom;"""

data = urllib.parse.urlencode({'data': overpass_data}).encode('utf-8')
req = urllib.request.Request("https://overpass-api.de/api/interpreter", data=data, method='POST')
with urllib.request.urlopen(req, timeout=60) as resp:
    road_data = json.loads(resp.read().decode('utf-8'))

elements = road_data.get('elements', [])

all_coords = []
for el in elements:
    geom = el.get('geometry')
    if geom:
        for node in geom:
            all_coords.append((node['lat'], node['lon']))

if not all_coords:
    all_coords = [(float(p['lat']), float(p['lon'])) for p in included]

map_center_lat = sum(p[0] for p in all_coords) / len(all_coords)
map_center_lon = sum(p[1] for p in all_coords) / len(all_coords)

MPD_LAT2 = 111320.0
MPD_LON2 = MPD_LAT2 * math.cos(math.radians(map_center_lat))

def latlon_to_m(lat, lon):
    return ((lon - map_center_lon) * MPD_LON2,
            (lat - map_center_lat) * MPD_LAT2)

project_points = [latlon_to_m(lat, lon) for lat, lon in all_coords]
for p in included:
    project_points.append(latlon_to_m(float(p['lat']), float(p['lon'])))

mxs = [p[0] for p in project_points]
mys = [p[1] for p in project_points]

min_mx, max_mx = min(mxs), max(mxs)
min_my, max_my = min(mys), max(mys)

range_x = max(0.1, max_mx - min_mx)
range_y = max(0.1, max_my - min_my)

SCALE = min((WIDTH * 0.9) / range_x,
            (HEIGHT * 0.9) / range_y)

def to_svg_xy(lat, lon):
    mx, my = latlon_to_m(lat, lon)
    cx = (mx - (min_mx + max_mx)/2.0) * SCALE + WIDTH/2.0
    cy = -(my - (min_my + max_my)/2.0) * SCALE + HEIGHT/2.0
    return cx, cy

svg = []
# adiciona xmlns:xlink e xmlns padrão
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">')
svg.append('<defs>')
# Filtro de sombra para os pins
svg.append('<filter id="pinShadow" x="-50%" y="-50%" width="200%" height="200%">')
svg.append('<feGaussianBlur in="SourceAlpha" stdDeviation="2"/>')
svg.append('<feOffset dx="0" dy="2" result="offsetblur"/>')
svg.append('<feComponentTransfer>')
svg.append('<feFuncA type="linear" slope="0.4"/>')
svg.append('</feComponentTransfer>')
svg.append('<feMerge>')
svg.append('<feMergeNode/>')
svg.append('<feMergeNode in="SourceGraphic"/>')
svg.append('</feMerge>')
svg.append('</filter>')

svg.append('<mask id="edgeMask">')

# Calcular o raio máximo (da borda à extremidade)
max_dimension = max(WIDTH, HEIGHT)
center_x = WIDTH / 2.0
center_y = HEIGHT / 2.0

# O raio do gradiente vai do centro até a borda mais distante
fade_radius = max_dimension / 2.0
inner_radius = fade_radius - SIDE_FADE_PX

# Normalizar para porcentagem (0-100%)
inner_percent = (inner_radius / fade_radius) * 100.0

# Gradiente radial: branco no centro, preto nas bordas
svg.append(f'<radialGradient id="radialFade" cx="50%" cy="50%" r="50%">')
svg.append(f'<stop offset="0%" stop-color="white"/>')
svg.append(f'<stop offset="{inner_percent:.1f}%" stop-color="white"/>')
svg.append('<stop offset="100%" stop-color="black"/>')
svg.append('</radialGradient>')

svg.append(f'<rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="url(#radialFade)"/>')

svg.append('</mask>')
svg.append('</defs>')

svg.append('<g mask="url(#edgeMask)">')
for el in elements:
    geom = el.get('geometry')
    if not geom:
        continue
    pts = []
    for n in geom:
        x, y = to_svg_xy(n['lat'], n['lon'])
        pts.append(f"{x:.2f},{y:.2f}")
    if len(pts) >= 2:
        svg.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="rgba(255,255,255,0.8)" stroke-width="1.2"/>')
svg.append('</g>')

for p in included:
    x, y = to_svg_xy(float(p['lat']), float(p['lon']))
    color = p.get('color', 'rgba(255,100,100,0.9)')
    text_color = p.get('text_color', 'white')
    font_weight = p.get('font_weight', '700')
    name = p.get('name', '')
    link = p.get('link', '') or None

    # Criar pin de mapa (gota)
    pin_size = 20
    # desenha a gota de forma relativa à posição y
    pin_path = f'M {x:.2f},{y-pin_size:.2f} ' \
               f'c -5.5,0 -10,4.5 -10,10 ' \
               f'c 0,7 10,{pin_size:.2f} 10,{pin_size:.2f} ' \
               f'c 0,0 10,-{pin_size-10:.2f} 10,-{pin_size:.2f} ' \
               f'c 0,-5.5 -4.5,-10 -10,-10 z'

    # Se houver link, abrir <a ...>, caso contrário apenas desenha os elementos
    if link:
        href = esc_xml(link)
        # adiciona style cursor:pointer para indicar que é clicável
        svg.append(f'<a href="{href}" xlink:href="{href}" target="_blank" rel="noopener noreferrer" style="cursor:pointer">')

    # Pin principal com borda e sombra
    svg.append(f'<path d="{pin_path}" fill="{color}" stroke="white" stroke-width="2.5" filter="url(#pinShadow)"/>')

    # Círculo interno branco no centro do pin
    svg.append(f'<circle cx="{x:.2f}" cy="{y-pin_size+10:.2f}" r="4" fill="white" opacity="0.9"/>')

    # Texto do nome abaixo do pin com contorno preto
    if name:
        # deslocamento maior para mover alguns pixels mais para baixo (solicitado)
        text_y = y + 14.0  # originalmente era y+8; aumentei para "mover alguns pixels abaixo"
        esc_name = esc_xml(name)
        # primeiro traço preto para contorno grosseiro
        svg.append(f'<text x="{x:.2f}" y="{text_y:.2f}" text-anchor="middle" font-size="13" font-weight="{font_weight}" fill="rgba(0,0,0,0.9)" stroke="rgba(0,0,0,0.9)" stroke-width="4" paint-order="stroke">{esc_name}</text>')
        # texto colorido por cima
        svg.append(f'<text x="{x:.2f}" y="{text_y:.2f}" text-anchor="middle" font-size="13" font-weight="{font_weight}" fill="{esc_xml(text_color)}">{esc_name}</text>')

    if link:
        svg.append('</a>')

svg.append('</svg>')

with open(svg_out, 'w', encoding='utf-8') as f:
    f.write("\n".join(svg))
PY

echo "done"
