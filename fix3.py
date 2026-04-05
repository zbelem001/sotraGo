import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'r') as f:
    content = f.read()

map_code = """            onTap: () {
              // L'utilisateur doit accepter le mode éclaireur !
              showLocationPrompt(context, () {
                setState(() {
                  _isSearchMode = false;
                  _selectedItinerary = itinerary;
                  _selectedLine =
                      null; // Désélectionner la ligne simple si active
                });
                _fitMapToItinerary(itinerary);
              });
            },"""
map_new = """            onTap: () {
              setState(() {
                _isSearchMode = false;
                _selectedItinerary = itinerary;
                _selectedLine = null; // Désélectionner la ligne simple si active
              });
              _fitMapToItinerary(itinerary);
            },"""
content = content.replace(map_code, map_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'w') as f:
    f.write(content)
