import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_angle/desktop/angle.dart';
import 'package:flutter_angle/shared/options.dart';
import '../logging.dart';
import 'opengl_scene.dart';

class FlutterAngleManager with LoggableClass {
  FlutterAngle angle = FlutterAngle();
  bool isInitialized = false;
  bool glIsInitialized = false;
  bool sceneInitialized = false;
  bool textureInitialized = false;

  static final double renderToTextureSize = 4096;
  final List<OpenGLScene> scenes = [];

  final textures = <FlutterAngleTexture>[];

  static final FlutterAngleManager _singleton = FlutterAngleManager._internal();

  factory FlutterAngleManager() {
    return _singleton;
  }

  FlutterAngleManager._internal();

  Future<bool> init() async {
    if (!isInitialized) {
      isInitialized = true;
      await angle.init();
      glIsInitialized = true;
      return true;
    }
    return false;
  }

  void addScene(OpenGLScene scene) {
    scenes.add(scene);
  }

  Future<FlutterAngleTexture?> allocTexture(AngleOptions options) async {
    if (glIsInitialized) {
      var newTexture = await angle.createTexture(options);
      textures.add(newTexture);
      return newTexture;
    }
    return null;
  }

  void initScene(BuildContext context, OpenGLScene scene) {
    if ((!sceneInitialized) && textureInitialized) {
      scene.init(context, scene.renderToTextureId!.getContext());
      sceneInitialized = true;
    }
  }

  Future<void> initPlatformState(
    BuildContext context,
    List<OpenGLScene> scenes,
  ) async {
    await init();

    if ((!context.mounted) || (!glIsInitialized)) {
      return;
    }

    try {
      for (var scene in scenes) {
        final options = AngleOptions(
          width: scene.textureWidth(),
          height: scene.textureHeight(),
          dpr: 1,
          antialias: true,
          useSurfaceProducer: true,
        );

        // Allocate an open GL texture for each scene
        var textureId = await allocTexture(options);
        scene.renderToTextureId = textureId;
      }
      textureInitialized = true;
    } on PlatformException catch (e) {
      logError("initPlatformState: ${e.message}");
      return;
    }
  }
}
