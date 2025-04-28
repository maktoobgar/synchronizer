@tool
extends Node

# Record the name of an inner class as key
# Record the path of the script that inner class is defined in as value
var class_name_to_class_name: Dictionary[String, GDScript] = {
	"PlayerPeer": MultiplayerClass.PlayerPeer,
}

# Unused keys
var __unused_object_keys__: Dictionary[String, bool] = {
	"Built-in script": true,
	"Node": true,
	"_import_path": true,
	"scene_file_path": true,
	"owner": true,
	"multiplayer": true,
	"Process": true,
	"Thread Group": true,
	"Physics Interpolation": true,
	"Auto Translate": true,
	"Editor Description": true,
}

func _init() -> void:
	for property in Resource.new().get_property_list():
		__unused_object_keys__[property["name"]] = true

func _get_structure(value: Variant) -> Dictionary:
	var output = {}
	output["__type__"] = typeof(value)
	match typeof(value):
		TYPE_OBJECT:
			value = value as Object
			if value == null or value is GDScript:
				return {}
			output["__typed_class_name__"] = value.get_class()
			if output["__typed_class_name__"] == "RefCounted":
				output["__typed_inner_script_name__"] = InnerClasses.find_script_name(value.get_script())
			elif output["__typed_class_name__"] != "":
				var script: GDScript = value.get_script()
				output["__typed_script_path_name__"] = script.resource_path
			else:
				output["__typed_script_path_name__"] = ""
		TYPE_ARRAY:
			if value.is_typed():
				output["__typed_array_builtin__"] = value.get_typed_builtin()
				output["__typed_array_class_name__"] = value.get_typed_class_name()
				if output["__typed_array_class_name__"] == "RefCounted":
					output["__typed_array_inner_script_name__"] = InnerClasses.find_script_name(value.get_typed_script())
				elif output["__typed_array_class_name__"] != "":
					var script: GDScript = value.get_typed_script()
					output["__typed_array_script_path_name__"] = script.resource_path
				else:
					output["__typed_array_script_path_name__"] = ""
		TYPE_DICTIONARY:
			if value.is_typed_key():
				output["__typed_key_builtin__"] = value.get_typed_key_builtin()
				output["__typed_key_class_name__"] = value.get_typed_key_class_name()
				if output["__typed_key_class_name__"] == "RefCounted":
					output["__typed_key_inner_script_name__"] = InnerClasses.find_script_name(value.get_typed_key_script())
				elif output["__typed_key_class_name__"] != "":
					var script: GDScript = value.get_typed_key_script()
					output["__typed_key_script_path_name__"] = script.resource_path
				else:
					output["__typed_key_script_path_name__"] = ""
			if value.is_typed_value():
				output["__typed_value_builtin__"] = value.get_typed_value_builtin()
				output["__typed_value_class_name__"] = value.get_typed_value_class_name()
				if output["__typed_value_class_name__"] == "RefCounted":
					output["__typed_value_inner_script_name__"] = InnerClasses.find_script_name(value.get_typed_value_script())
				elif output["__typed_value_class_name__"] != "":
					var script: GDScript = value.get_typed_value_script()
					output["__typed_value_script_path_name__"] = script.resource_path
				else:
					output["__typed_value_script_path_name__"] = ""
	return output

func find_class(key: String) -> GDScript:
	var script = class_name_to_class_name[key] if class_name_to_class_name.has(key) else null
	assert(script != null, "Couldn't find the class of '{0}' key.".format([key]))
	return script

func find_script_name(inner_class: GDScript) -> String:
	for key in class_name_to_class_name:
		if inner_class != class_name_to_class_name[key]:
			continue
		return key
	assert(false, "No name found for passed inner class.")
	return ""

func pack(value: Variant, typed = false) -> Variant:
	var encoded_data = {}
	if typed:
		encoded_data = value
		value = value["__value__"]
	else:
		encoded_data = _get_structure(value)
		if encoded_data.is_empty():
			return null

	var output = null
	match encoded_data["__type__"]:
		TYPE_DICTIONARY:
			output = {}
			for key in value:
				output[key] = pack(value[key])
		TYPE_ARRAY:
			output = []
			for item in value:
				output.append(pack(item))
		TYPE_OBJECT:
			output = {}
			if value.is_class("Node") and value.is_inside_tree():
				return null
			for property in value.get_property_list():
				var parameter = value.get(property["name"])
				if __unused_object_keys__.has(property["name"]) or property["name"].ends_with(".gd"):
					continue
				match typeof(value):
					TYPE_CALLABLE, TYPE_NIL, TYPE_SIGNAL:
						continue
				output[property["name"]] = pack(parameter)
		_:
			output = value
	encoded_data["__value__"] = output

	return encoded_data

func unpack(value: Dictionary) -> Variant:
	match value["__type__"]:
		TYPE_OBJECT:
			if value["__typed_class_name__"] == "RefCounted":
				var inner_class = InnerClasses.find_class(value["__typed_inner_script_name__"])
				var obj = inner_class.new()
				if value["__value__"] != null:
					_unpack_to(obj, value["__value__"])
				return obj
			else:
				var class_script = load(value["__typed_script_path_name__"])
				var obj = class_script.new()
				if value["__value__"] != null:
					_unpack_to(obj, value["__value__"])
				return obj
		TYPE_ARRAY:
			var array_class: GDScript = null
			if value["__typed_array_builtin__"] == TYPE_OBJECT and value["__typed_array_class_name__"] == "RefCounted":
				array_class = InnerClasses.find_class(value["__typed_array_inner_script_name__"])
			elif value["__typed_array_builtin__"] == TYPE_OBJECT and value["__typed_array_class_name__"] != "RefCounted":
				array_class = load(value["__typed_array_script_path_name__"])

			var arr = Array([],
				value["__typed_array_builtin__"],
				value["__typed_array_class_name__"] ,
				array_class
			)
			if value["__value__"] != null:
				_unpack_to(arr, value["__value__"])
			return arr
		TYPE_DICTIONARY:
			var key_class: GDScript = null
			var value_class: GDScript = null

			if value["__typed_key_builtin__"] == TYPE_OBJECT and value["__typed_key_class_name__"] == "RefCounted":
				key_class = InnerClasses.find_class(value["__typed_key_inner_script_name__"])
			elif value["__typed_key_builtin__"] == TYPE_OBJECT and value["__typed_key_class_name__"] != "RefCounted":
				key_class = load(value["__typed_key_script_path_name__"])

			if value["__typed_value_builtin__"] == TYPE_OBJECT and value["__typed_value_class_name__"] == "RefCounted":
				value_class = InnerClasses.find_class(value["__typed_value_inner_script_name__"])
			elif value["__typed_value_builtin__"] == TYPE_OBJECT and value["__typed_value_class_name__"] != "RefCounted":
				value_class = load(value["__typed_value_script_path_name__"])

			var obj = Dictionary({},
				value["__typed_key_builtin__"],
				value["__typed_key_class_name__"],
				key_class,
				value["__typed_value_builtin__"],
				value["__typed_value_class_name__"],
				value_class
			)
			if value["__value__"] != null:
				_unpack_to(obj, value["__value__"])
			return obj
		_:
			return value["__value__"]

func _unpack_to(to: Variant, from: Variant) -> void:
	match typeof(to):
		TYPE_ARRAY:
			for item in from:
				to.append(unpack(item))
		TYPE_DICTIONARY, TYPE_OBJECT:
			for key in from:
				to.set(key, unpack(from[key]))
		_:
			to = from
