import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:xml/xml.dart';
import '../texture_manager.dart';

class KerningInfo {
  final int first; // First character code
  final int second; // Second character code
  final double amount; // Kerning amount
  KerningInfo(this.first, this.second, this.amount);
}

class CharInfo {
  final bool isCharAvailable;

  final Rect region;

  final double xOffset;
  final double yOffset;
  final double xAdvance;

  CharInfo(
      this.isCharAvailable,
      this.region,
      this.xOffset,
      this.yOffset,
      this.xAdvance,
      );

  @override
  String toString() {
    return 'CharInfo{isCharAvailable: $isCharAvailable, region: $region, xOffset: $xOffset, yOffset: $yOffset, xAdvance: $xAdvance}';
  }
}

class BitmapFont {
  final double lineHeight;

  /// Font LineHeight
  final double baseline;

  /// Font BaseLine
  final double scaleW;

  /// Width of Font texture in pixels
  final double scaleH;

  /// Height of Font texture in pixels

  final Map<String, CharInfo> chars;

  bool initialized = false;

  // KerningInfo is a map with the first character as the key and a list of KerningInfo objects as the value.
  final Map<int, List<KerningInfo>> kerningPairs;

  WebGLTexture? fontTexture;

  final String name;
  BitmapFont(
      this.name,
      this.lineHeight,
      this.baseline,
      this.scaleW,
      this.scaleH,
      this.chars,
      this.kerningPairs,
      );
  void loadTexture(String textureName) async {
    fontTexture = await TextureManager().loadAndBindTextureFromAssets(
      textureName,
    );

    initialized = true;
  }

  static BitmapFont loadFromXML(String name, String xmlString) {
    final document = XmlDocument.parse(xmlString);

    // Access the <info> element
    // This data is present in the file but currently unused
    //final infoElement = document.findAllElements('info').first;
    //final face = infoElement.getAttribute('face');
    //final size = int.parse(infoElement.getAttribute('size')!);

    // Access the <common> element
    final commonElement = document.findAllElements('common').first;
    final lineHeight = int.parse(commonElement.getAttribute('lineHeight')!);
    final base = int.parse(commonElement.getAttribute('base')!);
    final scaleW = int.parse(commonElement.getAttribute('scaleW')!);
    final scaleH = int.parse(commonElement.getAttribute('scaleH')!);

    Map<String, CharInfo> chars = {};
    // Access the <char> elements
    final charElements = document.findAllElements('char');
    for (final charElement in charElements) {
      final id = int.parse(charElement.getAttribute('id')!);
      final x = int.parse(charElement.getAttribute('x')!);
      final y = int.parse(charElement.getAttribute('y')!);
      final width = int.parse(charElement.getAttribute('width')!);
      final height = int.parse(charElement.getAttribute('height')!);
      final xOffset = int.parse(charElement.getAttribute('xoffset')!);
      final yOffset = int.parse(charElement.getAttribute('yoffset')!);
      final xAdvance = int.parse(charElement.getAttribute('xadvance')!);

      chars.putIfAbsent(
        String.fromCharCode(id),
            () => CharInfo(
          true,
          Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            width.toDouble(),
            height.toDouble(),
          ),
          xOffset.toDouble(),
          yOffset.toDouble(),
          xAdvance.toDouble(),
        ),
      );
    }

    final kerningsSection = document.findAllElements('kernings').first;

    final kerningElements = kerningsSection.findAllElements('kerning');
    Map<int, List<KerningInfo>> kerningPairs = {};

    for (final kerningElement in kerningElements) {
      final first = int.parse(kerningElement.getAttribute('first')!);
      final second = int.parse(kerningElement.getAttribute('second')!);
      final amount = int.parse(kerningElement.getAttribute('amount')!);

      List<KerningInfo> kerningList = kerningPairs.putIfAbsent(first, () => []);
      kerningList.add(KerningInfo(first, second, amount.toDouble()));
    }

    return BitmapFont(
      name,
      lineHeight.toDouble(),
      base.toDouble(),
      scaleW.toDouble(),
      scaleH.toDouble(),
      chars,
      kerningPairs,
    );
  }
  double kerningForPair(int first, int second) {
    List<KerningInfo>? kerningPairList = kerningPairs[first];

    if (kerningPairList != null) {
      for (var kerning in kerningPairList) {
        if (kerning.first == first && kerning.second == second) {
          return kerning.amount;
        }
      }
    }

    return 0.0;
  }

  double widthOfString(String str) {
    double lineLength = 0.0;

    for (int i = 0; i < str.length; i++) {
      // Get the code unit (UTF-16) for the character at the current index
      final CharInfo? charInfo = chars[str[i]];

      double kerning = 0.0;

      if (charInfo != null) {
        // If not the last character, look up kerning info for this character and the next
        if ((i + 1) < str.length) {
          kerning = kerningForPair(str.codeUnitAt(i), str.codeUnitAt(i + 1));
        }

        lineLength += charInfo.xAdvance + kerning;
      }
    }

    return lineLength;
  }
  Size sizeOfString(String str) {
    return Size(widthOfString(str), lineHeight);
  }
}
