import 'dart:typed_data';

import 'types.dart';

/// Resolves a glTF accessor into a flat [Float32List] of its raw component
/// values. The accessor's component type is normalized to float32 for callers,
/// since flutter_scene's vertex format is uniformly float32.
///
/// [bufferData] is the GLB binary chunk (or the resolved external buffer).
Float32List readAccessorAsFloat32(
  GltfAccessor accessor,
  GltfBufferView? bufferView,
  Uint8List bufferData, {
  List<GltfBufferView>? allBufferViews,
}) {
  final componentCount = accessor.type.componentCount;
  final totalComponents = accessor.count * componentCount;
  final out = Float32List(totalComponents);

  final view = ByteData.sublistView(bufferData);

  if (bufferView != null) {
    final stride =
        bufferView.byteStride ??
        (componentCount * accessor.componentType.bytes);
    final start = bufferView.byteOffset + accessor.byteOffset;
    for (int i = 0; i < accessor.count; i++) {
      final base = start + i * stride;
      for (int c = 0; c < componentCount; c++) {
        out[i * componentCount + c] = _readFloatComponent(
          view,
          base + c * accessor.componentType.bytes,
          accessor.componentType,
          accessor.normalized,
        );
      }
    }
  }
  _applySparseFloat(accessor, out, view, allBufferViews);
  return out;
}

/// Resolves an integer-typed accessor (used for indices and joint indices)
/// into a [Uint32List].
Uint32List readAccessorAsUint32(
  GltfAccessor accessor,
  GltfBufferView? bufferView,
  Uint8List bufferData, {
  List<GltfBufferView>? allBufferViews,
}) {
  final componentCount = accessor.type.componentCount;
  final totalComponents = accessor.count * componentCount;
  final out = Uint32List(totalComponents);

  final view = ByteData.sublistView(bufferData);

  if (bufferView != null) {
    final stride =
        bufferView.byteStride ??
        (componentCount * accessor.componentType.bytes);
    final start = bufferView.byteOffset + accessor.byteOffset;
    for (int i = 0; i < accessor.count; i++) {
      final base = start + i * stride;
      for (int c = 0; c < componentCount; c++) {
        out[i * componentCount + c] = _readIntComponent(
          view,
          base + c * accessor.componentType.bytes,
          accessor.componentType,
        );
      }
    }
  }
  _applySparseInt(accessor, out, view, allBufferViews);
  return out;
}

void _applySparseFloat(
  GltfAccessor accessor,
  Float32List output,
  ByteData data,
  List<GltfBufferView>? bufferViews,
) {
  final sparse = accessor.sparse;
  if (sparse == null) return;
  if (bufferViews == null) {
    throw const FormatException('Sparse accessor needs all buffer views.');
  }
  final indicesView = bufferViews[sparse.indices.bufferView];
  final valuesView = bufferViews[sparse.values.bufferView];
  final components = accessor.type.componentCount;
  for (var i = 0; i < sparse.count; i++) {
    final index = _readIntComponent(
      data,
      indicesView.byteOffset +
          sparse.indices.byteOffset +
          i * sparse.indices.componentType.bytes,
      sparse.indices.componentType,
    );
    final valueBase =
        valuesView.byteOffset +
        sparse.values.byteOffset +
        i * components * accessor.componentType.bytes;
    for (var component = 0; component < components; component++) {
      output[index * components + component] = _readFloatComponent(
        data,
        valueBase + component * accessor.componentType.bytes,
        accessor.componentType,
        accessor.normalized,
      );
    }
  }
}

void _applySparseInt(
  GltfAccessor accessor,
  Uint32List output,
  ByteData data,
  List<GltfBufferView>? bufferViews,
) {
  final sparse = accessor.sparse;
  if (sparse == null) return;
  if (bufferViews == null) {
    throw const FormatException('Sparse accessor needs all buffer views.');
  }
  final indicesView = bufferViews[sparse.indices.bufferView];
  final valuesView = bufferViews[sparse.values.bufferView];
  final components = accessor.type.componentCount;
  for (var i = 0; i < sparse.count; i++) {
    final index = _readIntComponent(
      data,
      indicesView.byteOffset +
          sparse.indices.byteOffset +
          i * sparse.indices.componentType.bytes,
      sparse.indices.componentType,
    );
    final valueBase =
        valuesView.byteOffset +
        sparse.values.byteOffset +
        i * components * accessor.componentType.bytes;
    for (var component = 0; component < components; component++) {
      output[index * components + component] = _readIntComponent(
        data,
        valueBase + component * accessor.componentType.bytes,
        accessor.componentType,
      );
    }
  }
}

double _readFloatComponent(
  ByteData data,
  int offset,
  GltfComponentType type,
  bool normalized,
) {
  double value;
  switch (type) {
    case GltfComponentType.byte_:
      value = data.getInt8(offset).toDouble();
      if (normalized) value = (value / 127.0).clamp(-1.0, 1.0);
    case GltfComponentType.unsignedByte:
      value = data.getUint8(offset).toDouble();
      if (normalized) value /= 255.0;
    case GltfComponentType.short:
      value = data.getInt16(offset, Endian.little).toDouble();
      if (normalized) value = (value / 32767.0).clamp(-1.0, 1.0);
    case GltfComponentType.unsignedShort:
      value = data.getUint16(offset, Endian.little).toDouble();
      if (normalized) value /= 65535.0;
    case GltfComponentType.unsignedInt:
      value = data.getUint32(offset, Endian.little).toDouble();
    case GltfComponentType.float:
      value = data.getFloat32(offset, Endian.little);
  }
  return value;
}

int _readIntComponent(ByteData data, int offset, GltfComponentType type) =>
    switch (type) {
      GltfComponentType.byte_ => data.getInt8(offset),
      GltfComponentType.unsignedByte => data.getUint8(offset),
      GltfComponentType.short => data.getInt16(offset, Endian.little),
      GltfComponentType.unsignedShort => data.getUint16(offset, Endian.little),
      GltfComponentType.unsignedInt => data.getUint32(offset, Endian.little),
      GltfComponentType.float => data.getFloat32(offset, Endian.little).toInt(),
    };
