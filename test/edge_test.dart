import 'package:flutter_test/flutter_test.dart';
import 'package:fsg/edge.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Edge', () {
    test('Edge constructor', () {
      final start = Vector3(1, 2, 3);
      final end = Vector3(4, 5, 6);
      final edge = Edge(start, end);
      expect(edge.start, start);
      expect(edge.end, end);
    });

    test('Edge.zero constructor', () {
      final edge = Edge.zero();
      expect(edge.start, Vector3.zero());
      expect(edge.end, Vector3.zero());
    });

    test('transform method', () {
      final start = Vector3(1, 0, 0);
      final end = Vector3(0, 1, 0);
      final edge = Edge(start, end);
      final origin = Vector3(1, 1, 1);
      final xAxis = Vector3(1, 0, 0);
      final yAxis = Vector3(0, 1, 0);
      final transformedEdge = edge.transform(origin, xAxis, yAxis);
      expect(transformedEdge.start, Vector3(2, 1, 1));
      expect(transformedEdge.end, Vector3(1, 2, 1));
    });

    test('transformEdges method', () {
      final edges = [
        Edge(Vector3(1, 0, 0), Vector3(0, 1, 0)),
        Edge(Vector3(2, 0, 0), Vector3(0, 2, 0)),
      ];
      final origin = Vector3(1, 1, 1);
      final xAxis = Vector3(1, 0, 0);
      final yAxis = Vector3(0, 1, 0);
      final transformedEdges = Edge.transformEdges(edges, origin, xAxis, yAxis);
      expect(transformedEdges.length, 2);
      expect(transformedEdges[0].start, Vector3(2, 1, 1));
      expect(transformedEdges[0].end, Vector3(1, 2, 1));
      expect(transformedEdges[1].start, Vector3(3, 1, 1));
      expect(transformedEdges[1].end, Vector3(1, 3, 1));
    });
  });
}
