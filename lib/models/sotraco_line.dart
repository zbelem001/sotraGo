import 'package:latlong2/latlong.dart';

class SotracoStop {
  final String name;
  final LatLng location;
  final bool isMainStop;

  SotracoStop({
    required this.name,
    required this.location,
    this.isMainStop = false,
  });
}

class SotracoLine {
  final String lineNumber;
  final String city;
  final String departure;
  final String arrival;
  final String name;
  final List<List<LatLng>>
  routeSegments; // Supporte LineString et MultiLineString
  final List<SotracoStop> stops;

  SotracoLine({
    required this.lineNumber,
    required this.city,
    required this.departure,
    required this.arrival,
    required this.name,
    required this.routeSegments,
    required this.stops,
  });

  factory SotracoLine.fromJson(Map<String, dynamic> json) {
    List<List<LatLng>> allSegments = [];
    List<SotracoStop> parsedStops = [];

    // Parse de la géométrie (lignes)
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      String type = json['geometry']['type'] ?? "LineString";
      var coords = json['geometry']['coordinates'] as List;

      if (type == "MultiLineString") {
        for (var segment in coords) {
          if (segment is List) {
            allSegments.add(_parseSegment(segment));
          }
        }
      } else if (type == "LineString") {
        allSegments.add(_parseSegment(coords));
      }
    }

    // Parse des arrêts avec coordonnées (nouveau format OSM)
    if (json['stops_with_coordinates'] != null) {
      for (var stop in (json['stops_with_coordinates'] as List)) {
        if (stop['lat'] != null && stop['lon'] != null) {
          double lat = (stop['lat'] is num)
              ? (stop['lat'] as num).toDouble()
              : double.parse(stop['lat'].toString());
          double lon = (stop['lon'] is num)
              ? (stop['lon'] as num).toDouble()
              : double.parse(stop['lon'].toString());
          String stopName = stop['name'] ?? 'Arrêt inconnu';
          bool isMainStop = stop['is_main_stop'] == true;
          parsedStops.add(
            SotracoStop(
              name: stopName,
              location: LatLng(lat, lon),
              isMainStop: isMainStop,
            ),
          );
        }
      }
    }

    return SotracoLine(
      lineNumber: json['line_number']?.toString() ?? '',
      city: json['city'] ?? '',
      departure: json['departure'] ?? '',
      arrival: json['arrival'] ?? '',
      name: json['name'] ?? '',
      routeSegments: allSegments,
      stops: parsedStops,
    );
  }

  static List<LatLng> _parseSegment(List segmentCoords) {
    List<LatLng> segment = [];
    for (var point in segmentCoords) {
      if (point is List && point.length >= 2) {
        double lon = (point[0] is num)
            ? (point[0] as num).toDouble()
            : double.parse(point[0].toString());
        double lat = (point[1] is num)
            ? (point[1] as num).toDouble()
            : double.parse(point[1].toString());
        segment.add(LatLng(lat, lon));
      }
    }
    return segment;
  }
}
