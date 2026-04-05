import 'dart:io';

void main() {
  var file = File('lib/screens/events_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll('final String imageUrl;', '');
  content = content.replaceAll('required this.imageUrl,', '');
  content = content.replaceAll(RegExp(r'imageUrl: ".*",\n'), '');
  
  file.writeAsStringSync(content);
}
