# VRM runtime support branch

This branch is based on `flutter_scene-0.22.2` and adds engine-generic glTF
features needed by a separate VRM integration package:

- sparse accessor decoding
- primitive morph target parsing and packing
- reusable CPU morph blending into a mutable GPU vertex buffer
- stable source glTF node indices through `GltfSourceComponent`

VRM metadata, expression semantics, MToon, SpringBone, constraints, and
look-at intentionally remain outside the engine package. The first consumer is
`flutter_scene_vrm` in the Madogiwa validation repository.

The CPU morph implementation is a vertical-slice path. Production multi-avatar
tracking should retain `MorphTargetController` as the public boundary while
moving the blend to per-instance GPU weights.
