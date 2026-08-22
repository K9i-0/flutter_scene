import 'package:flutter_scene/src/components/component.dart';

/// Stable source identity attached to each runtime-imported glTF node.
///
/// Extension packages such as VRM can resolve node-index bindings without
/// depending on optional or duplicated node names.
class GltfSourceComponent extends Component {
  GltfSourceComponent(this.nodeIndex);

  final int nodeIndex;
}
