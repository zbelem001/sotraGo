import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/sotraco_line.dart';
import 'main_screen.dart';

class LinesScreen extends StatefulWidget {
  final String? initialLineNumber;
  const LinesScreen({super.key, this.initialLineNumber});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  List<SotracoLine> _lines = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};
  String? _expandedLineNumber;

  String _selectedCity = "Tout";
  final List<String> _cities = [
    "Tout",
    "Ouagadougou",
    "Bobo-Dioulasso",
    "Koudougou",
    "Ouahigouya",
    "Dédougou",
    "Banfora",
  ];

  @override
  void initState() {
    super.initState();
    _expandedLineNumber = widget.initialLineNumber;
    _loadLines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLines() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/sotraco_ouaga.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      setState(() {
        _lines = jsonList.map((data) => SotracoLine.fromJson(data)).toList();
        // Si un initialLineNumber est fourni, on place cette ligne en haut de la liste
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
        String city = line.city.toLowerCase();
        String target = _selectedCity.toLowerCase();

        // Ouagadougou gère historiquement Koubri et tout ce qui est vide ou "ouaga"
        if (target == "ouagadougou") {
          return city.contains("ouaga") ||
              city.contains("koubri") ||
              city.trim().isEmpty;
        } else {
          return city.contains(target);
        }
      }).toList();
    }

    // Classer les favoris en haut de la liste
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
      appBar: AppBar(
        title: const Text(
          'Lignes SOTRACO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // BARRE DE RECHERCHE
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Rechercher une ligne, un arrêt...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSlate
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // FILTRE DES VILLES
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            city,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkSlate
                              : Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedCity = city;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // LISTE DES LIGNES
                Expanded(
                  child: _filteredLines.isEmpty
                      ? const Center(child: Text("Aucune ligne trouvée"))
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: 100,
                            top: 8,
                            left: 16,
                            right: 16,
                          ),
                          itemCount: _filteredLines.length,
                          itemBuilder: (context, index) {
                            final line = _filteredLines[index];
                            return _buildLineCard(line, isDark);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLineCard(SotracoLine line, bool isDark) {
    // Filtrer pour ne montrer que les arrêts principaux (nommés) de cette ligne
    final mainStops = line.stops.where((s) => s.isMainStop).toList();
    // Si mainStops est vide, on prend juste les arrêts normaux ou vides (max 10 pour l'aperçu)
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
    final String formattedTitle =
        "Ligne $cleanLineNumber : $cleanDeparture ↔ $cleanArrival";

    final bool isIntercommunal =
        line.lineNumber.toLowerCase().contains('lci') ||
        line.lineNumber.toLowerCase().contains('lic') ||
        line.name.toLowerCase().contains('inter');
    final int price = isIntercommunal ? 500 : 200;
    final int stopCount = stopsToShow.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2FBF5),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ExpansionTile(
            key: Key(
              '${line.lineNumber}_${_expandedLineNumber == line.lineNumber}',
            ),
            initiallyExpanded: _expandedLineNumber == line.lineNumber,
            onExpansionChanged: (expanded) {
              if (expanded) {
                setState(() {
                  _expandedLineNumber = line.lineNumber;
                });
              } else if (_expandedLineNumber == line.lineNumber) {
                setState(() {
                  _expandedLineNumber = null;
                });
              }
            },
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            title: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                formattedTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$stopCount arrêts",
                      style: TextStyle(
                        color: isDark
                            ? Colors.amber.shade300
                            : Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$price FCFA",
                      style: TextStyle(
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black12
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Principaux arrêts :",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (stopsToShow.isEmpty)
                      const Text("Aucun arrêt répertorié."),
                    ...stopsToShow.map(
                      (stop) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.stop_circle,
                              size: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stop.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to map screen and show this line
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainScreen(
                                initialIndex: 0,
                                initialMapLine: line.lineNumber,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.map),
                        label: const Text("Voir sur la carte"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  if (_favorites.contains(line.lineNumber)) {
                    _favorites.remove(line.lineNumber);
                  } else {
                    _favorites.add(line.lineNumber);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _favorites.contains(line.lineNumber)
                      ? Colors.amber.withValues(alpha: 0.15)
                      : (isDark ? Colors.black12 : Colors.grey.shade100),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Icon(
                  _favorites.contains(line.lineNumber)
                      ? Icons.star
                      : Icons.star_border,
                  color: _favorites.contains(line.lineNumber)
                      ? Colors.amber
                      : Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
