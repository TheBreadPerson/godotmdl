class_name SMDConverter extends Node

func convert_to_smd(model_path : String) -> void:
	var file_extension = "."+model_path.get_extension()
	match file_extension:
		".obj":
			convert_obj_to_smd(model_path, model_path.replace(".obj", ".smd"))
		".fbx":
			convert_fbx_to_smd(model_path, model_path.replace(".fbx", ".smd"))
		".mesh":
			convert_mesh_to_smd(model_path, model_path.replace(".mesh", ".smd"))
		_:
			printerr("Unknown file extension!")
			return

func convert_obj_to_smd(obj_path: String, smd_path: String) -> void:
	if not FileAccess.file_exists(obj_path):
		printerr("Error: Input OBJ file does not exist: ", obj_path)
		return

	var obj_file := FileAccess.open(obj_path, FileAccess.READ)
	
	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []
	var triangles: Array[Dictionary] = [] # Stores dictionary with: {"material": String, "face": Array}

	var current_material := "default_material"

	# 1. Parse the OBJ file line by line
	while not obj_file.eof_reached():
		var line := obj_file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(" ", false)
		var prefix := parts[0]

		match prefix:
			"v": # Vertex position
				if parts.size() >= 4:
					vertices.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
			"vt": # Texture coordinate (UV)
				if parts.size() >= 3:
					uvs.append(Vector2(float(parts[1]), float(parts[2])))
			"vn": # Vertex normal
				if parts.size() >= 4:
					normals.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
			"usemtl": # Material definition
				if parts.size() >= 2:
					current_material = parts[1]
			"f": # Face indices (Supports Triangles and Quads)
				var face_vertices: Array[Array] = []
				for i in range(1, parts.size()):
					var vert_data := parts[i].split("/")
					# Convert 1-based indexing to 0-based indexing
					var v_idx := int(vert_data[0]) - 1
					var vt_idx := (int(vert_data[1]) - 1) if vert_data.size() > 1 and not vert_data[1].is_empty() else -1
					var vn_idx := (int(vert_data[2]) - 1) if vert_data.size() > 2 and not vert_data[2].is_empty() else -1
					face_vertices.append([v_idx, vt_idx, vn_idx])
				
				# Triangulate Quads/N-gons into Triangle Fans
				if face_vertices.size() >= 3:
					for i in range(1, face_vertices.size() - 1):
						var tri_face = [face_vertices[0], face_vertices[i], face_vertices[i + 1]]
						triangles.append({"material": current_material, "face": tri_face})

	obj_file.close()

	# 2. Write the SMD File
	var smd_file := FileAccess.open(smd_path, FileAccess.WRITE)
	if not smd_file:
		printerr("Error: Could not open output path for writing: ", smd_path)
		return

	smd_file.store_line("version 1")
	
	# Define a single root bone (Bone 0) for the static reference mesh
	smd_file.store_line("nodes")
	smd_file.store_line("0 \"static_root\" -1")
	smd_file.store_line("end")

	# Base skeleton requirements
	smd_file.store_line("skeleton")
	smd_file.store_line("time 0")
	smd_file.store_line("0 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000")
	smd_file.store_line("end")

	# Write standard triangles format
	smd_file.store_line("triangles")
	for tri in triangles:
		smd_file.store_line(tri["material"])
		
		# Each triangle must have exactly 3 vertices
		for v_data in tri["face"]:
			var v_idx: int = v_data[0]
			var vt_idx: int = v_data[1]
			var vn_idx: int = v_data[2]

			# Grab data or fall back to default vectors
			var v_pos := vertices[v_idx] if v_idx < vertices.size() else Vector3.ZERO
			var v_uv := uvs[vt_idx] if vt_idx != -1 and vt_idx < uvs.size() else Vector2.ZERO
			var v_norm := normals[vn_idx] if vn_idx != -1 and vn_idx < normals.size() else Vector3.UP

			# Valve SMD layout formatting string
			var vertex_string := "  0 %f %f %f %f %f %f %f %f" % [
				v_pos.x, v_pos.y, v_pos.z,
				v_norm.x, v_norm.y, v_norm.z,
				v_uv.x, v_uv.y
			]
			smd_file.store_line(vertex_string)
			
	smd_file.store_line("end")
	smd_file.close()
	print("Success: Converted OBJ to SMD -> ", smd_path)

