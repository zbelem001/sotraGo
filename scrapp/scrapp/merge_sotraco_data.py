import json

with open('lignes_ouaga.json', 'r') as f:
    web_data = json.load(f)

with open('osm_sotraco_ouaga.json', 'r') as f:
    osm_data = json.load(f)

web_dict = {}
for line in web_data:
    ln = str(line['line_number']).upper().replace('LIGNE ', '').strip()
    web_dict[ln] = line

merged_lines = {}

for route in osm_data:
    ln = str(route['line_number']).upper().strip()
    
    # On ignore si on a dejà fusionné la ligne (on garde qu'une seule direction)
    if ln in merged_lines:
        # On peut choisir la direction avec le plus d'arrêts
        if len(route['stops_with_coordinates']) > len(merged_lines[ln]['stops_with_coordinates']):
            pass # on va la remplacer
        else:
            continue

    # Nomme le premier et le dernier arrêt selon le départ et l'arrivée OSM
    stops = route['stops_with_coordinates']
    if stops:
        if route['departure'] and route['departure'] != 'Inconnu':
            stops[0]['name'] = route['departure']
        if route['arrival'] and route['arrival'] != 'Inconnu':
            stops[-1]['name'] = route['arrival']
            
    # On ajoute les noms d'arrêts du WEB (répartition approximative)
    web_info = web_dict.get(ln)
    if web_info and stops:
        web_stops = web_info.get('stops', [])
        
        # Astuce : On répartit les noms du WEB sur les arrêts OSM pour au moins 
        # afficher les arrêts principaux sur la carte !
        if len(web_stops) > 0 and len(stops) >= len(web_stops):
            step = len(stops) / len(web_stops)
            for i, w_stop in enumerate(web_stops):
                idx = int(i * step)
                if idx < len(stops):
                    # Si c'est pas déjà le départ/arrivée qu'on a réécrit
                    if idx != 0 and idx != len(stops)-1:
                        stops[idx]['name'] = w_stop
                        stops[idx]['is_main_stop'] = True

    merged_lines[ln] = {
        "city": route["city"],
        "line_number": ln,
        "name": route["name"], # On peut utiliser le nom complet OSM
        "departure": route["departure"],
        "arrival": route["arrival"],
        "description": web_info['description'] if web_info else '',
        "main_stops_list": web_info['stops'] if web_info else [],
        "stops_with_coordinates": stops,
        "geometry": route["geometry"]
    }

# Convertir le dict en liste et trier
final_list = list(merged_lines.values())
# Tri numérique (les lignes UTS etc à la fin)
def sort_key(x):
    try:
        return int(x['line_number'])
    except:
        return 999
        
final_list.sort(key=sort_key)

with open('final_sotraco_ouaga.json', 'w', encoding='utf-8') as f:
    json.dump(final_list, f, ensure_ascii=False, indent=2)

print(f"Fusion terminée ! {len(final_list)} lignes uniques conservées.")
