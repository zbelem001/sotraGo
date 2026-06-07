import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/sotraco_line.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import '../services/location_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LINES SCREEN  –  inspired by "Plan Route" UI
//  Colors: AppColors defaults only
// ─────────────────────────────────────────────────────────────────────────────
class LinesScreen extends StatefulWidget {
  final String? initialLineNumber;
  const LinesScreen({super.key, this.initialLineNumber});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  List<SotracoLine> _lines = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Tout"; // replaces city chips for main filter row
  String _selectedCity = "Tout";
  String? _expandedLineNumber;
  final Set<String> _favorites = {};
  final TextEditingController _searchCtrl = TextEditingController();

  // Filter tabs (like Fastest / Cheapest / Least Walking)
  final List<_FilterTab> _filterTabs = const [
    _FilterTab(label: "Tout", icon: Icons.apps_rounded),
    _FilterTab(label: "Favoris", icon: Icons.star_rounded),
    _FilterTab(label: "Ouagadougou", icon: Icons.location_city_rounded),
    _FilterTab(label: "Bobo", icon: Icons.location_on_rounded),
    _FilterTab(label: "Koudougou", icon: Icons.place_rounded),
    _FilterTab(label: "Ouahigouya", icon: Icons.place_outlined),
    _FilterTab(label: "Banfora", icon: Icons.forest_rounded),
  ];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _expandedLineNumber = widget.initialLineNumber;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadLines();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _loadLines() async {
    try {
      final raw = await ApiService().fetchLinesData();
      final list = json.decode(raw) as List<dynamic>;
      setState(() {
        _lines = list.map((d) => SotracoLine.fromJson(d)).toList();
        if (widget.initialLineNumber != null) {
          final idx = _lines.indexWhere(
            (l) => l.lineNumber == widget.initialLineNumber,
          );
          if (idx != -1) {
            final l = _lines.removeAt(idx);
            _lines.insert(0, l);
          }
        }
        _isLoading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      debugPrint("Erreur: $e");
      setState(() => _isLoading = false);
    }
  }

  // ── Filtered list ──────────────────────────────────────────────────────────
  List<SotracoLine> get _filtered {
    List<SotracoLine> r = List.from(_lines);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      r = r
          .where(
            (l) =>
                l.lineNumber.toLowerCase().contains(q) ||
                l.name.toLowerCase().contains(q) ||
                l.departure.toLowerCase().contains(q) ||
                l.arrival.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_selectedFilter != "Tout") {
      r = r.where((l) {
        if (_selectedFilter == "Favoris")
          return _favorites.contains(l.lineNumber);
        final c = l.city.toLowerCase();
        final t = _selectedFilter.toLowerCase();
        if (t == "ouagadougou")
          return c.contains("ouaga") ||
              c.contains("koubri") ||
              c.trim().isEmpty;
        return c.contains(t);
      }).toList();
    }

    r.sort((a, b) {
      final af = _favorites.contains(a.lineNumber) ? 0 : 1;
      final bf = _favorites.contains(b.lineNumber) ? 0 : 1;
      return af.compareTo(bf);
    });
    return r;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardBg = isDark ? AppColors.darkSlate : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              _TopBar(
                isDark: isDark,
                filteredCount: _filtered.length,
                totalCount: _lines.length,
              ),

              // ── Location inputs (origin / destination style) ───────────
              _LocationInputs(
                isDark: isDark,
                cardBg: cardBg,
                onChanged: (v) => setState(() => _searchQuery = v),
                controller: _searchCtrl,
                query: _searchQuery,
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = "");
                },
              ),

              const SizedBox(height: 10),

              // ── Filter tabs (Fastest / Cheapest style) ───────────────
              _FilterTabRow(
                tabs: _filterTabs,
                selected: _selectedFilter,
                isDark: isDark,
                onSelect: (v) => setState(() => _selectedFilter = v),
              ),

              const SizedBox(height: 10),

              // ── Route cards list ─────────────────────────────────────
              Expanded(child: _buildBody(isDark, cardBg)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color cardBg) {
    if (_isLoading) return _LoadingState(isDark: isDark);
    if (_filtered.isEmpty) return _EmptyState(isDark: isDark);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) {
          final line = _filtered[i];
          return _RouteCard(
            line: line,
            isDark: isDark,
            cardBg: cardBg,
            isFav: _favorites.contains(line.lineNumber),
            isExpanded: _expandedLineNumber == line.lineNumber,
            onFav: () => setState(() {
              _favorites.contains(line.lineNumber)
                  ? _favorites.remove(line.lineNumber)
                  : _favorites.add(line.lineNumber);
            }),
            onExpand: (v) => setState(
              () => _expandedLineNumber = v ? line.lineNumber : null,
            ),
            onMap: () {
              if (LocationService().isScoutModeEnabled) {
                LocationService().startScouting(line.lineNumber);
              }
              Navigator.pushAndRemoveUntil(
                ctx,
                MaterialPageRoute(
                  builder: (_) => MainScreen(
                    initialIndex: 0,
                    initialMapLine: line.lineNumber,
                  ),
                ),
                (_) => false,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDark;
  final int filteredCount;
  final int totalCount;
  const _TopBar({
    required this.isDark,
    required this.filteredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          // Title centered
          Expanded(
            child: Text(
              "Lignes SOTRACO",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Text(
              "$filteredCount / $totalCount",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOCATION INPUTS  (Your Location / Destination style)
// ─────────────────────────────────────────────────────────────────────────────
class _LocationInputs extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final String query;
  final VoidCallback onClear;
  const _LocationInputs({
    required this.isDark,
    required this.cardBg,
    required this.onChanged,
    required this.controller,
    required this.query,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            // Origin row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Votre position",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Divider with vertical line
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 14,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),

            // Destination = search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: "Rechercher une ligne ou un arrêt…",
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: query.isNotEmpty
                            ? GestureDetector(
                                onTap: onClear,
                                child: Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400,
                                ),
                              )
                            : null,
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                  // Swap icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      size: 17,
                      color: AppColors.primary,
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILTER TAB ROW  (Fastest / Cheapest style)
// ─────────────────────────────────────────────────────────────────────────────
class _FilterTab {
  final String label;
  final IconData icon;
  const _FilterTab({required this.label, required this.icon});
}

class _FilterTabRow extends StatelessWidget {
  final List<_FilterTab> tabs;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onSelect;
  const _FilterTabRow({
    required this.tabs,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final active = selected == tab.label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(tab.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSlate : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200),
                    width: 1.2,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 13,
                      color: active
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTE CARD  (inspired by the 24min / $2.50 card style)
// ─────────────────────────────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final SotracoLine line;
  final bool isDark;
  final Color cardBg;
  final bool isFav;
  final bool isExpanded;
  final VoidCallback onFav;
  final ValueChanged<bool> onExpand;
  final VoidCallback onMap;

  const _RouteCard({
    required this.line,
    required this.isDark,
    required this.cardBg,
    required this.isFav,
    required this.isExpanded,
    required this.onFav,
    required this.onExpand,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final mainStops = line.stops.where((s) => s.isMainStop).toList();
    final stops = mainStops.isNotEmpty ? mainStops : line.stops;

    final cleanDep = line.departure
        .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
        .trim();
    final cleanArr = line.arrival
        .replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')
        .trim();
    final cleanNum = line.lineNumber
        .replaceAll(RegExp(r'Ligne\s*', caseSensitive: false), '')
        .trim();

    final bool isIC =
        line.lineNumber.toLowerCase().contains('lci') ||
        line.lineNumber.toLowerCase().contains('lic') ||
        line.name.toLowerCase().contains('inter');
    final int price = isIC ? 500 : 200;
    final int stopCount = stops.length;

    // Simulated duration (2 min/stop base)
    final int durationMin = (stopCount * 2).clamp(10, 90);

    return GestureDetector(
      onTap: () => onExpand(!isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? AppColors.primary.withOpacity(0.5)
                : (isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade200),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Card header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: duration + price + fav
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Duration
                      Text(
                        "$durationMin min",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stop count as "schedule"
                      Text(
                        "$stopCount arrêts",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      // Price
                      Text(
                        "$price FCFA",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Fav
                      GestureDetector(
                        onTap: onFav,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFav
                                ? Colors.amber.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFav
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isFav
                                ? Colors.amber
                                : (isDark
                                      ? Colors.white30
                                      : Colors.grey.shade400),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Row 2: Route progress bar (walk → bus → walk)
                  _RouteProgressBar(
                    lineNumber: cleanNum,
                    isDark: isDark,
                    isIC: isIC,
                  ),

                  const SizedBox(height: 12),

                  // Row 3: tags + walk info
                  Row(
                    children: [
                      _SmallTag(
                        icon: isIC
                            ? Icons.connecting_airports_rounded
                            : Icons.eco_rounded,
                        label: isIC ? "Intercommunal" : "Low CO₂",
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Text(
                        "$cleanDep  →  $cleanArr",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Expanded stops ───────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _ExpandedStops(
                stops: stops,
                isDark: isDark,
                onMap: onMap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTE PROGRESS BAR  (walk ——— [B42] ——— walk)
// ─────────────────────────────────────────────────────────────────────────────
class _RouteProgressBar extends StatelessWidget {
  final String lineNumber;
  final bool isDark;
  final bool isIC;
  const _RouteProgressBar({
    required this.lineNumber,
    required this.isDark,
    required this.isIC,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = AppColors.primary;
    final dotColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Row(
      children: [
        // Walk icon left
        _WalkDot(isDark: isDark),
        // Line segment left
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [dotColor, lineColor.withOpacity(0.6)],
              ),
            ),
          ),
        ),
        // Bus badge (center)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: lineColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lineColor.withOpacity(0.4), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIC
                    ? Icons.directions_bus_filled_rounded
                    : Icons.directions_bus_rounded,
                size: 13,
                color: lineColor,
              ),
              const SizedBox(width: 5),
              Text(
                lineNumber,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: lineColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        // Line segment right
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lineColor.withOpacity(0.6), dotColor],
              ),
            ),
          ),
        ),
        // Walk icon right
        _WalkDot(isDark: isDark),
      ],
    );
  }
}

class _WalkDot extends StatelessWidget {
  final bool isDark;
  const _WalkDot({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade200,
        ),
      ),
      child: Icon(
        Icons.directions_walk_rounded,
        size: 15,
        color: isDark ? Colors.white54 : Colors.grey.shade500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL TAG  (Low CO2 / Intercommunal)
// ─────────────────────────────────────────────────────────────────────────────
class _SmallTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _SmallTag({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXPANDED STOPS + CTA
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandedStops extends StatelessWidget {
  final List<dynamic> stops;
  final bool isDark;
  final VoidCallback onMap;
  const _ExpandedStops({
    required this.stops,
    required this.isDark,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : AppColors.primary.withOpacity(0.03),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.shade100,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "ARRÊTS",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stops timeline
          ...stops.asMap().entries.map((e) {
            final isFirst = e.key == 0;
            final isLast = e.key == stops.length - 1;
            final isTerminus = isFirst || isLast;
            final stop = e.value;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        if (!isFirst)
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 1.5,
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 4),
                        Container(
                          width: isTerminus ? 12 : 7,
                          height: isTerminus ? 12 : 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTerminus
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.25),
                            boxShadow: isTerminus
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 1.5,
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stop label
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        stop.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isTerminus
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isTerminus
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isTerminus)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        isFirst ? "DÉPART" : "ARRIVÉE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onMap,
              icon: const Icon(Icons.map_rounded, size: 17),
              label: const Text(
                "Voir sur la carte",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: AppColors.primary.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADING & EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  final bool isDark;
  const _LoadingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Chargement des lignes…",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune ligne trouvée",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Essayez un autre terme",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
