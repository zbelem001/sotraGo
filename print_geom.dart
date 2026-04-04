import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/data/bd.json');
  final String jsonString = file.readAsStringSync();
  final List<dynamic> jsonList = json.decode(jsonString);

  for (var data in jsonList) {
    if (data['line_number'] == 'Ligne 2B') {
      print(data['geometry']['type']);
    }
  }
}
