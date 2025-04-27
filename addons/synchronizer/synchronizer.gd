## Every value change first gets sent to host and from
## host it gets sent to every one else to get synchronized.
##
## NOTE: I ask myself and I answer.
## - How about if I don't want this time to sync my value with
## anyone else?
## + I think you are doing some tricky stuff and you can do better
## and cleaner for sure. (DO NOT do whatever you are doing)
@tool
extends Node

class_name Synchronizer

var selff = self

# Clients are gonna rpc it to server
# Server is gonna run it to update a player's value
@rpc("any_peer", "call_remote", "reliable")
func _class_synchronizer_for_one_player(node_address: String, key: String, player_id: int) -> void:
	assert(_get_multiplayer().is_server(), "only server runs this code")
	var node = get_node(node_address) if node_address else null
	if not node:
		return
	var value = node.get_meta(key, null).pack_parameter()
	_class_synchronizer.rpc_id(player_id, node_address, key, value)

# Clients are gonna rpc it to server
# Server is gonna run it to update a player's value
@rpc("any_peer", "call_remote", "reliable")
func _list_synchronizer_for_one_player(node_address: String, keys: Array[String], player_id: int) -> void:
	assert(_get_multiplayer().is_server(), "only server runs this code")
	var node = get_node(node_address) if node_address else null
	if not node:
		return
	var values = []
	for key in keys:
		assert(get_meta(key, null) != null, "'{0}' not found in properties of this node '{1}'".format([key, self.name]))
		values.push_back(node.get_meta(key, null).pack_parameter())
	_list_synchronizer.rpc_id(player_id, node_address, keys, values)

# Mainly clients are gonna run the code
# Mainly server is gonna rpc it to everyone or a specific client that has outdated data
@rpc("any_peer", "call_remote", "reliable")
func _class_synchronizer(node_address: String, key: String, value: Variant) -> void:
	if key == "players":
		pass
	var node = get_node(node_address) if node_address else null
	if not node:
		return
	node._set_parameter(key, value)

# Server is gonna run the code
# Clients are gonna rpc it to server
# Then server calls '_class_synchronizer'
@rpc("any_peer", "call_remote", "reliable")
func _request_class_synchronization(node_address: String, key: String, value: Variant, but_this_id: int = -1) -> void:
	# First I need to first of everyone else update the value myself as the server
	_class_synchronizer(node_address, key, value)
	# Then I'm gonna pass it to anyone else
	for id in _get_multiplayer().get_peers():
		if id != _get_multiplayer().get_unique_id() and id != but_this_id:
			_class_synchronizer.rpc_id(id, node_address, key, value)

# Mainly clients are gonna run the code
# Mainly server is gonna rpc it to everyone or a specific client that has outdated data
@rpc("any_peer", "call_remote", "reliable")
func _list_synchronizer(node_address: String, keys: Array[String], values: Array[Variant]) -> void:
	for i in range(len(keys)):
		var key = keys[i]
		var value = values[i]
		_class_synchronizer(node_address, key, value)

# Server is gonna run the code
# Clients are gonna rpc it to server
# Then server calls the function on top
@rpc("any_peer", "call_remote", "reliable")
func _request_list_synchronization(node_address: String, keys: Array[String], values: Array[Variant], but_this_id: int = -1) -> void:
	# Before everyone else, I need to update the value myself as the server
	_list_synchronizer(node_address, keys, values)
	# Then I'm gonna pass it to anyone else
	for id in _get_multiplayer().get_peers():
		if id != _get_multiplayer().get_unique_id() and id != but_this_id:
			_list_synchronizer.rpc_id(id, node_address, keys, values)

# First input = Variable name that changed
# Second input = New changed value
@onready var signals: Dictionary[String, Array] = _get_signals(_get_property_names(self))

func _is_connected() -> bool:
	return multiplayer and multiplayer.is_server() or (multiplayer.has_multiplayer_peer() and multiplayer.get_multiplayer_peer().get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED)

func _get_multiplayer() -> MultiplayerAPI:
	if is_inside_tree():
		var tree = get_tree()
		if tree:
			tree.set_multiplayer(tree.get_multiplayer())
	return multiplayer

func _get_signals(keys: Dictionary[String, bool]) -> Dictionary[String, Array]:
	var signals: Dictionary[String, Array] = {}
	for key in keys:
		signals[key] = []
	return signals

func _get_property_names(obj: Object) -> Dictionary[String, bool]:
	var keys: Dictionary[String, bool] = {}
	for property in obj.get_property_list():
		if property.name != "RefCounted" and property.name != "script" and property.name != "Built-in script":
			keys[property.name] = true
	return keys

# This function gets called by network data stream calls
func _set_parameter(key: String, value: Variant) -> void:
	set_parameter(key, value, false)

