import 'package:vector_math/vector_math_64.dart';

class Edge {
  final Vector3 p1;
  final Vector3 p2;
  Edge(this.p1, this.p2);

  Edge.zero() : p1 = Vector3.zero(), p2 = Vector3.zero();

  Edge transform(Vector3 origin3D, Vector3 xAxis, Vector3 yAxis) {
    Vector3 p1Transformed = origin3D + (xAxis * p1.x) + (yAxis * p1.y);
    Vector3 p2Transformed = origin3D + (xAxis * p2.x) + (yAxis * p2.y);

    return Edge(p1Transformed,p2Transformed);
  }

  static List<Edge> transformEdges(List<Edge> edges,Vector3 origin3D, Vector3 xAxis, Vector3 yAxis) {
    List<Edge> transformed = [];
    for (var e in edges) {
      transformed.add(e.transform(origin3D, xAxis, yAxis));
    }
    return transformed;
  }
}