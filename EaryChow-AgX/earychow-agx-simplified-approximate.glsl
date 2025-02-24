// AgX by @sobotka https://github.com/sobotka/AgX-S2O3 and https://github.com/sobotka/SB2383-Configuration-Generation
// Blender's AgX by @EaryChow et al. https://github.com/EaryChow/AgX_LUT_Gen
// This shader port of Eary's version of AgX: Copyright (c) 2025 Allen Pestaluky
// Source material does not provide a license, so this port similarly does not provide a license.

// This is a simplified glsl implementation of EaryChow's AgX that is used by Blender.
// Input: unbounded linear Rec. 709
// Output: unbounded linear Rec. 709 (Most any value you care about will be within [0.0, 1.0], thus safe to clip.)
// This code is based off of the script that generates the AgX_Base_sRGB.cube LUT that Blender uses.
// Source: https://github.com/EaryChow/AgX_LUT_Gen/blob/main/AgXBasesRGB.py
// Changes: Negative clipping in input color space without "guard rails" and no chroma-angle mixing.
// Repository for this code: https://github.com/allenwp/AgX-GLSL-Shaders
// Refer to source repository for other matrices if input/output color space ever changes.
vec3 tonemap_agx(vec3 color) {
	// Combined linear sRGB to linear Rec 2020 and Blender AgX inset matrices:
	const mat3 srgb_to_rec2020_agx_inset_matrix = mat3(
			0.54490813676363087053, 0.14044005884001287035, 0.088827411851915368603,
			0.37377945959812267119, 0.75410959864013760045, 0.17887712465043811023,
			0.081384976686407536266, 0.10543358536857773485, 0.73224999956948382528);

	// Combined inverse AgX outset matrix and linear Rec 2020 to linear sRGB matrices.
	const mat3 agx_outset_rec2020_to_srgb_matrix = mat3(
			1.9645509602733325934, -0.29932243390911083839, -0.16436833806080403409,
			-0.85585845117807513559, 1.3264510741502356555, -0.23822464068860595117,
			-0.10886710826831608324, -0.027084020983874825605, 1.402665347143271889);

	// Terms of Timothy Lottes' tonemapping curve equation:
	// c and b are calculated based on a and d with AgX mid and max parameters
	// using the Mathematica notebook in the source AgX-GLSL-Shaders repository.
	const float a = 1.36989969378897;
	const float c = 0.3589386656982;
	const float b = 1.4325264680543;
	const float e = a * 0.903916850555009; // = a * d

	// Large negative values in one channel and large positive values in other
	// channels can result in a colour that appears darker and more saturated than
	// desired after passing it through the inset matrix. For this reason, it is
	// best to prevent negative input values.
	// This is done before the Rec. 2020 transform to allow the Rec. 2020
	// transform to be combined with the AgX inset matrix. This results in a loss
	// of color information that could be correctly interpreted within the
	// Rec. 2020 color space as positive RGB values, but is often not worth
	// the performance cost of an additional matrix multiplication.
	// A value of 2e-10 intentionally introduces insignificant error to prevent
	// log2(0.0) after the inset matrix is applied; color will be >= 1e-10 after
	// the matrix transform.
	color = max(color, 2e-10);

	// Apply inset matrix.
	color = srgb_to_rec2020_agx_inset_matrix * color;

	// Use Timothy Lottes' tonemapping equation to approximate AgX's curve.
	// Slide 44 of "Advanced Techniques and Optimization of HDR Color Pipelines"
	// https://gpuopen.com/wp-content/uploads/2016/03/GdcVdrLottes.pdf
	// color = pow(color, a);
	// color = color / (pow(color, d) * b + c);
	// Simplified using hardware-implemented shader operations.
	// Thanks to Stephen Hill for this optimization tip!
	color = log2(color);
	color = exp2(color * a) / (exp2(color * e) * b + c);

	// Apply outset to make the result more chroma-laden and then go back to linear sRGB.
	color = agx_outset_rec2020_to_srgb_matrix * color;

	// Blender's lusRGB.compensate_low_side is too complex for this shader, so
	// simply return the color, even if it has negative components. These negative
	// components may be useful for subsequent color adjustments.
	return color;
}