# Everyone else calls this function through _class_synchronizer function
func set_parameter(key: String, value: Variant, auto_sync: bool = true) -> void:
	var parameter: Parameter = self.get_meta(key) if self.has_meta(key) else null
	if value is Dictionary and (not value.is_typed_key() or value.get_typed_key_builtin() == TYPE_STRING) and value.has("__type__"):
		value = InnerClasses.unpack(value)
	if parameter and parameter is Parameter:
		parameter.v = value
	else:
		set(key, value)
	fire(key, value)

	if auto_sync and parameter is Parameter and parameter.auto_sync:
		synchronize_but_me(key)
	elif auto_sync and parameter == null:
		synchronize_but_me(key)

# Fires a signal that is for Request-Response model
#
# Signal fires with the name of request function
func fire_function(key: String, array: Array) -> void:
	if key not in self.signals:
		self.signals[key] = []
	for i in range(len(self.signals[key]) - 1, -1, -1):
		var function = self.signals[key][i]
		if not function or function is not Callable or not function.is_valid():
			self.signals[key].remove_at(i)
	for function in self.signals[key]:
		function.callv(array)

# This function emits a signal
func fire(key: String, value) -> void:
	if key not in self.signals:
		self.signals[key] = []
	for i in range(len(self.signals[key]) - 1, -1, -1):
		var function = self.signals[key][i]
		if not function or function is not Callable or not function.is_valid():
			self.signals[key].remove_at(i)
	for function in self.signals[key]:
		function.call(value)

# This function connects a function to a signal
func listen(key: String, callable: Callable) -> void:
	if key not in self.signals:
		self.signals[key] = []
	if key == "players":
		pass
	self.signals[key].push_back(callable)

# Authority or clients can call this function
#
# It syncs everyone elses value with your actual parameter value in class
#
# Client: Take my data and updates everyone else's data with mine
func synchronize(key: String, from_who: int = 1):
	var parameter: Parameter = self.get_meta(key) if self.has_meta(key) else null
	var value = null
	if parameter and parameter is Parameter:
		value = self.get_meta(key, null).pack_parameter()
	else:
		value = InnerClasses.pack(self.get(key))
	var node_address = get_path() if is_inside_tree() else NodePath()
	if not node_address.is_empty():
		if from_who == _get_multiplayer().get_unique_id():
			_class_synchronizer(node_address, key, value)
			_class_synchronizer.rpc(node_address, key, value)
		else:
			_request_class_synchronization.rpc_id(from_who, node_address, key, value)

func synchronize_but_me(key: String, from_who: int = 1):
	var parameter: Parameter = self.get_meta(key) if self.has_meta(key) else null
	var value = null
	if parameter and parameter is Parameter:
		value = self.get_meta(key, null).pack_parameter()
	else:
		value = InnerClasses.pack(self.get(key))
	var node_address = get_path() if is_inside_tree() else NodePath()
	if not node_address.is_empty():
		if from_who == _get_multiplayer().get_unique_id():
			_class_synchronizer.rpc(node_address, key, value)
		else:
			_request_class_synchronization.rpc_id(from_who, node_address, key, value, _get_multiplayer().get_unique_id())

# Authority calls this function (Because it doens't make sense for a client
# to update another client, we just let server to decide on data flow)
#
# Used in cases that you know somebody has outdated data
# So specifically update their value with this
# Not very useful, used in specific scenarios
#
# Nobody asked any questions => Mainly Server: You (player_id guy) Take my data and update yours with mine
func synchronize_id(player_id: int, key: String):
	var parameter: Parameter = self.get_meta(key) if self.has_meta(key) else null
	var value = null
	if parameter and parameter is Parameter:
		value = self.get_meta(key, null).pack_parameter()
	else:
		value = InnerClasses.pack(self.get(key))
	var node_address = get_path() if is_inside_tree() else NodePath()
	if not node_address.is_empty():
		if player_id != _get_multiplayer().get_unique_id():
			_class_synchronizer.rpc_id(player_id, node_address, key, value)
		else:
			_class_synchronizer(node_address, key, value)

# Instead of client giving a value and asking for server and everyone else
# to update their value to the value they given, it requests to update everyone
# else's data with the data from server (Mainly server)
#
# I just came late to the party... tell me, what's up?
#
# One request from someone => Everyone get the updated data from (mainly) server
#
# NOTE: If you don't know what you're doing, maybe don't change 'from_who' parameter
func synchronize_from_server(key: String, from_who: int = 1) -> void:
	var node_address = get_path() if is_inside_tree() else NodePath()
	if not node_address.is_empty():
		var parameter: Parameter = self.get_meta(key) if self.has_meta(key) else null
		var value = null
		if parameter and parameter is Parameter:
			value = self.get_meta(key, null).pack_parameter()
		else:
			value = InnerClasses.pack(self.get(key))
		if _get_multiplayer().get_unique_id() == from_who:
			_class_synchronizer(node_address, key, value)
		else:
			_class_synchronizer_for_one_player.rpc_id(from_who, node_address, key, _get_multiplayer().get_unique_id())

