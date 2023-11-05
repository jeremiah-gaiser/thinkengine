class_name ThinkEngine extends Node3D

var rd: RenderingDevice
var result_buffer: RID
var potential_state_buffer: RID
var spike_state_bytes_buffer: RID
var connections_bytes_buffer: RID
var compute_list: int
var shader: RID 
var uniform_set: RID
var pipeline: RID
var output_bytes: PackedByteArray 
var output: PackedFloat32Array

func new_uniform(buffer, binding_index) -> RDUniform:
	var uniform1 := RDUniform.new()
	uniform1.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform1.binding = binding_index
	uniform1.add_id(buffer)
	return uniform1

# Called when the node enters the scene tree for the first time.
func _init(w: int, h: int, l: int):
	rd = RenderingServer.create_local_rendering_device()
	# Load GLSL shader
	var shader_file := load("res://compute_ex.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)

	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var matrix_size = w*h*l
	
	# Weighted sum of spike states stored here.
	# If potential state meets the threshold, then spiking occurs.
	var potential_state := PackedFloat32Array()
	
	# Set to 1 if threshold met
	# Otherwise, decrease value by decrease rate
	var spike_state := PackedFloat32Array()
	
	# Each cell has a fixed number of connections to adjacent cells...
	#...with differing definitions of adjacent (faces, corners, edges)
	var connections := PackedFloat32Array()
	
	var result_matrix := PackedFloat32Array()
	
	potential_state.resize(matrix_size)
	spike_state.resize(matrix_size)
	result_matrix.resize(matrix_size)
	connections.resize(matrix_size * 26)
	
	for i in range(w):
		for j in range(h):
			if randf() > 0.9:
				spike_state[i*h*l + j*l] = 1   

	var result_matrix_bytes := result_matrix.to_byte_array()
	var potential_state_bytes := potential_state.to_byte_array()
	var spike_state_bytes := spike_state.to_byte_array()
	var connections_bytes := connections.to_byte_array()

	# Create a storage buffer that can hold our float values.
	result_buffer = rd.storage_buffer_create(result_matrix_bytes.size(), result_matrix_bytes)
	potential_state_buffer = rd.storage_buffer_create(potential_state_bytes.size(), potential_state_bytes)
	spike_state_bytes_buffer = rd.storage_buffer_create(spike_state_bytes.size(), spike_state_bytes)
	connections_bytes_buffer = rd.storage_buffer_create(connections_bytes.size(), connections_bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform1 := new_uniform(result_buffer, 0)
	var uniform2 := new_uniform(potential_state_buffer, 1)
	var uniform3 := new_uniform(spike_state_bytes_buffer, 2)
	var uniform4 := new_uniform(connections_bytes_buffer, 3)
	
	uniform_set = rd.uniform_set_create([uniform1, uniform2, uniform3, uniform4], shader, 0)
	pipeline = rd.compute_pipeline_create(shader)

func step():
	compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	rd.compute_list_dispatch(compute_list, 8, 8, 1)
	rd.compute_list_end()
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	# Read back the data from the buffer
	output_bytes = rd.buffer_get_data(result_buffer)
	output = output_bytes.to_float32_array()
	
	return output

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
