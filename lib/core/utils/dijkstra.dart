import '../../features/metro/domain/entities/station.dart';

class Dijkstra {
  static Map<String, dynamic> findShortestPath(
      Map<String, Station> graph, String startId, String endId) {
    if (!graph.containsKey(startId) || !graph.containsKey(endId)) {
      return {'path': [], 'distance': double.infinity, 'transfers': 0};
    }

    Map<String, double> distances = {};
    Map<String, String?> previous = {};
    Set<String> nodes = {};

    for (var id in graph.keys) {
      if (id == startId) {
        distances[id] = 0;
      } else {
        distances[id] = double.infinity;
      }
      previous[id] = null;
      nodes.add(id);
    }

    while (nodes.isNotEmpty) {
      String? smallest;
      for (var node in nodes) {
        if (smallest == null || distances[node]! < distances[smallest]!) {
          smallest = node;
        }
      }

      if (smallest == null || distances[smallest] == double.infinity) {
        break;
      }

      if (smallest == endId) {
        break;
      }

      nodes.remove(smallest);

      for (var neighborId in graph[smallest]!.connectedTo) {
        double alt = distances[smallest]! + 1; // Assuming constant weight of 1 between stations
        if (alt < (distances[neighborId] ?? double.infinity)) {
          distances[neighborId] = alt;
          previous[neighborId] = smallest;
        }
      }
    }

    List<String> path = [];
    String? current = endId;
    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    if (path.isEmpty || path[0] != startId) {
      return {'path': [], 'distance': double.infinity, 'transfers': 0};
    }

    // Calculate transfers
    int transfers = 0;
    for (int i = 0; i < path.length - 1; i++) {
      if (graph[path[i]]!.line != graph[path[i + 1]]!.line) {
        transfers++;
      }
    }

    return {
      'path': path.map((id) => graph[id]!).toList(),
      'distance': distances[endId],
      'transfers': transfers,
    };
  }
}
