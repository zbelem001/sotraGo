import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/sotraco_line.dart';

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
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadLines();
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
    if (_searchQuery.isEmpty) return _lines;
    return _lines.where((line) {
      final query = _searchQuery.toLowerCase();
      // On cherche dans le numéro, le nom, départ, arrivée
      return line.lineNumber.toLowerCase().contains(query) ||
          line.name.toLowerCase().contains(query) ||
          line.departure.toLowerCase().contains(query) ||
          line.arrival.toLowerCase().contains(query);
    }).toList();
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
                    decoration: InputDecoration(
                      hintText: "Rechercher une ligne, un arrêt...",
                      prefixIcon: const Icon(Icons.search),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.darkSlate : Colors.white,
      child: ExpansionTile(
        initiallyExpanded: widget.initialLineNumber == line.lineNumber,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        leading: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            line.lineNumber,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                line.name.isNotEmpty
                    ? line.name
                          .replaceAll(
                            RegExp(r'Terminus ', caseSensitive: false),
                            '',
                          )
                          .replaceAll('➔', '↔')
                    : "Ligne ${line.lineNumber}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_favorites.contains(line.lineNumber)) {
                    _favorites.remove(line.lineNumber);
                  } else {
                    _favorites.add(line.lineNumber);
                  }
                });
              },
              child: Icon(
                _favorites.contains(line.lineNumber)
                    ? Icons.star
                    : Icons.star_border,
                color: _favorites.contains(line.lineNumber)
                    ? Colors.amber
                    : Colors.grey,
                size: 28,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: Text(
            "${line.departure.replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')} ↔ ${line.arrival.replaceAll(RegExp(r'Terminus ', caseSensitive: false), '')}",
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey[50],
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
                if (stopsToShow.isEmpty) const Text("Aucun arrêt répertorié."),
                ...stopsToShow.map(
                  (stop) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stop_circle,
                          size: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
