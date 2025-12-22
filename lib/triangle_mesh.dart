import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_angle/native-array/index.dart';
import 'package:fsg/polyline.dart';
import 'package:fsg/util.dart';
import 'package:vector_math/vector_math_64.dart'
    show Vector3, Ray, Triangle, Vector2, Aabb3;

import 'vertex_buffer.dart';

class TriangleMeshHitDetails {
  final TriangleMesh mesh;
  final Vector3 hitPoint;
  final int triangleIndex;
  final double distance;

  late final Vector3 normal;

  TriangleMeshHitDetails(
      this.mesh, this.hitPoint, this.triangleIndex, this.distance) {
    normal = mesh.getNormal(triangleIndex);
  }
}

class TriangleMesh {
  // Components are vertex[3], texCoord[2], normal[3]
  static const int componentCount = 8;
  static const int texCoordOffset = 3;
  static const int normalOffset = 5;

  final int triangleCount;

  /// The cached bounding box of the mesh. Null until first computed.
  Aabb3? _bounds;

  late final Float32List verts;

  TriangleMesh(this.triangleCount)
      : verts = Float32List(triangleCount * componentCount * 3);

  TriangleMesh.empty()
      : triangleCount = 0,
        verts = Float32List(0);

  Vector3 getVertex(int index) {
    final int j = index * componentCount;
    return Vector3(verts[j], verts[j + 1], verts[j + 2]);
  }

  Vector3 getNormal(int index) {
    final int j = index * componentCount + normalOffset;
    return Vector3(verts[j], verts[j + 1], verts[j + 2]);
  }

  Triangle getTriangle(int index) {
    final int i = index * componentCount * 3;
    final int j = i + componentCount;
    final int k = j + componentCount;

    return Triangle.points(
        Vector3(verts[i], verts[i + 1], verts[i + 2]),
        Vector3(verts[j], verts[j + 1], verts[j + 2]),
        Vector3(verts[k], verts[k + 1], verts[k + 2]));
  }

