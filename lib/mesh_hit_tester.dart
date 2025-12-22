import 'dart:math';

import 'package:fsg/triangle_mesh.dart';
import 'package:vector_math/vector_math_64.dart';

/// A utility class that provides static methods for ray-casting against a [TriangleMesh].
class MeshHitTester {
  /// Private constructor to prevent instantiation of this utility class.
  MeshHitTester._();

  /// Performs a ray-mesh intersection test.
  ///
  /// Returns [TriangleMeshHitDetails] if an intersection occurs, otherwise `null`.
  /// This test first checks against the mesh's bounding box for a quick exit,
  /// then checks each triangle for the closest hit.
  static TriangleMeshHitDetails? intersect(TriangleMesh mesh, Ray ray,
      {double epsilon = 1e-6}) {
    // First, perform a cheap check against the overall bounding box.
    double? intersection = ray.intersectsWithAabb3(mesh.getBounds());
    if (intersection == null || intersection < 0) {
      return null;
    }

    TriangleMeshHitDetails? closestHit;

    // If the ray hits the box, check each triangle for the closest intersection.
    for (int i = 0; i < mesh.triangleCount; i++) {
      Vector3? hit = _rayTriangleIntersect(mesh, i, ray, epsilon: epsilon);
      if (hit != null) {
        final distance = ray.origin.distanceTo(hit);
        if (closestHit == null || distance < closestHit.distance) {
          closestHit = TriangleMeshHitDetails(mesh, hit, i, distance);
        }
      }
    }
    return closestHit;
  }

  /// Performs a ray-triangle intersection using the Möller–Trumbore algorithm.
  static Vector3? _rayTriangleIntersect(TriangleMesh mesh, int triangleIndex, Ray ray,
      {double epsilon = 1e-6}) {
    final int vertexIndex = triangleIndex * 3;
    final point0 = mesh.getVertex(vertexIndex);
    final edge1 = mesh.getVertex(vertexIndex + 1) - point0;
    final edge2 = mesh.getVertex(vertexIndex + 2) - point0;

    final h = ray.direction.cross(edge2);
    final a = edge1.dot(h);

    if (a > -epsilon && a < epsilon) {
      return null; // Ray is parallel to the triangle.
    }

    final f = 1.0 / a;
    final s = ray.origin - point0;
    final u = f * s.dot(h);

    if (u < 0.0 || u > 1.0) {
      return null; // Intersection point is outside the triangle.
    }

    final q = s.cross(edge1);
    final v = f * ray.direction.dot(q);

    if (v < 0.0 || u + v > 1.0) {
      return null; // Intersection point is outside the triangle.
    }

    final t = f * edge2.dot(q);

    if (t > epsilon) {
      return ray.origin + ray.direction * t;
    } else {
      return null; // Intersection is behind the ray's origin.
    }
  }
}
