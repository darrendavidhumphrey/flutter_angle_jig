import 'package:flutter_angle/flutter_angle.dart';

class TextureManager {
  late RenderingContext gl;
  static final TextureManager _singleton = TextureManager._internal();
  factory TextureManager() {
    return _singleton;
  }
  TextureManager._internal();
  Map<String, WebGLTexture> textures = {};
  void init(RenderingContext gl) {
    this.gl = gl;
  }
  Future<WebGLTexture> loadAndBindTextureFromAssets(
    String url) async {

    // Check if texture is already loaded
    if (textures[url] != null) {
      return textures[url]!;
    }

    WebGLTexture texture = gl.createTexture();
    final data = await gl.loadImageFromAsset('assets/$url');

      gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, 1);
      gl.bindTexture(WebGL.TEXTURE_2D, texture);

      await gl.texImage2DfromImage(
        WebGL.TEXTURE_2D,
        data,
        format: WebGL.RGBA,
        type: WebGL.UNSIGNED_BYTE,
      );

      gl.texParameteri(
        WebGL.TEXTURE_2D,
        WebGL.TEXTURE_MAG_FILTER,
        WebGL.LINEAR_MIPMAP_LINEAR,
      );
      gl.texParameteri(
        WebGL.TEXTURE_2D,
        WebGL.TEXTURE_MIN_FILTER,
        WebGL.LINEAR_MIPMAP_LINEAR,
      );
      gl.generateMipmap(WebGL.TEXTURE_2D);
      gl.bindTexture(WebGL.TEXTURE_2D, null);
      textures[url] = texture;
      return texture;
  }
}