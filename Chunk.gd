extends Spatial

var chunk_pos = Vector3(0,0,0)
var noise = OpenSimplexNoise.new()
onready var game = get_tree().get_root().get_node("Game")
#var mat = SpatialMaterial.new()
var mesh_node
var chunk_mesh
var block_class
var static_node
var temp_dict_2 = {}
var block_dict = {}
var blocks =  {}
var count = 0
var texture_atlas_size = Vector2(8,8)
var mat = load("res://TextureMaterial.tres")

var adjacent_blocks = {
	Side.front  : Vector3(0,0,1),
	Side.back   : Vector3(0,0,-1),
	Side.right  : Vector3(1,0,0),
	Side.left   : Vector3(-1,0,0),
	Side.top    : Vector3(0,1,0),
	Side.bottom : Vector3(0,-1,0),
	}

var block_types = {0:{Side.top:Vector2(0,0),Side.bottom:Vector2(2,0),Side.left:Vector2(1,0),
				Side.right:Vector2(1,0),Side.front:Vector2(1,0),Side.back:Vector2(1,0)},
				1:{Side.top:Vector2(3,0),Side.bottom:Vector2(3,0),Side.left:Vector2(3,0),
				Side.right:Vector2(3,0),Side.front:Vector2(3,0),Side.back:Vector2(3,0)},
				2:{Side.top:Vector2(4,0),Side.bottom:Vector2(4,0),Side.left:Vector2(4,0),
				Side.right:Vector2(4,0),Side.front:Vector2(4,0),Side.back:Vector2(4,0)},
				3:{Side.top:Vector2(5,0),Side.bottom:Vector2(5,0),Side.left:Vector2(5,0),
				Side.right:Vector2(5,0),Side.front:Vector2(5,0),Side.back:Vector2(5,0)},}


enum Side {
	front,
	back,
	right,
	left,
	top,
	bottom
}

func _ready():
	pass

func get_texture_atlas_uvs(size,pos):
	var offset = Vector2(pos.x/size.x,pos.y/size.y)
	var bottom_right = Vector2(offset.x+(1/size.x),offset.y+(1/size.y))
	var top_left = Vector2(offset.x,offset.y)
	var top_right = Vector2(offset.x+(1/size.x),offset.y)
	var bottom_left = Vector2(offset.x,offset.y+(1/size.y))
	return [top_left, top_right, bottom_left, bottom_right]


func get_cube_uvs(orient,type):
	var uv_array = []
	
	if orient==Side.front:
		var coordinates = get_texture_atlas_uvs(texture_atlas_size,block_types[type][Side.front])
		uv_array = [
			coordinates[0],
			coordinates[3],
			coordinates[2],
			
			coordinates[1],
			coordinates[3],
			coordinates[0],
		]
	if orient==Side.back:
		var coordinates = get_texture_atlas_uvs(texture_atlas_size,block_types[type][Side.back])
		uv_array = [
			coordinates[0],
			coordinates[1],
			coordinates[3],
			
			coordinates[0],
			coordinates[3],
			coordinates[2],
		]
	if orient==Side.right:
		var coordinates = get_texture_atlas_uvs(texture_atlas_size,block_types[type][Side.right])
		uv_array = [
			coordinates[0],
			coordinates[1],
			coordinates[3],
			
			coordinates[3],
			coordinates[2],
			coordinates[0],
		]
	if orient==Side.left:
		var coordinates = get_texture_atlas_uvs(texture_atlas_size,block_types[type][Side.left])
		uv_array = [
			coordinates[2],
			coordinates[1],
			coordinates[3],
			
			coordinates[2],
			coordinates[0],
			coordinates[1],
		]
	if orient==Side.top:
		var coordinates = get_texture_atlas_uvs(texture_atlas_size,block_types[type][Side.top])
		uv_array = [
			coordinates[3],
			coordinates[0],
			coordinates[1],
			
			coordinates[3],
			coordinates[2],
			coordinates[0],
		]
	if orient==Side.bottom:
		var coordinates = get_texture_atlas_uvs(texture_atlas_size,block_types[type][Side.bottom])
		uv_array = [
			coordinates[2],
			coordinates[0],
			coordinates[1],
			
			coordinates[2],
			coordinates[1],
			coordinates[3],
		]
		
	return uv_array
		

