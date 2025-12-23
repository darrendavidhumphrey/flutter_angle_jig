import 'package:fsg/polyline.dart';
import 'package:vector_math/vector_math_64.dart';

/// Represents one edge of the convex clipping polygon, defined by a point on the
/// edge and an inward-pointing normal vector.
class ClipEdge {
  final Vector2 normal;
  final Vector2 pointOnEdge;

  ClipEdge(this.normal, this.pointOnEdge);
}

/// A class that clips a [Polyline] against a rectangular boundary using the
/// Sutherland-Hodgman algorithm.
class PolylineClipper {
  final List<ClipEdge> clipEdges;
  static const double _epsilon = 1e-6;

  /// Precomputes the four clipping edges with inward-pointing normals.
  static List<ClipEdge> _precomputeClipEdgesFromRect(
    double left,
    double top,
    double right,
    double bottom,
  ) {
    return [
      ClipEdge(Vector2(1, 0), Vector2(left, top)),    // Left edge
      ClipEdge(Vector2(-1, 0), Vector2(right, top)),  // Right edge
      ClipEdge(Vector2(0, -1), Vector2(left, top)),   // Top edge
      ClipEdge(Vector2(0, 1), Vector2(left, bottom)), // Bottom edge
    ];
  }

  /// Clips an input polygon (list of vertices) against a single clipping edge.
  List<Vector2> _clipAgainstEdge(List<Vector2> vertices, ClipEdge edge) {
    final List<Vector2> outputList = [];
    if (vertices.isEmpty) return outputList;

    Vector2 s = vertices.last;
    for (final Vector2 p in vertices) {
      // With INWARD normals, a positive dot product means inside.
      final bool s_inside = edge.normal.dot(s - edge.pointOnEdge) >= 0;
      final bool p_inside = edge.normal.dot(p - edge.pointOnEdge) >= 0;

      if (s_inside && p_inside) {
        outputList.add(p);
      } else if (s_inside && !p_inside) {
        outputList.add(_getIntersection(s, p, edge));
      } else if (!s_inside && p_inside) {
        outputList.add(_getIntersection(s, p, edge));
        outputList.add(p);
      }
      s = p;
    }
    return outputList;
  }

  /// Calculates the intersection point of line segment SP with a clip edge.
  Vector2 _getIntersection(Vector2 s, Vector2 p, ClipEdge edge) {
    final Vector2 direction = p - s;
    final double denominator = edge.normal.dot(direction);
    if (denominator.abs() < _epsilon) return s;
    final double t = -edge.normal.dot(s - edge.pointOnEdge) / denominator;
    return s + direction * t;
  }

  /// Cleans the final list of vertices by removing duplicates and checks for degeneracy.
  Polyline? _cleanAndCreatePolyline(List<Vector2> vertices) {
    if (vertices.length < 3) return null;

    final List<Vector2> uniqueVertices = [];
    final double epsilonSq = _epsilon * _epsilon;

    if (vertices.isNotEmpty) {
      uniqueVertices.add(vertices.first);
      for (int i = 1; i < vertices.length; i++) {
        if ((vertices[i] - uniqueVertices.last).length2 > epsilonSq) {
          uniqueVertices.add(vertices[i]);
        }
      }
    }

    if (uniqueVertices.length > 1 &&
        (uniqueVertices.last - uniqueVertices.first).length2 < epsilonSq) {
      uniqueVertices.removeLast();
    }

    if (uniqueVertices.length < 3) return null;

    return Polyline.fromVector2(uniqueVertices);
  }

  /// Clips a closed polyline against the precomputed clipping edges.
  Polyline? clip(Polyline polyline) {
    if (polyline.length < 3) return null;

    List<Vector2> clippedVertices =
        List.generate(polyline.length, (i) => polyline.getVector2(i));

    for (final edge in clipEdges) {
      clippedVertices = _clipAgainstEdge(clippedVertices, edge);
    }

    return _cleanAndCreatePolyline(clippedVertices);
  }

  PolylineClipper({
    required double left,
    required double bottom,
    required double right,
    required double top,
  }) : clipEdges = _precomputeClipEdgesFromRect(left, top, right, bottom);
}
