import 'package:flutter/material.dart';
import 'package:flutter_angle_jig/frame_counter.dart';
import 'package:flutter_angle_jig/gl_common/bitmap_fonts/bitmap_font_manager.dart';
import 'package:flutter_angle_jig/gl_common/flutter_angle_manager.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_angle_jig/gl_common/opengl_scene.dart';
import 'package:flutter_angle_jig/gl_common/shaders/built_in_shaders.dart';
import 'package:flutter_angle_jig/gl_common/shaders/gl_materials.dart';
import 'package:flutter_angle_jig/gl_common/texture_manager.dart';
import 'package:flutter_angle_jig/logging.dart';
import 'package:flutter_angle_jig/opengl_render_to_texture.dart';
import 'package:provider/provider.dart';

class OpenGLCanvas extends OpenGLScene  {

  OpenGLCanvas();

  void initMaterials() {
    Color defaultGrey = Colors.grey[200]!;
    Color defaultSpecular = Colors.black;
    const double defaultShininess = 5;

    GlMaterialManager().setDefaultMaterial(
      GlMaterial(defaultGrey, defaultGrey, defaultSpecular, defaultShininess),
    );

    GlMaterialManager().addMaterial(
      "X",
      GlMaterial(Colors.red, Colors.red, defaultSpecular, defaultShininess),
    );

    GlMaterialManager().addMaterial(
      "Y",
      GlMaterial(Colors.green, Colors.green, defaultSpecular, defaultShininess),
    );

    GlMaterialManager().addMaterial(
      "Z",
      GlMaterial(Colors.blue, Colors.blue, defaultSpecular, defaultShininess),
    );

    GlMaterialManager().addMaterial(
      "BURLYWOOD4",
      GlMaterial(
        Colors.yellow,
        Colors.yellow,
        defaultSpecular,
        defaultShininess,
      ),
    );
  }

  @override
  void init(BuildContext context, RenderingContext gl) {
    super.init(context, gl);
    TextureManager().init(gl);

    initMaterials();

    BuiltInShaders().init(gl);
    BitmapFontManager().createDefaultFont();


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
    rebuildLayers(gl,now);

    drawLayers();

    mvPopMatrix();

    gl.finish();
  }
}

void main() async {
  Logging.logLevel = LogLevel.pedantic;
  Logging.brevity = Brevity.detailed;
  Logging.setConsoleLogFunction((String message) {
    // if (kDebugMode) {
    print(message);
    //  }
  });

  WidgetsFlutterBinding.ensureInitialized();
  final OpenGLCanvas canvas = OpenGLCanvas();

  runApp(TestApp(canvas: canvas));
}


class TestApp extends StatelessWidget {

  final OpenGLCanvas canvas;
  const TestApp({super.key, required this.canvas});

  @override
  Widget build(BuildContext context) {
    FlutterAngleManager().initPlatformState(context, [canvas]);
    return
      ChangeNotifierProvider(
          create: (context) => FrameCounterModel(),
          child:
          MaterialApp(title: 'test',
        home: MainScreen(canvas: canvas)));
  }
}

class MainScreen extends StatelessWidget {
  final OpenGLCanvas canvas;
  const MainScreen({super.key, required this.canvas});

  @override
  Widget build(BuildContext context) {
    return Consumer<FrameCounterModel>(
        builder: (context, counter, child) {
          print("count: ${counter.count}");

    return OpenGLRenderToTextureWidget(
    scene: canvas);
  });
    }
}