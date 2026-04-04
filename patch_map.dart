import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  
  // 1. Add _getColorForLine method
  if (!content.contains('_getColorForLine')) {
    final methodStr = '''
  Color _getColorForLine(String lineNumber) {
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.orange,
      Colors.purple, Colors.teal, Colors.cyan, Colors.indigo,
      Colors.pink, Colors.amber, Colors.deepOrange, Colors.lime
    ];
    return colors[lineNumber.hashCode.abs() % colors.length];
  }
''';
    content = content.replaceFirst('  Future<void> _loadBusData() async {', methodStr + '\n  Future<void> _loadBusData() async {');
  }

  // 2. Remove the auto zoom tracking
  content = content.replaceAll(
    '_mapController.move(_currentLocation!, 15.0);', 
    '// _mapController.move(_currentLocation!, 15.0);'
  );

  // 3. Create polylines logic in build
  final buildStart = '''
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    // List des polylines (lignes sur la carte)
    final List<Polyline<Object>> polylinesToDraw = [];
    final List<Marker> markers = [];

    // --- LOGIC TO GATHER POLYLINES & MARKERS ---
    if (_selectedLine != null) {
      Color c = _getColorForLine(_selectedLine!.lineNumber);
      polylinesToDraw.addAll(
        _selectedLine!.routeSegments.map(
          (s) => Polyline<Object>(points: s, color: c, strokeWidth: 4.5),
        ),
      );
      
      // Points depart/arrivee & arrets
      for (int i = 0; i < _selectedLine!.stops.length; i++) {
        var stop = _selectedLine!.stops[i];
        if (i > 0 && i < _selectedLine!.stops.length - 1) {
          markers.add(
            Marker(
              point: stop.location,
              width: 16, height: 16,
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
      if (_selectedLine!.stops.isNotEmpty) {
        markers.add(Marker(point: _selectedLine!.stops.first.location, width: 24, height: 24, child: Icon(Icons.location_on, color: Colors.green)));
        markers.add(Marker(point: _selectedLine!.stops.last.location, width: 24, height: 24, child: Icon(Icons.flag, color: Colors.red)));
      }
    } else if (_selectedItinerary != null) {
      Color c = _getColorForLine(_selectedItinerary!.segments.first.line.lineNumber);
      for (var segment in _selectedItinerary!.segments) {
        polylinesToDraw.addAll(segment.line.routeSegments.map(
          (s) => Polyline<Object>(points: s, color: c, strokeWidth: 4.0),
        ));
      }
    } else {
      // DESSINER TOUTES LES LIGNES
      for (var line in _allLines) {
        Color c = _getColorForLine(line.lineNumber);
        polylinesToDraw.addAll(
          line.routeSegments.map(
            (s) => Polyline<Object>(points: s, color: c, strokeWidth: 2.0), // Epaisseur reduite
          ),
        );
        // Mini bulle (au milieu)
        if (line.routeSegments.isNotEmpty && line.routeSegments.first.length > 5) {
          var midPoint = line.routeSegments.first[line.routeSegments.first.length ~/ 2];
          markers.add(
            Marker(
              point: midPoint,
              width: 40, height: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    line.lineNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        }
      }
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
      markers.add(Marker(point: seg.boardStop.location, width: 30, height: 30, child: const Icon(Icons.directions_walk, color: Colors.green, size: 30)));
      markers.add(Marker(point: seg.alightStop.location, width: 30, height: 30, child: const Icon(Icons.directions_bus, color: Colors.red, size: 30)));
    }
    // --- END LOGIC ---
''';

  int buildStartIndex = content.indexOf('@override\n  Widget build(BuildContext context) {');
  int tileLayerIndex = content.indexOf('TileLayer(');
  
  if (buildStartIndex != -1 && tileLayerIndex != -1) {
    // Find the end of `children: [` right before `TileLayer`
    int endReplacedIndex = content.lastIndexOf('children: [', tileLayerIndex) + 12;

    String newContent = content.substring(0, buildStartIndex) + buildStart + '''
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
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
''' + content.substring(endReplacedIndex);
    
    // Now replace PolylineLayer
    newContent = newContent.replaceFirst(
      '''              if (busSegments.isNotEmpty)
                PolylineLayer(
                  polylines: busSegments.map((segmentPoints) {
                    return Polyline<Object>(
                      points: segmentPoints,
                      color: AppColors.primary,
                      strokeWidth: 5.0,
                    );
                  }).toList(),
                ),''',
      '''              if (polylinesToDraw.isNotEmpty)
                PolylineLayer(
                  polylines: polylinesToDraw,
                ),'''
    );
    
    File('lib/screens/map_screen.dart').writeAsStringSync(newContent);
  }
}
