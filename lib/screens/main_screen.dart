import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'home_screen.dart';
import 'lines_screen.dart';
import 'events_screen.dart';
import '../services/location_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialMapLine;

  const MainScreen({super.key, this.initialIndex = 0, this.initialMapLine});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late List<Widget> _pages;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const HomeScreen(),
      MapScreen(key: _mapKey, initialLineNumber: widget.initialMapLine),
      const LinesScreen(),
      const EventsScreen(),
    ];
  }

  void _onTabTapped(int index) {
    // Si on veut aller sur la map (1) ou les lignes (2) et que le mode éclaireur est désactivé
    if ((index == 1 || index == 2) && !LocationService().isScoutModeEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez activer le Mode Éclaireur sur l'accueil pour accéder à la carte et aux lignes.",
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      // On ne réinitialise plus la map complètement par une nouvelle UniqueKey()
      // pour que le GlobalKey soit conservé et pour garder une fluidité,
      // MAIS on peut éventuellement appeler une méthode pour nettoyer la carte.
      // Ou on recree la carte avec le même key si on veut tout reset sauf la key: Non, une GlobalKey est unique.
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
    );
  }
}
