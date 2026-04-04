import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/data/bd.json');
  final String jsonString = file.readAsStringSync();
  final List<dynamic> jsonList = json.decode(jsonString);

  for (var data in jsonList) {
    try {
      List parsedRoute = [];
      if (data['geometry'] != null && data['geometry']['coordinates'] != null) {
        var coords = data['geometry']['coordinates'] as List;
        for (var point in coords) {
          if (point is List && point.length >= 2) {
            double lon = (point[0] is int) ? (point[0] as int).toDouble() : point[0];
            double lat = (point[1] is int) ? (point[1] as int).toDouble() : point[1];
            parsedRoute.add([lat, lon]);
          }
        }
      }
      print("Parsed Ligne: \${data['line_number']} avec \${parsedRoute.length} points");
    } catch (e) {
      print("Error parse line \${data['line_number']} : \$e");
    }
  }
}
