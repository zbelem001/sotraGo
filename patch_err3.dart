import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  List<String> lines = content.split('\n');
  lines.removeRange(576, 597);
  lines.insert(576, '''                    if (_currentLocation != null) {
                      // _mapController.move(_currentLocation!, 15.0);
                    } else {
                      _getCurrentLocation();
                    }''');
  File('lib/screens/map_screen.dart').writeAsStringSync(lines.join('\n'));
}
