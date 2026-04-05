import re

with open('lib/screens/map_screen.dart', 'r+') as f:
    content = f.read()

    new_methods = """
  bool get hasSubState =>
      _isSearchMode ||
      _selectedItinerary != null ||
      _selectedLine != null ||
      _foundRoutes.isNotEmpty;

  void handleBack() {
    if (_isSearchMode) {
      setState(() {
        _isSearchMode = false;
        _destController.clear();
        _searchResults = [];
      });
    } else if (_selectedItinerary != null || _foundRoutes.isNotEmpty) {
      setState(() {
        _selectedItinerary = null;
        _foundRoutes = [];
        _destController.clear();
      });
    } else if (_selectedLine != null) {
      _setSelectedLine(null);
      _fitMapToAllLines();
    }
  }
"""
    content = re.sub(r'(final MapController _mapController = MapController\(\);)', r'\1\n' + new_methods, content, count=1)

    # Specific regex to remove the newly injected PopScope safely and replace with `return Scaffold(` but keep its closing paren out.
    # The PopScope is roughly matching:
    popscope_pattern = r'bool hasSubState =.*?return PopScope\([\s\S]*?child:\s*Scaffold\('
    content = re.sub(popscope_pattern, 'return Scaffold(', content)
    
    # We also need to remove the closing paren of PopScope that we manually added previously!
    # Wait, in the previous fix, I changed `), ), ); } Widget _buildSearchOverlay` to `), ), ); } Widget _buildSearchOverlay`. Wait, no.
    # Let's just do a string replacement for the end of the build method.
    f.seek(0)
    f.write(content)
    f.truncate()
