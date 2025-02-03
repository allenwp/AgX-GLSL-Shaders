# GLSL Ports of EaryChow's AgX Configuration
The AgX configuration used by [Blender](https://www.blender.org/) was [created by EaryChow](https://github.com/EaryChow/AgX) with the help of some others along the way. The original AgX was [created by sobotka](https://github.com/sobotka/AgX). Both of these configurations require a LUT for the tonemapping curve, which is not always suitable. This folder contains GLSL ports of this AgX configuration that were created during development of the AgX implementation used by the [Godot Game Engine](https://godotengine.org/).

The tonemapping curve pivots on the middle grey linear value of `0.18`, which means that the curve function cannot be approximated and also have dynamic minimum or maximum exposure values. An input value of `0.18` should always result in an output value of `0.18`, just as a input value of `0.0` should result in an output of `0.0`. An input value that matches the maximum exposure in linear space should have an output value of `1.0`. In this way, the maximum exposure in linear space is the `white` value of the tonemapper.

## GLSL File Descriptions
**Reference/earychow-agx-simplified-reference.glsl**
- A reference implementation of the AgX tonemapper that is not suitable for realtime (it's slow).
- Used to verify that other simplifications and approximations are behaving correctly.

**earychow-agx-simplified.glsl**
- An exact GLSL port, simplified to have Rec. 709 input and output.
- Clips negative values in input colour space.
- Does not include chroma angle mixing.
- Optimized for realtime use, but still quite expensive because it is not an approximation, but instead an exact port.

**earychow-agx-simplified-with-max-parameter.glsl**
- Provides access to the maximum exposure to control the tonemapper's `white` value.
- An exact GLSL port, simplified to have Rec. 709 input and output.
- Clips negative values in input colour space.
- Does not include chroma angle mixing.
- Optimized for realtime use, but similar performance as using a LUT (kind of slow). On the flip side, this does not have a max exposure baked into it.


## Colour Spaces
Although EaryChow's AgX uses Rec. 2020 as working colour space, the GLSL ports in this repository use Rec. 709 as the input and output colour spaces. Simply swap the `srgb_to_rec2020_agx_inset_matrix` and `agx_outset_rec2020_to_srgb_matrix` matrices with one of the following if you are using a different input/output colour space.

Remember that both input and output of the AgX function use linear encoding.

### Combined Input Colour Space Transform and AgX Inset Matrices
**Rec. 2020 Input**
```
const mat3 agx_inset_matrix = mat3(
	0.856627153315983, 0.137318972929847, 0.11189821299995,
	0.0951212405381588, 0.761241990602591, 0.0767994186031903,
	0.0482516061458583, 0.101439036467562, 0.811302368396859);
```

### Combined AgX Inverse Outset and Output Colour Space Transform Matrices
**Rec. 2020 Output**
```
const mat3 agx_inverse_outset_matrix = mat3(
	1.1271005818144366432, -0.14132976349843826565, -0.14132976349843824772,
	-0.1106066430966032116, 1.1578237022162717623, -0.11060664309660291788,
	-0.016493938717834568157, -0.01649393871783425265, 1.2519364065950402828);
```
