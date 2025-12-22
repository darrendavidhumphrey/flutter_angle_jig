import 'package:flutter/foundation.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/gl_context_manager.dart';

/// A manager for loading, creating, and caching WebGL textures for a given GL context.
class TextureManager with GlContextManager {
  final Map<String, Future<WebGLTexture>> _textures = {};

  /// Creates a new TextureManager.
  /// This class is intended to be held by a central singleton (e.g., FSG)
  /// rather than being a singleton itself.
  TextureManager();

  /// Loads an image from assets and creates a WebGL texture from it.
  ///
  /// Textures are cached based on their asset [url]. If a texture is already
  /// in the cache, the existing instance is returned. Otherwise, a new texture
  /// is created with the specified filtering and wrapping parameters.
  Future<WebGLTexture> createTextureFromAsset(
    String url, {
    int magFilter = WebGL.LINEAR,
    int minFilter = WebGL.LINEAR_MIPMAP_LINEAR,
    int wrapS = WebGL.REPEAT,
    int wrapT = WebGL.REPEAT,
  }) async {
    // Use putIfAbsent for robust, atomic-like caching.
    return _textures.putIfAbsent(url, () async {
      try {
        final texture = gl.createTexture();
        final data = await gl.loadImageFromAsset('assets/$url');

        gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, 1);
        gl.bindTexture(WebGL.TEXTURE_2D, texture);

        await gl.texImage2DfromImage(
          WebGL.TEXTURE_2D,
          data,
          format: WebGL.RGBA,
          type: WebGL.UNSIGNED_BYTE,
        );

        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, wrapS);
        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, wrapT);
        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, magFilter);
        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, minFilter);

        // Mipmaps are only valid if one of the min_filter options uses them.
        if (minFilter == WebGL.NEAREST_MIPMAP_NEAREST ||
            minFilter == WebGL.LINEAR_MIPMAP_NEAREST ||
            minFilter == WebGL.NEAREST_MIPMAP_LINEAR ||
            minFilter == WebGL.LINEAR_MIPMAP_LINEAR) {
          gl.generateMipmap(WebGL.TEXTURE_2D);
        }

        gl.bindTexture(WebGL.TEXTURE_2D, null);
        return texture;
      } catch (e) {
        debugPrint('Failed to load texture from asset: $url. Error: $e');
        // Remove the failed future from the cache so we can retry later.
        _textures.remove(url);
        // Re-throw to allow the caller to handle the error.
        rethrow;
      }
    });
  }

  /// Disposes all cached textures.
  ///
  /// This method is asynchronous to safely handle textures that may still be
  /// loading at the time of disposal.
  Future<void> dispose() async {
    // Wait for all outstanding texture loading operations to complete.
    await Future.wait(_textures.values.map((future) async {
      try {
        final texture = await future;
        gl.deleteTexture(texture);
      } catch (e) {
        // If loading failed, there is no texture to delete.
      }
    }));
    _textures.clear();
  }
}
