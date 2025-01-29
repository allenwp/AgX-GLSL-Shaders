vec3 exponential(vec3 x_in, float power) {
	return x_in / pow(1.0 + pow(x_in, vec3(power)), vec3(1.0 / power));
}

vec3 exponential_curve(vec3 x_in, vec3 scale_input, float slope, float power, float transition_x, float transition_y) {
	vec3 result = (scale_input * exponential(((slope * (x_in - transition_x)) / scale_input), power)) + transition_y;
	// Even when x_in is non-negative, rounding error can cause the result to be -0.
	// This clipping deals with cases of negative input and rounding error.
	return max(result, 0.0);
}

float scale_function(float transition_x, float transition_y, float power, float slope) {
	float term_a = pow(slope * (1.0 - transition_x), -1.0 * power);
	float term_b = pow((slope * (1.0 - transition_x)) / (1.0 - transition_y), power) - 1.0;
	return pow(term_a * term_b, -1.0 / power);
}

vec3 calculate_sigmoid(vec3 x_in, float midgrey, float normalized_log2_minimum, float normalized_log2_maximum) {
	const float slope = 2.4;
	const float power = 1.5;

	// pivot_x is 0.18 (middle gray) in original linear values
	float pivot_x = abs(normalized_log2_minimum) / (normalized_log2_maximum - normalized_log2_minimum);
	float pivot_y = pow(midgrey, (1.0 / 2.4));

	vec3 bottom_scale = vec3(-1.0 * scale_function(1.0 - pivot_x, 1.0 - pivot_y, power, slope));
	vec3 top_scale = vec3(scale_function(pivot_x, pivot_y, power, slope));
	vec3 scaleValue = mix(top_scale, bottom_scale, lessThan(x_in, vec3(pivot_x)));
	return exponential_curve(x_in, scaleValue, slope, power, pivot_x, pivot_y);
}

// log_encoding_Log2 from colour/models/rgb/transfer_functions/log.py of colour science package
vec3 log_encoding_Log2(vec3 lin, float middle_grey, float min_exposure, float max_exposure) {
	lin = lin / middle_grey;
	lin = max(lin, 1e-10); // prevent undefined behaviour of log2(0.0)
	vec3 lg2 = log2(lin);
	vec3 log_norm = (lg2 - min_exposure) / (max_exposure - min_exposure);
	return log_norm; // Might be negative, but negatives are clipped later.
}

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

	const float midgrey = 0.18;
	const float normalized_log2_minimum = -10.0;

	// Large negative values in one channel and large positive values in other
	// channels can result in a colour that appears darker and more saturated than
	// desired after passing it through the inset matrix. For this reason, it is
	// best to prevent negative input values.
	// This is done before the Rec. 2020 transform to allow the Rec. 2020
	// transform to be combined with the AgX inset matrix. This results in a loss
	// of color information that could be correctly interpreted within the
	// Rec. 2020 color space as positive RGB values, but is often not worth
	// the performance cost of an additional matrix multiplication.
	color = max(color, 0);

	// Apply inset matrix.
	color = srgb_to_rec2020_agx_inset_matrix * color;

	// Apply Log2 curve to prepare for sigmoid.
	color = log_encoding_Log2(color, midgrey, normalized_log2_minimum, normalized_log2_maximum);

	// Apply sigmoid function.
	color = calculate_sigmoid(color, midgrey, normalized_log2_minimum, normalized_log2_maximum);

	// Convert back to linear before applying outset matrix.
	color = pow(color, vec3(2.4));

	// Apply outset to make the result more chroma-laden and then go back to linear sRGB.
	color = agx_outset_rec2020_to_srgb_matrix * color;

	// Blender's lusRGB.compensate_low_side is too complex for this shader, so
	// simply return the color, even if it has negative components. These negative
	// components may be useful for subsequent color adjustments.
	return color;
}