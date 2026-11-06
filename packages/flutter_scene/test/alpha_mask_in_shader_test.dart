import 'dart:convert';
import 'dart:io';

import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'alphaMaskInShader only applies to masked, non-lightmapped surfaces',
    () {
      final material = PhysicallyBasedMaterial();
      expect(material.alphaMaskInShader, isFalse);
      expect(material.cutsOutInShader, isFalse);

      material.alphaMaskInShader = true;
      expect(
        material.cutsOutInShader,
        isFalse,
        reason: 'opaque never cuts out',
      );

      material.alphaMode = AlphaMode.mask;
      expect(material.cutsOutInShader, isTrue);

      material.alphaMode = AlphaMode.blend;
      expect(material.cutsOutInShader, isFalse);

      material
        ..alphaMode = AlphaMode.mask
        ..alphaMaskInShader = false;
      expect(material.cutsOutInShader, isFalse, reason: 'opt-in only');
      // The depth and shadow passes keep alpha-testing either way.
      expect(material.depthAlphaMasked, isTrue);
    },
  );

  test('every masked standard variant is in the base shader bundle', () {
    final bundle =
        jsonDecode(File('shaders/base.shaderbundle.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final suffix in [
      '',
      'Cube',
      'NoShadow',
      'NoShadowCube',
      'Lean',
      'LeanCube',
      'LeanNoShadow',
      'LeanNoShadowCube',
    ]) {
      final entry = bundle['StandardMasked${suffix}Fragment'] as Map?;
      expect(entry, isNotNull, reason: 'StandardMasked${suffix}Fragment');
      expect(entry!['type'], 'fragment');
      final source = File(entry['file'] as String).readAsStringSync();
      expect(source, contains('#define FLUTTER_SCENE_ALPHA_MASK_IN_SHADER'));
    }
    expect(
      File('shaders/flutter_scene_standard.frag').readAsStringSync(),
      contains('#ifdef FLUTTER_SCENE_ALPHA_MASK_IN_SHADER'),
    );
  });
}
