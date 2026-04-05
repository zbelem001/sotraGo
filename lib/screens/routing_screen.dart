import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/sotraco_line.dart';
import '../services/routing_service.dart';
import '../services/geocoding_service.dart';

class RoutingScreen extends StatefulWidget {
  final LatLng currentLocation;
  final List<SotracoLine> allLines;

  const RoutingScreen({
    super.key,
    required this.currentLocation,
    required this.allLines,
  });

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen> {
  final RoutingService _routingService = RoutingService();
  final GeocodingService _geocodingService = GeocodingService();

  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocusNode = FocusNode();

  LatLng? _selectedDestination;
  List<Itinerary> _foundRoutes = [];

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _destController.dispose();
    _destFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isSearching = true);

      try {
        final results = await _geocodingService.searchPlaces(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Veuillez activer votre connexion Internet pour chercher un lieu.",
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _calculateRoute() async {
    if (_selectedDestination == null) return;

    var routes = await _routingService.findRoutes(
      widget.currentLocation,
      _selectedDestination!,
      widget.allLines,
    );

    setState(() {
      _foundRoutes = routes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Barre de recherche style VTC (Yango/Uber)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        // Champ Départ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.my_location,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Ma position actuelle",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Champ Arrivée
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _destController,
                                  focusNode: _destFocusNode,
                                  decoration: const InputDecoration(
                                    hintText:
                                        "Où allez-vous ? (ex: SIAO, Gounghin...)",
                                    border: InputBorder.none,
                                  ),
                                  onChanged: _onSearchChanged,
                                ),
                              ),
                              if (_destController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _destController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _foundRoutes = [];
                                      _selectedDestination = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Corps : Résultats de recherche OU propositions d'itinéraires
            Expanded(
              child: _searchResults.isNotEmpty || _isSearching
                  ? _buildSearchResults()
                  : _buildRouteResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.place, color: Colors.white),
          ),
          title: Text(
            place['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            place['details'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            _destFocusNode.unfocus();
            _destController.text = place['name'];
            setState(() {
              _selectedDestination = place['location'];
              _searchResults = [];
            });
            _calculateRoute();
          },
        );
      },
    );
  }

  Widget _buildRouteResults() {
    if (_selectedDestination == null) {
      // Écran par défaut quand rien n'est cherché
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Recherchez un lieu pour trouver un bus",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_foundRoutes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "Aucun trajet direct trouvé vers cette destination.\nEssayez de vous rapprocher d'un grand axe ou d'augmenter votre périmètre de marche.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _foundRoutes.length,
      itemBuilder: (context, index) {
        var itinerary = _foundRoutes[index];
        var segment = itinerary.segments.first; // MVP 1 trajet direct

        String lineTitle = segment.line.name.isNotEmpty
            ? segment.line.name
                  .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
                  .replaceAll(RegExp(r'➔|→|->'), '↔')
            : 'Ligne ${segment.line.lineNumber}';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => Navigator.pop(context, itinerary),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Prendre la\n$lineTitle",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "${itinerary.estimatedTime.toStringAsFixed(0)} min",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Marcher ${itinerary.totalWalkingDistance.toStringAsFixed(0)}m",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${itinerary.totalCost} FCFA",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.trip_origin,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "De: ${segment.boardStop.name}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "À: ${segment.alightStop.name}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
