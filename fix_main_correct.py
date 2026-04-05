import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/main.dart', 'r') as f:
    text = f.read()

text = text.replace("import 'services/socket_service.dart';\\nimport 'services/location_service.dart';", "import 'services/socket_service.dart';\nimport 'services/location_service.dart';")

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/main.dart', 'w') as f:
    f.write(text)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/home_screen.dart', 'r') as f:
    txt = f.read()

txt = txt.replace("import 'main_screen.dart';\\nimport '../services/location_service.dart';", "import 'main_screen.dart';\nimport '../services/location_service.dart';")

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/home_screen.dart', 'w') as f:
    f.write(txt)

