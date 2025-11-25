import 'package:flutter/material.dart';
import 'package:flutter_angle_jig/gl_common/bitmap_fonts/bitmap_font_manager.dart';
import 'package:flutter_angle_jig/gl_common/flutter_angle_manager.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_angle_jig/gl_common/opengl_scene.dart';
import 'package:flutter_angle_jig/gl_common/shaders/built_in_shaders.dart';
import 'package:flutter_angle_jig/gl_common/shaders/gl_materials.dart';
import 'package:flutter_angle_jig/gl_common/texture_manager.dart';
import 'package:flutter_angle_jig/logging.dart';
import 'package:flutter_angle_jig/opengl_render_to_texture.dart';

class OpenGLCanvas extends OpenGLScene {
  OpenGLCanvas();

  void initMaterials() {
    Color defaultGrey = Colors.grey[200]!;
    Color defaultSpecular = Colors.black;
    const double defaultShininess = 5;

    GlMaterialManager().setDefaultMaterial(
      GlMaterial(defaultGrey, defaultGrey, defaultSpecular, defaultShininess),
    );
  }

  @override
  void init(BuildContext context, RenderingContext gl) {
    super.init(context, gl);
    TextureManager().init(gl);

    initMaterials();

    BuiltInShaders().init(gl);
    BitmapFontManager().createDefaultFont();

    // TODO: Add a layer
    // gl.viewport(0, 0, viewportSize.width.toInt(), viewportSize.height.toInt());
  }

  @override
  void dispose() {}

  @override
  void drawScene() {
    gl.clearColor(1.0, 0.0, 0.0, 1.0);

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.enable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.BLEND);
    gl.disable(WebGL.CULL_FACE);
    gl.depthFunc(WebGL.LESS);

    mvPushMatrix();
    // TODO: Matrices
    pMatrix = Matrix4.identity();
    mvMatrix = Matrix4.identity();

    // Rebuild (if needed) and draw all layers
    DateTime now = DateTime.now();
    rebuildLayers(gl, now);

    drawLayers();

    mvPopMatrix();

    gl.finish();
  }
}

void main() async {
  Logging.logLevel = LogLevel.trace;
  Logging.brevity = Brevity.detailed;
  Logging.setConsoleLogFunction((String message) {
    // if (kDebugMode) {
    print(message);
    //  }
  });
  WidgetsFlutterBinding.ensureInitialized();
  final OpenGLCanvas canvas = OpenGLCanvas();

  runApp(ExampleApp(canvas: canvas));
}

class ExampleApp extends StatelessWidget {
  final OpenGLCanvas canvas;
  const ExampleApp({super.key, required this.canvas});

  @override
  Widget build(BuildContext context) {
    FlutterAngleManager().initPlatformState(context, [canvas]);
    return MaterialApp(
      title: 'test',
      home: ExampleMainScreen(canvas: canvas),
    );
  }
}

class ExampleMainScreen extends StatelessWidget {
  final OpenGLCanvas canvas;
  const ExampleMainScreen({super.key, required this.canvas});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        /* canvasBloc.setViewportSize(
            Size(constraints.maxWidth, constraints.maxHeight));\
          */
        return OpenGLRenderToTextureWidget(scene: canvas);
      },
    );
  }
}
