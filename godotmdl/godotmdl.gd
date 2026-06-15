@tool
class_name GodotMDL extends EditorPlugin

var mdl_context_menu : MDLContextMenu
const SETTING_PATH = "addons/godotmdl/studiomdl_path"

func _add_project_setting() -> void:
	if not ProjectSettings.has_setting(SETTING_PATH):
		ProjectSettings.set_setting(SETTING_PATH, "")

	ProjectSettings.set_initial_value(SETTING_PATH, "")
	ProjectSettings.set_as_basic(SETTING_PATH, true)
	
	var property_info = {
		"name": SETTING_PATH,
		"description": "Folder where studiomdl.exe is located.",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_DIR,
		"hint_string": """Select the path containing studiomdl.exe (ex: "C:/Program Files (x86)/Steam/steamapps/common/Source SDK Base 2013 Singleplayer/bin"""
	}
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.save()

func _enter_tree():
	mdl_context_menu = MDLContextMenu.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, mdl_context_menu)
	_add_project_setting()

func _exit_tree():
	if mdl_context_menu:
		remove_context_menu_plugin(mdl_context_menu)
		mdl_context_menu = null
	if ProjectSettings.has_setting(SETTING_PATH):
		var settings = EditorInterface.get_editor_settings()
		settings.erase(SETTING_PATH)