func convert_fbx_to_smd(fbx_path : String, smd_path : String) -> void:
	if not FileAccess.file_exists(fbx_path):
		printerr("Error: Input FBX file does not exist: ", fbx_path)
		return

	var imported := load(fbx_path)
	var mesh: Mesh = null

	# Extract mesh from loaded FBX (can be either direct Mesh or PackedScene)
	if imported is Mesh:
		mesh = imported
	elif imported is PackedScene:
		var scene_root := (imported as PackedScene).instantiate()
		var mesh_instance := _find_mesh_instance(scene_root)
		if mesh_instance:
			mesh = mesh_instance.mesh
		scene_root.queue_free()

	if not mesh:
		printerr("Error: No mesh found in FBX file: ", fbx_path)
		return

	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []
	var triangles: Array[Dictionary] = []

	# Extract mesh data from all surfaces
	for surface_idx in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_idx)
		var material_name := "default_material"

		# Try to get material name from metadata
		if mesh.has_meta("surface_material_" + str(surface_idx)):
			material_name = mesh.get_meta("surface_material_" + str(surface_idx))

		var surface_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] if arrays[Mesh.ARRAY_VERTEX] else PackedVector3Array()
		var surface_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] else PackedVector3Array()
		var surface_uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] else PackedVector2Array()
		var surface_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] else PackedInt32Array()

		# Store vertex base index for this surface
		var vertex_base := vertices.size()
		var normal_base := normals.size()
		var uv_base := uvs.size()

		# Add surface vertices to main arrays
		for vert in surface_vertices:
			vertices.append(vert)

		for normal in surface_normals:
			normals.append(normal)

		for uv in surface_uvs:
			uvs.append(uv)

		# Process indices into triangles
		if surface_indices.size() > 0:
			for i in range(0, surface_indices.size(), 3):
				if i + 2 < surface_indices.size():
					var tri_face := [
						[vertex_base + surface_indices[i], uv_base + surface_indices[i], normal_base + surface_indices[i]],
						[vertex_base + surface_indices[i + 1], uv_base + surface_indices[i + 1], normal_base + surface_indices[i + 1]],
						[vertex_base + surface_indices[i + 2], uv_base + surface_indices[i + 2], normal_base + surface_indices[i + 2]]
					]
					triangles.append({"material": material_name, "face": tri_face})
		else:
			# No indices, use sequential vertices as triangles
			for i in range(0, surface_vertices.size(), 3):
				if i + 2 < surface_vertices.size():
					var tri_face := [
						[vertex_base + i, uv_base + i, normal_base + i],
						[vertex_base + i + 1, uv_base + i + 1, normal_base + i + 1],
						[vertex_base + i + 2, uv_base + i + 2, normal_base + i + 2]
					]
					triangles.append({"material": material_name, "face": tri_face})

	# Write the SMD File
	var smd_file := FileAccess.open(smd_path, FileAccess.WRITE)
	if not smd_file:
		printerr("Error: Could not open output path for writing: ", smd_path)
		return

	smd_file.store_line("version 1")

	# Define a single root bone for the static reference mesh
	smd_file.store_line("nodes")
	smd_file.store_line("0 \"static_root\" -1")
	smd_file.store_line("end")

	# Base skeleton requirements
	smd_file.store_line("skeleton")
	smd_file.store_line("time 0")
	smd_file.store_line("0 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000")
	smd_file.store_line("end")

	# Write standard triangles format
	smd_file.store_line("triangles")
	for tri in triangles:
		smd_file.store_line(tri["material"])

		# Each triangle must have exactly 3 vertices
		for v_data in tri["face"]:
			var v_idx: int = v_data[0]
			var vt_idx: int = v_data[1]
			var vn_idx: int = v_data[2]

			# Grab data or fall back to default vectors
			var v_pos := vertices[v_idx] if v_idx < vertices.size() else Vector3.ZERO
			var v_uv := uvs[vt_idx] if vt_idx < uvs.size() else Vector2.ZERO
			var v_norm := normals[vn_idx] if vn_idx < normals.size() else Vector3.UP

			# Valve SMD layout formatting string
			var vertex_string := "  0 %f %f %f %f %f %f %f %f" % [
				v_pos.x, v_pos.y, v_pos.z,
				v_norm.x, v_norm.y, v_norm.z,
				v_uv.x, v_uv.y
			]
			smd_file.store_line(vertex_string)

	smd_file.store_line("end")
	smd_file.close()
	print("Success: Converted FBX to SMD -> ", smd_path)

