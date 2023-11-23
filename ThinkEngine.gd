class_name ThinkEngine extends Node3D

var rd: RenderingDevice
var potential_buffer: RID
var debug_buffer: RID
var spike_buffer: RID
var connections_values: PackedFloat32Array
var connections_buffer: RID
var covariant_buffer: RID
var covariant_array: PackedFloat32Array
var stimulus_buffer: RID
var compute_list: int
var uniform_set: RID
var pipeline: RID
var output_bytes: PackedByteArray 
var output: PackedFloat32Array 
var matrix_size: int
var worker_dims: int
var uniform_array: Array
var shader: RID
var response_values: PackedFloat32Array
var rp_values: PackedFloat32Array
var stimulus_values: PackedFloat32Array
var score: float = 0.0
var report_data = {
	'frame': [],
	'reward': [],
	'penalty': [],
	'refractory_step': [],
	'threshold': [],
	'score': [],
	'stimulus_values': [],
	'response_values': [],
	'rp_values': [],
}

var frame_number: int

var task: Array
var task_idx: int

var reward: float 
var penalty: float 
var refractory_step: float

var variables_buffer: RID
var excit_inhib_buffer: RID
var pr_ratio = 0.333

var w: int
var h: int
var l: int

var connection_count: int = 27
var connection_u = 0.1
var connection_s = 0.5
var threshold: float = 0.4

var explore_u = 0 
var explore_s = 0.05

func identity(a):
	return 

func new_uniform(buffer, binding_index) -> RDUniform:
	var uniform1 := RDUniform.new()
	uniform1.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform1.binding = binding_index
	uniform1.add_id(buffer)
	return uniform1
	
func generate_packed_float32(size: int, 
		  					 init_function: Callable=identity):
	var a := PackedFloat32Array()
	a.resize(size)
	init_function.call(a)
	return a
	
func generate_buffer(a: PackedFloat32Array) -> RID:
	var bytes := a.to_byte_array() 
	return rd.storage_buffer_create(bytes.size(), bytes)	
		
func initialize_variables_buffer(a):
	a[0] = w
	a[1] = h
	a[2] = l
	a[3] = connection_count
	a[4] = threshold
	a[5] = refractory_step 

func log_data():
	report_data['frame'].append(frame_number)
	report_data['reward'].append(reward)
	report_data['penalty'].append(penalty)
	report_data['refractory_step'].append(refractory_step)
	report_data['threshold'].append(threshold)
	report_data['score'].append(score)
	report_data['stimulus_values'].append(stimulus_values)
	report_data['response_values'].append(response_values)
	report_data['rp_values'].append(rp_values)
	
	
func initialize_connections(a):
	var rand_con: float
	var con_idx: int
	for cell_idx in range(matrix_size):
		for i in range(3):
			for j in range(3):
				for k in range(3):
					rand_con = randfn(connection_u, connection_s)
					con_idx = cell_idx*27 + i*9 + j*3 + k
					a[con_idx] = rand_con
					connections_values[con_idx] = rand_con
					
func get_score():
	score = 0
	for i in range(len(response_values)):
		score += clamp(response_values[i], 0, 999) * rp_values[i]

func collect_uniforms(buffer_a):
	var output_a = []
	var uniform_idx = 0
	for b in buffer_a:
		output_a.append(new_uniform(b, uniform_idx))
		uniform_idx += 1
	return output_a
	
func initialize_excit_inhib(a):
	for c_i in range(len(a)):
#		if randf() < 0.7:
			a[c_i] = 1
#		else:
#			a[c_i] = -1
#	print(a)

func update_buffer(new_buffer, uniform_array_idx):
	uniform_array[uniform_array_idx] = new_buffer
	uniform_set = rd.uniform_set_create(collect_uniforms(uniform_array), shader, 0)
	pipeline = rd.compute_pipeline_create(shader)

func skip_idx(idx_val, conditions):
	var skip = false
	for c in conditions:		
		if c[0].call(idx_val, c[1]) == false: 
			skip = true
			break
	return skip
		
func gt(a,b):
	return a > b
	
func lt(a,b):
	return a < b

func rf(a,b):
	return false
	
func set_reward(conditions: Array):	
	rp_values.fill(-1*pr_ratio)
	var idx: int
	
	for i in range(w):
		if skip_idx(i, conditions[0]):
			continue
		for j in range(h):
			if skip_idx(j, conditions[1]):
				continue 	
			rp_values[i*h + j] = 1
	
func reward_left():
	set_reward([[[lt, w/2]], []])
					
func reward_right():
	set_reward([[[gt, w/2]], []])
			
func randomize_stimulus():
	task_idx = randi()%len(task)
	
	for f in task[task_idx]: 
		f.call()
		
	stimulus_buffer = generate_buffer(stimulus_values)
	update_buffer(stimulus_buffer, 6)
	
