import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle_jig/gl_common/opengl_scene.dart';
import 'package:flutter_angle_jig/opengl_render_to_texture.dart';
import 'package:flutter_angle_jig/ui/navigation_delegate.dart';

class NavigationWidget extends StatefulWidget {
  final OpenGLScene scene;
  final NavigationDelegate navigationDelegate;
  const NavigationWidget({super.key, required this.scene, required this.navigationDelegate});

  @override
  OrbitViewState createState() => OrbitViewState();
}

class OrbitViewState extends State<NavigationWidget> {
  late FocusNode _focusNode;


  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    widget.navigationDelegate.setScene(widget.scene);

    // TODO: Force the initial update
    // TODO: Handle all other events
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // TODO: Handle keyboard event
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerSignal: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          if (event is PointerScrollEvent) {
            widget.navigationDelegate.onPointerScroll(event);
          }
        },
        onPointerDown: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          if (event.kind == PointerDeviceKind.mouse) {
            if (event.buttons == kPrimaryButton) {
              widget.navigationDelegate.onPointerDown(event);
            }
          }
        },
        onPointerMove: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          if (event.kind == PointerDeviceKind.mouse) {
            if (event.buttons == kPrimaryButton) {
              widget.navigationDelegate.onPointerMove(event);
            }
          }
        },

        child: OpenGLRenderToTextureWidget(scene: widget.scene),
      ),
    );
  }
}

