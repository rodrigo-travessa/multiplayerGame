extends MarginContainer

var main_scene: PackedScene = preload("uid://cllxvom2safnd")
@onready var main_menu_scene : PackedScene = load("uid://kew6ccjrwycd")
@onready var back_button: Button = %BackButton

@onready var display_name_text_edit: TextEdit = %DisplayNameTextEdit
@onready var port_text_edit: TextEdit = %PortTextEdit
@onready var host_button: Button = %HostButton
@onready var ip_address_text_edit: TextEdit = %IpAddressTextEdit
@onready var join_button: Button = %JoinButton
@onready var server_error_label: Label = %ServerErrorLabel
@onready var client_error_label: Label = %ClientErrorLabel
@onready var error_button: Button = %ErrorButton
@onready var error_container: MarginContainer = %ErrorContainer

var is_connecting: bool

func _ready() -> void:
	error_container.visible = false
	error_button.pressed.connect(error_button_pressed)
	
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	display_name_text_edit.text_changed.connect(on_text_changed)
	port_text_edit.text_changed.connect(on_text_changed)
	ip_address_text_edit.text_changed.connect(on_text_changed)
	
	display_name_text_edit.text = MultiplayerConfig.display_name
	ip_address_text_edit.text  = MultiplayerConfig.ip_address
	port_text_edit.text =str(MultiplayerConfig.port)
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)
	
	validate()

func error_button_pressed():
	error_container.visible = false

func on_text_changed():
	validate()

func _on_host_pressed() -> void :
	var server_peer := ENetMultiplayerPeer.new()
	var error := server_peer.create_server(MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error(false)
		return
	
	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(main_scene)

func show_error(is_client: bool):
	client_error_label.visible = is_client
	server_error_label.visible = !is_client
	error_container.visible = true

func _on_join_pressed() -> void:
	var client_peer := ENetMultiplayerPeer.new()
	var error := client_peer.create_client(MultiplayerConfig.ip_address, MultiplayerConfig.port)
	print(error)
	if error != Error.OK:
		show_error(true)
		return
	is_connecting = true
	multiplayer.multiplayer_peer = client_peer
	validate()
	

func on_connection_failed():
	is_connecting = false
	show_error(true)
	validate()
func validate():
	var port := port_text_edit.text
	if port.is_valid_int():
		MultiplayerConfig.port = int(port)
		if MultiplayerConfig.port <= 0:
			MultiplayerConfig.port = -1
	
	MultiplayerConfig.display_name = display_name_text_edit.text
	
	var is_valid_port := MultiplayerConfig.port > 0
	var is_valid_name := !MultiplayerConfig.display_name.is_empty()
	var is_valid_ip := !MultiplayerConfig.ip_address.is_empty()
	
	var ip := ip_address_text_edit.text
	if ip.is_valid_ip_address():
		MultiplayerConfig.ip_address = ip
	else:
		MultiplayerConfig.ip_address = ""
	
	host_button.disabled = !is_valid_port or !is_valid_name or is_connecting
	join_button.disabled = !is_valid_port or !is_valid_name or !is_valid_ip or is_connecting

func _on_connected_to_server():
	get_tree().change_scene_to_packed(main_scene)

func _on_back_button_pressed():
	get_tree().change_scene_to_packed(main_menu_scene)
