with open("lib/screens/main_screen.dart", "r") as f:
    text = f.read()

old_code = """    setState(() {
      // On ne réinitialise plus la map complètement par une nouvelle UniqueKey()
      // pour que le GlobalKey soit conservé et pour garder une fluidité,
      // MAIS on peut éventuellement appeler une méthode pour nettoyer la carte.
      // Ou on recree la carte avec le même key si on veut tout reset sauf la key: Non, une GlobalKey est unique.
      _currentIndex = index;
    });"""

new_code = """    if (index == 1 && _currentIndex != 1) {
      _mapKey.currentState?.resetToAllLines();
    }

    setState(() {
      _currentIndex = index;
    });"""

text = text.replace(old_code, new_code)

with open("lib/screens/main_screen.dart", "w") as f:
    f.write(text)
