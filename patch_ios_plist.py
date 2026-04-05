with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/ios/Runner/Info.plist', 'r') as f:
    content = f.read()

new_keys = """<key>UIApplicationSupportsIndirectInputEvents</key>
        <true/>
        <key>NSLocationWhenInUseUsageDescription</key>
        <string>Cette application utilise votre position pour suivre les bus en temps réel et afficher votre emplacement sur la carte.</string>
        <key>NSLocationAlwaysUsageDescription</key>
        <string>Cette application requiert votre position en arrière-plan pour continuer à transmettre les mouvements du bus lorsque vous êtes en route.</string>"""

content = content.replace("<key>UIApplicationSupportsIndirectInputEvents</key>\n        <true/>", new_keys)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/ios/Runner/Info.plist', 'w') as f:
    f.write(content)
