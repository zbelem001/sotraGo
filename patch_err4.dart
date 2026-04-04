import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  List<String> lines = content.split('\n');
  lines.insert(582, '''                  },
                ),
              ),
          ],
        ),
      ),
    );
  }''');
  File('lib/screens/map_screen.dart').writeAsStringSync(lines.join('\n'));
}