func get_cube_vertices(orient):
	
	var vertice_array = []
	
	if orient==Side.front:
		vertice_array = [
			Vector3(0,1,1),
			Vector3(1,0,1),
			Vector3(0,0,1),
			
			Vector3(1,1,1),
			Vector3(1,0,1),
			Vector3(0,1,1),
		]
	elif orient==Side.back:
		vertice_array = [
			Vector3(1,1,0),
			Vector3(0,1,0),
			Vector3(0,0,0),
			
			Vector3(1,1,0),
			Vector3(0,0,0),
			Vector3(1,0,0),
		]
	elif orient==Side.right:
		vertice_array = [
			Vector3(1,1,1),
			Vector3(1,1,0),
			Vector3(1,0,0),
			
			Vector3(1,0,0),
			Vector3(1,0,1),
			Vector3(1,1,1),
		]
	elif orient==Side.left:
		vertice_array = [
			Vector3(0,0,0),
			Vector3(0,1,1),
			Vector3(0,0,1),
			
			Vector3(0,0,0),
			Vector3(0,1,0),
			Vector3(0,1,1),
		]
	elif orient==Side.top:
		vertice_array = [
			Vector3(1,1,1),
			Vector3(0,1,0),
			Vector3(1,1,0),
			
			Vector3(1,1,1),
			Vector3(0,1,1),
			Vector3(0,1,0),
		]
	elif orient==Side.bottom:
		vertice_array = [
			Vector3(1,0,1),
			Vector3(1,0,0),
			Vector3(0,0,0),
			
			Vector3(1,0,1),
			Vector3(0,0,0),
			Vector3(0,0,1),
		]
	return vertice_array
		
	
func update_chunk(update_blocks=null):
	
	if update_blocks==null:
		update_blocks = block_dict.keys()
	for block in update_blocks:
		if not block in block_dict:
			continue
		block_dict[block]["a"] = []
		var x = block.x
		var y = block.y
		var z = block.z
		for s in adjacent_blocks:
			if not block_dict.has((adjacent_blocks[s]+block)):
				block_dict[block]["a"].append(s)

	render_chunk()
	gen_chunk_collision()
	display_chunk()
	

func display_chunk():
	
	add_child(chunk_mesh)


func render_chunk():
	if chunk_mesh!=null:
		chunk_mesh.free()
	var mesh_instance = MeshInstance.new()
	var surface_tool = SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for b in block_dict:
		var block = block_dict[b]
		var vertices = []
		var uvs = []
		
		for a in block["a"]:
			vertices += get_cube_vertices(a)
			uvs += get_cube_uvs(a,block["t"])
			
		for i in vertices.size():
			surface_tool.add_uv(uvs[i])
			surface_tool.add_vertex(vertices[i]+b)

	surface_tool.generate_normals()
	surface_tool.set_material(mat)
	var m = surface_tool.commit()
	mesh_instance.set_mesh(m);
	mesh_instance.set_name("mesh")
	chunk_mesh = mesh_instance

	
func gen_chunk_collision():
	if static_node!=null:
		static_node.free()
	var collision_verts = []

	for b in block_dict:
		var vertices =  []
		for a in block_dict[b]["a"]:
			vertices+=get_cube_vertices(a)
		for v in vertices:
			collision_verts.append(v+b)
	if len(collision_verts)==0:
		return
	
	var static_body = StaticBody.new()
	static_body.set_name("StaticBody")
	add_child(static_body)
	static_node=static_body
	var collision_shape = CollisionShape.new()
	static_body.add_child(collision_shape)
	var concave_polygon_shape = ConcavePolygonShape.new()
	concave_polygon_shape.set_faces(collision_verts)
	
	collision_shape.set_shape(concave_polygon_shape)


func place_block(block_vect,type):
	block_dict[block_vect] = {"t":1}
	var update_blocks = [block_vect]
	for s in adjacent_blocks:
		update_blocks.append(block_vect+adjacent_blocks[s])
	update_chunk(update_blocks)

func remove_block(block_vect):
	block_dict.erase(block_vect)
	var update_blocks = [block_vect]
	for s in adjacent_blocks:
		update_blocks.append(block_vect+adjacent_blocks[s])
	update_chunk(update_blocks)
	var start_time = OS.get_ticks_msec()
func generate_chunk(gen_seed):
	var start_time = OS.get_ticks_msec()
	var list = []
	var n = 0

	noise.seed = gen_seed
	noise.octaves = 3
	noise.period = 25
	noise.persistence = 0.3

	for i in range(8):
		for j in range(8):
			for k in range(8):
				n = noise.get_noise_3d((i+(chunk_pos[0]*8)),(j+(chunk_pos[1]*8)),(k+(chunk_pos[2]*8)))
				n/=2
				n+=0.5
				#0.955
				var thresh = pow(0.955,(j+(chunk_pos[1]*8)))
				if n < thresh:
					if (j+(chunk_pos[1]*8))<14:
						block_dict[Vector3(i,j,k)] = {"t":2}
					else:
						block_dict[Vector3(i,j,k)] = {"t":0}
				elif (j+(chunk_pos[1]*8))<12:
					block_dict[Vector3(i,j,k)] = {"t":3}


	update_chunk()
	#print("Elapsed time: ", OS.get_ticks_msec() - start_time)

	
