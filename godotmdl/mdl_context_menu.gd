@tool
class_name MDLContextMenu extends EditorContextMenuPlugin

var supported_types : Array = [".obj", ".fbx", ".mesh"]
var add_icon : Texture2D = preload("res://addons/godotmdl/Add.svg")

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh:
		return node
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found

	return null

func _popup_menu(paths: PackedStringArray):
	var has_models = Array(paths).filter(func(p):
		for ext in supported_types:
			if p.ends_with(ext):
				return true
		return false).size() > 0;
	if not has_models: return;

	add_context_menu_item("Create .mdl file", create_mdl_file, add_icon);

func create_mdl_file(paths: PackedStringArray):
	var models = Array(paths).filter(func(p):
		for ext in supported_types:
			if p.ends_with(ext):
				return true
		return false)
	var smd_converter : SMDConverter = SMDConverter.new()
	var qc_generator : QCGenerator = QCGenerator.new()
	var mdl_generator : MDLGenerator = MDLGenerator.new()

	for model_file in models:
		var file_extension = "."+model_file.get_extension()
		smd_converter.convert_to_smd(model_file)
		qc_generator.generate_qc_file(model_file.replace(file_extension, ".qc"))
		mdl_generator.generate_mdl(model_file.replace(file_extension, "").split("/")[-1], model_file.replace(file_extension, ".qc"))

