import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/main.dart', 'r') as f:
    text = f.read()

text = text.replace("import 'services/location_service.dart';", "")
text = text.replace("import 'services/socket_service.dart';", "import 'services/socket_service.dart';\\nimport 'services/location_service.dart';")

text = text.replace("""void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService()
      .initSocket(); // Initialisation du socket AVANT l'interface MapScreen
  runApp(const SiraApp());
}""", """void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService().initSocket(); 
  await LocationService().init();
  runApp(const SiraApp());
}""")

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/main.dart', 'w') as f:
    f.write(text)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/home_screen.dart', 'r') as f:
    txt = f.read()

txt = txt.replace("import '../services/location_service.dart';", "")
txt = txt.replace("import 'main_screen.dart';", "import 'main_screen.dart';\\nimport '../services/location_service.dart';")

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/home_screen.dart', 'w') as f:
    f.write(txt)

