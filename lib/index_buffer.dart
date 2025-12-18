import 'package:flutter_angle/flutter_angle.dart';
class IndexBuffer {
  Buffer? _iboId; // OpenGL Vertex Buffer Object ID

  RenderingContext? _gl;

  int _activeIndexCount = 0;
  int _allocatedIndexCount = 0;
  int get indexCount => _activeIndexCount;

  Int16Array? _indexData;

  IndexBuffer();

Int16Array? requestBuffer(int newIndexCount) {
    bool needsToGrow = (newIndexCount > _allocatedIndexCount);

    bool needsToShrink =
        (_indexData != null) && (newIndexCount < _allocatedIndexCount / 2);

    bool needsToFreeBuffer =
        (needsToGrow || needsToShrink) && (_indexData != null);

    if (needsToFreeBuffer) {
      _indexData!.dispose();
    }
    bool needsToAlloc = (needsToGrow || needsToShrink);

    if (needsToAlloc) {
      if (newIndexCount > 0) {
        _indexData = Int16Array(newIndexCount);
      } else {
        _indexData = null;
      }
    }
    _allocatedIndexCount = newIndexCount;

    // Ensure vertices stay in range when the buffer shrinks
    if (needsToShrink) {
      _activeIndexCount = newIndexCount;
    }

    return _indexData;
  }


  void dispose() {
    if (_iboId != null) {
      _gl!.deleteBuffer(_iboId!);
      _iboId = null;
    }
      if (_indexData != null) {
        _indexData!.dispose();
        _indexData = null;
      }

  }

  void init(RenderingContext gl) {
    _gl = gl;
    _iboId = _gl!.createBuffer();
  }

  void setActiveIndexCount(int count) {
    assert(count <= _allocatedIndexCount);
    _allocatedIndexCount = count;
    _gl!.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _iboId);
    _gl!.bufferData(WebGL.ELEMENT_ARRAY_BUFFER, _indexData, WebGL.STATIC_DRAW);
    _gl!.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
  }

  void drawSetup() {
    _gl!.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _iboId);
  }

  void drawTeardown() {
    _gl!.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
  }
}
