class_name QCGenerator extends Node


func generate_qc_file(path : String) -> void:
	# path is something like: res://models/test.obj
	var file = FileAccess.open(path, FileAccess.WRITE)
	var model_path : String = ""
	var model_name : String = path.replace(".qc", "").split("/")[-1]

	if file:
		file.store_string(
			"""$modelname "{model_path}{model_name}.mdl"
$scale 1.0

// Tells the engine to collapse bones and optimize the model
$staticprop

$body mesh "{model_name}.smd"

$surfaceprop "wood" // Sets the sound and impact properties

$sequence idle "{model_name}.smd" loop fps 15

$collisionmodel "{model_name}.smd" {
    $mass 50
    $concave
}
""".format({"model_path" : model_path, "model_name" : model_name}))