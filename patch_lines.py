import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/lines_screen.dart', 'r') as f:
    content = f.read()

import_sp = "import '../widgets/location_prompt.dart';"
content = content.replace(import_sp, "// import '../widgets/location_prompt.dart'; removed")

btn_old = """                        child: ElevatedButton.icon(
                          onPressed: () {
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
btn_new = """                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Démarre le tracking d'arrière-plan avec la ligne s'il est éclaireur
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
                          },"""
content = content.replace(btn_old, btn_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/lines_screen.dart', 'w') as f:
    f.write(content)
