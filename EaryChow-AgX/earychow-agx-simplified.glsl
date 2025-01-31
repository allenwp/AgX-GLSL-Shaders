// This is a simplified glsl implementation of EaryChow's AgX that is used by Blender.
// Input: unbounded linear Rec. 709
// Output: unbounded linear Rec.709 (Most any value you care about will be within [0.0, 1.0], thus safe to clip.)
// This code is based off of the script that generates the AgX_Base_sRGB.cube LUT that Blender uses.
// Source: https://github.com/EaryChow/AgX_LUT_Gen/blob/main/AgXBasesRGB.py
// Changes: Negative clipping in input color space without "guard rails" and no chroma-angle mixing.
// Repository for this code: https://github.com/allenwp/AgX-GLSL-Shaders
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

	const float min_ev = -12.473931188332412333;
    const float max_ev = 4.0260688116675876672;
    const float dynamic_range = max_ev - min_ev;
	const float x_pivot = 0.60606060606060606061; // = abs(normalized_log2_minimum / (normalized_log2_maximum - normalized_log2_minimum))
	const float y_pivot = 0.48943708957387834110; // = midgrey ^ (1.0 / 2.4)
	const float a_bottom = -58.33732197712189689;
	const float a_top = 46.1410501578363761;
	const float b_bottom = 35.355952713407210237;
	const float b_top = -27.96427282293113701;
	const vec3 power = vec3(1.5);
	const vec3 inverse_power = vec3(1.0 / 1.5);

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

	color = (log2(color) / dynamic_range) - (min_ev / dynamic_range);
	// Alternative if log is faster than log2 on some platforms (unused constants can be removed):
	//color = 0.75599582959590377775 + 0.087436063084179600446 * log(color);
	color = max(color, 0);

	vec3 mask = step(vec3(x_pivot), color);
	vec3 a = a_bottom + (a_top - a_bottom) * mask;
	vec3 b = b_bottom + (b_top - b_bottom) * mask;
	color = y_pivot + (((-2.4 * x_pivot)) + 2.4 * color) / pow(1.0 + 0.019613086908021587964 * pow(abs(b + a * color), power), inverse_power);

	color = pow(color, vec3(2.4));

	// Apply outset to make the result more chroma-laden and then go back to linear sRGB.
	color = agx_outset_rec2020_to_srgb_matrix * color;

	// Blender's lusRGB.compensate_low_side is too complex for this shader, so
	// simply return the color, even if it has negative components. These negative
	// components may be useful for subsequent color adjustments.
	return color;
}