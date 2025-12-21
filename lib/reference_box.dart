import 'package:fsg/polyline.dart';
import 'package:fsg/util.dart';
import 'package:vector_math/vector_math_64.dart';

/// Represents an immutable, oriented bounding box in 3D space.
class ReferenceBox {
  final Vector3 origin;
  final Vector3 xVector;
  final Vector3 yVector;
  final Vector3 zVector;

  late final Plane? plane;
  late final Vector3 xAxis; // Normalized X direction
  late final Vector3 yAxis; // Normalized Y direction
  late final Vector3 zAxis; // Normalized Z direction
  late final Quad cachedQuad;

  /// A flag indicating whether the box has a valid, non-degenerate plane.
  late final bool _isValid;
  bool get isValid => _isValid;

  /// The normal vector of the box's plane.
  ///
  /// Returns the calculated normal if the plane is valid, otherwise returns a
  /// default `Vector3(0, 0, 1)`.
  Vector3 get normal => plane?.normal ?? Vector3(0, 0, 1);

  /// Creates a ReferenceBox from an origin and three basis vectors.
  ReferenceBox(this.origin, this.xVector, this.yVector, this.zVector) {
    _initialize();
  }

  /// Creates a degenerate ReferenceBox at the origin, which will be marked as invalid.
  ReferenceBox.zero()
      : origin = Vector3.zero(),
        xVector = Vector3.zero(),
        yVector = Vector3.zero(),
        zVector = Vector3.zero() {
    _initialize();
  }

  /// Creates a new box that is assumed to be co-planar with another.
  ReferenceBox.coplanarWithNewVectors(
    ReferenceBox other,
    this.origin,
    this.xVector,
    this.yVector,
    this.zVector,
  ) {
    plane = other.plane;
    xAxis = other.xAxis;
    yAxis = other.yAxis;
    zAxis = other.zAxis;
    cachedQuad = _calculateQuad();
  }

  /// Internal helper to compute derived properties and validate the box.
  void _initialize() {
    final normalizedX = xVector.normalized();
    final normalizedY = yVector.normalized();
    final normalizedZ = zVector.normalized();

    if (normalizedX.isInfinite ||
        normalizedX.isNaN ||
        normalizedY.isInfinite ||
        normalizedY.isNaN ||
        normalizedZ.isInfinite ||
        normalizedZ.isNaN) {
      xAxis = Vector3.zero();
      yAxis = Vector3.zero();
      zAxis = Vector3.zero();
      plane = Plane.components(0, 0, 1, 0);
      _isValid = false;
      print("NOT VALID");
    } else {
      xAxis = normalizedX;
      yAxis = normalizedY;
      zAxis = normalizedZ;
      // This will be null if points are collinear, correctly marking as invalid.
      plane = makePlaneFromVertices(origin, origin + xVector, origin + yVector);
      _isValid = true;
    }
    cachedQuad = _calculateQuad();
  }

  Quad _calculateQuad() {
    final p0 = origin;
    final p1 = p0 + xVector;
    final p2 = p1 + yVector;
    final p3 = p0 + yVector;
    return Quad.points(p0, p1, p2, p3);
  }

  ReferenceBox makeBoxFromOffsets2D(Vector2 startOffset, Vector2 endOffset) {
    final newOrigin =
        origin + (xAxis * startOffset.x) + (yAxis * startOffset.y);
    final newXVector = xAxis * (endOffset.x - startOffset.x);
    final newYVector = yAxis * (endOffset.y - startOffset.y);
    //final newZVector = newXVector.cross(newYVector);
    final newZVector = Vector3(0,0,1);
    return ReferenceBox(newOrigin, newXVector, newYVector, newZVector);
  }

  ReferenceBox subBoxFromOffsets(
      Vector2 startOffset2D, Vector2 endOffset2D, Vector3 zVector) {
    final corners = _calcCornersFrom2DVectors(
      origin,
      startOffset2D,
      endOffset2D,
      xAxis,
      yAxis,
    );
    final newXVector = xAxis * (endOffset2D.x - startOffset2D.x);
    final newYVector = yAxis * (endOffset2D.y - startOffset2D.y);
    return ReferenceBox(corners[0], newXVector, newYVector, zVector);
  }

  static List<Vector3> _calcCornersFrom2DVectors(
    Vector3 origin3D,
    Vector2 startOffset2D,
    Vector2 endOffset2D,
    Vector3 xAxis,
    Vector3 yAxis,
  ) {
    return [
      origin3D + (xAxis * startOffset2D.x) + (yAxis * startOffset2D.y),
      origin3D + (xAxis * endOffset2D.x) + (yAxis * startOffset2D.y),
      origin3D + (xAxis * endOffset2D.x) + (yAxis * endOffset2D.y),
      origin3D + (xAxis * startOffset2D.x) + (yAxis * endOffset2D.y),
    ];
  }

  Quad calcQuadFrom2DVectors(Vector2 startOffset2D, Vector2 endOffset2D) {
    final corners = _calcCornersFrom2DVectors(
      origin,
      startOffset2D,
      endOffset2D,
      xAxis,
      yAxis,
    );
    return Quad.points(corners[0], corners[1], corners[2], corners[3]);
  }

  Polyline polylineFrom2DVectors(Vector2 startOffset2D, Vector2 endOffset2D) {
    final corners = _calcCornersFrom2DVectors(
      origin,
      startOffset2D,
      endOffset2D,
      xAxis,
      yAxis,
    );
    return Polyline.fromVector3(corners);
  }

  Polyline toPolyline() {
    return Polyline.fromVector3([
      cachedQuad.point0,
      cachedQuad.point1,
      cachedQuad.point2,
      cachedQuad.point3,
    ]);
  }

  Vector3 transformPointToReferencePlane(Vector2 v) {
    return origin + (xAxis * v.x) + (yAxis * v.y);
  }

  Vector3? rayIntersect(Ray pickRay) {
    if (!isValid) {
      return null;
    }
    final p = plane!;
    final double denominator = p.normal.dot(pickRay.direction);

    if (denominator.abs() < 1e-6) {
      return null;
    }

    final double t = -(p.normal.dot(pickRay.origin) - p.constant) / denominator;

    if (t < 0) {
      return null;
    }

    final intersectionPoint = pickRay.origin + pickRay.direction * t;

    // containsPoint already checks for plane validity, but we check here first.
    if (toPolyline().containsPoint(intersectionPoint)) {
      return intersectionPoint;
    }

    return null;
  }

  @override
  String toString() {
    return "Origin: $origin X: $xVector Y: $yVector Z: $zVector axes: [$xAxis $yAxis $zAxis ${isValid ? normal : 'invalid'}]";
  }
}
