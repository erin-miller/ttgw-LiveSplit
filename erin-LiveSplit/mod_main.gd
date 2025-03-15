extends Node


const MOD_DIR := "erin-LiveSplit"
const LOG_NAME := "erin-LiveSplit:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	# Add extensions
	install_script_extensions()
	install_script_hook_files()

	# Add translations
	add_translations()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")


func install_script_hook_files() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")


func add_translations() -> void:
	translations_dir_path = mod_dir_path.path_join("translations")


func _ready() -> void:
	var s_script = load(mod_dir_path.path_join("splitter.gd"))
	if s_script:
		var s = s_script.new()
		add_child(s)
	
	ModLoaderLog.info("Ready", LOG_NAME)
