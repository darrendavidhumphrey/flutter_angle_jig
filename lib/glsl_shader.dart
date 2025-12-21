import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'logging.dart';

/// Defines an abstract interface for the WebGL rendering context methods needed
/// by the [GlslShader] class. This allows for easier testing by mocking this
/// interface instead of the complex [RenderingContext].
abstract class GlslShaderContext {
  dynamic createShader(int type);
  void shaderSource(dynamic shader, String source);
  void compileShader(dynamic shader);
  dynamic getShaderParameter(dynamic shader, int pname);
  String? getShaderInfoLog(dynamic shader);
  Program createProgram();
  void attachShader(Program program, dynamic shader);
  void linkProgram(Program program);
  dynamic getProgramParameter(Program program, int pname);
  String? getProgramInfoLog(Program program);
  void deleteShader(dynamic shader);
  void deleteProgram(Program program);
  UniformLocation getAttribLocation(Program program, String name);
  UniformLocation getUniformLocation(Program program, String name);
  void enableVertexAttribArray(int index);
  void checkError(String label);
}

/// A concrete implementation of [GlslShaderContext] that wraps a real
/// [RenderingContext] from the `flutter_angle` package. Your application will
/// use this class at runtime.
class RenderingContextWrapper implements GlslShaderContext {
  final RenderingContext _gl;

  RenderingContextWrapper(this._gl);

  @override
  dynamic createShader(int type) => _gl.createShader(type);
  @override
  void shaderSource(dynamic shader, String source) =>
      _gl.shaderSource(shader, source);
  @override
  void compileShader(dynamic shader) => _gl.compileShader(shader);
  @override
  dynamic getShaderParameter(dynamic shader, int pname) =>
      _gl.getShaderParameter(shader, pname);
  @override
  String? getShaderInfoLog(dynamic shader) => _gl.getShaderInfoLog(shader);
  @override
  Program createProgram() => _gl.createProgram();
  @override
  void attachShader(Program program, dynamic shader) =>
      _gl.attachShader(program, shader);
  @override
  void linkProgram(Program program) => _gl.linkProgram(program);
  @override
  dynamic getProgramParameter(Program program, int pname) =>
      _gl.getProgramParameter(program, pname);
  @override
  String? getProgramInfoLog(Program program) => _gl.getProgramInfoLog(program);
  @override
  void deleteShader(dynamic shader) => _gl.deleteShader(shader);
  @override
  void deleteProgram(Program program) => _gl.deleteProgram(program);
  @override
  UniformLocation getAttribLocation(Program program, String name) =>
      _gl.getAttribLocation(program, name);
  @override
  UniformLocation getUniformLocation(Program program, String name) =>
      _gl.getUniformLocation(program, name);
  @override
  void enableVertexAttribArray(int index) => _gl.enableVertexAttribArray(index);
  @override
  void checkError(String label) => _gl.checkError(label);
}

/// A class that encapsulates a WebGL shader program.
class GlslShader with LoggableClass {
  final Map<String, int> _attributes = <String, int>{};
  final Map<String, UniformLocation> _uniforms = <String, UniformLocation>{};
  Program? program;

  final GlslShaderContext gl;
  final List<String> attributeNames;
  final List<String> uniformNames;
  final int _sourceHashCode;

  Map<String, int> get attributes => UnmodifiableMapView(_attributes);
  Map<String, UniformLocation> get uniforms => UnmodifiableMapView(_uniforms);

  /// Private constructor. Use the factory `fromSource`.
  GlslShader._internal(
    this.gl,
    this.attributeNames,
    this.uniformNames,
    this._sourceHashCode,
  );

  /// Compiles shaders from source and creates a GlslShader instance.
  static GlslShader fromSource(
    GlslShaderContext gl,
    String fragSrc,
    String vertSrc,
    List<String> attributeNames,
    List<String> uniformNames,
  ) {
    final shader = GlslShader._internal(
        gl, attributeNames, uniformNames, Object.hash(fragSrc, vertSrc));
    shader._compileAndLink(fragSrc, vertSrc);
    return shader;
  }

  void _compileAndLink(String fragSrc, String vertSrc) {
    dynamic fragShader;
    dynamic vertShader;
    try {
      fragShader = _compileShader(WebGL.FRAGMENT_SHADER, fragSrc);
      vertShader = _compileShader(WebGL.VERTEX_SHADER, vertSrc);

      final p = gl.createProgram();
      program = p;
      gl.attachShader(p, vertShader);
      gl.attachShader(p, fragShader);
      gl.linkProgram(p);

      if (!(gl.getProgramParameter(p, WebGL.LINK_STATUS) as bool)) {
        throw Exception(
            'Shader program linking failed: ${gl.getProgramInfoLog(p) ?? ''}');
      }

      _fetchAttributeAndUniformLocations(p);
    } catch (e) {
      logError('Error creating GlslShader: $e');
      dispose();
      rethrow;
    } finally {
      if (vertShader != null) gl.deleteShader(vertShader);
      if (fragShader != null) gl.deleteShader(fragShader);
    }
  }

  dynamic _compileShader(int type, String source) {
    final shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!(gl.getShaderParameter(shader, WebGL.COMPILE_STATUS) as bool)) {
      final error =
          'Shader compilation failed (${type == WebGL.VERTEX_SHADER ? 'Vertex' : 'Fragment'}): ${gl.getShaderInfoLog(shader) ?? ''}';
      gl.deleteShader(shader);
      throw Exception(error);
    }
    return shader;
  }

  void _fetchAttributeAndUniformLocations(Program p) {
    for (String attrib in attributeNames) {
      int attributeLocation = gl.getAttribLocation(p, attrib).id;
      gl.enableVertexAttribArray(attributeLocation);
      gl.checkError(attrib);
      _attributes[attrib] = attributeLocation;
    }
    for (String uniform in uniformNames) {
      var uniformLocation = gl.getUniformLocation(p, uniform);
      gl.checkError(uniform);
      _uniforms[uniform] = UniformLocation(uniformLocation.id);
    }
  }

  void dispose() {
    final p = program;
    if (p != null) {
      gl.deleteProgram(p);
      program = null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlslShader &&
        other.runtimeType == runtimeType &&
        other.gl == gl &&
        other._sourceHashCode == _sourceHashCode &&
        listEquals(other.attributeNames, attributeNames) &&
        listEquals(other.uniformNames, uniformNames);
  }

  @override
  int get hashCode => Object.hash(
        gl,
        _sourceHashCode,
        Object.hashAll(attributeNames),
        Object.hashAll(uniformNames),
      );
}
