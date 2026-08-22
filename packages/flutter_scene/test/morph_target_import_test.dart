import 'dart:typed_data';

import 'package:flutter_scene/src/importer/gltf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('packs sparse glTF morph targets into the engine vertex set', () {
    final bytes = ByteData(88);
    final basePositions = <double>[0, 0, 0, 1, 0, 0, 0, 1, 0];
    final baseNormals = <double>[0, 0, 1, 0, 0, 1, 0, 0, 1];
    for (var i = 0; i < basePositions.length; i++) {
      bytes.setFloat32(i * 4, basePositions[i], Endian.little);
      bytes.setFloat32(36 + i * 4, baseNormals[i], Endian.little);
    }
    bytes.setUint8(72, 1);
    bytes.setFloat32(76, 0.25, Endian.little);
    bytes.setFloat32(80, 0.5, Endian.little);
    bytes.setFloat32(84, -0.25, Endian.little);

    final bufferViews = <GltfBufferView>[
      GltfBufferView(buffer: 0, byteLength: 36, byteOffset: 0),
      GltfBufferView(buffer: 0, byteLength: 36, byteOffset: 36),
      GltfBufferView(buffer: 0, byteLength: 1, byteOffset: 72),
      GltfBufferView(buffer: 0, byteLength: 12, byteOffset: 76),
    ];
    final accessors = <GltfAccessor>[
      GltfAccessor(
        componentType: GltfComponentType.float,
        count: 3,
        type: GltfAccessorType.vec3,
        bufferView: 0,
      ),
      GltfAccessor(
        componentType: GltfComponentType.float,
        count: 3,
        type: GltfAccessorType.vec3,
        bufferView: 1,
      ),
      GltfAccessor(
        componentType: GltfComponentType.float,
        count: 3,
        type: GltfAccessorType.vec3,
        sparse: const GltfAccessorSparse(
          count: 1,
          indices: GltfAccessorSparseIndices(
            bufferView: 2,
            componentType: GltfComponentType.unsignedByte,
          ),
          values: GltfAccessorSparseValues(bufferView: 3),
        ),
      ),
    ];

    final packed = packGltfPrimitive(
      primitive: GltfMeshPrimitive(
        attributes: const {'POSITION': 0, 'NORMAL': 1},
        targets: const [
          {'POSITION': 2},
        ],
      ),
      accessors: accessors,
      bufferViews: bufferViews,
      bufferData: bytes.buffer.asUint8List(),
      coordinatePolicy: GltfCoordinatePolicy.runtimeBoundary,
    );

    expect(packed.morphTargets, hasLength(1));
    expect(
      packed.morphTargets.single.positions,
      orderedEquals(<double>[0, 0, 0, 0.25, 0.5, -0.25, 0, 0, 0]),
    );
  });
}
