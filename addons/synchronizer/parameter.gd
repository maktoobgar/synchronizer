# Used along side with Synchronizer to synchronize your data
@tool
extends Node

class_name Parameter

# General Type
var __type__ = -1

# Key Type Specifics if Object
var __typed_class_name__ = ""
# Inner Class
var __typed_inner_script_name__ = ""
# Normal Class
var __typed_script_path_name__ = ""

# Key Type Specifics if Array
var __typed_array_builtin__ = -1
var __typed_array_class_name__ = ""
# Inner Class
var __typed_array_inner_script_name__ = ""
# Normal Class
var __typed_array_script_path_name__ = ""

# Key Type Specifics if Dictionary
var __typed_key_builtin__ = -1
var __typed_key_class_name__ = ""
# Inner Class
var __typed_key_inner_script_name__ = ""
# Normal Class
var __typed_key_script_path_name__ = ""

# Value Type Specifics if Dictionary
var __typed_value_builtin__ = -1
var __typed_value_class_name__ = ""
# Inner Class
var __typed_value_inner_script_name__ = ""
# Normal Class
var __typed_value_script_path_name__ = ""

var v: Variant = null
var synchronizer: Node = null
var auto_sync: bool = true

func _init(synchronizer: Synchronizer, value: Variant, auto_sync: bool = true) -> void:
	self._record_type(InnerClasses._get_structure(value))

	self.v = value
	self.synchronizer = synchronizer
	self.auto_sync = auto_sync

	# Make a meta in this format '__parameter_{number}__'
	# that holds reference to this object
	var parameter_count = synchronizer.get_meta("__parameters_count__", 0)
	self.name = "__parameter_" + str(parameter_count + 1) + "__"
	synchronizer.set_meta("__parameters_count__", parameter_count + 1)
	synchronizer.set_meta(self.name, self)

func _record_type(value: Variant) -> void:
	for key in value:
		if key != "__value__":
			self.set(key, value[key])

func pack_parameter() -> Dictionary:
	var encoded_data = {
		"__type__": self.__type__,
	}

	match self.__type__:
		TYPE_OBJECT:
			encoded_data["__typed_class_name__"] = self.__typed_class_name__
			encoded_data["__typed_inner_script_name__"] = self.__typed_inner_script_name__
			encoded_data["__typed_script_path_name__"] = self.__typed_script_path_name__
		TYPE_ARRAY:
			encoded_data["__typed_array_builtin__"] = self.__typed_array_builtin__
			encoded_data["__typed_array_class_name__"] = self.__typed_array_class_name__
			encoded_data["__typed_array_inner_script_name__"] = self.__typed_array_inner_script_name__
			encoded_data["__typed_array_script_path_name__"] = self.__typed_array_script_path_name__
		TYPE_DICTIONARY:
			encoded_data["__typed_key_builtin__"] = self.__typed_key_builtin__
			encoded_data["__typed_key_class_name__"] = self.__typed_key_class_name__
			encoded_data["__typed_key_inner_script_name__"] = self.__typed_key_inner_script_name__
			encoded_data["__typed_key_script_path_name__"] = self.__typed_key_script_path_name__
			encoded_data["__typed_value_builtin__"] = self.__typed_value_builtin__
			encoded_data["__typed_value_class_name__"] = self.__typed_value_class_name__
			encoded_data["__typed_value_inner_script_name__"] = self.__typed_value_inner_script_name__
			encoded_data["__typed_value_script_path_name__"] = self.__typed_value_script_path_name__

	encoded_data["__value__"] = self.v
	encoded_data = InnerClasses.pack(encoded_data, true)
	return encoded_data

func unpack_parameter(value: Variant) -> Variant:
	return InnerClasses.unpack(value)

func set_v(value: Variant, auto_sync: bool = true) -> Parameter:
	self.synchronizer.set_parameter(self.name, value, auto_sync)
	return self

func listen(callable: Callable) -> Parameter:
	self.synchronizer.listen(self.name, callable)
	return self

func synchronize(value: Variant = ERR_INVALID_DATA, from_who: int = 1) -> Parameter:
	self.synchronizer.synchronize(self.name, value, from_who)
	return self

func synchronize_but_me(value: Variant = ERR_INVALID_DATA, from_who: int = 1) -> Parameter:
	self.synchronizer.synchronize_but_me(self.name, value, from_who)
	return self

func synchronize_id(player_id: int, value: Variant = ERR_INVALID_DATA) -> Parameter:
	self.synchronizer.synchronize_id(player_id, self.name, value)
	return self

func synchronize_from_server(from_who: int = 1) -> Parameter:
	self.synchronizer.synchronize_from_server(self.name, from_who)
	return self