func synchronize_list_from_server(keys: Array[String], from_who: int = 1) -> void:
	var values = []
	for key in keys:
		var parameter: Parameter = self.get_meta(key) if self.has_meta(key) else null
		var value = null
		if parameter and parameter is Parameter:
			value = self.get_meta(key, null).pack_parameter()
		else:
			value = InnerClasses.pack(self.get(key))
		values.push_back(get_meta(key, null).pack_parameter())
	var node_address = get_path() if is_inside_tree() else NodePath()
	if not node_address.is_empty():
		if _is_connected() and _get_multiplayer().get_unique_id() == from_who:
			_list_synchronizer(node_address, keys, values)
		else:
			_list_synchronizer_for_one_player.rpc_id(from_who, node_address, keys, _get_multiplayer().get_unique_id())

# An internal function to execute rpc calls and return its output
func _execute_rpc(node_address: String, function_name: String, arguments: Array) -> Variant:
	var node = get_node(node_address) if node_address else null
	if not node:
		return null
	if not node.has_method(function_name):
		return null
	var function: Callable = node.get(function_name)
	arguments = arguments.map(func(argument):
		return InnerClasses.unpack(argument))
	var output = function.callv(arguments)
	if is_instance_of(output, FunctionRPC):
		output = output.run()
	_fire_rpc(node_address, function_name, arguments)
	return output

# Clients are gonna run this code
# Server is gonna rpc it to everyone but the requester
@rpc("any_peer", "call_remote", "reliable")
func _broadcast_rpc(node_address: String, function_name: String, arguments: Array) -> Variant:
	return _execute_rpc(node_address, function_name, arguments)

# Server is gonna run the code
# Clients are gonna rpc it
# It is just a request of running a function for everyone else
@rpc("any_peer", "call_remote", "reliable")
func _broadcast_rpc_call_from_server(node_address: String, function_name: String, arguments: Array) -> void:
	_execute_rpc(node_address, function_name, arguments)
	_broadcast_rpc.rpc(node_address, function_name, arguments)

# The exact same as what _execute_rpc does but just used for everyone else (any_peer)
# to send messages specifically to another client direcetly
# Anyone rpc it
# Anyone runs it
@rpc("any_peer", "call_remote", "reliable")
func _single_rpc(node_address: String, function_name: String, arguments: Array) -> void:
	_execute_rpc(node_address, function_name, arguments)

# A request that goes to server and runs on server and the response comes
# back to the requester itself
# Client rpc it
# Server runs it
@rpc("any_peer", "call_remote", "reliable")
func _request(node_address: String, function_name: String, arguments: Array, response_function_name: String, player_id: int) -> void:
	var output = _execute_rpc(node_address, function_name, arguments)
	if output != null:
		arguments.append(InnerClasses.pack(output))
	_response.rpc_id(player_id, node_address, response_function_name, arguments)

# A response to request of a client from server
# (Mainly) Server rpc it
# Client runs it
@rpc("any_peer", "call_remote", "reliable")
func _response(node_address: String, response_function_name: String, arguments: Array) -> void:
	_execute_rpc(node_address, response_function_name, arguments)

# A request for one peer (Mainly server) to broadcast a signal
@rpc("any_peer", "call_remote", "reliable")
func _request_broadcast_fire_rpc(node_address: String, function_name: String, arguments: Array) -> void:
	_fire_rpc(node_address, function_name, arguments)
	_fire_rpc.rpc(node_address, function_name, arguments)

# Emits a signal
@rpc("any_peer", "call_remote", "reliable")
func _fire_rpc(node_address: String, function_name: String, arguments: Array) -> void:
	var node = get_node(node_address) if node_address else null
	if not node:
		return
	var fire_function = node.get("fire_function")
	if fire_function and fire_function is Callable:
		fire_function.call(function_name, arguments)

