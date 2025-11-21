
import 'bitmap_font.dart';
part 'built_in_font.dart';

class BitmapFontManager {
  final Map<String,BitmapFont> fonts={};
  static final BitmapFontManager _singleton = BitmapFontManager._internal();

  factory BitmapFontManager() {
    return _singleton;
  }

  BitmapFontManager._internal();


  void registerFont(String name,BitmapFont font) {
    fonts[name]=font;
  }

  BitmapFont? getFont(String name) {
    return fonts[name];
  }
  void createFont(String fontName,String xmlString, String textureName) {
    if (!fonts.containsKey(fontName)) {
      var font = BitmapFont.loadFromXML(fontName,xmlString);
      font.loadTexture(textureName);
      registerFont(fontName, font);
    }
  }

  void createDefaultFont() {
    createFont("default",creatoDisplayBoldXml,"CreatoDisplay-Bold.png");
  }

  BitmapFont get defaultFont {
    return fonts["default"]!;
  }

}