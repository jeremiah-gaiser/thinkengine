extends Node3D

var grid_size: Vector3 = Vector3(20, 20, 20)
var voxel_size: float = 0.05
var multi_mesh: MultiMesh
var multi_mesh_instance: MultiMeshInstance3D
var think_engine: ThinkEngine

func _ready():
	setup_multi_mesh()
	generate_voxel_grid()
	think_engine = ThinkEngine.new(grid_size.x, grid_size.y, grid_size.z)
	
func setup_multi_mesh():
	multi_mesh = MultiMesh.new()
	multi_mesh.use_custom_data = true
	multi_mesh.use_colors = true
	multi_mesh.mesh = SphereMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)

func random_color():
	return Color(randf(), randf(), randf(), randf())
	
func random_emission_energy():
	return randf()

var total_instances: int

func generate_voxel_grid():
	var centered_x = int(grid_size.x / 2)
	var centered_y = int(grid_size.y / 2)
	var centered_z = int(grid_size.z / 2)
	total_instances = (2 * centered_x) * (2 * centered_y) * (2 * centered_z)

	multi_mesh.instance_count = total_instances
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1, 1, 1)  # Pure white
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://emission.gdshader")
	multi_mesh_instance.material_override = shader_material

	var instance_count = 0
	
	for x in range(-centered_x, centered_x):
		for y in range(-centered_y, centered_y):
			for z in range(-centered_z, centered_z):
				var instance_transform = Transform3D()
				instance_transform.origin = Vector3(x * voxel_size, y * voxel_size, z * voxel_size)
				
				instance_transform.basis = Basis().scaled(Vector3(0.025, 0.025, 0.025))
				multi_mesh.set_instance_transform(instance_count, instance_transform)
				multi_mesh.set_instance_custom_data(instance_count, Color(0,0,0))
				
				
				if z == -centered_z:
					if randf() < 0.9:
						multi_mesh.set_instance_custom_data(instance_count, Color(1,0,0))
				instance_count += 1
	
var slice_idx: int
var mod: int
var frame_count: int = 0
var grid_idx: int
var think_out: PackedFloat32Array
var cell_index: int

func _process(d):
	frame_count += 1
	think_out = think_engine.step()
	
	cell_index = 0
	
	for v in think_out:
		cell_index += 1
		if v == 0:
			break
		multi_mesh.set_instance_custom_data(cell_index, Color(v,0,0))
