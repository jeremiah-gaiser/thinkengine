#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 32) in;

layout(set = 0, binding = 0, std430) buffer Results {
    float results[];
};

layout(set = 0, binding = 1, std430) buffer Potential {
    float potential[];
};

layout(set = 0, binding = 2, std430) buffer Spike {
    float spike[];
};

layout(set = 0, binding = 3, std430) buffer Connections {
    float connections[];
};


// The code we want to execute in each invocation
void main() {
    // int row = int(gl_GlobalInvocationID.y);
    int col = int(gl_GlobalInvocationID.x);
    results[col] += 0.01;
}