func update_threshold(new_val):
	threshold = new_val
	variables_buffer = generate_buffer(generate_packed_float32(6, initialize_variables_buffer))
	update_buffer(variables_buffer, 3)
	
func update_r_step(new_val):
	refractory_step = new_val
	variables_buffer = generate_buffer(generate_packed_float32(6, initialize_variables_buffer))
	update_buffer(variables_buffer, 3)
	
func update_reward(new_val):
	reward = new_val
	
func update_penalty(new_val):
	penalty = new_val
	
func update_exploration(new_val):
	explore_s = new_val
	
func generate_random_horizontal():
	stimulus_values.fill(0)
	var y = randi()%(h-1)
	for i in range(w):
		stimulus_values[i*h + y] = 2
	
func generate_random_vertical():
	stimulus_values.fill(0)
	var x = randi()%(w-1)
	for j in range(h):
		stimulus_values[x*h + j] = 2	
		
func stim_random_cell():
	stimulus_values.fill(0)
	stimulus_values[randi()%len(stimulus_values)] = 2

func reward_match():
	rp_values.fill(-1*pr_ratio)
	for i in range(len(rp_values)):
		if stimulus_values[i] > 0:
			rp_values[i] = 1
	
func explore():
	for i in range(len(connections_values)): 
		connections_values[i] += randfn(explore_u, explore_s)
	
	update_buffer(generate_buffer(connections_values), 2)
	
# Called when the node enters the scene tree for the first time.
func _init(width: int, 
		   height: int, 
		   length: int):
	w=width
	h=height
	l=length
	threshold = threshold
	
	rd = RenderingServer.create_local_rendering_device()
	# Load GLSL shader
	var shader_file := load("res://compute_ex.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	shader = rd.shader_create_from_spirv(shader_spirv)
	worker_dims = ceil(sqrt(w*h*l / (32**2)))

	# Prepare our data. We use floats in the shader, so we need 32 bit.
	matrix_size = w*h*l
	
	response_values.resize(w*h)
	rp_values.resize(w*h)
	stimulus_values.resize(w*h)
	
	connections_values.resize(matrix_size * connection_count)
	
	potential_buffer = generate_buffer(generate_packed_float32(matrix_size))
	spike_buffer = generate_buffer(generate_packed_float32(matrix_size))
	connections_buffer = generate_buffer(generate_packed_float32(matrix_size * connection_count, initialize_connections))
	covariant_buffer = generate_buffer(generate_packed_float32(matrix_size * connection_count))
	variables_buffer = generate_buffer(generate_packed_float32(6, initialize_variables_buffer))
	debug_buffer = generate_buffer(generate_packed_float32(8))
	excit_inhib_buffer = generate_buffer(generate_packed_float32(matrix_size, initialize_excit_inhib))
	stimulus_buffer = generate_buffer(generate_packed_float32(w*h))
	
	uniform_array = [potential_buffer, 
					 spike_buffer, 
					 connections_buffer, 
					 variables_buffer, 
					 debug_buffer, 
					 excit_inhib_buffer,
					 stimulus_buffer,
					 covariant_buffer]
	
	uniform_set = rd.uniform_set_create(collect_uniforms(uniform_array), shader, 0)
	pipeline = rd.compute_pipeline_create(shader)
	
#	task = [[generate_random_vertical, reward_left], 
#			[generate_random_horizontal, reward_right]]
	
	task = [[stim_random_cell, reward_match]]
	
	randomize_stimulus()

func step(frame: int):	
	frame_number = frame
	compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	rd.compute_list_dispatch(compute_list, 1, 1, 1)
	rd.compute_list_end()
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()	
	
	if frame % 1 == 0:
		get_response()
		get_score()
	
		if score == 0:
			explore()

		if score > 0:
			scale_connections(1 + reward)

		if score < 0:
			scale_connections(1 - penalty)
			explore()
			
	if frame % 50 == 0:
		log_data()
	
func get_response():
	output = get_spike_state()
	for i in range(w):
		for j in range(h):
			response_values[i*h + j] = output[i*h*l + j*l + l-1]
	
func scale_connections(alpha):
	covariant_array = rd.buffer_get_data(covariant_buffer).to_float32_array()
	for i in range(len(covariant_array)): 
		if covariant_array[i] == 1:
			connections_values[i] = connections_values[i]*alpha
	update_buffer(generate_buffer(connections_values), 2)

func get_covariants():
	return rd.buffer_get_data(covariant_buffer).to_float32_array()

func get_spike_state():
	output_bytes = rd.buffer_get_data(spike_buffer)
	return output_bytes.to_float32_array()

func dump_log():
	var path = 'exp_data/exp_' + Time.get_date_string_from_system(true) + '_' + Time.get_time_string_from_system() + '_' + '.json'
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report_data))



