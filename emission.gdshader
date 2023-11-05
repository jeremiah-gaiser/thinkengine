shader_type spatial;
render_mode blend_mix;

// Define a uniform for base emission energy
uniform float base_emission_energy : hint_range(0, 10) = 1.0;
varying vec3 v_custom_emission;

void vertex() {
	v_custom_emission = INSTANCE_CUSTOM.rgb;
}

void fragment() {
    // Use the INSTANCE_CUSTOM variable (a vec4) to store custom per-instance data.
    // For this case, let's use the x component to store our custom emission energy.
	EMISSION = vec3(0.38, 0.87, 1.0) * v_custom_emission.x;
	ALPHA = v_custom_emission.x/2.0 + 0.1;
}