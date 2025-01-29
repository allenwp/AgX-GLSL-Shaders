// This is a simplified glsl implementation of EaryChow's AgX that is used by Blender.
// Input: unbounded linear Rec. 709
// Output: unbounded linear Rec.709 (Most any value you care about will be within [0.0, 1.0], thus safe to clip.)
// This code is based off of the script that generates the AgX_Base_sRGB.cube LUT that Blender uses.
// Source: https://github.com/EaryChow/AgX_LUT_Gen/blob/main/AgXBasesRGB.py
// Changes: Negative clipping in input color space without "guard rails" and no chroma-angle mixing.
// Added parameter normalized_log2_maximum to allow white value to be changed.
// Default normalized_log2_maximum is 6.5.
// If you have a white value in linear space, you can transform it to a normalized_log2_maximum prameter like this:
// white = max(1.172, white); // Sigmoid function breaks down with a lower max than this.
// float normalized_log2_maximum = log2(white / 0.18); // 0.18 is "midgrey".
vec3 tonemap_agx(vec3 color, float normalized_log2_maximum) {
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

	const float normalized_log2_minimum = -10.0;
	const float power = 1.5;
	const vec3 inverse_power = vec3(1.0 / 1.5);

	// Large negative values in one channel and large positive values in other
	// channels can result in a colour that appears darker and more saturated than
	// desired after passing it through the inset matrix. For this reason, it is
	// best to prevent negative input values.
	// This is done before the Rec. 2020 transform to allow the Rec. 2020
	// transform to be combined with the AgX inset matrix. This results in a loss
	// of color information that could be correctly interpreted within the
	// Rec. 2020 color space as positive RGB values, but it is less common for Godot
	// to provide this function with negative sRGB values and therefore not worth
	// the performance cost of an additional matrix multiplication.
	// A value of 2e-10 intentionally introduces insignificant error to prevent
	// log2(0.0) after the inset matrix is applied; color will be >= 1e-10 after
	// the matrix transform.
	color = max(color, 2e-10);

	// Apply inset matrix.
	color = srgb_to_rec2020_agx_inset_matrix * color;

	float log_range = normalized_log2_maximum - normalized_log2_minimum;
	float pivot_x = 10.0 / log_range;
	vec3 log_encoded_x = (1.4426950408889634074 * log(5688.8888888888888889 * color)) / log_range;
	log_encoded_x = max(log_encoded_x, 1e-10); // Clip to 0, but go a little higher to account for later rounding error that may happen.
	vec3 distance = log_encoded_x - pivot_x;

	vec3 A_bottom = pivot_x - log_encoded_x;
	float B_bottom = 10.858542784410844740 - (1.0 / pow(pivot_x, power));
	float B_top = (-1.0 + 10.191614048660063014 * pow(1.0 - pivot_x, power)) / pow(1.0 - pivot_x, power);
	bvec3 mask = lessThan(log_encoded_x, vec3(pivot_x));
	vec3 A = mix(distance, A_bottom, mask);
	vec3 B = mix(vec3(B_top), vec3(B_bottom), mask);

	color = pow(0.48943708957387834110 + (2.4 * distance) / pow(1 + pow(pow(B, inverse_power) * A, vec3(power)), inverse_power), vec3(2.4));

	// Apply outset to make the result more chroma-laden and then go back to linear sRGB.
	color = agx_outset_rec2020_to_srgb_matrix * color;

	// Blender's lusRGB.compensate_low_side is too complex for this shader, so
	// simply return the color, even if it has negative components. These negative
	// components may be useful for subsequent color adjustments.
	return color;
}