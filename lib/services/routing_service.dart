import 'package:latlong2/latlong.dart';
import '../models/sotraco_line.dart';

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

  Itinerary({
    required this.segments,
    required this.startLocation,
    required this.endLocation,
    required this.totalWalkingDistance,
    required this.estimatedTime,
    required this.totalCost,
  });
}

class RoutingService {
  final Distance distance = const Distance();

  // Vitesse de marche moyenne : ~5 km/h -> ~83 mètres par minute
  final double walkingSpeed = 5000.0 / 60.0;

  // Vitesse moyenne d'un bus en ville incluant les arrêts : ~15 km/h -> 250 mètres par minute
  final double busSpeed = 15000.0 / 60.0;

  // Prix du billet Sotraco (estimé à 150 FCFA)
  final int costPerRide = 150;

  /// Cherche les meilleurs itinéraires entre [start] et [end]
  List<Itinerary> findRoutes(
    LatLng start,
    LatLng end,
    List<SotracoLine> allLines,
  ) {
    List<Itinerary> results = [];

    // Pour chaque ligne de bus, on trouve son point de montée et de descente les plus pertinents
    for (var line in allLines) {
      if (line.stops.isEmpty || line.stops.length < 2) continue;

      SotracoStop? bestBoard;
      double minBoardDist = double.infinity;
      
      SotracoStop? bestAlight;
      double minAlightDist = double.infinity;

      // Trouver l'arrêt le plus proche du point de départ
      for (var stop in line.stops) {
        double dStart = distance.as(LengthUnit.Meter, start, stop.location);
        if (dStart < minBoardDist) {
          minBoardDist = dStart;
          bestBoard = stop;
        }
      }

      // Trouver l'arrêt le plus proche de l'arrivée
      for (var stop in line.stops) {
        double dEnd = distance.as(LengthUnit.Meter, end, stop.location);
        if (dEnd < minAlightDist) {
          minAlightDist = dEnd;
          bestAlight = stop;
        }
      }

      if (bestBoard == null || bestAlight == null) continue;
      
      // Si l'arrêt de montée est le même que celui de descente, le bus ne sert à rien
      if (bestBoard == bestAlight) continue;

      // Calcul des distances
      double totalWalk = minBoardDist + minAlightDist;

      // Distance estimée en bus (vol d'oiseau * 1.4 pour estimer les routes)
      double busDist = distance.as(LengthUnit.Meter, bestBoard.location, bestAlight.location) * 1.4;

      // Temps total estimé
      double time = (totalWalk / walkingSpeed) + (busDist / busSpeed);

      // On peut définir une limite de bon sens (ex: ne pas marcher 15km pour prendre le bus 1km)
      // Mais on laisse quand même les résultats pour que l'utilisateur voit l'option
      results.add(
        Itinerary(
          segments: [
            RouteSegment(
              line: line,
              boardStop: bestBoard,
              alightStop: bestAlight,
            ),
          ],
          startLocation: start,
          endLocation: end,
          totalWalkingDistance: totalWalk,
          estimatedTime: time,
          totalCost: costPerRide,
        ),
      );
    }

    // 3. Trier les résultats du plus rapide au plus lent
    results.sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));

    // Ne retourner que les 10 meilleurs résultats pour ne pas inonder l'utilisateur
    return results.take(10).toList();
  }
}
