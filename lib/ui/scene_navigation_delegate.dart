import 'package:flutter/gestures.dart';
import '../scene.dart';

abstract class SceneNavigationDelegate {

  void setScene(Scene scene);

  void onTapDown(TapDownDetails event);
  void onPointerDown(PointerDownEvent event);
  void onPointerMove(PointerMoveEvent event);
  void onPointerScroll(PointerScrollEvent event);
}