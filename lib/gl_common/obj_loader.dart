import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';

import '../float32_array_filler.dart';
class VertexAttributeCombination {
  int positionIndex;
  int texCoordIndex;
  int normalIndex;
  VertexAttributeCombination(
    this.positionIndex,
    this.texCoordIndex,
    this.normalIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VertexAttributeCombination &&
          runtimeType == other.runtimeType &&
          positionIndex == other.positionIndex &&
          texCoordIndex == other.texCoordIndex &&
          normalIndex == other.normalIndex;
  @override
  int get hashCode =>
      positionIndex.hashCode ^ texCoordIndex.hashCode ^ normalIndex.hashCode;
}

// A combination of position, texCoord and normal
class P3T2N3 {
  Vector3 position;
  Vector2 texCoord;
  Vector3 normal;
  P3T2N3(this.position, this.texCoord, this.normal);
}


class Face {
  List<int> corners; // A face is defined a list of corner indices

  Face(List<int> faceCorners) :
    corners = toTriangleIndices(faceCorners);

  // Wavefront objects can contain faces with more than 3 corners
  // This function converts a face with more than 3 corners into a list of triangles
  static List<int> toTriangleIndices(List<int> faceCorners) {
    if (faceCorners.length == 3) {
      return faceCorners;
    }

    List<int> result = [];

    for (int i = 0; i < faceCorners.length - 2; i++) {
      result.add(faceCorners[0]);
      result.add(faceCorners[i + 1]);
      result.add(faceCorners[i + 2]);
    }
    return result;
  }
}

class Mesh {
  String? materialName;
  final List<int> triangleIndices = [];
  final int bufferOffset;
  Mesh(List<Face> faces, {required this.bufferOffset, this.materialName}) {
    for (var face in faces) {
      triangleIndices.addAll(face.corners);
    }
  }
}

class WavefrontObjModel {
  List<P3T2N3> vertices = [];
  List<Mesh> meshes = [];

  Float32Array vertexData() {
    const int p2t2n3ComponentCount = 8;
    Float32Array vertexData = Float32Array(
      vertices.length * p2t2n3ComponentCount,
    );

    Float32ArrayFiller filler = Float32ArrayFiller(vertexData);

    for (int i = 0; i < vertices.length; i++) {
      P3T2N3 v = vertices[i];
      filler.addV3T2N3(v.position, v.texCoord, v.normal);
    }
    return vertexData;
  }

