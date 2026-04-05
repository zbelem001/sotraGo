import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'r') as f:
    text = f.read()

text = text.replace("    );\n  }\n}", "    );\n    );\n  }\n}") # closing PopScope -> );

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/map_screen.dart', 'w') as f:
    f.write(text)

