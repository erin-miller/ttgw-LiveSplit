extends Node

const LOG_NAME := "erin-LiveSplit"

@export var url := "ws://127.0.0.1:16834/livesplit"

var socket := WebSocketPeer.new()

var pent: FinalBossScene = null
var game_timer: RunTimer = null

var started := false
var at_game_end := false


func _ready() -> void:
	_connect_socket()
	Util.s_floor_number_changed.connect(_on_floor_change)
	var root = get_tree().get_root().get_tree()
	root.node_added.connect(_on_node_added)

func _process(_delta) -> void:
	socket.poll()
	
	# do not start script until socket is ready
	var state = socket.get_ready_state()
	if state != WebSocketPeer.STATE_OPEN:
		_reconnect_socket()
		return
	
	# refetch timer if invalid (likely due to a long pause)
	if not is_instance_valid(game_timer) and Util.get_player():
		game_timer = get_node("/root/SceneLoader/Persistent/Player/GameTimer/")
	
	# if there isn't an active player, reset
	if started and not is_game_active():
		_reset()
		return
	
	# timer init
	if game_timer:
		# start timer
		if not started and game_timer.time > 0:
			_send_req("switchto gametime")
			_send_req("start")
			started = true
		
		_send_req("setgametime " + str(game_timer.time))

func is_game_active() -> bool:
	return Util.get_player() != null

func _on_node_added(node):
	var new = node.name.to_lower()
	if new == "barrel_room":
		_on_barrel_added()
	if new == "penthouse":
		_on_penthouse_added()

func _on_barrel_added():
	ModLoaderLog.debug("Splitting timer due to entering executive office.", LOG_NAME)
	_send_req("split")

func _on_floor_change():
	# do not split on ground floor
	if Util.floor_number <= 0 or not Util.get_player():
		return
	ModLoaderLog.debug("Splitting timer due to new floor end.", LOG_NAME)
	_send_req("split")

func _on_penthouse_added():
	ModLoaderLog.debug("Preparing end game timer...", LOG_NAME)
	BattleService.s_battle_ended.connect(_on_game_end)
	at_game_end = true

func _on_game_end():
	ModLoaderLog.debug("Ending timer due to game end.", LOG_NAME)
	_send_req("split")

func _send_req(msg: String):
	var err: Error = socket.send_text(msg)
	if err:
		ModLoaderLog.error(error_string(err) + " on message: " + msg, LOG_NAME)

func _reconnect_socket():
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		socket = WebSocketPeer.new()
		_connect_socket()

func _connect_socket():
	var err := socket.connect_to_url(url)
	if err != OK:
		ModLoaderLog.error("Failed to connect to LiveSplit WebSocket server.", LOG_NAME)
	else:
		ModLoaderLog.debug("Connected to LiveSplit WebSocket server.", LOG_NAME)
		socket.poll() # immediately connect

func _reset():
	if not at_game_end:
		started = false
		_send_req("reset")

func _exit_tree() -> void:
	at_game_end = false
	_reset()
	socket.close()
