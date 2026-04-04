import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  content = content.replaceFirst(
'''    }

    } else if (_selectedItinerary != null) {''',
'''    } else if (_selectedItinerary != null) {'''
  );
  File('lib/screens/map_screen.dart').writeAsStringSync(content);
}
