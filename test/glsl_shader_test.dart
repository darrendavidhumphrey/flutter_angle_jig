import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsg/glsl_shader.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'glsl_shader_test.mocks.dart';

// Simple valid GLSL shaders for testing.
const String kValidVertexShader = '''
  attribute vec4 a_position;
  void main() {
    gl_Position = a_position;
  }
''';

const String kValidFragmentShader = '''
  void main() {
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
  }
''';

// Invalid GLSL shaders with syntax errors.
const String kInvalidVertexShader = '''
  attribute vec4 a_position;
  void main() {
    gl_Position = a_position // Missing semicolon
  }
''';

@GenerateMocks([GlslShaderContext, Program, UniformLocation])
void main() {
  group('GlslShader.fromSource', () {
    late MockGlslShaderContext mockGl;
    late MockProgram mockProgram;
    late Object mockVertexShader;
    late Object mockFragmentShader;
    late MockUniformLocation mockUniformLocation;

    setUp(() {
      mockGl = MockGlslShaderContext();
      mockProgram = MockProgram();
      mockVertexShader = Object();
      mockFragmentShader = Object();
      mockUniformLocation = MockUniformLocation();

      // Mock the standard successful GL call sequence
      when(mockGl.createShader(WebGL.VERTEX_SHADER))
          .thenReturn(mockVertexShader);
      when(mockGl.createShader(WebGL.FRAGMENT_SHADER))
          .thenReturn(mockFragmentShader);
      when(mockGl.shaderSource(any, any)).thenReturn(null);
      when(mockGl.compileShader(any)).thenReturn(null);
      when(mockGl.createProgram()).thenReturn(mockProgram);
      when(mockGl.attachShader(any, any)).thenReturn(null);
      when(mockGl.linkProgram(any)).thenReturn(null);
      when(mockGl.getProgramParameter(any, WebGL.LINK_STATUS)).thenReturn(true);
      when(mockGl.getAttribLocation(any, any)).thenReturn(mockUniformLocation);
      when(mockGl.getUniformLocation(any, any)).thenReturn(mockUniformLocation);
      when(mockGl.enableVertexAttribArray(any)).thenReturn(null);
      when(mockGl.checkError(any)).thenReturn(null);
      when(mockGl.deleteShader(any)).thenReturn(null);
      when(mockGl.deleteProgram(any)).thenReturn(null);
      when(mockUniformLocation.id).thenReturn(1);
    });

    test('succeeds with valid shaders', () {
      when(mockGl.getShaderParameter(any, WebGL.COMPILE_STATUS))
          .thenReturn(true);

      expect(
        () => GlslShader.fromSource(
          mockGl,
          kValidFragmentShader,
          kValidVertexShader,
          ['a_position'],
          [],
        ),
        returnsNormally,
      );
    });

    test('throws and cleans up for invalid vertex shader', () {
      when(mockGl.getShaderParameter(any, WebGL.COMPILE_STATUS))
          .thenAnswer((invocation) {
        return invocation.positionalArguments[0] != mockVertexShader;
      });
      when(mockGl.getShaderInfoLog(mockVertexShader))
          .thenReturn('Vertex Compile Error');

      expect(
        () => GlslShader.fromSource(
          mockGl,
          kValidFragmentShader,
          kInvalidVertexShader,
          [],
          [],
        ),
        throwsA(isA<Exception>()),
      );

      // Verify that the failed shader was deleted.
      verify(mockGl.deleteShader(mockVertexShader)).called(1);
    });

    test('dispose cleans up program', () {
      when(mockGl.getShaderParameter(any, WebGL.COMPILE_STATUS)).thenReturn(true);
      final shader = GlslShader.fromSource(
          mockGl, kValidFragmentShader, kValidVertexShader, [], []);
      expect(shader.program, isNotNull);

      shader.dispose();

      verify(mockGl.deleteProgram(mockProgram)).called(1);
    });
  });
}
