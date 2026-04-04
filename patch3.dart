import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  content = content.replaceAll(
    '    if (_currentLocation != null) {',
'''    } else if (_selectedItinerary != null) {
      Color c = _getColorForLine(_selectedItinerary!.segments.first.line.lineNumber);
      for (var segment in _selectedItinerary!.segments) {
        polylinesToDraw.addAll(segment.line.routeSegments.map(
          (s) => Polyline<Object>(points: s, color: c, strokeWidth: 3.5),
        ));
      }
    } else {
      for (var line in _allLines) {
        Color c = _getColorForLine(line.lineNumber);
        polylinesToDraw.addAll(
          line.routeSegments.map(
            (s) => Polyline<Object>(points: s, color: c, strokeWidth: 2.0),
          ),
        );
      }
    }

    if (_currentLocation != null) {'''
  );
  File('lib/screens/map_screen.dart').writeAsStringSync(content);
}
