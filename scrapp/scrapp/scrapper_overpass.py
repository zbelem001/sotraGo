import json
import requests
import time

ENDPOINTS = [
    'https://overpass-api.de/api/interpreter', 
    'https://lz4.overpass-api.de/api/interpreter', 
    'https://z.overpass-api.de/api/interpreter', 
    'https://overpass.openstreetmap.fr/api/interpreter' 
]

def get_sotraco_data():
    print("⏳ Interrogation de l'API Overpass pour Ouagadougou...")
    
    overpass_query = """
    [out:json][timeout:25];
    area["name"="Ouagadougou"]->.searchArea;
    (
      relation["route"="bus"]["operator"~"SOTRACO", i](area.searchArea);
      relation["route"="bus"]["network"~"SOTRACO", i](area.searchArea);
    );
    out geom;
    """

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) SotracoScrapper/1.0',
        'Accept': 'application/json'
    }

    data = None
    for url in ENDPOINTS:
        print(f"🔄 Essai avec le serveur : {url}")
        try:
            response = requests.post(url, data={'data': overpass_query}, headers=headers, timeout=30)
            
            if response.status_code == 200:
                try:
                    data = response.json()
                    print("✅ Données récupérées avec succès !")
                    break 
                except json.JSONDecodeError:
                    print("❌ Réponse non-JSON reçue (erreur serveur interne).")
            else:
                print(f"⚠️ Erreur HTTP {response.status_code}")
        except requests.exceptions.Timeout:
            print("❌ Délai d'attente dépassé (Timeout).")
        except Exception as e:
            print(f"❌ Échec de la connexion.")

    if not data:
        print("❌ Impossible de récupérer les données. Les serveurs sont probablement surchargés. Réessayez plus tard ou utilisez le site officiel overpass-turbo.eu.")
        return

    elements = data.get('elements', [])
    if not elements:
        print("⚠️ Aucune ligne SOTRACO trouvée sur OpenStreetMap pour Ouagadougou.")
        return

    routes = []
    print(f"Traitement de {len(elements)} relations (lignes/variantes) trouvées...")

    for el in elements:
        if el['type'] == 'relation':
            tags = el.get('tags', {})
            line_ref = tags.get('ref', 'Inconnu')
            line_name = tags.get('name', f"Ligne {line_ref}")
            departure = tags.get('from', 'Inconnu')
            arrival = tags.get('to', 'Inconnu')
            
            stops = []
            segments = []

            for member in el.get('members', []):
                role = member.get('role', '')
                
                if member['type'] == 'node' and (role == 'stop' or role == 'platform'):
                    stops.append({
                        "name": member.get('tags', {}).get('name', f"Arrêt ({member.get('lat')}, {member.get('lon')})"),
                        "lat": member.get('lat'),
                        "lon": member.get('lon')
                    })
                
                elif member['type'] == 'way':
                    geometry = member.get('geometry', [])
                    if geometry:
                        segment_coords = [[float(pt['lon']), float(pt['lat'])] for pt in geometry if 'lat' in pt and 'lon' in pt]
                        if segment_coords:
                            segments.append(segment_coords)

            routes.append({
                "city": "Ouagadougou",
                "line_number": line_ref if line_ref != 'Inconnu' else line_name,
                "name": line_name,
                "departure": departure,
                "arrival": arrival,
                "stops_with_coordinates": stops,
                "geometry": {
                    "type": "MultiLineString",
                    "coordinates": segments
                }
            })

    output_file = 'osm_sotraco_ouaga.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(routes, f, ensure_ascii=False, indent=2)

    print(f"🎉 Extraction terminée avec succès !")
    print(f"📁 Données géographiques enregistrées dans : {output_file}")
    print(f"🚌 Nombre de lignes extraites : {len(routes)}")

if __name__ == '__main__':
    get_sotraco_data()
