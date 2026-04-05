import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/main.dart', 'r') as f:
    content = f.read()

import_old = "import 'services/socket_service.dart';"
import_new = "import 'services/socket_service.dart';\nimport 'services/location_service.dart';"
content = content.replace(import_old, import_new)

main_old = """void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService().initSocket(); // Initialisation du socket AVANT l'interface MapScreen
  runApp(const SiraApp());
}"""
main_new = """void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService().initSocket(); // Initialisation du socket AVANT l'interface MapScreen
  await LocationService().init(); // Charger l'état persistant du mode éclaireur
  runApp(const SiraApp());
}"""
content = content.replace(main_old, main_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/main.dart', 'w') as f:
    f.write(content)
