import os

filepath = 'lib/screens/main_screen.dart'
with open(filepath, 'r') as f:
    text = f.read()

# On va supprimer la partie "if (_isLoading) { return Scaffold(..."
# Et à la place, ajouter un Stack dans le build pour overlay_isLoading

# Couper la méthode build actuelle
split_parts = text.split("  @override\n  Widget build(BuildContext context) {")
before_build = split_parts[0]
build_and_after = split_parts[1]

# Trouver le début du vrai return
return_pop_scope_index = build_and_after.find("return PopScope(")

new_build = """  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // L'interface principale (HomeScreen, etc.)
        PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) return;

            if (_currentIndex == 1) {
              final mapState = _mapKey.currentState;
              if (mapState != null && mapState.hasSubState) {
                mapState.handleBack();
                return; // Arrêt ici pour ne pas changer d'onglet
              }
            }

            // Si on n'est pas sur la carte, on y retourne (avec état par défaut)
            _onTabTapped(0);
          },
          child: Scaffold(
            extendBody: true, // Pour l'effet futuriste (la barre peut flotter)
            body: _pages[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    activeIcon: Icon(Icons.map),
                    label: 'Carte',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.directions_bus_outlined),
                    activeIcon: Icon(Icons.directions_bus),
                    label: 'Lignes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.campaign_outlined),
                    activeIcon: Icon(Icons.campaign),
                    label: 'Bons plans',
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Si ça charge, on affiche un voile transparent et le cercle de chargement
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6), // Voile noir semi-transparent
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Chargement des données en cours...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none, // Nécessaire car en dehors du Scaffold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
"""

with open(filepath, 'w') as f:
    f.write(before_build + new_build)
