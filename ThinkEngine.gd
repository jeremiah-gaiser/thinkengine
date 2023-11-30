class_name ThinkEngine extends Node3D

var report_path = 'exp_data/final/exp1/e1_trial'

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
	'reward': '',
	'penalty': '',
	'refractory_step': '',
	'threshold': '',
	'score': [],
	'explore_variance': '',
	'rp_values': '',
}

var logged_hyperparams = false

var horizontal_stimulus = false
var stimulus_idx = 0

var pos_scores: float
var neg_scores: float

var frame_number: int

var task: Array
var task_idx = 0

var reward: float 
var penalty: float 
var refractory_step: float

var variables_buffer: RID
var excit_inhib_buffer: RID
var pr_ratio = 5
var bg_prob: float

var w: int
var h: int
var l: int

var connection_count: int = 27
var connection_u = 0.1
var connection_s = 0.5
var threshold: float

var odds_score = 0
var success_ticker = 0


var explore_u = 0 
var explore_s: float

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
	if !logged_hyperparams:
		var k = ['threshold', 'reward', 'penalty', 'refractory_step', 'rp_values', 'explore_variance']
		var v = [threshold, reward, penalty, refractory_step, rp_values, explore_s]
		
		for i in range(len(k)):
			report_data[k[i]] = v[i]
		
		logged_hyperparams = true
	
	report_data['frame'].append(frame_number)
	report_data['score'].append(score)
	
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
	
	pos_scores = 0
	neg_scores = 0
	
	var cell_score: float
	
	for i in range(len(response_values)):
		if response_values[i] < 0.01:
			response_values[i] = 0
			
		cell_score = response_values[i] * rp_values[i]
#		score += cell_score
		
		if cell_score > 0:
			pos_scores += cell_score
		if cell_score < 0:
			neg_scores += -cell_score
			
	if pos_scores == 0:
		score = 0	
		return
	
	if neg_scores == 0:
		score = 1 / bg_prob
		return
	
	score = (pos_scores / (pos_scores + neg_scores)) / bg_prob 
	
		

func collect_uniforms(buffer_a):
	var output_a = []
	var uniform_idx = 0
	for b in buffer_a:
		output_a.append(new_uniform(b, uniform_idx))
		uniform_idx += 1
	return output_a
	
func initialize_excit_inhib(a):
	for c_i in range(len(a)):
		a[c_i] = 1
#		if randf() < 0.8:
#			a[c_i] = 1
#		else:
#			a[c_i] = -1

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
	rp_values.fill(-1)
	var idx: int
	var reward_cell_count = 0
	
	for i in range(w):
		if skip_idx(i, conditions[0]):
			continue
		for j in range(h):
			if skip_idx(j, conditions[1]):
				continue 	
			rp_values[i*h + j] = 1
			reward_cell_count += 1
	
	bg_prob = float(reward_cell_count) / float(len(response_values))
	
func reward_left():
	set_reward([[[lt, w/2]], []])
					
func reward_right():
	set_reward([[[gt, w/2]], []])
			
func randomize_stimulus():
#	task_idx = randi()%len(task)
	task_idx += 1
	
	for f in task[task_idx % len(task)]: 
		f.call()
		
#	stimulus_buffer = generate_buffer(stimulus_values)
#	update_buffer(stimulus_buffer, 6)
	
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
	
func generate_line():
	stimulus_values.fill(0)
	
	if horizontal_stimulus:
		for i in range(w):
			stimulus_values[i*h + stimulus_idx] = 2
	else:
		for j in range(h):
			stimulus_values[stimulus_idx*h + j] = 2
			
	stimulus_buffer = generate_buffer(stimulus_values)
	update_buffer(stimulus_buffer, 6)	
	
func generate_random_horizontal():
	horizontal_stimulus = true
	stimulus_idx = randi()%h
	generate_line()
	
func generate_random_vertical():
	horizontal_stimulus = false
	stimulus_idx = randi()%w
	generate_line()
		
func stim_random_cell():
	stimulus_values.fill(0)
	stimulus_values[randi()%len(stimulus_values)] = 2

func jitter_stimulus():
	var stim_idx_delta = randi()%2
	if stimulus_idx == w-1:
		stim_idx_delta *= -1
	elif stimulus_idx > 0:
		stim_idx_delta *= [1,-1][randi()%2]
	stimulus_idx += stim_idx_delta
	generate_line()
	

func reward_match():
	rp_values.fill(-1*pr_ratio)
	for i in range(len(rp_values)):
		if stimulus_values[i] > 0:
			rp_values[i] = 1
#	var stim_i = 0
#	var stim_j = 0
#
#	for i in range(w):
#		for j in range(h):
#			if stimulus_values[i*h + j] > 0:
#				stim_i = i
#				stim_j = j
#
#	for i in range(w):
#		for j in range(h):
#			if abs(i-stim_i) < 2:
#				if abs(j-stim_j) < 2:
#					rp_values[i*h + j] = 1
	
func explore():
	var explore_mod = 1
	
	if score > 1:
		explore_mod = 0.25*(1/bg_prob - score)/(1/bg_prob) 
	
	for i in range(len(connections_values)): 
		connections_values[i] += randfn(explore_u, explore_s*explore_mod)
	
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
#
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
	
	get_response()
	
	if frame % 5 == 0:
		get_score()
		print(score, ' ', bg_prob)
	
		if score == 0:
			explore()

		if score > 1:
			scale_connections(1 + reward)
			explore()

		if score < 1:
			scale_connections(1 - penalty)
			explore()
			
	if frame % 50 == 0:
		log_data()
	
#	if frame % 25 == 0:
#		jitter_stimulus()
	
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

func get_pos_neg_scores():
	return [str(pos_scores), str(neg_scores)]
	
func return_score():
	return str(score)

func dump_log():
	var report_idx = 1
	
	report_path += '_' + str(report_idx)
#	var path = 'exp_data/exp_' + Time.get_date_string_from_system(true) + '_' + Time.get_time_string_from_system() + '_' + '.json'
	while FileAccess.file_exists(report_path + '.json'):
		report_idx += 1
		var split_string = report_path.split('_')
		split_string[-1] = str(report_idx)
		report_path = "_".join(split_string)		
		
	var file = FileAccess.open(report_path + '.json', FileAccess.WRITE)
	print(report_path + '.json')
	file.store_string(JSON.stringify(report_data))



