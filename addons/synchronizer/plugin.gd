@tool
extends EditorPlugin

const PATH_TO_INNER_CLASSES = "res://addons/synchronizer/inner_classes.gd"
const SINGLETON_NAME = "InnerClasses"

# Plugin installation
func _enter_tree():
	add_autoload_singleton(SINGLETON_NAME, PATH_TO_INNER_CLASSES)

# Plugin uninstallation
func _exit_tree():
	remove_autoload_singleton(SINGLETON_NAME)
