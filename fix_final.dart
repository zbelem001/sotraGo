import 'dart:io';

void main() {
  String content = File('map_screen_corrupted.txt').readAsStringSync();
  List<String> lines = content.split('\n');
  int startIndex = lines.indexWhere((l) => l.contains('_getCurrentLocation();'));
  int endIndex = lines.indexWhere((l) => l.contains('return Container('));
  
  lines.removeRange(startIndex + 1, endIndex);
  final replaceStr = '''                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineSelector() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;''';
  lines.insert(startIndex + 1, replaceStr);
  
  File('lib/screens/map_screen.dart').writeAsStringSync(lines.join('\n'));
}
