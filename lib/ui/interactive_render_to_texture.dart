import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fsg/scene.dart';
import 'package:fsg/ui/render_to_texture.dart';
import 'package:fsg/ui/scene_navigation_delegate.dart';
import 'package:visibility_detector/visibility_detector.dart';

class InteractiveRenderToTexture extends StatefulWidget {
  final Scene scene;
  final SceneNavigationDelegate? navigationDelegate;
  final bool automaticallyPause;
  const InteractiveRenderToTexture({
    super.key,
    this.automaticallyPause = true,
    required this.scene,
    this.navigationDelegate,
  });

  @override
  OrbitViewState createState() => OrbitViewState();
}

class OrbitViewState extends State<InteractiveRenderToTexture> {
  late FocusNode _focusNode;
  final Key _pauseKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.automaticallyPause) {
      widget.scene.isPaused = true;
    }
  }

  @override
  Widget build(BuildContext context) {

    if (widget.navigationDelegate != null) {
      widget.navigationDelegate!.setScene(widget.scene);
    }
    // TODO: Force the initial update
    // TODO: Handle all other events

    return VisibilityDetector(
      key: _pauseKey,
      onVisibilityChanged: (visibilityInfo) {
        if (widget.automaticallyPause) {
          bool visible = (visibilityInfo.visibleFraction > 0);
          widget.scene.isPaused = !visible;
        }
      },
      child: GestureDetector(
        onTapDown: (TapDownDetails event) {
          if (widget.navigationDelegate != null) {
            widget.navigationDelegate!.onTapDown(event);
          }
        },
        child: Focus(
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
                if (widget.navigationDelegate != null) {
                  widget.navigationDelegate!.onPointerScroll(event);
                }
              }
            },

            onPointerMove: (event) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
              if (widget.navigationDelegate != null) {
                widget.navigationDelegate!.onPointerMove(event);
              }
            },

            child: RenderToTexture(scene: widget.scene),
          ),
        ),
      ),
    );
  }
}


