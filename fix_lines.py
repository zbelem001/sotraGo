import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/lines_screen.dart', 'r') as f:
    content = f.read()

import_sp = "import '../widgets/location_prompt.dart';"
content = content.replace(import_sp, "// removed")

lines_code = """                        onPressed: () {
                          showLocationPrompt(context, () {
                            // Démarre le tracking d'arrière-plan pour cette ligne (Mode Éclaireur)
                            LocationService().startScouting(line.lineNumber);
                            
                            // Navigate to map screen and show this line
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(
                                  initialIndex: 1,
                                  initialMapLine: line.lineNumber,
                                ),
                              ),
                              (route) => false,
                            );
                          });
                        },"""
lines_new = """                        onPressed: () {
                          if (LocationService().isScoutModeEnabled) {
                             LocationService().startScouting(line.lineNumber);
                          }
                          
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainScreen(
                                initialIndex: 1,
                                initialMapLine: line.lineNumber,
                              ),
                            ),
                            (route) => false,
                          );
                        },"""
content = content.replace(lines_code, lines_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/lines_screen.dart', 'w') as f:
    f.write(content)
