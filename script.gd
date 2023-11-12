extends Node3D

var grid_size: Vector3 = Vector3(30, 30, 30) 
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

func _ready():
	setup_multi_mesh()
	generate_voxel_grid()
	think_engine = ThinkEngine.new(grid_size.x, grid_size.y, grid_size.z)
	$Control/Threshold.set_value_no_signal(think_engine.threshold)
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
	
	for v in cell_vals:
		multi_mesh.set_instance_custom_data(cell_index, Color(v,0,0))
		
		cell_index += 1
		
		if cell_index >= total_instances:
			break
	

func _process(d):
	frame_count += 1
	
	#if frame_count % 10 != 0:
	#	return
	
	think_out = think_engine.step()
	update_cells(think_out)

func _on_button_pressed():
	think_engine.update_stimulus()
	pass # Replace with function body.

func _on_threshold_value_changed(value):
	think_engine.update_threshold(value)
	print(value)
	pass # Replace with function body.
