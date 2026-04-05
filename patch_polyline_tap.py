import sys

with open('lib/screens/map_screen.dart', 'r') as f:
    content = f.read()

old_block = """                  GestureDetector(
                    onTap: () {
                      final hitValues = _hitNotifier.value?.hitValues;
                      if (hitValues != null && hitValues.isNotEmpty) {
                        String tappedLineNumber = hitValues.first;
                        var line = _allLines.firstWhere(
                          (l) => l.lineNumber == tappedLineNumber,
                        );
                        setState(() {
                          _selectedLine = line;
                        });
                        _fitMapToSelectedLine();
                      } else {
                        // Click in an empty area: unselect all
                        setState(() {
                          _selectedLine = null;
                        });
                        _fitMapToAllLines();
                      }
                    },"""

new_block = """                  GestureDetector(
                    onTap: () {
                      final hitValues = _hitNotifier.value?.hitValues;
                      if (hitValues != null && hitValues.isNotEmpty) {
                        String tappedLineNumber = hitValues.first;
                        var line = _allLines.firstWhere(
                          (l) => l.lineNumber == tappedLineNumber,
                        );
                        showLocationPrompt(context, () {
                          setState(() {
                            _selectedLine = line;
                          });
                          _fitMapToSelectedLine();
                        });
                      } else {
                        // Click in an empty area: unselect all
                        setState(() {
                          _selectedLine = null;
                        });
                        _fitMapToAllLines();
                      }
                    },"""

if old_block in content:
    content = content.replace(old_block, new_block)
    with open('lib/screens/map_screen.dart', 'w') as f:
        f.write(content)
    print("Success: Polyline tap updated")
else:
    print("Error: Block not found")

