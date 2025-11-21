import 'dart:ui';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';

class Float32ArrayFiller {
  Float32Array array;
  int _currentPosition = 0;
  int get currentPosition => _currentPosition;

  Float32ArrayFiller(this.array);

  // Add a vector3
  void addV3(Vector3 vec) {
    assert (_currentPosition <= array.length-3);
    array[_currentPosition++] = vec.x;
    array[_currentPosition++] = vec.y;
    array[_currentPosition++] = vec.z;
  }

  // Add a color
  void addC4(Color color) {
    assert (_currentPosition <= array.length-4);
    array[_currentPosition++] = color.r;
    array[_currentPosition++] = color.g;
    array[_currentPosition++] = color.b;
    array[_currentPosition++] = color.a;
  }

  // Add a position and a color
  void addV3C4(Vector3 vec, Color color) {
    addV3(vec);
    addC4(color);
  }

  // Add a vector2
  void addV2(Vector2 vec) {
    assert (_currentPosition <= array.length-2);
    array[_currentPosition++] = vec.x;
    array[_currentPosition++] = vec.y;
  }

  // Add a position and a texture coordinate
  void addV3V2(Vector3 v3, Vector2 v2) {
    addV3(v3);
    addV2(v2);
  }

  // Add a position and a texture coordinate
  void addV3T2N3(Vector3 v, Vector2 tc,Vector3 n) {
    addV3(v);
    addV2(tc);
    addV3(n);
  }

  // Add a triangle with color
  void addTriangleWithColor(Vector3 v1, Vector3 v2, Vector3 v3,Color color) {
    addV3C4(v1, color);
    addV3C4(v2, color);
    addV3C4(v3, color);
  }


  // Add a 2D textured rectangle to the array
  void addTexturedQuad(Quad q, Rect tr) {
    Vector2 tTlc = Vector2(tr.left, tr.top);
    Vector2 tTrc = Vector2(tr.right, tr.top);
    Vector2 tBlc = Vector2(tr.left, tr.bottom);
    Vector2 tBrc = Vector2(tr.right, tr.bottom);

    // First triangle blc,brc,trc
    addV3V2(q.point0, tBlc);
    addV3V2(q.point1, tBrc);
    addV3V2(q.point2, tTrc);

    // Second triangle blc,trc,tlc
    addV3V2(q.point0, tBlc);
    addV3V2(q.point2, tTrc);
    addV3V2(q.point3, tTlc);
  }
}