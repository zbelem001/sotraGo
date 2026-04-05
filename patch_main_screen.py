import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/main_screen.dart', 'r') as f:
    content = f.read()

import_old = "import 'events_screen.dart';"
import_new = "import 'events_screen.dart';\nimport '../services/location_service.dart';"
content = content.replace(import_old, import_new)

tap_old = """  void _onTabTapped(int index) {
    setState(() {
      // Si l'utilisateur retourne sur la carte, on la réinitialise à l'état par défaut
      if (index == 1 && _currentIndex != 1) {
        _pages[1] = MapScreen(key: UniqueKey());
      }
      _currentIndex = index;
    });
  }"""
tap_new = """  void _onTabTapped(int index) {
    // Si on veut aller sur la map (1) ou les lignes (2) et que le mode éclaireur est désactivé
    if ((index == 1 || index == 2) && !LocationService().isScoutModeEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez activer le Mode Éclaireur sur l'accueil pour accéder à la carte et aux lignes."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      // Si l'utilisateur retourne sur la carte, on la réinitialise à l'état par défaut
      if (index == 1 && _currentIndex != 1) {
        _pages[1] = MapScreen(key: UniqueKey());
      }
      _currentIndex = index;
    });
  }"""
content = content.replace(tap_old, tap_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/main_screen.dart', 'w') as f:
    f.write(content)
