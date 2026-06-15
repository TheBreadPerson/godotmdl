class_name MDLGenerator extends Node

func _cleanup_file(path : String):
	if FileAccess.file_exists(path):
		var error = DirAccess.remove_absolute(path)
		if error != OK:
			print("Failed to delete ", path, ". Error code: ", error)

func generate_mdl(path : String, qc_path : String):
	var folder_path : String = ProjectSettings.get_setting(GodotMDL.SETTING_PATH)
	var exe_path = folder_path.path_join("studiomdl.exe")

	if OS.has_feature("windows"):
		exe_path = exe_path.replace("/", "\\")
	var output = []
	var arguments : PackedStringArray = PackedStringArray(["-game", ProjectSettings.globalize_path("res://"), ProjectSettings.globalize_path(qc_path)])
	OS.execute(exe_path, arguments, output, true)
	print(output[0])

	_cleanup_file(qc_path)
	_cleanup_file(qc_path.replace(".qc", ".smd"))

	EditorInterface.get_resource_filesystem().scan() # refresh files for .mdl to show up