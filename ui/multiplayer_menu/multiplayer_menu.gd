extends MarginContainer

@onready var display_name_text_edit: TextEdit = %DisplayNameTextEdit
@onready var port_text_edit: TextEdit = %PortTextEdit
@onready var host_button: Button = %HostButton
@onready var ip_address_text_edit: TextEdit = %IPAddressTextEdit
@onready var join_button: Button = %JoinButton
@onready var back_button: Button = %BackButton
@onready var error_container: MarginContainer = $ErrorContainer
@onready var client_error_label: Label = %ClientErrorLabel
@onready var server_error_label: Label = %ServerErrorLabel
@onready var error_confirm_button: Button = %ErrorConfirmButton


@onready var main_menu_scene: PackedScene = load("uid://dgistbjkrs4hx")

var main_scene: PackedScene = preload("uid://bw77affpadnt4")
var is_connecting: bool


func _ready():
	error_container.visible = false
	error_confirm_button.pressed.connect(_on_error_confirm_pressed)

	back_button.pressed.connect(_on_back_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	display_name_text_edit.text_changed.connect(_on_text_changed)
	ip_address_text_edit.text_changed.connect(_on_text_changed)
	port_text_edit.text_changed.connect(_on_text_changed)
	
	display_name_text_edit.text = MultiplayerConfig.display_name
	ip_address_text_edit.text = MultiplayerConfig.ip_address
	port_text_edit.text = str(MultiplayerConfig.port)
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	validate()
	
	UIAudioManager.register_buttons([
		back_button,
		host_button,
		join_button,
		error_confirm_button
	])


func validate():
	var port := port_text_edit.text
	if port.is_valid_int():
		MultiplayerConfig.port = int(port)
		if MultiplayerConfig.port <= 0:
			MultiplayerConfig.port = -1
	else:
		MultiplayerConfig.port = -1
	
	var ip := ip_address_text_edit.text
	if ip.is_valid_ip_address():
		MultiplayerConfig.ip_address = ip
	else:
		MultiplayerConfig.ip_address = ""
	
	MultiplayerConfig.display_name = display_name_text_edit.text
	
	var is_valid_port := MultiplayerConfig.port > 0
	var is_valid_name := !MultiplayerConfig.display_name.is_empty()
	var is_valid_ip := !MultiplayerConfig.ip_address.is_empty()

	host_button.disabled = is_connecting || !is_valid_port || !is_valid_name
	join_button.disabled = is_connecting || !is_valid_port || !is_valid_name || !is_valid_ip


func show_error(is_client: bool):
	client_error_label.visible = is_client
	server_error_label.visible = !is_client
	error_container.visible = true


func _on_host_pressed() -> void:
	var server_peer := ENetMultiplayerPeer.new()
	var error := server_peer.create_server(MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error(false)
		return

	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(main_scene)


func _on_join_pressed() -> void:
	var client_peer := ENetMultiplayerPeer.new()
	var error := client_peer.create_client(MultiplayerConfig.ip_address, MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error(true)
		return

	is_connecting = true
	multiplayer.multiplayer_peer = client_peer
	validate()


func _on_connected_to_server():
	get_tree().change_scene_to_packed(main_scene)


func _on_back_pressed():
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_text_changed():
	validate()


func _on_error_confirm_pressed():
	error_container.visible = false


func _on_connection_failed():
	is_connecting = false
	validate()
	show_error(true)
