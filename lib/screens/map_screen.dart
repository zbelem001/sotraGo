import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../models/sotraco_line.dart';
import '../services/routing_service.dart';
import '../services/geocoding_service.dart';
import '../services/api_service.dart';
// // // removed removed removed
import 'lines_screen.dart';
import 'leaderboard_screen.dart';
import '../services/socket_service.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  final String? initialLineNumber;
  const MapScreen({super.key, this.initialLineNumber});

  @override
  State<MapScreen> createState() => MapScreenState();
}

bool _hasShownInfoBubble = false;

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  bool get hasSubState =>
      _isSearchMode ||
      _selectedItinerary != null ||
      _selectedLine != null ||
      _foundRoutes.isNotEmpty;

  void handleBack() {
    if (_isSearchMode) {
      setState(() {
        _isSearchMode = false;
        _destController.clear();
        _searchResults = [];
      });
    } else if (_selectedItinerary != null || _foundRoutes.isNotEmpty) {
      setState(() {
        _selectedItinerary = null;
        _foundRoutes = [];
        _destController.clear();
      });
    } else if (_selectedLine != null) {
      _setSelectedLine(null);
      _fitMapToAllLines();
    }
  }

  final LayerHitNotifier<String> _hitNotifier = ValueNotifier(null);
  final LatLng _ouagaCenter = const LatLng(12.3714, -1.5197);

  List<SotracoLine> _allLines = [];
  SotracoLine? _selectedLine;
  Itinerary? _selectedItinerary;
  bool _isLoading = true;
  LatLng? _currentLocation;
  bool _isLocating = false;
  bool _showInfoBubble = false;

  bool _isSearchMode = false;
  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocusNode = FocusNode();
  final RoutingService _routingService = RoutingService();
  final GeocodingService _geocodingService = GeocodingService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchingPlace = false;
  Timer? _searchDebounce;
  List<Itinerary> _foundRoutes = [];
  LatLng? _selectedDestination;

  // -- Tracking Temps Réel --
  final Map<String, Map<String, dynamic>> _activeBuses = {};

  bool _isScouting = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadBusData();
    _checkLocationPermission();

    // Écouter le temps réel
    SocketService().socket.on('busLocationUpdated', _onBusLocationUpdated);

    if (!_hasShownInfoBubble) {
      _showInfoBubble = true;
      _hasShownInfoBubble = true;
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _showInfoBubble = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    SocketService().socket.off('busLocationUpdated', _onBusLocationUpdated);
    _destController.dispose();
    _destFocusNode.dispose();
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _onBusLocationUpdated(dynamic data) {
    if (mounted) {
      setState(() {
        String deviceId = data['deviceId'];
        _activeBuses[deviceId] = {
          'lat': data['lat'],
          'lng': data['lng'],
          'timestamp': data['timestamp'],
        };
      });
    }
  }

  void _setSelectedLine(SotracoLine? line) {
    setState(() {
      _selectedLine = line;
      _activeBuses.clear(); // On nettoie les anciens bus

      if (line != null) {
        SocketService().socket.emit('subscribeToLine', {
          'line': line.lineNumber,
        });
      }
    });
  }

  Future<void> _toggleScoutingMode() async {
    setState(() {
      _isScouting = !_isScouting;
    });

    if (_isScouting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "🕵️‍♂️ Mode Éclaireur ACTIVÉ ! Partage sécurisé et gagnant.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // On utilise le mode "Platform specific" pour le stream avec pings écodynamiques
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter:
                  30, // Filtre : n'émettre un ping que si déplacement > 30 mètres !
            ),
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentLocation = LatLng(
                  position.latitude,
                  position.longitude,
                );
              });

              // 🧠 L'IA "Zéro friction"
              // Dès que le GPS bouge, le téléphone envoie la position UNIQUEMENT s'il est sûr
              // de sa ligne actuelle, soit parce qu'elle est sélectionnée manuellement,
              // soit déduite du calcul d'itinéraire.

              if (_selectedLine != null) {
                SocketService().sendLocationUpdate(
                  _selectedLine!.lineNumber,
                  position.latitude,
                  position.longitude,
                );
              } else if (_selectedItinerary != null) {
                for (var segment in _selectedItinerary!.segments) {
                  // Les segments sont vos arrêts/lignes
                  SocketService().sendLocationUpdate(
                    segment.line.lineNumber,
                    position.latitude,
                    position.longitude,
                  );
                  break; // On ne broadcast que pour le premier bus du trajet pour l'instant
                }
              }
            }
          });
    } else {
      _positionStream?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🛑 Mode Éclaireur DÉSACTIVÉ."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });

      // Optionnel: Centrer la carte sur l'utilisateur
      // _mapController.move(_currentLocation!, 15.0);
    } catch (e) {
      debugPrint("Erreur géolocalisation: $e");
      setState(() => _isLocating = false);
    }
  }

  String _normalizeString(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    String normalized = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      normalized = normalized.replaceAll(
        withDia[i].toLowerCase(),
        withoutDia[i].toLowerCase(),
      );
    }
    return normalized;
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearchingPlace = false;
      });
      return;
    }

    // 1. Recherche locale immédiate au fil de la frappe (Arrêts connus SOTRACO)
    String normalizedQuery = _normalizeString(query);
    List<Map<String, dynamic>> localResults = [];
    Set<String> addedStops = {};

    for (var line in _allLines) {
      for (var stop in line.stops) {
        if (stop.name.isEmpty) continue;

        String normalizedStop = _normalizeString(stop.name);

        if (normalizedStop.contains(normalizedQuery) &&
            !addedStops.contains(stop.name)) {
          addedStops.add(stop.name);
          localResults.add({
            'name': stop.name,
            'details': 'Arrêt Ligne ${line.lineNumber} (${line.name})',
            'location': stop.location,
            'is_local': true,
          });
        }
      }
    }

    // Limiter les propositions locales pour ne pas inonder l'écran
    localResults = localResults.take(8).toList();

    setState(() {
      _searchResults = localResults;
    });

    // 2. Si l'utilisateur a tapé au moins 3 caractères, on lance ou prolonge la recherche globale OSM
    if (query.length >= 3) {
      _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
        setState(() => _isSearchingPlace = true);

        try {
          final osmResults = await _geocodingService.searchPlaces(query);
          if (mounted) {
            setState(() {
              // Fusionner les résultats sans doublons parfaits de nom
              var allMerged = [
                ..._searchResults,
              ]; // On part des résultats locaux ou déjà mergés
              for (var result in osmResults) {
                String osmNormalized = _normalizeString(result['name']);

                // Ne pas écraser les arrêts locaux avec des doublons globaux
                bool alreadyExists = allMerged.any(
                  (existing) =>
                      _normalizeString(existing['name']) == osmNormalized,
                );

                if (!alreadyExists) {
                  result['is_local'] = false;
                  allMerged.add(result);
                }
              }
              _searchResults = allMerged;
              _isSearchingPlace = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isSearchingPlace = false);
            // L'erreur silencieuse est préférable si on a déjà des résultats locaux
          }
        }
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_selectedDestination == null || _currentLocation == null) return;
    var routes = await _routingService.findRoutes(
      _currentLocation!,
      _selectedDestination!,
      _allLines,
    );
    setState(() {
      _foundRoutes = routes;
    });
  }

  Color _getColorForLine(String lineNumber) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.cyan,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.deepOrange,
      Colors.lime,
    ];
    return colors[lineNumber.hashCode.abs() % colors.length];
  }

  Future<void> _loadBusData() async {
    try {
      final String jsonString = await ApiService().fetchLinesData();
      final List<dynamic> jsonList = json.decode(jsonString);

      List<SotracoLine> lines = jsonList
          .map((data) => SotracoLine.fromJson(data))
          .where((line) => line.routeSegments.isNotEmpty)
          .toList();

      setState(() {
        _allLines = lines;
        _isLoading = false;
      });

      SotracoLine? matchedLine;
      if (widget.initialLineNumber != null) {
        try {
          matchedLine = _allLines.firstWhere(
            (line) => line.lineNumber == widget.initialLineNumber,
          );
        } catch (_) {}
      }
      _setSelectedLine(matchedLine);

      if (_selectedLine != null) {
        _fitMapToSelectedLine();
      } else {
        _fitMapToAllLines();
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des données SOTRACO: $e");
      setState(() => _isLoading = false);
    }
  }

  void _fitMapToAllLines() {
    if (_allLines.isEmpty) return;

    List<LatLng> allPoints = [];
    for (var line in _allLines) {
      for (var segment in line.routeSegments) {
        allPoints.addAll(segment);
      }
    }

    if (allPoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(allPoints);
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
        );
      });
    }
  }

  void _fitMapToSelectedLine() {
    if (_selectedLine == null || _selectedLine!.routeSegments.isEmpty) {
      _fitMapToAllLines();
      return;
    }

    // Extraire tous les points pour recentrer la carte globalement
    List<LatLng> allPoints = [];
    for (var segment in _selectedLine!.routeSegments) {
      allPoints.addAll(segment);
    }

    if (allPoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(allPoints);
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
        );
      });
    }
  }

  void _fitMapToItinerary(Itinerary itinerary) {
    List<LatLng> allPoints = [];
    if (_currentLocation != null) allPoints.add(_currentLocation!);

    for (var segment in itinerary.segments) {
      for (var routeSegment in segment.line.routeSegments) {
        allPoints.addAll(routeSegment);
      }
    }

    if (allPoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(allPoints);
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
        );
      });
    }
  }

  void _showPricingInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.payments_outlined, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tarifs & Abonnements SOTRACO",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPricingRow(
              context,
              "Ticket à la course",
              "200 FCFA",
              Icons.confirmation_number,
            ),
            const Divider(),
            _buildPricingRow(
              context,
              "Abonnement hebdomadaire",
              "1 000 FCFA",
              Icons.view_week,
            ),
            const Divider(),
            _buildPricingRow(
              context,
              "Abonnement mensuel",
              "3 000 FCFA",
              Icons.calendar_month,
            ),
            const Divider(),
            _buildPricingRow(
              context,
              "Abonnement annuel",
              "35 000 FCFA",
              Icons.event_available,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Fermer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(
    BuildContext context,
    String title,
    String price,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    // List des polylines (lignes sur la carte)
    final List<Polyline<String>> _polylinesUnselected = [];
    final List<Polyline<String>> _polylinesSelected = [];
    final List<Marker> markers = [];

    // --- LOGIC TO GATHER POLYLINES & MARKERS ---
    if (_selectedItinerary != null) {
      Color c = _getColorForLine(
        _selectedItinerary!.segments.first.line.lineNumber,
      );

      // Si le backend nous fournit la géométrie précise, l'utiliser :
      if (_selectedItinerary!.geometry != null) {
        _polylinesSelected.add(
          Polyline<String>(
            points: _selectedItinerary!.geometry!,
            color: Colors.green,
            strokeWidth: 5.0,
          ),
        );
      }

      // Tracer chaque segment du trajet en bus
      for (var segment in _selectedItinerary!.segments) {
        _polylinesSelected.addAll(
          segment.line.routeSegments.map(
            (s) => Polyline<String>(points: s, color: c, strokeWidth: 4.5),
          ),
        );

        // Ajouter les arrêts intermédiaires de la ligne pour ce segment
        int idxBoard = segment.line.stops.indexOf(segment.boardStop);
        int idxAlight = segment.line.stops.indexOf(segment.alightStop);

        if (idxBoard != -1 && idxAlight != -1) {
          int startIdx = idxBoard < idxAlight ? idxBoard : idxAlight;
          int endIdx = idxBoard < idxAlight ? idxAlight : idxBoard;

          for (int i = startIdx + 1; i < endIdx; i++) {
            markers.add(
              Marker(
                point: segment.line.stops[i].location,
                width: 16,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: c, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }
        }

        // Ajouter les marqueurs pour les arrêts de montée et descente
        markers.add(
          Marker(
            point: segment.boardStop.location,
            width: 30,
            height: 30,
            child: const Icon(
              Icons.directions_walk,
              color: Colors.green,
              size: 30,
            ),
          ),
        );
        markers.add(
          Marker(
            point: segment.alightStop.location,
            width: 30,
            height: 30,
            child: const Icon(Icons.location_on, color: Colors.red, size: 30),
          ),
        );
      }

      // Tracer les lignes pointillées (marche à pied)
      if (_currentLocation != null && _selectedItinerary!.segments.isNotEmpty) {
        _polylinesSelected.add(
          Polyline<String>(
            points: [
              _selectedItinerary!.startLocation,
              _selectedItinerary!.segments.first.boardStop.location,
            ],
            color: Colors.grey,
            strokeWidth: 3.0,
            pattern: StrokePattern.dashed(segments: const [10, 10]),
          ),
        );

        _polylinesSelected.add(
          Polyline<String>(
            points: [
              _selectedItinerary!.segments.last.alightStop.location,
              _selectedItinerary!.endLocation,
            ],
            color: Colors.grey,
            strokeWidth: 3.0,
            pattern: StrokePattern.dashed(segments: const [10, 10]),
          ),
        );

        // Marqueur final de la destination
        markers.add(
          Marker(
            point: _selectedItinerary!.endLocation,
            width: 40,
            height: 40,
            child: const Icon(Icons.flag, color: Colors.blue, size: 40),
          ),
        );
      }
    } else {
      // DESSINER TOUTE LES LIGNES
      for (var line in _allLines) {
        bool isSelected =
            _selectedLine != null &&
            _selectedLine!.lineNumber == line.lineNumber;
        bool isNoneSelected = _selectedLine == null;

        Color baseColor = _getColorForLine(line.lineNumber);
        Color c = isNoneSelected
            ? baseColor
            : (isSelected ? baseColor : Colors.grey.withAlpha(200));
        double width = isNoneSelected ? 2.5 : (isSelected ? 4.5 : 1.5);

        var polylinesList = isSelected
            ? _polylinesSelected
            : _polylinesUnselected;

        polylinesList.addAll(
          line.routeSegments.map(
            (s) => Polyline<String>(
              points: s,
              color: c,
              strokeWidth: width,
              hitValue: line.lineNumber,
            ),
          ),
        );

        // Afficher le nom de la ligne s'il y a un composant principal.
        // Affiché tout le temps, sauf si une AUTRE ligne est sélectionnée.
        if (isSelected) {
          if (line.routeSegments.isNotEmpty) {
            List<LatLng> longestSegment = line.routeSegments.first;
            for (var seg in line.routeSegments) {
              if (seg.length > longestSegment.length) {
                longestSegment = seg;
              }
            }

            if (longestSegment.isNotEmpty) {
              var midPoint = longestSegment[longestSegment.length ~/ 2];

              String displayName = line.name.isNotEmpty
                  ? line.name
                        .replaceAll(
                          RegExp(r'Terminus ', caseSensitive: false),
                          '',
                        )
                        .replaceAll(RegExp(r'➔|→|->'), '↔')
                  : "Ligne ${line.lineNumber}";

              // Estimer la largeur en fonction de la taille du texte
              double estimatedWidth = displayName.length * 8.0 + 16.0;

              markers.add(
                Marker(
                  point: midPoint,
                  width: estimatedWidth > 200 ? 200 : estimatedWidth,
                  height: 60, // Augmenté pour la ligne de liaison
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          displayName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Trait fin de liaison
                      Container(
                        width: 2,
                        height: 25, // Longueur du trait
                        color: c,
                      ),
                      // Petit point d'ancrage sur la ligne
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: c, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }

        // Afficher les points d'arrêts QUE si elle est cliquée !
        if (isSelected) {
          // Points depart/arrivee & arrets
          for (int i = 0; i < line.stops.length; i++) {
            var stop = line.stops[i];
            if (i > 0 && i < line.stops.length - 1) {
              markers.add(
                Marker(
                  point: stop.location,
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: c, width: 3),
                    ),
                  ),
                ),
              );
            }
          }
          if (line.stops.isNotEmpty) {
            markers.add(
              Marker(
                point: line.stops.first.location,
                width: 24,
                height: 24,
                child: const Icon(Icons.location_on, color: Colors.green),
              ),
            );
            markers.add(
              Marker(
                point: line.stops.last.location,
                width: 24,
                height: 24,
                child: const Icon(Icons.flag, color: Colors.red),
              ),
            );
          }
        }
      }
    }

    final List<Polyline<String>> polylinesToDraw = [
      ..._polylinesUnselected,
      ..._polylinesSelected,
    ];

    // DESSINER LES BUS EN DIRECT (MODE ECLAIREUR / COMMUNITY)
    for (var bus in _activeBuses.values) {
      markers.add(
        Marker(
          point: LatLng(bus['lat'], bus['lng']),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(blurRadius: 10, color: Colors.blue.withOpacity(0.5)),
              ],
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.directions_bus, color: Colors.blue, size: 24),
            ),
          ),
        ),
      );
    }

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_selectedItinerary != null) {
      var seg = _selectedItinerary!.segments.first;
      markers.add(
        Marker(
          point: seg.boardStop.location,
          width: 30,
          height: 30,
          child: const Icon(
            Icons.directions_walk,
            color: Colors.green,
            size: 30,
          ),
        ),
      );
      markers.add(
        Marker(
          point: seg.alightStop.location,
          width: 30,
          height: 30,
          child: const Icon(Icons.directions_bus, color: Colors.red, size: 30),
        ),
      );
    }
    // --- END LOGIC ---
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ouagaCenter,
              initialZoom: 13.5,
              maxZoom: 18.0,
              minZoom: 11.0,
              onTap: (_, __) {
                // Deselect when clicking on the map background
                if (_selectedLine != null) {
                  _setSelectedLine(null);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.sotraco.sira',
              ),

              if (polylinesToDraw.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    final hitValues = _hitNotifier.value?.hitValues;
                    if (hitValues != null && hitValues.isNotEmpty) {
                      String tappedLineNumber = hitValues.first;
                      var line = _allLines.firstWhere(
                        (l) => l.lineNumber == tappedLineNumber,
                      );
                      setState(() {
                        _selectedLine = line;
                      });
                      _fitMapToSelectedLine();
                    } else {
                      // Click in an empty area: unselect all
                      setState(() {
                        _selectedLine = null;
                      });
                      _fitMapToAllLines();
                    }
                  },
                  child: PolylineLayer<String>(
                    polylines: polylinesToDraw,
                    hitNotifier: _hitNotifier,
                    simplificationTolerance: 0.4,
                  ),
                ),

              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),

          // ... (Le reste de l'UI est identique)
          if (_selectedItinerary == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildPredictiveSearchBar(),
            ),

          if (_selectedItinerary != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'close_itinerary',
                backgroundColor: Colors.white,
                mini: true,
                onPressed: () => setState(() => _selectedItinerary = null),
                child: const Icon(Icons.close, color: Colors.black),
              ),
            ),

          if (_showInfoBubble &&
              _selectedLine == null &&
              _selectedItinerary == null &&
              !_isSearchMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Material(
                color: AppColors.primary,
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Appuyez sur une ligne sur la carte pour voir ses détails !",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _showInfoBubble = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isSearchMode) _buildSearchOverlay(isDark),

          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSlate : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text("Chargement du réseau SOTRACO..."),
                  ],
                ),
              ),
            ),

          if (_selectedItinerary != null)
            Positioned(
              bottom: 120,
              left: 16,
              right: 80, // Laisse de la place pour les FABs
              child: Card(
                color: isDark ? AppColors.darkSlate : Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Prendre la ${_selectedItinerary!.segments.first.line.name}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Monter à : ${_selectedItinerary!.segments.first.boardStop.name}",
                      ),
                      Text(
                        "Descendre à : ${_selectedItinerary!.segments.first.alightStop.name}",
                      ),
                      const Divider(),
                      Text(
                        "⏳ ${_selectedItinerary!.estimatedTime.toStringAsFixed(0)} min  |  🚶 ${(_selectedItinerary!.totalWalkingDistance / 1000).toStringAsFixed(1)} km  |  💰 ${_selectedItinerary!.totalCost} FCFA",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 120,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Bouton Détails (si ligne sélectionnée) ou Itinéraire
                if (_selectedLine != null && _selectedItinerary == null)
                  FloatingActionButton.extended(
                    heroTag: 'details_btn',
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    label: const Text(
                      'Détails',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LinesScreen(
                            initialLineNumber: _selectedLine!.lineNumber,
                          ),
                        ),
                      );
                    },
                  )
                else
                  FloatingActionButton(
                    heroTag: 'route_btn',
                    backgroundColor: Colors.green.shade600,
                    child: const Icon(Icons.directions, color: Colors.white),
                    onPressed: () {
                      if (_currentLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Veuillez patienter, obtention de votre position...',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _isSearchMode = true;
                        _selectedItinerary =
                            null; // Cacher l'itinéraire précédent pendant la recherche
                      });
                      _setSelectedLine(
                        null,
                      ); // Nettoie bien la ligne ET les bus éventuels
                      _destFocusNode.requestFocus();
                    },
                  ),
                const SizedBox(height: 16),
                // Bouton Ma position
                FloatingActionButton(
                  heroTag: 'location_btn',
                  backgroundColor: AppColors.primary,
                  child: _isLocating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                  onPressed: () {
                    if (_currentLocation != null) {
                      _mapController.move(
                        _currentLocation!,
                        _mapController.camera.zoom,
                      );
                    } else {
                      _getCurrentLocation();
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Bouton Tarifs et abonnements
                FloatingActionButton(
                  heroTag: 'pricing_btn',
                  backgroundColor: isDark ? AppColors.darkSlate : Colors.white,
                  child: const Icon(Icons.payments, color: Colors.green),
                  onPressed: () {
                    _showPricingInfo(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(bool isDark) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
          child: SafeArea(
            child: Column(
              children: [
                // Header: Barre de destination uniquement, identique au design original
                Container(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 4,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _isSearchMode = false;
                            _destController.clear();
                            _searchResults = [];
                            _foundRoutes = [];
                            _selectedDestination = null;
                          });
                        },
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkSlate : Colors.white)
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _destController,
                            focusNode: _destFocusNode,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Où allez-vous ? (ex: Zogona, SIAO)',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _destController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      onPressed: () {
                                        _destController.clear();
                                        setState(() {
                                          _searchResults = [];
                                          _foundRoutes = [];
                                          _selectedDestination = null;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Corps : Résultats de recherche OU propositions d'itinéraires
                Expanded(
                  child: _searchResults.isNotEmpty || _isSearchingPlace
                      ? _buildSearchResults()
                      : _buildRouteResults(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSearchingPlace && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length + (_isSearchingPlace ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        final place = _searchResults[index];
        final bool isLocal = place['is_local'] == true;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isLocal
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
            child: Icon(
              isLocal ? Icons.directions_bus : Icons.place,
              color: isLocal ? Colors.green : Colors.grey,
            ),
          ),
          title: Text(
            place['name'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            place['details'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontSize: 12,
            ),
          ),
          onTap: () {
            _destFocusNode.unfocus();
            _destController.text = place['name'];
            setState(() {
              _selectedDestination = place['location'];
              _searchResults = []; // On efface les résultats
            });
            _calculateRoute();
          },
        );
      },
    );
  }

  Widget _buildRouteResults() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_selectedDestination == null) {
      if (_destController.text.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Recherchez une destination pour trouver un bus",
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox(); // Attente debounce / recherche
      }
    }

    if (_foundRoutes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "Aucun trajet direct trouvé vers cette destination.\nEssayez de vous rapprocher d'un grand axe ou d'augmenter votre périmètre de marche.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
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

        Color cardColor = isDark ? Colors.grey[850]! : Colors.white;
        Color textColor = isDark ? Colors.white : Colors.black;
        Color subtleTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

        return Card(
          color: cardColor,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _isSearchMode = false;
                _selectedItinerary = itinerary;
                _selectedLine =
                    null; // Désélectionner la ligne simple si active
              });
              _fitMapToItinerary(itinerary);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Prendre la\n$lineTitle",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
                        "Marcher ${(itinerary.totalWalkingDistance / 1000).toStringAsFixed(1)} km",
                        style: TextStyle(color: subtleTextColor),
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
                        style: TextStyle(color: subtleTextColor),
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
                          style: TextStyle(color: textColor),
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
                          style: TextStyle(color: textColor),
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

  Widget _buildPredictiveSearchBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color glassColor = isDark
        ? AppColors.darkSlate.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);

    // Ne pas afficher la barre minimale si on est en mode recherche complet
    if (_isSearchMode) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            readOnly: true,
            onTap: () {
              if (_currentLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Veuillez patienter, obtention de votre position...',
                    ),
                  ),
                );
                return;
              }
              setState(() {
                _isSearchMode = true;
                _selectedItinerary =
                    null; // Cacher l'itinéraire précédent pendant la recherche
              });
              _setSelectedLine(
                null,
              ); // Nettoie bien la ligne ET les bus éventuels
              _destFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              hintText: 'Où allez-vous ? (ex: Zogona, SIAO)',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
