import 'package:fsg/polyline.dart';
import 'package:fsg/util.dart';
import 'package:vector_math/vector_math_64.dart';

class ReferenceBox {
  bool get isValid => _isValid;
  Vector3 get normal => plane.normal;
  Vector3 get xAxis => _xAxis;
  Vector3 get yAxis => _yAxis;
  Vector3 origin;
  Vector3 xVector;
  Vector3 yVector;
  Vector3 zVector;
  late Plane plane;
  bool _isValid = false;
  late Vector3 _xAxis;
  late Vector3 _yAxis;
  late Quad _cachedQuad;
  Quad get cachedQuad => _cachedQuad;
  ReferenceBox.zero()
      : origin = Vector3.zero(),
        xVector = Vector3.zero(),
        yVector = Vector3.zero(),
        zVector = Vector3.zero() {
    plane = Plane.components(0, 0, 1, 0);
    _isValid = false;
    _xAxis = Vector3.zero();
    _yAxis = Vector3.zero();
    setQuad();
  }
  ReferenceBox(this.origin, this.xVector, this.yVector, this.zVector) {
    _xAxis = xVector.normalized();
    _yAxis = yVector.normalized();
    setPlane();
    setQuad();
  }

  // A more efficient constructor that copies over common fields that don't need
  // to be recalculated when the make a new reference box that is a subset of
  // the old one
  ReferenceBox.makeOffsetBox(
      ReferenceBox other,
      this.origin,
      this.xVector,
      this.yVector,
      this.zVector,
      ) {
    plane = other.plane;
    _isValid = other._isValid;
    _xAxis = other._xAxis;
    _yAxis = other._yAxis;
    setQuad();
  }

  @override
  String toString() {
    return "Origin: ${origin.toString()} "
        "X: ${xVector.toString()} "
        "Y: ${yVector.toString()} "
        "Z: ${zVector.toString()} "
        "axes: [${xAxis.toString()} "
        "${yAxis.toString()} "
        "${plane.normal.toString()}]";
  }

  ReferenceBox makeRefBoxFromOffsets3D(
      Vector2 startOffset2D,
      Vector2 endOffset2D,
      ) {
    List<Vector3> corners = calcCornersFrom2DVectors(
      origin,
      startOffset2D,
      endOffset2D,
      xAxis,
      yAxis,
    );
    var newXVector = xVector.normalized() * (endOffset2D.x - startOffset2D.x);
    var newYVector = yVector.normalized() * (endOffset2D.y - startOffset2D.y);
    var refBox = ReferenceBox(corners[0], newXVector, newYVector, zVector);
    return refBox;
  }

  static List<Vector3> calcCornersFrom2DVectors(
      Vector3 origin3D,
      Vector2 startOffset2D,
      Vector2 endOffset2D,
      Vector3 xAxis,
      Vector3 yAxis,
      ) {
    // Calculate the four corners by combining the 3D origin with the 2D offsets
    // projected onto the 3D plane using the direction vectors.
    return [
      // Corner 1: (startOffset2D.x, startOffset2D.y) in local 2D space
      origin3D + (xAxis * startOffset2D.x) + (yAxis * startOffset2D.y),

      // Corner 2: (endOffset2D.x, startOffset2D.y) in local 2D space
      origin3D + (xAxis * endOffset2D.x) + (yAxis * startOffset2D.y),

      // Corner 3: (endOffset2D.x, endOffset2D.y) in local 2D space
      origin3D + (xAxis * endOffset2D.x) + (yAxis * endOffset2D.y),

      // Corner 4: (startOffset2D.x, endOffset2D.y) in local 2D space
      origin3D + (xAxis * startOffset2D.x) + (yAxis * endOffset2D.y),
    ];
  }

  Quad calcQuadFrom2DVectors(Vector2 startOffset2D, Vector2 endOffset2D) {
    List<Vector3> corners = calcCornersFrom2DVectors(
      origin,
      startOffset2D,
      endOffset2D,
      xAxis,
      yAxis,
    );
    return Quad.points(corners[0], corners[1], corners[2], corners[3]);
  }

  Polyline polylineFrom2DVectors(Vector2 startOffset2D, Vector2 endOffset2D) {
    List<Vector3> corners = calcCornersFrom2DVectors(
      origin,
      startOffset2D,
      endOffset2D,
      xAxis,
      yAxis,
    );
    return Polyline.fromVector3(corners);
  }

  // Make a polyline from the origin, xVec and yVec
  // Compute the top left corner as the sum of those three
  Polyline toPolyline() {
    return Polyline.fromVector3([
      cachedQuad.point0,
      cachedQuad.point1,
      cachedQuad.point2,
      cachedQuad.point3,
    ]);
  }

  void setQuad() {
    Vector3 p0 = origin;
    Vector3 p1 = p0 + xVector; // origin + xVector
    Vector3 p2 = p1 + yVector; // origin + xVector + yVector
    Vector3 p3 = p0 + yVector; // origin + yVector

    _cachedQuad = Quad.points(p0, p1, p2, p3);
  }

  void setPlane() {
    Plane? p = makePlaneFromVertices(
      origin,
      origin + xVector,
      origin + yVector,
    );
    if (p != null) {
      _isValid = true;
      plane = p;
    } else {
      plane = Plane.components(0, 0, 1, 0);
      _isValid = false;
    }
  }

  Vector3 transformPointToReferencePlane(Vector2 v) {
    return origin + (xAxis * v.x) + (yAxis * v.y);
  }
}
