import 'package:latlong2/latlong.dart';
import '../models/sotraco_line.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class RouteSegment {
  final SotracoLine line;
  final SotracoStop boardStop;
  final SotracoStop alightStop;

  RouteSegment({
    required this.line,
    required this.boardStop,
    required this.alightStop,
  });
}

class Itinerary {
  final List<RouteSegment> segments;
  final LatLng startLocation;
  final LatLng endLocation;
  final double totalWalkingDistance; // en mètres
  final double estimatedTime; // en minutes (marche + trajet)
  final int totalCost; // en FCFA

  // Ajout de la géométrie de backend pour tracer si présente
  final List<LatLng>? geometry;

  Itinerary({
    required this.segments,
    required this.startLocation,
    required this.endLocation,
    required this.totalWalkingDistance,
    required this.estimatedTime,
    required this.totalCost,
    this.geometry,
  });
}

class RoutingService {
  final Distance distance = const Distance();

  /// Cherche les meilleurs itinéraires via l'API, avec Fallback local
  Future<List<Itinerary>> findRoutes(
    LatLng start,
    LatLng end,
    List<SotracoLine> allLines,
  ) async {
    // ESSAI DE CONSULTER L'API BACKEND
    try {
      final backendResponse = await ApiService().fetchItinerary(
        start.latitude, start.longitude,
        end.latitude, end.longitude,
      );

      if (backendResponse != null && backendResponse['status'] == 'success') {
        return _parseBackendItinerary(backendResponse, start, end, allLines);
      }
    } catch (e) {
      debugPrint("API routing en échec, passage au Fallback : $e");
    }

    // FALLBACK : CALCUL V1 MOBILE (à vol d'oiseau)
    return _localFallbackRouting(start, end, allLines);
  }

  List<Itinerary> _parseBackendItinerary(
    Map<String, dynamic> json,
    LatLng start,
    LatLng end,
    List<SotracoLine> allLines,
  ) {
    List<Itinerary> results = [];
    var routeData = json['itinerary'];
    if (routeData == null) return results;

    List<RouteSegment> segments = [];
    
    // On boucle sur les steps pour retrouver les arrêts et la ligne
    for (var step in routeData['steps'] ?? []) {
      if (step['type'] == 'BUS') {
        String lineName = step['line'];
        String boardStopName = step['boardStop'];
        String alightStopName = step['alightStop'];

        // Retrouver la ligne métier correspondante
        SotracoLine? matchLine;
        try {
          matchLine = allLines.firstWhere((l) => l.lineNumber == lineName);
        } catch (e) {
          continue;
        }

        SotracoStop? boardStop;
        SotracoStop? alightStop;

        try {
          boardStop = matchLine.stops.firstWhere((s) => s.name == boardStopName);
        } catch (e) {
          if (matchLine.stops.isNotEmpty) {
            boardStop = matchLine.stops.first;
          }
        }

        try {
          alightStop = matchLine.stops.firstWhere((s) => s.name == alightStopName);
        } catch (e) {
          if (matchLine.stops.isNotEmpty) {
             alightStop = matchLine.stops.last;
          }
        }

        if (boardStop != null && alightStop != null) {
          segments.add(RouteSegment(
            line: matchLine,
            boardStop: boardStop,
            alightStop: alightStop,
          ));
        }
      }
    }

    // Extraction potentielle de la géométrie de type List<LatLng>
    List<LatLng>? geom;
    if (routeData['geometry'] != null) {
      geom = (routeData['geometry'] as List).map((p) {
        return LatLng(p[1], p[0]); // Geojson = [lng, lat]
      }).toList();
    }

    if (segments.isNotEmpty) {
      results.add(Itinerary(
        segments: segments,
        startLocation: start,
        endLocation: end,
        totalWalkingDistance: (routeData['totalWalkingDistance'] as num).toDouble(),
        estimatedTime: (routeData['estimatedTimeMinutes'] as num).toDouble(),
        totalCost: (routeData['totalCostFCFA'] as num).toInt(),
        geometry: geom,
      ));
    }

    return results;
  }

  // --- LE CALCUL ORIGINAL MIS EN MODE FALLBACK ---
  final double walkingSpeed = 5000.0 / 60.0;
  final double busSpeed = 15000.0 / 60.0;

  List<Itinerary> _localFallbackRouting(LatLng start, LatLng end, List<SotracoLine> allLines) {
    List<Itinerary> results = [];
    for (var line in allLines) {
      if (line.stops.isEmpty || line.stops.length < 2) continue;

      bool isIntercommunal = line.lineNumber.toLowerCase().contains('lci') ||
          line.lineNumber.toLowerCase().contains('lic') ||
          line.name.toLowerCase().contains('inter');
      final int linePrice = isIntercommunal ? 500 : 200;

      SotracoStop? bestBoard;
      double minBoardDist = double.infinity;
      SotracoStop? bestAlight;
      double minAlightDist = double.infinity;

      for (var stop in line.stops) {
        double dStart = distance.as(LengthUnit.Meter, start, stop.location);
        if (dStart < minBoardDist) {
          minBoardDist = dStart;
          bestBoard = stop;
        }
      }

      for (var stop in line.stops) {
        double dEnd = distance.as(LengthUnit.Meter, end, stop.location);
        if (dEnd < minAlightDist) {
          minAlightDist = dEnd;
          bestAlight = stop;
        }
      }

      if (bestBoard == null || bestAlight == null || bestBoard == bestAlight) continue;

      double totalWalk = minBoardDist + minAlightDist;
      double busDist = distance.as(LengthUnit.Meter, bestBoard.location, bestAlight.location) * 1.4;
      double time = (totalWalk / walkingSpeed) + (busDist / busSpeed);

      results.add(Itinerary(
        segments: [RouteSegment(line: line, boardStop: bestBoard, alightStop: bestAlight)],
        startLocation: start,
        endLocation: end,
        totalWalkingDistance: totalWalk,
        estimatedTime: time,
        totalCost: linePrice,
      ));
    }
    results.sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));
    return results.take(10).toList();
  }
}
