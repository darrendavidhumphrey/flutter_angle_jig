import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'gl_common/flutter_angle_manager.dart';
import 'gl_common/opengl_scene.dart';
import 'logging.dart';

class OpenGLRenderToTextureWidget extends StatefulWidget {
  final OpenGLScene scene;
  const OpenGLRenderToTextureWidget({required this.scene,super.key});
  @override
  OpenGLRenderToTextureWidgetState createState() => OpenGLRenderToTextureWidgetState();
}

class OpenGLRenderToTextureWidgetState extends State<OpenGLRenderToTextureWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin, LoggableClass {
  Size screenSize = Size.zero;
  bool windowResized = false;
  Ticker? ticker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    if (ticker != null) {
      ticker!.dispose();
    }
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }
  @override
  void didChangeMetrics() {
    onWindowResize(context);
  }
  Future<void> onWindowResize(BuildContext context) async {
    windowResized = true;
    widget.scene.forceRepaint = true;
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {

        if (FlutterAngleManager().textureInitialized) {
          bool firstPaint = !FlutterAngleManager().sceneInitialized;
          if (firstPaint) {
            FlutterAngleManager().initScene(context,widget.scene);
            logTrace("Start RenderToTexture Ticker for scene of type ${widget.scene.runtimeType}");
            ticker = createTicker(widget.scene.renderSceneToTexture);
            ticker!.start();
          }

          if (firstPaint || windowResized) {
            windowResized = false;
            screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            widget.scene.setViewportSize(screenSize);
            // TODO: Notify canvasBloc.setViewportSize(Size(constraints.maxWidth, constraints.maxHeight));
          }
        } else {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            logTrace("Scheduling a refresh because texture is not initialized");
            // TODO: Notify canvasBloc.add(RefreshViewEvent());
          });
        }
        if (widget.scene.renderToTextureId == null) {
          return Container();
        }
        return Texture(textureId: widget.scene.renderToTextureId!.textureId,filterQuality: FilterQuality.medium);
      },
    );
  }
}
