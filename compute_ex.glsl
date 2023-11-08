#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 10, local_size_y = 10, local_size_z=10) in;


layout(set = 0, binding = 0, std430) buffer Potential {
    float potential[];
};

layout(set = 0, binding = 1, std430) buffer Spike {
    float spike[];
};

layout(set = 0, binding = 2, std430) buffer Connections {
    float connections[];
};

layout(set = 0, binding = 3, std430) buffer Variables {
    float variables[];
};

layout(set = 0, binding = 4, std430) buffer Debug {
    float debug[];
};


// The code we want to execute in each invocation
void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    int z = int(gl_GlobalInvocationID.z);

    int w = int(variables[0]);
    int h = int(variables[1]);
    int l = int(variables[2]);
    int c = int(variables[3]);

    float threshold = variables[4];
    float c_strength;
    float s_val;

    int idx = x*h*l + y*l + z;

    if(idx < w*h*l)
    {
        int c_group = x*h*l*c + y*l*c + z*c;
        int c_i;

        if (spike[idx] < 0.01){
            if (potential[idx] > threshold) 
            {
                spike[idx] = 1;
            }
        } else {
           spike[idx] -= 0.05;
        }

        
        for(int i=-1; i <2; i++)
        {
            if(x == 0 && i == -1){ continue; }
            if(x == w-1 && i == 1){ continue; }

            for(int j=-1; j<2; j++)
            {
                if(y == 0 && j == -1){ continue; }
                if(y == h-1 && j == 1){ continue; }

                for(int k=-1; k<2; k++)
                {
                    if(z == 0 && k==-1){ continue; }
                    if(z == l-1 && k == 1){ continue; } 
                    if(i==0 && j==0 && k==0){ continue; }

                    c_strength = connections[c_group + (i+1)*9 + (j+1)*3 + k+1]; 
                    s_val = spike[(x+i)*h*l + (y+j)*l + (z+k)]; 
                    potential[idx] += s_val;
                }
            }
        }
    }
}

