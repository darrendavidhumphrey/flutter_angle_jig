import 'package:fsg/polyline.dart';
import 'package:fsg/triangle_mesh.dart';
import 'package:vector_math/vector_math_64.dart';

// Represents a generic 3D solid (cube or rectangular solid)
class Solid {
  final List<Polyline> faces; // List of faces that make up the solid
  final String name; // e.g., "Central Cube", "Corner Cube", "Edge Solid"

  final Vector3 dimensions; // Width, Height, Depth

  // Use for ray-cast picking of the tessellated faces
  late TriangleMesh pickGeometry;

  Solid(this.faces, this.name, this.dimensions) {
    int triangleCount = faces.length * 2;
    pickGeometry = TriangleMesh(triangleCount);

    int currentTriangle = 0;
    for (var face in faces) {
      currentTriangle = pickGeometry.addOutlineAsTriFan(face, currentTriangle);
    }
    pickGeometry.recomputeBounds();
  }
}

/// Creates the faces, normals, and UVs for a cube given its center and size.
List<Polyline> createCubeFaces(Vector3 center, double size) {
  final double halfSize = size / 2.0;
  final List<Polyline> faces = [];

  // Define the 8 vertices of the cube relative to the center
  final v = [
    Vector3(center.x - halfSize, center.y - halfSize, center.z - halfSize), // 0: BLF (Bottom-Left-Front)
    Vector3(center.x + halfSize, center.y - halfSize, center.z - halfSize), // 1: BRF
    Vector3(center.x + halfSize, center.y + halfSize, center.z - halfSize), // 2: TRF
    Vector3(center.x - halfSize, center.y + halfSize, center.z - halfSize), // 3: TLF

    Vector3(center.x - halfSize, center.y - halfSize, center.z + halfSize), // 4: BLB (Bottom-Left-Back)
    Vector3(center.x + halfSize, center.y - halfSize, center.z + halfSize), // 5: BRB
    Vector3(center.x + halfSize, center.y + halfSize, center.z + halfSize), // 6: TRB
    Vector3(center.x - halfSize, center.y + halfSize, center.z + halfSize), // 7: TLB
  ];

  // Front face (+Z)
  faces.add(Polyline.fromVector3([v[0], v[1], v[2], v[3]]));

  // Back face (-Z)
  faces.add(Polyline.fromVector3([v[5], v[4], v[7], v[6]]));

  // Right face (+X)
  faces.add(Polyline.fromVector3([v[1], v[5], v[6], v[2]]));

  // Left face (-X)
  faces.add(Polyline.fromVector3([v[4], v[0], v[3], v[7]]));

  // Top face (+Y)
  faces.add(Polyline.fromVector3([v[3], v[2], v[6], v[7]]));

  // Bottom face (-Y)
  faces.add(Polyline.fromVector3([v[4], v[5], v[1], v[0]]));

  return faces;
}

/// Creates the faces, normals, and UVs for a rectangular solid given its center and dimensions.
List<Polyline> createRectangularSolidFaces(Vector3 center, Vector3 dimensions) {
  final double halfWidth = dimensions.x / 2.0;
  final double halfHeight = dimensions.y / 2.0;
  final double halfDepth = dimensions.z / 2.0;
  final List<Polyline> faces = [];

  // Define the 8 vertices relative to the center
  final v = [
    Vector3(center.x - halfWidth, center.y - halfHeight, center.z - halfDepth), // 0: BLF
    Vector3(center.x + halfWidth, center.y - halfHeight, center.z - halfDepth), // 1: BRF
    Vector3(center.x + halfWidth, center.y + halfHeight, center.z - halfDepth), // 2: TRF
    Vector3(center.x - halfWidth, center.y + halfHeight, center.z - halfDepth), // 3: TLF

    Vector3(center.x - halfWidth, center.y - halfHeight, center.z + halfDepth), // 4: BLB
    Vector3(center.x + halfWidth, center.y - halfHeight, center.z + halfDepth), // 5: BRB
    Vector3(center.x + halfWidth, center.y + halfHeight, center.z + halfDepth), // 6: TRB
    Vector3(center.x - halfWidth, center.y + halfHeight, center.z + halfDepth), // 7: TLB
  ];

  faces.add(Polyline.fromVector3([v[0], v[1], v[2], v[3]]));

  // Back face (-Z)
  faces.add(Polyline.fromVector3([v[5], v[4], v[7], v[6]]));

  // Right face (+X)
  faces.add(Polyline.fromVector3([v[1], v[5], v[6], v[2]]));

  // Left face (-X)
  faces.add(Polyline.fromVector3([v[4], v[0], v[3], v[7]]));

  // Top face (+Y)
  faces.add(Polyline.fromVector3([v[3], v[2], v[6], v[7]]));

  // Bottom face (-Y)
  faces.add(Polyline.fromVector3([v[4], v[5], v[1], v[0]]));

  return faces;
}
