extends Node3D

var grid_size: Vector3 = Vector3(20, 20, 20) 
var voxel_size: float = 0.05
var multi_mesh: MultiMesh
var multi_mesh_instance: MultiMeshInstance3D
var think_engine: ThinkEngine
var total_instances: int
var slice_idx: int
var mod: int
var frame_count: int = 0
var grid_idx: int
var think_out: PackedFloat32Array
var cell_index: int
var ui_state = {}
var pos_neg: Array

func _ready():
	setup_multi_mesh()
	generate_voxel_grid()
	
	think_engine = ThinkEngine.new(grid_size.x, 
								   grid_size.y, 
								   grid_size.z)
	
	load_ui_state()
	update_cells(think_engine.get_spike_state())
	
func setup_multi_mesh():
	multi_mesh = MultiMesh.new()
	multi_mesh.use_custom_data = true
	multi_mesh.use_colors = true
	multi_mesh.mesh = SphereMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)


func generate_voxel_grid():
	total_instances = grid_size.x * grid_size.y * grid_size.z

	multi_mesh.instance_count = total_instances
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1, 1, 1)  # Pure white
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://emission.gdshader")
	multi_mesh_instance.material_override = shader_material

	var instance_count = 0
	
	for x in range(0, grid_size.x):
		for y in range(0, grid_size.y):
			for z in range(0, grid_size.z):
				var instance_transform = Transform3D()
				instance_transform.origin = Vector3(x * voxel_size, y * voxel_size, z * voxel_size)
				
				instance_transform.basis = Basis().scaled(Vector3(0.01, 0.01, 0.01))
				multi_mesh.set_instance_transform(instance_count, instance_transform)
				multi_mesh.set_instance_custom_data(instance_count, Color(0,0,0))
				
				instance_count += 1
			
func update_cells(cell_vals):
	cell_index = 0
	
	for x in range(0, grid_size.x):
		for y in range(0, grid_size.y):
			for z in range(0, grid_size.z):
				cell_index = x*grid_size.y*grid_size.z + y*grid_size.z + z
				multi_mesh.set_instance_custom_data(cell_index, Color(cell_vals[cell_index],0,0))

func _process(d):
	frame_count += 1
	
	if frame_count % 150 == 0:
		think_engine.randomize_stimulus()
	
	think_engine.step(frame_count)
	update_cells(think_engine.get_spike_state())
	pos_neg = think_engine.get_pos_neg_scores()
	$Control/pos_score.text = pos_neg[0]
	$Control/neg_score.text = pos_neg[1]

func load_ui_state():
	var file = FileAccess.open("ui_state.json", FileAccess.READ)
	ui_state = JSON.parse_string(file.get_line())
	
	$Control/Threshold.set_value(ui_state['threshold'])
	$Control/r_step.set_value(ui_state['r_step'])
	$Control/reward.set_value(ui_state['reward'])
	$Control/penalty.set_value(ui_state['penalty'])
	$Control/exploration.set_value(ui_state['exploration'])
	
	file.close()
	
func save_ui_state():
	var file = FileAccess.open("ui_state.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({
		'threshold': $Control/Threshold.value,
		'r_step': $Control/r_step.value,
		'reward': $Control/reward.value,
		'penalty': $Control/penalty.value,
		'exploration': $Control/exploration.value,
	}))
	file.close()

func _on_exploration_value_changed(value):
	think_engine.update_exploration(value)
	$Control/exploration/val.text = str(value)

func _on_penalty_value_changed(value):
	think_engine.update_penalty(value)
	$Control/penalty/val.text = str(value)

func _on_reward_value_changed(value):
	think_engine.update_reward(value)
	$Control/reward/val.text = str(value)

func _on_threshold_value_changed(value):
	think_engine.update_threshold(value)
	$Control/Threshold/val.text = str(value)
	
func _on_r_step_value_changed(value):
	think_engine.update_r_step(value)
	$Control/r_step/val.text = str(value)

func _on_button_pressed():
	think_engine.randomize_stimulus()

func _on_reload_pressed():
	think_engine.dump_log()
	save_ui_state()
	get_tree().reload_current_scene()
	
func _on_close_pressed():
	think_engine.dump_log()
	save_ui_state()
	get_tree().quit()