# Every function call just happens to everyone else
# as soon as it gets called by a peer
class FunctionRPC:
	var synchronizer: Synchronizer
	var arguments: Array[Variant]
	var encoded_arguments: Array[Variant]
	var function: Callable
	var logic: Callable

	func _init(synchronizer: Synchronizer, function: Callable, arguments: Array[Variant], logic: Callable) -> void:
		self.synchronizer = synchronizer
		self.arguments = arguments
		self.encoded_arguments = arguments.map(func(v):
			return InnerClasses.pack(v))
		self.function = function
		self.logic = logic

	# Runs the function
	func run() -> Variant:
		return logic.call()

	# Call this function on this class for everyone else
	func rpc(from_who: int = 1) -> FunctionRPC:
		var node_address = synchronizer.get_path() if synchronizer.is_inside_tree() else ""
		var function_name = function.get_method()
		if not synchronizer._is_connected():
			synchronizer._execute_rpc(node_address, function_name, encoded_arguments)
			return
		if from_who == synchronizer._get_multiplayer().get_unique_id():
			# We want to make sure server runs the code first
			synchronizer._execute_rpc(node_address, function_name, encoded_arguments)
			synchronizer._broadcast_rpc.rpc(node_address, function_name, encoded_arguments)
		else:
			synchronizer._broadcast_rpc_call_from_server.rpc_id(from_who, node_address, function_name, encoded_arguments)
		return self

	# A function that anyone can call but mainly made for server
	# to update a client by fresh data
	func rpc_id(player_id: int) -> FunctionRPC:
		var node_address = synchronizer.get_path() if synchronizer.is_inside_tree() else ""
		var function_name = function.get_method()
		if synchronizer._get_multiplayer().get_unique_id() != player_id:
			synchronizer._single_rpc.rpc_id(player_id, node_address, function_name, encoded_arguments)
		else:
			# It is ok to not check connected state of network because I ran an rpc on myself
			synchronizer._execute_rpc(node_address, function_name, encoded_arguments)
		return self

	# Used to request (Mainly) server for an answer
	# Like asking a question
	func request(from_who: int = 1) -> FunctionRPC:
		var node_address = synchronizer.get_path() if synchronizer.is_inside_tree() else ""
		var function_name = function.get_method()
		var response_function_name = "_res_" + function_name
		if from_who != synchronizer._get_multiplayer().get_unique_id():
			synchronizer._request.rpc_id(from_who, node_address, function_name, encoded_arguments, response_function_name, synchronizer._get_multiplayer().get_unique_id())
		else:
			var output = synchronizer._execute_rpc(node_address, function_name, encoded_arguments)
			encoded_arguments.push_back(InnerClasses.pack(output))
			# It is ok to not check connected state of network because I asked a question from myself
			synchronizer._response(node_address, response_function_name, encoded_arguments)
			encoded_arguments.pop_back()
		return self

	# Used to request a server for an answer
	# Like asking a question exactly what request does but...
	# Answer gets sent to everyone
	func request_all(from_who: int = 1) -> FunctionRPC:
		var node_address = synchronizer.get_path() if synchronizer.is_inside_tree() else ""
		var function_name = function.get_method()
		var response_function_name = "_res_" + function_name
		if from_who != synchronizer._get_multiplayer().get_unique_id():
			synchronizer._request.rpc_id(from_who, node_address, function_name, encoded_arguments, response_function_name, synchronizer._get_multiplayer().get_unique_id())
		else:
			var output = synchronizer._execute_rpc(node_address, function_name, encoded_arguments)
			encoded_arguments.push_back(InnerClasses.pack(output))
			if not synchronizer._is_connected():
				synchronizer._response(node_address, response_function_name, encoded_arguments)
			else:
				synchronizer._response.rpc(node_address, response_function_name, encoded_arguments)
			encoded_arguments.pop_back()
		return self

	# Fires this function as a signal accross the whole network
	# First server runs the fire signal and then it broadcasts
	# through the whole network
	#
	# NOTE: It doesn't actually run the function, just fires a signal with the same name as function
	func fire_rpc(from_who: int = 1) -> void:
		var node_address = synchronizer.get_path() if synchronizer.is_inside_tree() else ""
		var function_name = function.get_method()
		if not synchronizer._is_connected():
			synchronizer._fire_rpc(node_address, function_name, encoded_arguments)
		elif from_who == synchronizer._get_multiplayer().get_unique_id():
			synchronizer._fire_rpc(node_address, function_name, encoded_arguments)
			synchronizer._fire_rpc.rpc(node_address, function_name, encoded_arguments)
		else:
			synchronizer._request_broadcast_fire_rpc.rpc_id(from_who, node_address, function_name, encoded_arguments)

func _after_ready() -> void:
	pass

func _init() -> void:
	var keys: Array[String] = []
	for i in range(get_meta("__parameters_count__", 0)):
		var meta_key_to_value = "__parameter_" + str(i + 1) + "__"
		var value = get_meta(meta_key_to_value, null)
		for property in get_property_list():
			var value_on_self = self.get(property.name)
			if is_same(value_on_self, value):
				value.name = property.name
				break
		keys.push_back(value.name)
		set_meta(value.name, value)
		remove_meta(meta_key_to_value)
	synchronize_list_from_server(keys)

	_after_ready.call_deferred()
