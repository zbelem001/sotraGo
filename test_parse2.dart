import 'dart:convert';
import 'dart:io';
void main() {
  final file = File('assets/data/bd.json');
  final String jsonString = file.readAsStringSync();
  final List<dynamic> jsonList = json.decode(jsonString);

  for (var data in jsonList) {
    try {
      if (data['geometry'] != null && data['geometry']['coordinates'] != null) {
        var coords = data['geometry']['coordinates'] as List;
        for (var p in coords) {
           var point = p as List;
           double lon = (point[0] is int) ? (point[0] as int).toDouble() : point[0] as double;
           double lat = (point[1] is int) ? (point[1] as int).toDouble() : point[1] as double;
        }
      }
    } catch (e) {
      print("ERROR IN ${data['line_number']}: $e");
    }
  }
}
