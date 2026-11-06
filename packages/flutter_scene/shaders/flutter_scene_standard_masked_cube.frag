// Alpha-masked twin of flutter_scene_standard_cube.frag: discards below the cutoff in the
// shader instead of taking the main pass's coverage pre-draw.
#define FLUTTER_SCENE_ALPHA_MASK_IN_SHADER
#include <flutter_scene_standard_cube.frag>
