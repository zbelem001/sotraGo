import json
import requests
from bs4 import BeautifulSoup
import re

URL = 'https://sotraco.bf/toutes-les-lignes/'

def scrape():
    print("Récupération de la page web...")
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    }
    
    try:
        r = requests.get(URL, headers=headers, timeout=15)
        r.raise_for_status()
    except Exception as e:
        print(f"Erreur lors du chargement de la page: {e}")
        return

    soup = BeautifulSoup(r.text, 'html.parser')
    
    # La section spécifique pour Ouagadougou a cet ID
    ouaga_section = soup.find(id='btss-1uc_content_tabs_elementor17350')
    if not ouaga_section:
        print("Erreur: Impossible de trouver la section Ouagadougou dans le HTML.")
        return

    results = []
    print("Analyse des lignes de Ouagadougou...")
    
    for em in ouaga_section.find_all('em', class_='ue_heading_title'):
        full_title = em.text.strip().replace('\u00a0', ' ')
        
        # Extraire le nom de la ligne et la description (points A et B)
        parts = full_title.split(':', 1)
        line_number = parts[0].strip()
        description = parts[1].strip() if len(parts) > 1 else ""
        
        # Trouver la div du texte qui suit
        post_text = em.find_next('div', class_='ue_post_text')
        if not post_text:
            continue
            
        p = post_text.find('p')
        if p:
            itin_text = p.text.replace('\u00a0', ' ').strip()
            
            # Séparer les arrêts par des tirets
            stops_raw = itin_text.split('-')
            
            stops = []
            for s in stops_raw:
                s_cl = s.strip().strip('.')
                # Retirer les vides ou trop courts si erreur HTML
                if len(s_cl) > 1:
                    stops.append(s_cl)
            
            results.append({
                "city": "Ouagadougou",
                "line_number": line_number,
                "description": description,
                "stops": stops
            })
            
    print(f"{len(results)} lignes trouvées !")
    
    # Sauvegarde dans un fichier JSON
    output_file = 'lignes_ouaga.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
        
    print(f"Extraction terminée avec succès. Fichier sauvegardé sous: {output_file}")

if __name__ == '__main__':
    scrape()