  // Modified function to process OBJ file and return a list of meshes
  void loadFromString(String objFileContent) {
    List<Vector3> tempPositions = [];
    List<Vector2> tempTextureCoordinates = [];
    List<Vector3> tempNormals = [];

    HashMap<VertexAttributeCombination, int> uniqueVertexMap = HashMap();
    int nextAvailableIndex = 0;

    List<String> lines = LineSplitter().convert(objFileContent);

    List<Face> currentMeshFaces = []; // Store Faces for the current mesh

    int iboOffset = 0;

    String currentMaterialName = "defaultMaterial";
    for (String line in lines) {
      List<String> parts = line.split(' ');
      int count = 0;
      String prefix = parts[count++];

      if (prefix == "v") {
        Vector3 pos = Vector3(
          double.parse(parts[count++]),
          double.parse(parts[count++]),
          double.parse(parts[count++]),
        );
        // print("tempPositions[${tempPositions.length}] ${pos.toString()}");
        tempPositions.add(pos);
      } else if (prefix == "vt") {
        Vector2 tc = Vector2(
          double.parse(parts[count++]),
          double.parse(parts[count++]),
        );
        tempTextureCoordinates.add(tc);
      } else if (prefix == "vn") {
        Vector3 normal = Vector3(
          double.parse(parts[count++]),
          double.parse(parts[count++]),
          double.parse(parts[count++]),
        );
        tempNormals.add(normal);
      } else if (prefix == "usemtl") {
        // Encountered a new material, so the previous set of faces (if any)
        // belongs to a mesh with the old material or no material.
        if (currentMeshFaces.isNotEmpty) {
          Mesh newMesh = Mesh(
            currentMeshFaces,
            bufferOffset: iboOffset,
            materialName: currentMaterialName,
          );
          meshes.add(newMesh);
          iboOffset += newMesh.triangleIndices.length;
          currentMeshFaces = []; // Reset for the new material
        }
        currentMaterialName = parts[1]; // Store the new material name
      } else if (prefix == "f") {
        List<int> faceCorners = []; // Corners for the current face
        // print("|$line|  parts length is ${parts.length}");
        for (int i = 1; i < parts.length; i++) {
          String vertexStr = parts[i];
          List<String> indicesStr = vertexStr.split('/');

          //print("f part [$i] |$indicesStr| length is ${indicesStr.length}");
          if (indicesStr.length == 3) {
            int positionIndex = int.parse(indicesStr[0]) - 1;
            int texCoordIndex = int.parse(indicesStr[1]) - 1;
            int normalIndex = int.parse(indicesStr[2]) - 1;

            VertexAttributeCombination currentCombination =
                VertexAttributeCombination(
                  positionIndex,
                  texCoordIndex,
                  normalIndex,
                );

            if (!uniqueVertexMap.containsKey(currentCombination)) {
              // print("face indices $positionIndex texCoord $texCoordIndex normal $normalIndex",);
              // print("Add vertex(${vertices.length})");

              var newVert = P3T2N3(
                tempPositions[currentCombination.positionIndex],
                tempTextureCoordinates[currentCombination.texCoordIndex],
                tempNormals[currentCombination.normalIndex],
              );

              vertices.add(newVert);
              uniqueVertexMap[currentCombination] = nextAvailableIndex++;
            } else {
              //print("Vertex already exists");
            }

            int meshIndex = uniqueVertexMap[currentCombination]!;

            //print("Add index to mesh $meshIndex");
            faceCorners.add(meshIndex); // Add to the current face's corners
          }
        }

        currentMeshFaces.add(
          Face(faceCorners),
        ); // Add the completed face to the current mesh's faces
      } else if (prefix == "o" || prefix == "g" || line == lines.last) {
        if (currentMeshFaces.isNotEmpty) {
          Mesh newMesh = Mesh(
            currentMeshFaces,
            bufferOffset: iboOffset,
            materialName: currentMaterialName,
          );
          meshes.add(newMesh);
          iboOffset += newMesh.triangleIndices.length;
          currentMeshFaces = []; // Reset for the next mesh
        }
      }
    }

    // Handle any remaining faces if the file doesn't end with an 'o' or 'g'
    if (currentMeshFaces.isNotEmpty) {
      Mesh newMesh = Mesh(
        currentMeshFaces,
        bufferOffset: iboOffset,
        materialName: currentMaterialName,
      );
      meshes.add(newMesh);
      iboOffset += newMesh.triangleIndices.length;
    }
  }

  /*  Debug code
  void dump() {
    print("Vertices: ${vertices.length}");
    for (var vert in vertices) {
      print("Vertex: ${vert.position} ${vert.texCoord} ${vert.normal}");
    }
    print("Meshes: ${meshes.length}");

    for (var mesh in meshes) {
      print("Mesh with ${mesh.triangleIndices.length} indices");
      print("Mesh material: ${mesh.materialName}");


      for (var index in mesh.triangleIndices) {
        print("Index: $index");
      }
    }
  }
   */
  WavefrontObjModel();

  static Future<WavefrontObjModel?> loadObjFromFile(String filePath) async {
    try {

      String objFileContent =
          await rootBundle.loadString(filePath); // Read the entire file content as a string
      WavefrontObjModel objModel = WavefrontObjModel();
      objModel.loadFromString(objFileContent);
      return objModel;
    } catch (e) {
      throw Exception("Error loading OBJ file: $e");
    }
  }
}
