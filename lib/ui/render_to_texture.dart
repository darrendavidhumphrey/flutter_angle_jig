import 'package:flutter/material.dart';
import 'package:fsg/ui/render_to_texture_core.dart';
import '../scene.dart';

/// A widget that renders a [Scene] to a texture and displays it.
///
/// This is a simple, non-interactive widget that uses [RenderToTextureCore] to
/// manage the underlying rendering lifecycle. For an interactive version, see
/// [InteractiveRenderToTexture].
class RenderToTexture extends StatelessWidget {
  /// The scene to be rendered.
  final Scene scene;

  /// If true, the scene will automatically pause when it is not visible.
  final bool automaticallyPause;

  const RenderToTexture({
    required this.scene,
    super.key,
    this.automaticallyPause = true,
  });

  @override
  Widget build(BuildContext context) {
    // This widget simply wraps the core rendering logic.
    return RenderToTextureCore(
      scene: scene,
      automaticallyPause: automaticallyPause,
    );
  }
}
