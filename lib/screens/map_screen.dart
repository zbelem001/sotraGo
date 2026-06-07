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
import 'lines_screen.dart';
import 'leaderboard_screen.dart';
import '../services/socket_service.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS  –  transposed from UrbanGo HTML design system
// ─────────────────────────────────────────────────────────────────────────────
class _D {
  // ── Palette (from tailwind config) ────────────────────────────────────────
  static const Color bg = Color(0xFF0E1322); // background
  static const Color surface = Color(0xFF0E1322); // surface
  static const Color surfaceCard = Color(0xFF131929); // surface-card
  static const Color surfaceInput = Color(0xFF1A2540); // surface-input
  static const Color surfaceContainer = Color(0xFF1A1F2F);
  static const Color surfaceContainerHigh = Color(0xFF25293A);
  static const Color surfaceVariant = Color(0xFF2F3445);
  static const Color borderSubtle = Color(0xFF1E2D4A);
  static const Color outlineVariant = Color(0xFF3B4A44);
  static const Color onSurface = Color(0xFFDEE1F7); // on-surface
  static const Color onSurfaceVar = Color(0xFFBACAC2); // on-surface-variant
  static const Color textPrimary = Color(0xFFF0F4FF);
  // Accent mint (primary in HTML)
  static const Color mint = Color(0xFF46F1C5);
  static const Color mintDim = Color(0xFF28DFB5);
  static const Color mintContainer = Color(0xFF00D4AA);
  // Secondary amber
  static const Color amber = Color(0xFFFFB955);
  // Tertiary blue
  static const Color blue = Color(0xFFC7D7FF);
  // Status
  static const Color success = Color(0xFF2ECC8A);
  static const Color error = Color(0xFFFF5A5F);

  // ── Glassmorphism helper ──────────────────────────────────────────────────
  static Color glassBg = const Color(0xFF0D1326).withOpacity(0.85);

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 20;
  static const double rFull = 999;

