import re

with open('lib/screens/home_screen.dart', 'r+') as f:
    text = f.read()

    # 1. Update Dialog
    text = text.replace('À propos de Sorré', 'À propos de SotraGO')
    text = text.replace('Bienvenue sur Sorré', 'Bienvenue sur SotraGO')

    # 2. Update the Hero header
    # Replace the plain text "Sira" with a Row containing the logo and "SotraGO"
    hero_pattern = r'Row\(\s*mainAxisAlignment:\s*MainAxisAlignment\.spaceBetween,\s*children:\s*\[\s*const Text\(\s*"Sira",\s*style:\s*TextStyle\([^\)]*\),\s*\),'
    
    new_hero = """Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 40,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "SotraGO",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),"""
                            
    text = re.sub(hero_pattern, new_hero, text)
    
    f.seek(0)
    f.write(text)
    f.truncate()
