import 'dart:io';

void main() {
  File file = File('lib/screens/map_screen.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    'LatLng? startPoint = (segments.isNotEmpty && segments.first.isNotEmpty) ? segments.first.first : null;',
    'LatLng? startPoint = _selectedLine != null && _selectedLine!.stops.isNotEmpty ? _selectedLine!.stops.first.location : ((segments.isNotEmpty && segments.first.isNotEmpty) ? segments.first.first : null);'
  );

  content = content.replaceAll(
    'LatLng? endPoint = (segments.isNotEmpty && segments.last.isNotEmpty) ? segments.last.last : null;',
    'LatLng? endPoint = _selectedLine != null && _selectedLine!.stops.isNotEmpty ? _selectedLine!.stops.last.location : ((segments.isNotEmpty && segments.last.isNotEmpty) ? segments.last.last : null);'
  );

  // C'est dangereux de juste remplacer la liste des markers. Re-ecrivons juste le MarkerLayer
  
  file.writeAsStringSync(content);
}
