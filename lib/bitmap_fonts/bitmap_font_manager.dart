import 'bitmap_font.dart';
part 'built_in_font.dart';

/// A manager for loading, creating, and accessing [BitmapFont] objects.
///
/// This class is intended to be held by a central singleton (e.g., FSG) and is
/// responsible for caching fonts and ensuring their textures are loaded before use.
class BitmapFontManager {
  /// The internal cache of registered fonts, keyed by their unique name.
  final Map<String, BitmapFont> _fonts = {};

  /// Creates a new BitmapFontManager.
  BitmapFontManager();

  /// Registers a pre-loaded [BitmapFont] instance with a given [name].
  void registerFont(String name, BitmapFont font) {
    _fonts[name] = font;
  }

  /// Retrieves a font by its registered [name].
  ///
  /// Returns `null` if a font with the given name has not been registered.
  BitmapFont? getFont(String name) {
    return _fonts[name];
  }

  /// Creates a font from XML data, loads its texture, and registers it.
  ///
  /// This method is asynchronous to ensure the font's texture is fully loaded
  /// from assets and ready for rendering before the font is registered. This
  /// prevents race conditions where a font might be used before its texture is valid.
  Future<void> createFont(
      String fontName, String xmlString, String textureName) async {
    // Only create and load the font if it hasn't been registered already.
    if (!_fonts.containsKey(fontName)) {
      var font = BitmapFont.fromXml(fontName, xmlString);
      // Correctly await the texture loading before registering the font.
      await font.loadTexture(textureName);
      registerFont(fontName, font);
    }
  }

  /// A convenience method to create and register the default font for the application.
  Future<void> createDefaultFont() async {
    await createFont("default", creatoDisplayBoldXml, "CreatoDisplay-Bold.png");
  }

  /// Returns the default font, which is expected to be named "default".
  ///
  /// Throws a [StateError] if the default font has not been created yet by
  /// calling [createDefaultFont].
  BitmapFont get defaultFont {
    final font = _fonts["default"];
    if (font == null) {
      throw StateError(
          'The default font has not been created. Call createDefaultFont() first.');
    }
    return font;
  }
}
