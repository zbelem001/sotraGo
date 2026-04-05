import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'r') as f:
    text = f.read()

# Replace block 1 (Around line 1100)
block_1 = """                      setState(() {
                        _isSearchMode = true;
                      });
                      _destFocusNode.requestFocus();"""
block_new = """                      setState(() {
                        _isSearchMode = true;
                        _selectedItinerary = null; // Cacher l'itinéraire précédent pendant la recherche
                        _selectedLine = null; // Désélectionner toute ligne également
                      });
                      _destFocusNode.requestFocus();"""
text = text.replace(block_1, block_new)

# Replace block 2 (Around line 1538)
block_2 = """              setState(() {
                _isSearchMode = true;
              });
              _destFocusNode.requestFocus();"""
text = text.replace(block_2, block_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'w') as f:
    f.write(text)

