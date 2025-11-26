import 'package:flutter_angle_jig/ui/navigation_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle_jig/gl_common/flutter_angle_manager.dart';
import 'package:flutter_angle_jig/logging.dart';
import 'package:flutter_angle_jig/ui/orbit_view_delegate.dart';
import 'simple_example_canvas.dart';

void main() async {
  Logging.logLevel = LogLevel.pedantic;
  Logging.brevity = Brevity.detailed;
  Logging.setConsoleLogFunction((String message) {
    if (kDebugMode) {
      print(message);
    }
  });

  WidgetsFlutterBinding.ensureInitialized();
  runApp(TestApp());
}

class TestApp extends StatelessWidget {

  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scene = SimpleExampleCanvas();
    final OrbitView orbitView = OrbitView();
    FlutterAngleManager().initPlatformState(context, scene);
    return MaterialApp(
        title: 'test',
        home: NavigationWidget(navigationDelegate: orbitView, scene: scene)
    );
  }
}

