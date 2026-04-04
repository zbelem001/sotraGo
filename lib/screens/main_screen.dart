import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'auth_screen.dart';
import 'lines_screen.dart';
import 'events_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      MapScreen(initialLineNumber: widget.initialMapLine),
      const LinesScreen(),
      const EventsScreen(),
      const AuthScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      // Si l'utilisateur retourne sur la carte, on la réinitialise à l'état par défaut
      if (index == 0 && _currentIndex != 0) {
        _pages[0] = MapScreen(key: UniqueKey());
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

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
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
