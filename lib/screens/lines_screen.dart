import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/sotraco_line.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import '../services/location_service.dart';

class LinesScreen extends StatefulWidget {
  final String? initialLineNumber;
  const LinesScreen({super.key, this.initialLineNumber});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen>
    with SingleTickerProviderStateMixin {
  List<SotracoLine> _lines = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};
  String? _expandedLineNumber;

  String _selectedCity = "Tout";
  final List<String> _cities = [
    "Tout",
    "Favoris",
    "Ouagadougou",
    "Bobo-Dioulasso",
    "Koudougou",
    "Ouahigouya",
    "Dédougou",
    "Banfora",
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _expandedLineNumber = widget.initialLineNumber;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadLines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLines() async {
    try {
      final String jsonString = await ApiService().fetchLinesData();
      final List<dynamic> jsonList = json.decode(jsonString);

      setState(() {
        _lines = jsonList.map((data) => SotracoLine.fromJson(data)).toList();
        if (widget.initialLineNumber != null) {
          final index = _lines.indexWhere(
            (l) => l.lineNumber == widget.initialLineNumber,
          );
          if (index != -1) {
            final line = _lines.removeAt(index);
            _lines.insert(0, line);
          }
        }
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint("Erreur de chargement des lignes: $e");
      setState(() => _isLoading = false);
    }
  }

  List<SotracoLine> get _filteredLines {
    List<SotracoLine> result;
    if (_searchQuery.isEmpty) {
      result = List.from(_lines);
    } else {
      final query = _searchQuery.toLowerCase();
      result = _lines.where((line) {
        return line.lineNumber.toLowerCase().contains(query) ||
            line.name.toLowerCase().contains(query) ||
            line.departure.toLowerCase().contains(query) ||
            line.arrival.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCity != "Tout") {
      result = result.where((line) {
        if (_selectedCity == "Favoris") {
          return _favorites.contains(line.lineNumber);
        }
        String city = line.city.toLowerCase();
        String target = _selectedCity.toLowerCase();
        if (target == "ouagadougou") {
          return city.contains("ouaga") ||
              city.contains("koubri") ||
              city.trim().isEmpty;
        } else {
          return city.contains(target);
        }
      }).toList();
    }

    result.sort((a, b) {
      final aIsFav = _favorites.contains(a.lineNumber) ? 0 : 1;
      final bIsFav = _favorites.contains(b.lineNumber) ? 0 : 1;
      return aIsFav.compareTo(bIsFav);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Custom Header ──────────────────────────────────────────────
            _buildHeader(isDark),

            // ── Search Bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSearchBar(isDark),
            ),

            const SizedBox(height: 12),

            // ── City Filter Chips ──────────────────────────────────────────
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cities.length,
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  final isSelected = _selectedCity == city;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCity = city),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkSlate
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          city,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Lines List ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredLines.isEmpty
                  ? _buildEmptyState(isDark)
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: _filteredLines.length,
                        itemBuilder: (context, index) {
                          final line = _filteredLines[index];
                          return _buildLineCard(line, isDark);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lignes SOTRACO",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${_lines.length} lignes disponibles",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.route_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  "${_filteredLines.length}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Rechercher une ligne, un arrêt...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
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
            "Chargement des lignes...",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune ligne trouvée",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Essayez un autre terme de recherche",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Line Card ──────────────────────────────────────────────────────────────
  Widget _buildLineCard(SotracoLine line, bool isDark) {
    final mainStops = line.stops.where((s) => s.isMainStop).toList();
    final stopsToShow = mainStops.isNotEmpty ? mainStops : line.stops;

    final String cleanDeparture = line.departure
        .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
        .trim();
    final String cleanArrival = line.arrival
        .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
        .trim();

    final String cleanLineNumber = line.lineNumber
        .replaceAll(RegExp(r'Ligne\s*', caseSensitive: false), '')
        .trim();
    final String formattedTitle = "$cleanDeparture ↔ $cleanArrival";

    final bool isIntercommunal =
        line.lineNumber.toLowerCase().contains('lci') ||
        line.lineNumber.toLowerCase().contains('lic') ||
        line.name.toLowerCase().contains('inter');
    final int price = isIntercommunal ? 500 : 200;
    final int stopCount = stopsToShow.length;
    final bool isFav = _favorites.contains(line.lineNumber);
    final bool isExpanded = _expandedLineNumber == line.lineNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade100),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: isExpanded
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),

          // Expansion tile
          ExpansionTile(
            key: Key('${line.lineNumber}_${isExpanded}'),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedLineNumber = expanded ? line.lineNumber : null;
              });
            },
            tilePadding: const EdgeInsets.fromLTRB(20, 12, 48, 12),
            childrenPadding: EdgeInsets.zero,
            collapsedIconColor: Colors.grey.shade400,
            iconColor: AppColors.primary,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Ligne $cleanLineNumber",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  _buildBadge(
                    "$stopCount arrêts",
                    Colors.amber,
                    isDark,
                    Icons.radio_button_checked_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    "$price FCFA",
                    Colors.green,
                    isDark,
                    Icons.payments_rounded,
                  ),
                ],
              ),
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.03),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stops header
                    Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Principaux arrêts",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (stopsToShow.isEmpty)
                      Text(
                        "Aucun arrêt répertorié.",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),

                    // Stops list with timeline style
                    ...stopsToShow.asMap().entries.map((entry) {
                      final isFirst = entry.key == 0;
                      final isLast = entry.key == stopsToShow.length - 1;
                      final stop = entry.value;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline column
                            SizedBox(
                              width: 24,
                              child: Column(
                                children: [
                                  // Top line
                                  if (!isFirst)
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: 1.5,
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 4),
                                  // Dot
                                  Container(
                                    width: isFirst || isLast ? 10 : 7,
                                    height: isFirst || isLast ? 10 : 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isFirst || isLast
                                          ? AppColors.primary
                                          : AppColors.primary.withValues(
                                              alpha: 0.35,
                                            ),
                                      border: isFirst || isLast
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                  ),
                                  // Bottom line
                                  if (!isLast)
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: 1.5,
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Stop name
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                ),
                                child: Text(
                                  stop.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isFirst || isLast
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isFirst || isLast
                                        ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                        : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (LocationService().isScoutModeEnabled) {
                            LocationService().startScouting(line.lineNumber);
                          }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainScreen(
                                initialIndex: 1,
                                initialMapLine: line.lineNumber,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text(
                          "Voir sur la carte",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Favorite button (top-right)
          Positioned(
            top: 12,
            right: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  if (isFav) {
                    _favorites.remove(line.lineNumber);
                  } else {
                    _favorites.add(line.lineNumber);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isFav
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFav ? Colors.amber : Colors.grey.shade400,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge Helper ──────────────────────────────────────────────────────────
  Widget _buildBadge(String label, Color color, bool isDark, IconData icon) {
    final Color textColor = isDark ? color.withValues(alpha: 0.9) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