  // ── Typography ─────────────────────────────────────────────────────────────
  // Headline – Syne weight
  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Syne',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );
  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Syne',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  // Body – DM Sans
  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: onSurface,
    height: 1.5,
  );
  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurface,
    height: 1.5,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: onSurfaceVar,
    height: 1.5,
  );
  // Mono – JetBrains Mono (labels, prices, tags)
  static const TextStyle labelMono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: onSurfaceVar,
  );
  static const TextStyle priceLg = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: mint,
    letterSpacing: -0.2,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get mintGlow => [
    BoxShadow(
      color: mint.withOpacity(0.25),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 24,
      offset: const Offset(0, -6),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAP SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  final String? initialLineNumber;
  const MapScreen({super.key, this.initialLineNumber});

  @override
  State<MapScreen> createState() => MapScreenState();
}

bool _hasShownInfoBubble = false;

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
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

  void resetToAllLines() {
    setState(() {
      _isSearchMode = false;
      _destController.clear();
      _searchResults = [];
      _selectedItinerary = null;
      _foundRoutes = [];
      _selectedDestination = null;
    });
    _setSelectedLine(null);
    _fitMapToAllLines();
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

  final Map<String, Map<String, dynamic>> _activeBuses = {};
  bool _isScouting = false;
  bool _isSatelliteView = true;
  StreamSubscription<Position>? _positionStream;

  // Bottom sheet animation
  late AnimationController _sheetCtrl;
  late Animation<double> _sheetAnim;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _sheetAnim = CurvedAnimation(
      parent: _sheetCtrl,
      curve: Curves.easeOutCubic,
    );
    _sheetCtrl.forward();

    _loadBusData();
    _checkLocationPermission();
    SocketService().socket.on('busLocationUpdated', _onBusLocationUpdated);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _mapController.move(_ouagaCenter, 13.5);
    });

    if (!_hasShownInfoBubble) {
      _showInfoBubble = true;
      _hasShownInfoBubble = true;
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showInfoBubble = false);
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
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _onBusLocationUpdated(dynamic data) {
    if (mounted)
      setState(() {
        _activeBuses[data['deviceId'] as String] = {
          'lat': data['lat'],
          'lng': data['lng'],
          'timestamp': data['timestamp'],
        };
      });
  }

  void _setSelectedLine(SotracoLine? line) {
    setState(() {
      _selectedLine = line;
      _activeBuses.clear();
      if (line != null) {
        SocketService().socket.emit('subscribeToLine', {
          'line': line.lineNumber,
        });
      }
    });
  }

  Future<void> _toggleScoutingMode() async {
    setState(() => _isScouting = !_isScouting);
    if (_isScouting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🕵️‍♂️ Mode Éclaireur ACTIVÉ !"),
          backgroundColor: _D.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_D.rMd),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 30,
            ),
          ).listen((Position position) {
            if (!mounted) return;
            setState(
              () => _currentLocation = LatLng(
                position.latitude,
                position.longitude,
              ),
            );
            if (_selectedLine != null) {
              SocketService().sendLocationUpdate(
                _selectedLine!.lineNumber,
                position.latitude,
                position.longitude,
              );
            } else if (_selectedItinerary != null) {
              for (var segment in _selectedItinerary!.segments) {
                SocketService().sendLocationUpdate(
                  segment.line.lineNumber,
                  position.latitude,
                  position.longitude,
                );
                break;
              }
            }
          });
    } else {
      _positionStream?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🛑 Mode Éclaireur DÉSACTIVÉ."),
          backgroundColor: _D.amber.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_D.rMd),
          ),
        ),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _isLocating = false;
      });
    } catch (e) {
      debugPrint("Erreur GPS: $e");
      setState(() => _isLocating = false);
    }
  }

  String _normalizeString(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    String n = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      n = n.replaceAll(withDia[i].toLowerCase(), withoutDia[i].toLowerCase());
    }
    return n;
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
    final nq = _normalizeString(query);
    List<Map<String, dynamic>> local = [];
    final Set<String> added = {};
    for (var line in _allLines) {
      for (var stop in line.stops) {
        if (stop.name.isEmpty) continue;
        if (_normalizeString(stop.name).contains(nq) &&
            !added.contains(stop.name)) {
          added.add(stop.name);
          local.add({
            'name': stop.name,
            'details': 'Arrêt Ligne ${line.lineNumber} (${line.name})',
            'location': stop.location,
            'is_local': true,
          });
        }
      }
    }
    setState(() => _searchResults = local.take(8).toList());
    if (query.length >= 3) {
      _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
        setState(() => _isSearchingPlace = true);
        try {
          final osmResults = await _geocodingService.searchPlaces(query);
          if (mounted)
            setState(() {
              var merged = List<Map<String, dynamic>>.from(_searchResults);
              for (var r in osmResults) {
                if (!merged.any(
                  (e) =>
                      _normalizeString(e['name']) ==
                      _normalizeString(r['name']),
                )) {
                  r['is_local'] = false;
                  merged.add(r);
                }
              }
              _searchResults = merged;
              _isSearchingPlace = false;
            });
        } catch (e) {
          if (mounted) setState(() => _isSearchingPlace = false);
        }
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_selectedDestination == null || _currentLocation == null) return;
    final routes = await _routingService.findRoutes(
      _currentLocation!,
      _selectedDestination!,
      _allLines,
    );
    setState(() => _foundRoutes = routes);
  }

  Color _getColorForLine(String lineNumber) {
    const colors = [
      Color(0xFF46F1C5),
      Color(0xFFFFB955),
      Color(0xFFC7D7FF),
      Color(0xFFFF7B54),
      Color(0xFF2ECC8A),
      Color(0xFFFF5A5F),
      Color(0xFF64B5F6),
      Color(0xFFCE93D8),
      Color(0xFFFFEB3B),
    ];
    return colors[lineNumber.hashCode.abs() % colors.length];
  }

  Future<void> _loadBusData() async {
    try {
      final raw = await ApiService().fetchLinesData();
      final list = (json.decode(raw) as List<dynamic>);
      final lines = list
          .map((d) => SotracoLine.fromJson(d))
          .where((l) => l.routeSegments.isNotEmpty)
          .toList();
      setState(() {
        _allLines = lines;
        _isLoading = false;
      });
      SotracoLine? match;
      if (widget.initialLineNumber != null) {
        try {
          match = _allLines.firstWhere(
            (l) => l.lineNumber == widget.initialLineNumber,
          );
        } catch (_) {}
      }
      _setSelectedLine(match);
      if (_selectedLine != null) _fitMapToSelectedLine();
    } catch (e) {
      debugPrint("Erreur chargement: $e");
      setState(() => _isLoading = false);
    }
  }

  void _fitMapToAllLines() {
    if (_allLines.isEmpty) return;
    final pts = _allLines
        .expand((l) => l.routeSegments.expand((s) => s))
        .toList();
    if (pts.isNotEmpty) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(pts),
            padding: const EdgeInsets.all(40),
          ),
        ),
      );
    }
  }

  void _fitMapToSelectedLine() {
    if (_selectedLine == null || _selectedLine!.routeSegments.isEmpty) {
      _fitMapToAllLines();
      return;
    }
    final pts = _selectedLine!.routeSegments.expand((s) => s).toList();
    if (pts.isNotEmpty) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(pts),
            padding: const EdgeInsets.all(60),
          ),
        ),
      );
    }
  }

  void _fitMapToItinerary(Itinerary itinerary) {
    List<LatLng> pts = [];
    if (_currentLocation != null) pts.add(_currentLocation!);
    for (var seg in itinerary.segments) {
      pts.addAll(seg.line.routeSegments.expand((s) => s));
    }
    if (pts.isNotEmpty) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(pts),
            padding: const EdgeInsets.all(60),
          ),
        ),
      );
    }
  }

  void _showPricingInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PricingSheet(),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String tileUrl = _isSatelliteView
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

    // ── Build polylines & markers ──────────────────────────────────────────
    final List<Polyline<String>> polylinesUnsel = [];
    final List<Polyline<String>> polylinesSel = [];
    final List<Marker> markers = [];

    if (_selectedItinerary != null) {
      final c = _getColorForLine(
        _selectedItinerary!.segments.first.line.lineNumber,
      );
      if (_selectedItinerary!.geometry != null) {
        polylinesSel.add(
          Polyline<String>(
            points: _selectedItinerary!.geometry!,
            color: _D.mint,
            strokeWidth: 5,
          ),
        );
      }
      for (var seg in _selectedItinerary!.segments) {
        polylinesSel.addAll(
          seg.line.routeSegments.map(
            (s) => Polyline<String>(points: s, color: c, strokeWidth: 4.5),
          ),
        );
        int idxB = seg.line.stops.indexOf(seg.boardStop);
        int idxA = seg.line.stops.indexOf(seg.alightStop);
        if (idxB != -1 && idxA != -1) {
          int s = idxB < idxA ? idxB : idxA;
          int e = idxB < idxA ? idxA : idxB;
          for (int i = s + 1; i < e; i++) {
            markers.add(
              Marker(
                point: seg.line.stops[i].location,
                width: 16,
                height: 16,
                child: _StopDot(color: c, small: true),
              ),
            );
          }
        }
        markers.add(
          Marker(
            point: seg.boardStop.location,
            width: 32,
            height: 32,
            child: _MapBadge(icon: Icons.directions_walk, color: _D.success),
          ),
        );
        markers.add(
          Marker(
            point: seg.alightStop.location,
            width: 32,
            height: 32,
            child: _MapBadge(icon: Icons.place_rounded, color: _D.error),
          ),
        );
      }
      if (_currentLocation != null && _selectedItinerary!.segments.isNotEmpty) {
        final calc = const Distance();
        double d1 = calc
            .as(
              LengthUnit.Meter,
              _selectedItinerary!.startLocation,
              _selectedItinerary!.segments.first.boardStop.location,
            )
            .toDouble();
        if (d1 > 10) {
          polylinesSel.add(
            Polyline<String>(
              points: [
                _selectedItinerary!.startLocation,
                _selectedItinerary!.segments.first.boardStop.location,
              ],
              color: _D.onSurfaceVar,
              strokeWidth: 2.5,
              pattern: StrokePattern.dashed(segments: const [8, 8]),
            ),
          );
        }
        double d2 = calc
            .as(
              LengthUnit.Meter,
              _selectedItinerary!.segments.last.alightStop.location,
              _selectedItinerary!.endLocation,
            )
            .toDouble();
        if (d2 > 10) {
          polylinesSel.add(
            Polyline<String>(
              points: [
                _selectedItinerary!.segments.last.alightStop.location,
                _selectedItinerary!.endLocation,
              ],
              color: _D.onSurfaceVar,
              strokeWidth: 2.5,
              pattern: StrokePattern.dashed(segments: const [8, 8]),
            ),
          );
          markers.add(
            Marker(
              point: _selectedItinerary!.endLocation,
              width: 40,
              height: 40,
              child: _MapBadge(icon: Icons.flag_rounded, color: _D.blue),
            ),
          );
        }
      }
    } else {
      for (var line in _allLines) {
        final isSel = _selectedLine?.lineNumber == line.lineNumber;
        final isNone = _selectedLine == null;
        final c = _getColorForLine(line.lineNumber);
        final color = isNone ? c : (isSel ? c : Colors.grey.withAlpha(180));
        final width = isNone ? 2.5 : (isSel ? 5.0 : 1.5);
        final list = isSel ? polylinesSel : polylinesUnsel;

        list.addAll(
          line.routeSegments.map(
            (s) => Polyline<String>(
              points: s,
              color: color,
              strokeWidth: width,
              hitValue: line.lineNumber,
            ),
          ),
        );

        if (isSel) {
          // Label on line
          if (line.routeSegments.isNotEmpty) {
            var longest = line.routeSegments.fold<List<LatLng>>(
              line.routeSegments.first,
              (prev, s) => s.length > prev.length ? s : prev,
            );
            if (longest.isNotEmpty) {
              final mid = longest[longest.length ~/ 2];
              final name =
                  (line.name.isNotEmpty
                          ? line.name
                          : 'Ligne ${line.lineNumber}')
                      .replaceAll(
                        RegExp(r'Terminus ', caseSensitive: false),
                        '',
                      )
                      .replaceAll(RegExp(r'➔|→|->'), '↔');
              markers.add(
                Marker(
                  point: mid,
                  width: 180,
                  height: 56,
                  alignment: Alignment.topCenter,
                  child: _LineLabel(name: name, color: c),
                ),
              );
            }
          }
          // Stops
          for (int i = 0; i < line.stops.length; i++) {
            final s = line.stops[i];
            if (i > 0 && i < line.stops.length - 1) {
              markers.add(
                Marker(
                  point: s.location,
                  width: 14,
                  height: 14,
                  child: _StopDot(color: c, small: false),
                ),
              );
            }
          }
          if (line.stops.isNotEmpty) {
            markers.add(
              Marker(
                point: line.stops.first.location,
                width: 28,
                height: 28,
                child: _MapBadge(
                  icon: Icons.radio_button_checked_rounded,
                  color: _D.success,
                ),
              ),
            );
            markers.add(
              Marker(
                point: line.stops.last.location,
                width: 28,
                height: 28,
                child: _MapBadge(icon: Icons.flag_rounded, color: _D.error),
              ),
            );
          }
        }
      }
    }

    // Live buses
    for (var bus in _activeBuses.values) {
      markers.add(
        Marker(
          point: LatLng(bus['lat'], bus['lng']),
          width: 40,
          height: 40,
          child: _LiveBusMarker(),
        ),
      );
    }

    // Current position
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: _MyLocationDot(),
        ),
      );
    }

    final polylines = [...polylinesUnsel, ...polylinesSel];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // ── Map ──────────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _ouagaCenter,
                initialZoom: 13.5,
                maxZoom: 18.0,
                minZoom: 11.0,
                onTap: (_, __) {
                  if (_selectedLine != null) _setSelectedLine(null);
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.moovfaso.app',
                ),
                if (polylines.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final hits = _hitNotifier.value?.hitValues;
                      if (hits != null && hits.isNotEmpty) {
                        try {
                          final line = _allLines.firstWhere(
                            (l) => l.lineNumber == hits.first,
                          );
                          setState(() => _selectedLine = line);
                          _fitMapToSelectedLine();
                        } catch (_) {}
                      } else {
                        setState(() => _selectedLine = null);
                        _fitMapToAllLines();
                      }
                    },
                    child: PolylineLayer<String>(
                      polylines: polylines,
                      hitNotifier: _hitNotifier,
                      simplificationTolerance: 0.4,
                    ),
                  ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),

            // ── Search bar (top, glass) ──────────────────────────────────
            if (!_isSearchMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                child: _GlassSearchBar(
                  onTap: () {
                    if (_currentLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Position en cours de détection…'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _isSearchMode = true;
                      _selectedItinerary = null;
                    });
                    _setSelectedLine(null);
                    _destFocusNode.requestFocus();
                  },
                ),
              ),

            // ── Info bubble ──────────────────────────────────────────────
            if (_showInfoBubble &&
                _selectedLine == null &&
                _selectedItinerary == null &&
                !_isSearchMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 20,
                right: 20,
                child: _InfoBubble(
                  onClose: () => setState(() => _showInfoBubble = false),
                ),
              ),

            // ── Full-screen search overlay ───────────────────────────────
            if (_isSearchMode)
              _SearchOverlay(
                destController: _destController,
                destFocusNode: _destFocusNode,
                searchResults: _searchResults,
                isSearching: _isSearchingPlace,
                foundRoutes: _foundRoutes,
                selectedDest: _selectedDestination,
                onBack: () => setState(() {
                  _isSearchMode = false;
                  _destController.clear();
                  _searchResults = [];
                  _foundRoutes = [];
                  _selectedDestination = null;
                }),
                onSearchChanged: _onSearchChanged,
                onClear: () {
                  _destController.clear();
                  setState(() {
                    _searchResults = [];
                    _foundRoutes = [];
                    _selectedDestination = null;
                  });
                },
                onPlaceSelected: (place) {
                  _destFocusNode.unfocus();
                  _destController.text = place['name'];
                  setState(() {
                    _selectedDestination = place['location'];
                    _searchResults = [];
                  });
                  _calculateRoute();
                },
                onRouteSelected: (itinerary) {
                  setState(() {
                    _isSearchMode = false;
                    _selectedItinerary = itinerary;
                    _selectedLine = null;
                  });
                  _fitMapToItinerary(itinerary);
                },
              ),

            // ── Loading ──────────────────────────────────────────────────
            if (_isLoading) Center(child: _LoadingCard()),

            // ── Itinerary bottom card ────────────────────────────────────
            if (_selectedItinerary != null && !_isSearchMode)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ItineraryCard(
                  itinerary: _selectedItinerary!,
                  onClose: () => setState(() => _selectedItinerary = null),
                ),
              ),

            // ── FAB column (right side) ──────────────────────────────────
            if (!_isSearchMode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                bottom: _selectedItinerary != null ? 360 : 100,
                right: 20,
                child: _FabColumn(
                  selectedLine: _selectedLine,
                  selectedItinerary: _selectedItinerary,
                  isSatellite: _isSatelliteView,
                  isLocating: _isLocating,
                  isScouting: _isScouting,
                  onDetails: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LinesScreen(
                        initialLineNumber: _selectedLine!.lineNumber,
                      ),
                    ),
                  ),
                  onRoute: () {
                    if (_currentLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Position en cours…')),
                      );
                      return;
                    }
                    setState(() {
                      _isSearchMode = true;
                      _selectedItinerary = null;
                    });
                    _setSelectedLine(null);
                    _destFocusNode.requestFocus();
                  },
                  onMapType: () =>
                      setState(() => _isSatelliteView = !_isSatelliteView),
                  onLocation: () {
                    if (_currentLocation != null) {
                      _mapController.move(
                        _currentLocation!,
                        _mapController.camera.zoom,
                      );
                    } else {
                      _getCurrentLocation();
                    }
                  },
                  onPricing: () => _showPricingInfo(context),
                  onScout: _toggleScoutingMode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLASS SEARCH BAR  (top of map)
