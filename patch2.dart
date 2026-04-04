import 'dart:io';

void main() {
  String content = File('lib/screens/map_screen.dart').readAsStringSync();
  content = content.replaceAll(
'''              if (busSegments.isNotEmpty)
                PolylineLayer(
                  polylines: busSegments.map((segmentPoints) {
                    return Polyline<Object>(
                      points: segmentPoints,
                      color: AppColors.primary,
                      strokeWidth: 5.0,
                    );
                  }).toList(),
                ),''',
'''              if (polylinesToDraw.isNotEmpty)
                PolylineLayer(
                  polylines: polylinesToDraw,
                ),'''
  );
  File('lib/screens/map_screen.dart').writeAsStringSync(content);
}
