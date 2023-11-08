class_name ThinkEngine extends Node3D

var rd: RenderingDevice
var potential_buffer: RID
var debug_buffer: RID
var spike_buffer: RID
var connections_buffer: RID
var compute_list: int
var uniform_set: RID
var pipeline: RID
var output_bytes: PackedByteArray 
var output: PackedFloat32Array
var matrix_size: int
var worker_dims: int

var w: int
var h: int
var l: int

var connection_count: int = 27
var connection_u = 0.01
var connection_s = 0.25

func identity(a):
	return 

func new_uniform(buffer, binding_index) -> RDUniform:
	var uniform1 := RDUniform.new()
	uniform1.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform1.binding = binding_index
	uniform1.add_id(buffer)
	return uniform1
	
func generate_buffer(size, init_function: Callable=Callable(self, "identity")) -> RID:
	var a := PackedFloat32Array()
	a.resize(size)
	init_function.call(a)
	var bytes := a.to_byte_array() 
	return rd.storage_buffer_create(bytes.size(), bytes)	

func initialize_spike_state(a):
	for i in range(1):
		var rx = randi()%10
		var ry = randi()%10
		a[rx*100 + ry*10] = 1
		
func initialize_variables_buffer(a):
	a[0] = w
	a[1] = h
	a[2] = l
	a[3] = connection_count
	a[4] = 1
	
func initialize_connections(a):
	for i in range(w*h*l*connection_count):
		a[i] = clamp(randfn(connection_u, connection_s),0,2)

func collect_uniforms(buffer_a):
	var output_a = []
	var uniform_idx = 0
	for b in buffer_a:
		output_a.append(new_uniform(b, uniform_idx))
		uniform_idx += 1
	return output_a

# Called when the node enters the scene tree for the first time.
func _init(width: int, height: int, length: int):
	w=width
	h=height
	l=length
	
	rd = RenderingServer.create_local_rendering_device()
	# Load GLSL shader
	var shader_file := load("res://compute_ex.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	var shader := rd.shader_create_from_spirv(shader_spirv)
	worker_dims = ceil(sqrt(w*h*l / (32**2)))

	# Prepare our data. We use floats in the shader, so we need 32 bit.
	matrix_size = w*h*l
	
	potential_buffer = generate_buffer(matrix_size)
	spike_buffer = generate_buffer(matrix_size, Callable(self, 'initialize_spike_state'))
	var connections_buffer := generate_buffer(matrix_size * connection_count, Callable(self, 'initialize_connections'))
	var variables_buffer := generate_buffer(5, Callable(self, 'initialize_variables_buffer'))
	debug_buffer = generate_buffer(8)
	
	uniform_set = rd.uniform_set_create(collect_uniforms([potential_buffer, spike_buffer, connections_buffer, variables_buffer, debug_buffer]), shader, 0)
	pipeline = rd.compute_pipeline_create(shader)

func step():	
	compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	
	rd.compute_list_dispatch(compute_list, 3, 3, 3)
	rd.compute_list_end()
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	# Read back the data from the buffer
	output_bytes = rd.buffer_get_data(spike_buffer)
	output = output_bytes.to_float32_array()
	print(rd.buffer_get_data(debug_buffer).to_float32_array())
	
	
	return output

func get_spike_state():
	output_bytes = rd.buffer_get_data(spike_buffer)
	return output_bytes.to_float32_array()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