// ─────────────────────────────────────────────────────────────────────────────
class _GlassSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_D.rLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _D.surfaceInput.withOpacity(0.90),
              borderRadius: BorderRadius.circular(_D.rLg),
              border: Border.all(color: _D.borderSubtle, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _D.mint, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Où allez-vous ? (ex: Zogona, SIAO)',
                    style: _D.bodyMd.copyWith(color: _D.onSurfaceVar),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _D.surfaceContainer,
                    borderRadius: BorderRadius.circular(_D.rSm),
                    border: Border.all(
                      color: _D.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _D.onSurfaceVar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INFO BUBBLE  (hint toast)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoBubble extends StatelessWidget {
  final VoidCallback onClose;
  const _InfoBubble({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _D.mint,
        borderRadius: BorderRadius.circular(_D.rMd),
        boxShadow: _D.mintGlow,
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: _D.bg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Appuyez sur une ligne pour voir ses détails",
              style: _D.bodySm.copyWith(
                color: _D.bg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, color: _D.bg, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCH OVERLAY  (full-screen)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchOverlay extends StatelessWidget {
  final TextEditingController destController;
  final FocusNode destFocusNode;
  final List<Map<String, dynamic>> searchResults;
  final bool isSearching;
  final List<Itinerary> foundRoutes;
  final LatLng? selectedDest;
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final ValueChanged<Map<String, dynamic>> onPlaceSelected;
  final ValueChanged<Itinerary> onRouteSelected;

  const _SearchOverlay({
    required this.destController,
    required this.destFocusNode,
    required this.searchResults,
    required this.isSearching,
    required this.foundRoutes,
    required this.selectedDest,
    required this.onBack,
    required this.onSearchChanged,
    required this.onClear,
    required this.onPlaceSelected,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: _D.bg.withOpacity(0.8),
          child: SafeArea(
            child: Column(
              children: [
                // ── Search input row ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _D.onSurface,
                        ),
                        onPressed: onBack,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _D.surfaceInput.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(_D.rLg),
                            border: Border.all(color: _D.mint.withOpacity(0.4)),
                          ),
                          child: TextField(
                            controller: destController,
                            focusNode: destFocusNode,
                            style: _D.bodyMd.copyWith(color: _D.textPrimary),
                            cursorColor: _D.mint,
                            decoration: InputDecoration(
                              hintText: 'Où allez-vous ? (ex: Zogona, SIAO)',
                              hintStyle: _D.bodyMd.copyWith(
                                color: _D.onSurfaceVar,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: _D.mint,
                                size: 20,
                              ),
                              suffixIcon: destController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: _D.onSurfaceVar,
                                      ),
                                      onPressed: onClear,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                            ),
                            onChanged: onSearchChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Results ───────────────────────────────────────────────
                Expanded(
                  child: searchResults.isNotEmpty || isSearching
                      ? _SearchResultsList(
                          results: searchResults,
                          isLoading: isSearching,
                          onSelect: onPlaceSelected,
                        )
                      : _RouteResultsList(
                          routes: foundRoutes,
                          selectedDest: selectedDest,
                          hasQuery: destController.text.isNotEmpty,
                          onSelect: onRouteSelected,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCH RESULTS LIST
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _SearchResultsList({
    required this.results,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _D.mint, strokeWidth: 2),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: results.length + (isLoading ? 1 : 0),
      separatorBuilder: (_, __) =>
          Divider(color: _D.outlineVariant.withOpacity(0.3), height: 1),
      itemBuilder: (_, i) {
        if (i == results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _D.mint,
                ),
              ),
            ),
          );
        }
        final p = results[i];
        final isLocal = p['is_local'] == true;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 0,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isLocal
                  ? _D.mint.withOpacity(0.12)
                  : _D.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocal ? Icons.directions_bus_rounded : Icons.place_rounded,
              color: isLocal ? _D.mint : _D.onSurfaceVar,
              size: 20,
            ),
          ),
          title: Text(
            p['name'],
            style: _D.bodyMd.copyWith(
              color: _D.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            p['details'],
            style: _D.bodySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onSelect(p),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTE RESULTS LIST
// ─────────────────────────────────────────────────────────────────────────────
class _RouteResultsList extends StatelessWidget {
  final List<Itinerary> routes;
  final LatLng? selectedDest;
  final bool hasQuery;
  final ValueChanged<Itinerary> onSelect;
  const _RouteResultsList({
    required this.routes,
    required this.selectedDest,
    required this.hasQuery,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDest == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _D.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: _D.borderSubtle),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                size: 32,
                color: _D.mint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recherchez une destination',
              style: _D.bodyMd.copyWith(color: _D.onSurfaceVar),
            ),
            const SizedBox(height: 6),
            Text('pour trouver le bus le plus proche', style: _D.bodySm),
          ],
        ),
      );
    }

    if (routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "Aucun trajet direct trouvé.\nEssayez de vous rapprocher d'un grand axe.",
            textAlign: TextAlign.center,
            style: _D.bodyMd.copyWith(color: _D.onSurfaceVar),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: routes.length,
      itemBuilder: (_, i) =>
          _RouteCard(itinerary: routes[i], onSelect: () => onSelect(routes[i])),
    );
  }
}

// ── Route result card ─────────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback onSelect;
  const _RouteCard({required this.itinerary, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final seg = itinerary.segments.first;
    final title =
        (seg.line.name.isNotEmpty
                ? seg.line.name
                : 'Ligne ${seg.line.lineNumber}')
            .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
            .replaceAll(RegExp(r'➔|→|->'), '↔');

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _D.surfaceCard,
          borderRadius: BorderRadius.circular(_D.rXl),
          border: Border.all(color: _D.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: bus badge + name + duration
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _D.mint.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _D.mint.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: _D.mint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prendre la', style: _D.bodySm),
                      Text(
                        title,
                        style: _D.bodyMd.copyWith(
                          color: _D.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${itinerary.estimatedTime.toStringAsFixed(0)} min',
                  style: _D.priceLg.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: _D.outlineVariant.withOpacity(0.4), height: 1),
            const SizedBox(height: 12),
            // Row 2: walk + cost
            Row(
              children: [
                _TagChip(
                  icon: Icons.directions_walk_rounded,
                  label:
                      '${(itinerary.totalWalkingDistance / 1000).toStringAsFixed(1)} km',
                  color: _D.onSurfaceVar,
                ),
                const SizedBox(width: 10),
                _TagChip(
                  icon: Icons.payments_outlined,
                  label: '${itinerary.totalCost} FCFA',
                  color: _D.amber,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stops
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 13, color: _D.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${seg.boardStop.name}',
                    style: _D.bodySm.copyWith(color: _D.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 13, color: _D.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${seg.alightStop.name}',
                    style: _D.bodySm.copyWith(color: _D.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ITINERARY BOTTOM CARD  (glass sheet anchored to bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback onClose;
  const _ItineraryCard({required this.itinerary, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final seg = itinerary.segments.first;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _D.glassBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: _D.outlineVariant.withOpacity(0.5)),
            ),
            boxShadow: _D.cardShadow,
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 95),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _D.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prendre la ${seg.line.name}',
                      style: _D.headlineMd.copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _D.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _D.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _D.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Board / Alight
              _StopRow(
                icon: Icons.trip_origin,
                color: _D.success,
                label: 'Monter à',
                value: seg.boardStop.name,
              ),
              const SizedBox(height: 8),
              _StopRow(
                icon: Icons.place_rounded,
                color: _D.error,
                label: 'Descendre à',
                value: seg.alightStop.name,
              ),
              const SizedBox(height: 16),
              // Stats row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _D.surfaceContainer,
                  borderRadius: BorderRadius.circular(_D.rMd),
                  border: Border.all(color: _D.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      icon: Icons.timer_outlined,
                      value:
                          '${itinerary.estimatedTime.toStringAsFixed(0)} min',
                      color: _D.mint,
                    ),
                    _VerticalDivider(),
                    _StatItem(
                      icon: Icons.directions_walk_rounded,
                      value:
                          '${(itinerary.totalWalkingDistance / 1000).toStringAsFixed(1)} km',
                      color: _D.blue,
                    ),
                    _VerticalDivider(),
                    _StatItem(
                      icon: Icons.payments_outlined,
                      value: '${itinerary.totalCost} FCFA',
                      color: _D.amber,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StopRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text('$label : ', style: _D.bodySm),
        Expanded(
          child: Text(
            value,
            style: _D.bodySm.copyWith(
              color: _D.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value, style: _D.labelMono.copyWith(color: color, fontSize: 12)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: _D.outlineVariant.withOpacity(0.4),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  FAB COLUMN
// ─────────────────────────────────────────────────────────────────────────────
class _FabColumn extends StatelessWidget {
  final SotracoLine? selectedLine;
  final Itinerary? selectedItinerary;
  final bool isSatellite, isLocating, isScouting;
  final VoidCallback onDetails,
      onRoute,
      onMapType,
      onLocation,
      onPricing,
      onScout;
  const _FabColumn({
    required this.selectedLine,
    required this.selectedItinerary,
    required this.isSatellite,
    required this.isLocating,
    required this.isScouting,
    required this.onDetails,
    required this.onRoute,
    required this.onMapType,
    required this.onLocation,
    required this.onPricing,
    required this.onScout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Context button: Details
        if (selectedLine != null && selectedItinerary == null) ...[
          _Fab(
            icon: Icons.info_outline_rounded,
            color: _D.mint,
            onTap: onDetails,
            tooltip: 'Détails',
          ),
          const SizedBox(height: 12),
        ],
        // Scout mode
        _Fab(
          icon: isScouting ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          color: isScouting ? _D.mint : _D.onSurfaceVar,
          onTap: onScout,
          glowing: isScouting,
          tooltip: 'Éclaireur',
        ),
        const SizedBox(height: 12),
        // Map type
        _Fab(
          icon: isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
          color: isSatellite ? _D.blue : _D.success,
          onTap: onMapType,
          tooltip: 'Vue',
        ),
        const SizedBox(height: 12),
        // Location
        _Fab(
          icon: Icons.my_location_rounded,
          color: _D.mint,
          onTap: onLocation,
          loading: isLocating,
          tooltip: 'Ma position',
        ),
        const SizedBox(height: 12),
        // Pricing
        _Fab(
          icon: Icons.payments_outlined,
          color: _D.amber,
          onTap: onPricing,
          tooltip: 'Tarifs',
        ),
      ],
    );
  }
}

class _Fab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;
  final bool glowing;
  final String tooltip;
  const _Fab({
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
    this.glowing = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: glowing ? color.withOpacity(0.15) : _D.surfaceCard,
            shape: BoxShape.circle,
            border: Border.all(
              color: glowing
                  ? color.withOpacity(0.5)
                  : _D.outlineVariant.withOpacity(0.4),
            ),
            boxShadow: glowing
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRICING BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PricingSheet extends StatelessWidget {
  const _PricingSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _D.glassBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: _D.outlineVariant.withOpacity(0.5)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _D.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: _D.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text('Tarifs & Abonnements', style: _D.headlineMd),
                ],
              ),
              const SizedBox(height: 20),
              ...[
                (
                  'Ticket à la course',
                  '200 FCFA',
                  Icons.confirmation_number_rounded,
                ),
                (
                  'Abonnement hebdomadaire',
                  '1 000 FCFA',
                  Icons.view_week_rounded,
                ),
                (
                  'Abonnement mensuel',
                  '3 000 FCFA',
                  Icons.calendar_month_rounded,
                ),
                (
                  'Abonnement annuel',
                  '35 000 FCFA',
                  Icons.event_available_rounded,
                ),
              ].map(
                (row) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _D.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              row.$3,
                              size: 18,
                              color: _D.onSurfaceVar,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              row.$1,
                              style: _D.bodyMd.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            row.$2,
                            style: _D.labelMono.copyWith(
                              color: _D.success,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: _D.outlineVariant.withOpacity(0.3),
                      height: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _D.mint,
                    foregroundColor: _D.bg,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_D.rMd),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Fermer',
                    style: _D.bodyMd.copyWith(
                      color: _D.bg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAP MARKER HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _StopDot extends StatelessWidget {
  final Color color;
  final bool small;
  const _StopDot({required this.color, required this.small});

  @override
  Widget build(BuildContext context) {
    final size = small ? 8.0 : 12.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(small ? 0.4 : 0.9),
        shape: BoxShape.circle,
        border: small ? null : Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _D.bg.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _LineLabel extends StatelessWidget {
  final String name;
  final Color color;
  const _LineLabel({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(_D.rSm),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 8),
            ],
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(width: 2, height: 20, color: color),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
      ],
    );
  }
}

class _LiveBusMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _D.surfaceCard,
        shape: BoxShape.circle,
        border: Border.all(color: _D.mint, width: 2),
        boxShadow: [
          BoxShadow(
            color: _D.mint.withOpacity(0.4),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.directions_bus_rounded, color: _D.mint, size: 22),
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _D.surfaceCard,
        borderRadius: BorderRadius.circular(_D.rXl),
        border: Border.all(color: _D.borderSubtle),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: _D.mint, strokeWidth: 2),
          ),
          const SizedBox(height: 14),
          Text(
            'Chargement du réseau…',
            style: _D.bodyMd.copyWith(color: _D.onSurfaceVar),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TagChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_D.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(label, style: _D.labelMono.copyWith(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
