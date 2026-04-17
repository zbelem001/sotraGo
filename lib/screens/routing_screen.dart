import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/sotraco_line.dart';
import '../services/routing_service.dart';
import '../services/geocoding_service.dart';
import '../theme/app_colors.dart';

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

class _RoutingScreenState extends State<RoutingScreen>
    with SingleTickerProviderStateMixin {
  final RoutingService _routingService = RoutingService();
  final GeocodingService _geocodingService = GeocodingService();

  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocusNode = FocusNode();

  LatLng? _selectedDestination;
  List<Itinerary> _foundRoutes = [];

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isCalculating = false;
  Timer? _debounce;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _destController.dispose();
    _destFocusNode.dispose();
    _debounce?.cancel();
    _animController.dispose();
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

    setState(() => _isCalculating = true);

    var routes = await _routingService.findRoutes(
      widget.currentLocation,
      _selectedDestination!,
      widget.allLines,
    );

    setState(() {
      _foundRoutes = routes;
      _isCalculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              _buildHeader(isDark),

              // ── Body ─────────────────────────────────────────────────
              Expanded(
                child: _searchResults.isNotEmpty || _isSearching
                    ? _buildSearchResults(isDark)
                    : _buildRouteResults(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with search inputs ────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlate : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.grey.shade100,
            width: 1,
          ),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Input fields with timeline connector
          Expanded(
            child: Column(
              children: [
                // Departure field (static)
                _buildInputField(
                  isDark: isDark,
                  icon: Icons.my_location_rounded,
                  iconColor: Colors.blue,
                  child: Text(
                    "Ma position actuelle",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                // Connector line between fields
                Padding(
                  padding: const EdgeInsets.only(left: 18.0),
                  child: Row(
                    children: [
                      Container(
                        width: 1.5,
                        height: 10,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),

                // Destination field (interactive)
                _buildInputField(
                  isDark: isDark,
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.red,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _destController,
                          focusNode: _destFocusNode,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "Où allez-vous ? (SIAO, Gounghin...)",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_destController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _destController.clear();
                            setState(() {
                              _searchResults = [];
                              _foundRoutes = [];
                              _selectedDestination = null;
                            });
                          },
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── Search Results ────────────────────────────────────────────────────────
  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              "Recherche en cours...",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 64,
        color: isDark ? Colors.white12 : Colors.grey.shade100,
      ),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return InkWell(
          onTap: () {
            _destFocusNode.unfocus();
            _destController.text = place['name'];
            setState(() {
              _selectedDestination = place['location'];
              _searchResults = [];
            });
            _calculateRoute();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.place_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place['details'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.north_west_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Route Results ─────────────────────────────────────────────────────────
  Widget _buildRouteResults(bool isDark) {
    // Default empty state
    if (_selectedDestination == null) {
      return _buildIdleState(isDark);
    }

    // Calculating
    if (_isCalculating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              "Calcul de l'itinéraire...",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // No results
    if (_foundRoutes.isEmpty) {
      return _buildNoRouteState(isDark);
    }

    // Results
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _foundRoutes.length,
      itemBuilder: (context, index) {
        final itinerary = _foundRoutes[index];
        final segment = itinerary.segments.first;

        String lineTitle = segment.line.name.isNotEmpty
            ? segment.line.name
                  .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
                  .replaceAll(RegExp(r'➔|→|->'), '↔')
            : 'Ligne ${segment.line.lineNumber}';

        return _buildItineraryCard(
          context: context,
          isDark: isDark,
          itinerary: itinerary,
          segment: segment,
          lineTitle: lineTitle,
          index: index,
        );
      },
    );
  }

  // ── Itinerary Card ────────────────────────────────────────────────────────
  Widget _buildItineraryCard({
    required BuildContext context,
    required bool isDark,
    required Itinerary itinerary,
    required dynamic segment,
    required String lineTitle,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, itinerary),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSlate : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.grey.shade100,
            width: 1.2,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            // Top: Line info + time
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Bus icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prendre la ligne",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lineTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Duration badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${itinerary.estimatedTime.toStringAsFixed(0)} min",
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade100,
            ),

            // Bottom: Walking + cost + stops
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.directions_walk_rounded,
                        label:
                            "${itinerary.totalWalkingDistance.toStringAsFixed(0)} m à pied",
                        color: Colors.blue,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.payments_rounded,
                        label: "${itinerary.totalCost} FCFA",
                        color: Colors.orange,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stop timeline
                  _buildStopRow(
                    icon: Icons.trip_origin_rounded,
                    iconColor: Colors.green,
                    label: "Montez à",
                    value: segment.boardStop.name,
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 1.5,
                          height: 12,
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  ),
                  _buildStopRow(
                    icon: Icons.place_rounded,
                    iconColor: Colors.red,
                    label: "Descendez à",
                    value: segment.alightStop.name,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Tap to confirm hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Appuyez pour voir sur la carte",
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info chip ─────────────────────────────────────────────────────────────
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stop row with icon ────────────────────────────────────────────────────
  Widget _buildStopRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          "$label  ",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Idle State ────────────────────────────────────────────────────────────
  Widget _buildIdleState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Où voulez-vous aller ?",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tapez une destination pour trouver\nle bus le plus proche.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── No Route State ────────────────────────────────────────────────────────
  Widget _buildNoRouteState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_rounded,
                size: 38,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Aucun trajet trouvé",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Aucun trajet direct vers cette destination. Essayez de vous rapprocher d'un grand axe.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
