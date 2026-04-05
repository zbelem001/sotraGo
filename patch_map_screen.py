import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'r') as f:
    content = f.read()

import_sp = "import '../widgets/location_prompt.dart';"
content = content.replace(import_sp, "// import '../widgets/location_prompt.dart'; removed")

btn_old = """            onTap: () {
              // L'utilisateur doit accepter le mode éclaireur !
              showLocationPrompt(context, () {
                setState(() {
                  _isSearchMode = false;
                  _selectedItinerary = itinerary;
                });
                _setSelectedLine(null); // Désélectionner la ligne simple si active
                _fitMapToItinerary(itinerary);
              });
            },"""
btn_new = """            onTap: () {
              // Appliquer l'itinéraire (il est déjà Eclaireur)
              setState(() {
                _isSearchMode = false;
                _selectedItinerary = itinerary;
              });
              _setSelectedLine(null); // Désélectionner la ligne simple si active
              _fitMapToItinerary(itinerary);
            },"""
content = content.replace(btn_old, btn_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'w') as f:
    f.write(content)
