import 'package:flutter/material.dart';
import 'package:flutter_angle/desktop/angle.dart';
import 'package:flutter_angle/desktop/wrapper.dart';
import 'package:flutter_angle/shared/options.dart';
import 'package:flutter_angle_jig/gl_common/shaders/built_in_shaders.dart';
import 'package:flutter_angle_jig/gl_common/shaders/gl_materials.dart';
import 'package:flutter_angle_jig/gl_common/texture_manager.dart';
import '../frame_counter.dart';
import '../logging.dart';
import 'bitmap_fonts/bitmap_font_manager.dart';
import 'angle_scene.dart';

class FlutterAngleJig with LoggableClass {
  FlutterAngle angle = FlutterAngle();
  bool isInitialized = false;
  bool glIsInitialized = false;

  bool contextInitialized = false;

  static final double renderToTextureSize = 4096;
  final Map<AngleScene, FlutterAngleTexture> scenes = {};

  final textures = <FlutterAngleTexture>[];

  static final FlutterAngleJig _singleton = FlutterAngleJig._internal();

  late FrameCounterModel frameCounter;

  factory FlutterAngleJig() {
    return _singleton;
  }

  FlutterAngleJig._internal();

  Future<bool> init() async {
    if (!isInitialized) {
      isInitialized = true;
      await angle.init();
      glIsInitialized = true;

      return true;
    }
    return false;
  }

  Future<FlutterAngleTexture?> allocTexture(AngleOptions options) async {
    if (glIsInitialized) {

      var newTexture = await angle.createTexture(options);
      textures.add(newTexture);
      return newTexture;
    }
    return null;
  }

  void initScene(BuildContext context, AngleScene scene) {
    if (!scene.isInitialized) {
      scene.init(context, scene.renderToTextureId!.getContext());
    }
  }
  void initPlatformState() {
   frameCounter = FrameCounterModel();
   init();
  }

  void initDefaultMaterial() {
    Color defaultGrey = Colors.grey[200]!;
    Color defaultSpecular = Colors.black;
    const double defaultShininess = 5;

    GlMaterialManager().setDefaultMaterial(
      GlMaterial(defaultGrey, defaultGrey, defaultSpecular, defaultShininess),
    );
  }

  void initContext(RenderingContext gl) {

    if (!contextInitialized) {
      TextureManager().init(gl);
      initDefaultMaterial();

      BuiltInShaders().init(gl);
      BitmapFontManager().createDefaultFont();
      contextInitialized = true;
    }
  }

  Future<bool> allocTextureForScene(AngleScene scene) async {
    final options = AngleOptions(
      width: scene.textureWidth(),
      height: scene.textureHeight(),
      dpr: 1,
      antialias: true,
      useSurfaceProducer: true,
    );

    // Allocate an open GL texture for each scene
    var textureId = await allocTexture(options);

    bool success = (textureId != null);
    if (success) {
      scene.renderToTextureId = textureId;
      scenes[scene] = textureId;
    }
    return success;
  }
}