func convert_mesh_to_smd(mesh_path: String, smd_path: String) -> void:
	if not FileAccess.file_exists(mesh_path):
		printerr("Error: Input mesh file does not exist: ", mesh_path)
		return

	var imported := load(mesh_path)
	var mesh: Mesh = null

	if imported is Mesh:
		mesh = imported
	else:
		printerr("Error: File is not a Mesh resource: ", mesh_path)
		return

	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []
	var triangles: Array[Dictionary] = []

	# Extract mesh data from all surfaces
	for surface_idx in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_idx)
		var material_name := "default_material"

		# Try to get material name from metadata
		if mesh.has_meta("surface_material_" + str(surface_idx)):
			material_name = mesh.get_meta("surface_material_" + str(surface_idx))

		var surface_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] if arrays[Mesh.ARRAY_VERTEX] else PackedVector3Array()
		var surface_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] else PackedVector3Array()
		var surface_uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] else PackedVector2Array()
		var surface_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] else PackedInt32Array()

		# Store vertex base index for this surface
		var vertex_base := vertices.size()
		var normal_base := normals.size()
		var uv_base := uvs.size()

		# Add surface vertices to main arrays
		for vert in surface_vertices:
			vertices.append(vert)

		for normal in surface_normals:
			normals.append(normal)

		for uv in surface_uvs:
			uvs.append(uv)

		# Process indices into triangles
		if surface_indices.size() > 0:
			for i in range(0, surface_indices.size(), 3):
				if i + 2 < surface_indices.size():
					var tri_face := [
						[vertex_base + surface_indices[i], uv_base + surface_indices[i], normal_base + surface_indices[i]],
						[vertex_base + surface_indices[i + 1], uv_base + surface_indices[i + 1], normal_base + surface_indices[i + 1]],
						[vertex_base + surface_indices[i + 2], uv_base + surface_indices[i + 2], normal_base + surface_indices[i + 2]]
					]
					triangles.append({"material": material_name, "face": tri_face})
		else:
			# No indices, use sequential vertices as triangles
			for i in range(0, surface_vertices.size(), 3):
				if i + 2 < surface_vertices.size():
					var tri_face := [
						[vertex_base + i, uv_base + i, normal_base + i],
						[vertex_base + i + 1, uv_base + i + 1, normal_base + i + 1],
						[vertex_base + i + 2, uv_base + i + 2, normal_base + i + 2]
					]
					triangles.append({"material": material_name, "face": tri_face})

	# Write the SMD File
	var smd_file := FileAccess.open(smd_path, FileAccess.WRITE)
	if not smd_file:
		printerr("Error: Could not open output path for writing: ", smd_path)
		return

	smd_file.store_line("version 1")

	# Define a single root bone for the static reference mesh
	smd_file.store_line("nodes")
	smd_file.store_line("0 \"static_root\" -1")
	smd_file.store_line("end")

	# Base skeleton requirements
	smd_file.store_line("skeleton")
	smd_file.store_line("time 0")
	smd_file.store_line("0 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000")
	smd_file.store_line("end")

	# Write standard triangles format
	smd_file.store_line("triangles")
	for tri in triangles:
		smd_file.store_line(tri["material"])

		# Each triangle must have exactly 3 vertices
		for v_data in tri["face"]:
			var v_idx: int = v_data[0]
			var vt_idx: int = v_data[1]
			var vn_idx: int = v_data[2]

			# Grab data or fall back to default vectors
			var v_pos := vertices[v_idx] if v_idx < vertices.size() else Vector3.ZERO
			var v_uv := uvs[vt_idx] if vt_idx < uvs.size() else Vector2.ZERO
			var v_norm := normals[vn_idx] if vn_idx < normals.size() else Vector3.UP

			# Valve SMD layout formatting string
			var vertex_string := "  0 %f %f %f %f %f %f %f %f" % [
				v_pos.x, v_pos.y, v_pos.z,
				v_norm.x, v_norm.y, v_norm.z,
				v_uv.x, v_uv.y
			]
			smd_file.store_line(vertex_string)

	smd_file.store_line("end")
	smd_file.close()
	print("Success: Converted mesh to SMD -> ", smd_path)	

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh:
		return node

	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found

	return null
