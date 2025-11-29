import 'dart:ui';
import 'package:flutter_angle/desktop/wrapper.dart';
import 'package:vector_math/vector_math_64.dart';
import 'angle_scene.dart';

abstract class AngleSceneLayer {
  late AngleScene parent;
  late RenderingContext gl;

  bool _needsRebuild = true;
  bool get needsRebuild => _needsRebuild;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AngleSceneLayer();

  Size _viewportSize = Size.zero;
  Size get viewportSize => _viewportSize;
  void setViewportSize(Size size) {
    _viewportSize = size;
  }

  void setNeedsRebuild(bool value) {
    _needsRebuild = value;
  }

  void init(RenderingContext gl) {
    this.gl = gl;
  }

  // Override this method to layer specific calculations
  void rebuild(RenderingContext gl, DateTime now);

  void setInitialized(bool value) {
    _isInitialized = value;
  }

  // Override in child class to draw layer
  void draw(Matrix4 pMatrix, Matrix4 mvMatrix);
}
