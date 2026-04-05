import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'r') as f:
    text = f.read()

# Replace block 1 (Around line 1099)
block_1 = """                      setState(() {
                        _isSearchMode = true;
                        _selectedItinerary = null; // Cacher l'itinéraire précédent pendant la recherche
                        _selectedLine = null; // Désélectionner toute ligne également
                      });
                      _destFocusNode.requestFocus();"""
block_new = """                      setState(() {
                        _isSearchMode = true;
                        _selectedItinerary = null; // Cacher l'itinéraire précédent pendant la recherche
                      });
                      _setSelectedLine(null); // Nettoie bien la ligne ET les bus éventuels
                      _destFocusNode.requestFocus();"""
text = text.replace(block_1, block_new)

# Notice it was replaced in both places exactly with block_1 string because block_new from previous script replaced block_2 string too!
# So replacing it again globally will fix both!

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'w') as f:
    f.write(text)