  Vector3? rayTriangleIntersect(int triangleIndex, Ray ray,
      {double epsilon = 1e-6}) {
    final int vertexIndex = triangleIndex * 3;
    final point0 = getVertex(vertexIndex);
    final edge1 = getVertex(vertexIndex + 1) - point0;
    final edge2 = getVertex(vertexIndex + 2) - point0;

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

  TriangleMeshHitDetails? rayIntersect(Ray ray, {double epsilon = 1e-6}) {
    // First, perform a cheap check against the overall bounding box.
    double? intersection = ray.intersectsWithAabb3(getBounds());
    if (intersection == null || intersection < 0) {
      return null;
    }

    double? closestDistance;
    int? closestTriangleIndex;

    // If the ray hits the box, check each triangle for the closest intersection.
    for (int i = 0; i < triangleCount; i++) {
      Vector3? hit = rayTriangleIntersect(i, ray);
      if (hit != null) {
        final distance = ray.origin.distanceTo(hit);
        if (closestDistance == null || distance < closestDistance) {
          closestDistance = distance;
          closestTriangleIndex = i;
        }
      }
    }

    if (closestTriangleIndex != null) {
      final hitPoint =
          ray.origin + ray.direction * closestDistance!;
      return TriangleMeshHitDetails(
          this, hitPoint, closestTriangleIndex, closestDistance);
    }

    return null;
  }

  /// Computes the AABB for the entire mesh by iterating directly through the
  /// raw vertex data for efficiency.
  Aabb3 _computeBounds() {
    if (triangleCount == 0) {
      return Aabb3();
    }

    // Initialize min and max with the first vertex's coordinates.
    final minV = Vector3(verts[0], verts[1], verts[2]);
    final maxV = Vector3(verts[0], verts[1], verts[2]);

    // Iterate through the rest of the vertices directly in the flat array.
    for (int i = componentCount; i < verts.length; i += componentCount) {
      final x = verts[i];
      final y = verts[i + 1];
      final z = verts[i + 2];

      minV.x = min(minV.x, x);
      minV.y = min(minV.y, y);
      minV.z = min(minV.z, z);
      maxV.x = max(maxV.x, x);
      maxV.y = max(maxV.y, y);
      maxV.z = max(maxV.z, z);
    }

    return Aabb3.minMax(minV, maxV);
  }

  /// Recomputes the bounding box. Should be called after modifying vertices.
  void recomputeBounds() {
    _bounds = _computeBounds();
  }

  /// Returns the cached bounding box, computing it if necessary.
  Aabb3 getBounds() {
    // Use the null-aware assignment operator to compute only on the first call.
    return _bounds ??= _computeBounds();
  }

  void _addVertex(
      int vertexIndex, Vector3 pos, Vector3 normal, Vector2 tex) {
    int meshIndex = vertexIndex * componentCount;
    verts[meshIndex++] = pos.x;
    verts[meshIndex++] = pos.y;
    verts[meshIndex++] = pos.z;
    verts[meshIndex++] = tex.x;
    verts[meshIndex++] = tex.y;
    verts[meshIndex++] = normal.x;
    verts[meshIndex++] = normal.y;
    verts[meshIndex++] = normal.z;
  }

  int addOutlineAsTriFan(Polyline outline, int currentTriangle) {
    if (!outline.planeIsValid) return currentTriangle;
    int numTris = outline.length - 2;

    final bounds = outline.getBounds2D();
    double w = bounds.max.x - bounds.min.x;
    double h = bounds.max.y - bounds.min.y;
    double x = bounds.min.x;
    double y = bounds.min.y;

    Vector3 v0 = outline.getVector3(0);
    for (int i = 0; i < numTris; i++) {
      Vector3 v1 = outline.getVector3(i + 2);
      Vector3 v2 = outline.getVector3(i + 1);

      List<Vector2> texCoord = computeTexCoords(v0, v1, v2, x, y, w, h);

      currentTriangle = addTriangle(
          v0, v1, v2, outline.normal!, texCoord, currentTriangle);
    }
    return currentTriangle;
  }

  int addOutlineAsReverseTriFan(
      Polyline outline, Vector3 normal, int currentTriangle, Vector3 depth) {
    if (!outline.planeIsValid) return currentTriangle;
    int numTris = outline.length - 2;

    final bounds = outline.getBounds2D();
    double w = bounds.max.x - bounds.min.x;
    double h = bounds.max.y - bounds.min.y;
    double x = bounds.min.x;
    double y = bounds.min.y;

    Vector3 v0 = outline.getVector3(0) + depth;
    for (int i = 0; i < numTris; i++) {
      Vector3 v1 = outline.getVector3(i + 2) + depth;
      Vector3 v2 = outline.getVector3(i + 1) + depth;

      List<Vector2> texCoord = computeTexCoords(v2, v1, v0, x, y, w, h);

      currentTriangle =
          addTriangle(v2, v1, v0, normal, texCoord, currentTriangle);
    }
    return currentTriangle;
  }

  int addTriangle(Vector3 v0, Vector3 v1, Vector3 v2, Vector3 normal,
      List<Vector2> texCoord, int currentTriangle) {
    int vertexIndex = currentTriangle * 3;
    _addVertex(vertexIndex, v0, normal, texCoord[0]);
    _addVertex(vertexIndex + 1, v1, normal, texCoord[1]);
    _addVertex(vertexIndex + 2, v2, normal, texCoord[2]);
    return currentTriangle + 1;
  }

  int makeSideFromEdge(
      Polyline outline, int index, int currentTriangle, Vector3 depth) {
    Vector3 p1 = outline.getVector3(index % outline.length);
    Vector3 p2 = outline.getVector3((index + 1) % outline.length);
    Vector3 normal = (p2 - p1).cross(depth).normalized();

    Vector3 p1z = p1 + depth;
    Vector3 p2z = p2 + depth;

    // TODO: Calculate correct texture coordinates for sides.
    List<Vector2> texCoord = [Vector2.zero(), Vector2(1, 0), Vector2(1, 1)];
    currentTriangle = addTriangle(p1, p2, p2z, normal, texCoord, currentTriangle);

    texCoord = [Vector2.zero(), Vector2(1, 1), Vector2(0, 1)];
    currentTriangle = addTriangle(p1, p2z, p1z, normal, texCoord, currentTriangle);

    return currentTriangle;
  }

  void addToVbo(VertexBuffer vbo) {
    int count = triangleCount * 3;
    Float32Array? vertexTextureArray = vbo.requestBuffer(count);
    // Use set() for an efficient block-copy of the data.
    vertexTextureArray?.set(verts);
    vbo.setActiveVertexCount(triangleCount * 3);
  }

  static TriangleMesh extrude(List<Polyline> outlines, Vector3 depth) {
    if (outlines.isEmpty) {
      return TriangleMesh.empty();
    }

    int topCount = 0;
    for (var outline in outlines) {
      if (outline.length > 2) {
        topCount += (outline.length - 2);
      }
    }

    int sideCount = 0;
    for (var outline in outlines) {
      sideCount += (outline.length) * 2;
    }

    int extrudedTriangleCount = topCount * 2 + sideCount;
    if (extrudedTriangleCount == 0) {
      return TriangleMesh.empty();
    }

    TriangleMesh result = TriangleMesh(extrudedTriangleCount);
    int currentTriangle = 0;

    for (var outline in outlines) {
      if (outline.planeIsValid) {
        currentTriangle = result.addOutlineAsTriFan(outline, currentTriangle);
      }
    }

    for (var outline in outlines) {
      if (outline.planeIsValid) {
        Vector3 bottomNormal = -outline.normal!;
        currentTriangle = result.addOutlineAsReverseTriFan(
            outline, bottomNormal, currentTriangle, depth);
      }
    }

    for (var outline in outlines) {
      for (int i = 0; i < outline.length; i++) {
        currentTriangle =
            result.makeSideFromEdge(outline, i, currentTriangle, depth);
      }
    }

    result.recomputeBounds();

    return result;
  }
}
