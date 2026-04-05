with open("lib/screens/map_screen.dart", "r") as f:
    content = f.read()

patch = """
  void resetToAllLines() {
    setState(() {
      _isSearchMode = false;
      _destController.clear();
      _searchResults = [];
      _selectedItinerary = null;
      _foundRoutes = [];
      _selectedDestination = null;
    });
    _setSelectedLine(null);
    _fitMapToAllLines();
  }
"""

content = content.replace("  final LayerHitNotifier", patch + "\n  final LayerHitNotifier")

with open("lib/screens/map_screen.dart", "w") as f:
    f.write(content)
