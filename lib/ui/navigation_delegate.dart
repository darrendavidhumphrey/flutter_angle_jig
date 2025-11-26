import 'package:flutter/gestures.dart';
import '../gl_common/opengl_scene.dart';

abstract class NavigationDelegate {

  void setScene(OpenGLScene scene);

  void onPointerDown(PointerDownEvent event);
  void onPointerMove(PointerMoveEvent event);
  void onPointerScroll(PointerScrollEvent event);
}