shader_type canvas_item;

uniform sampler3D current_state : hint_albedo;

void fragment() {
    ivec3 cell_coord = ivec3(FRAGCOORD.xy, 0); // Adjust this to get correct 3D coordinates

    int alive_neighbors = 0;

    // Loop through the neighboring cells
    for (int z = -1; z <= 1; ++z) {
        for (int y = -1; y <= 1; ++y) {
            for (int x = -1; x <= 1; ++x) {
                alive_neighbors += int(texelFetch(current_state, cell_coord + ivec3(x, y, z), 0).r);
            }
        }
    }

    // Simple logic to update cell state
    float new_state = texelFetch(current_state, cell_coord, 0).r;
    if (alive_neighbors == 3) {
        new_state = 1.0;
    } else if (alive_neighbors < 2 || alive_neighbors > 3) {
        new_state = 0.0;
    }

    COLOR = vec4(new_state, 0.0, 0.0, 1.0);
}
