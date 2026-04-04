import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  content = content.replaceAll(
    '((busSegments.isNotEmpty && busSegments.first.isNotEmpty)\n                ? busSegments.first.first\n                : null)',
    '(_selectedLine!.routeSegments.isNotEmpty && _selectedLine!.routeSegments.first.isNotEmpty ? _selectedLine!.routeSegments.first.first : null)'
  );
  content = content.replaceAll(
    '((busSegments.isNotEmpty && busSegments.last.isNotEmpty)\n                ? busSegments.last.last\n                : null)',
    '(_selectedLine!.routeSegments.isNotEmpty && _selectedLine!.routeSegments.last.isNotEmpty ? _selectedLine!.routeSegments.last.last : null)'
  );
  File('lib/screens/map_screen.dart').writeAsStringSync(content);
}
