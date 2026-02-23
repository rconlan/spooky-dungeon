extends Node3D

# References to UI elements
@onready var prompt_label: Label3D = $PromptLabel
@onready var dialogue_panel: ColorRect = $DialogueUI/DialoguePanel
@onready var dialogue_text: Label = $DialogueUI/DialoguePanel/DialogueText
@onready var interaction_area: Area3D = $InteractionArea
@onready var face_marker: Node3D = $FaceMarker
@export var dialogue_message: String = "Hello World"

# Camera zoom settings
@export var zoom_fov: float = 50.0  # Lower FOV = more zoom
@export var zoom_duration: float = 0.5  # Time to zoom in/out
@export var interaction_distance: float = 2.0  # How far in front of guard to position player

# Track if player is in range
var player_in_range: bool = false
var player: CharacterBody3D = null
# Dialogue settings
var typing_speed: float = 0.05  # Time between each character in seconds
var is_typing: bool = false

func _ready():
	# Hide both labels initially
	prompt_label.visible = false
	dialogue_panel.visible = false
	
	# Connect signals from the interaction area
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _process(_delta):
	# Check for E key press when player is in range
	if player_in_range and Input.is_action_just_pressed("interact"):
		_show_dialogue()

func _on_body_entered(body):
	# Check if it's the player entering
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = true
		player = body
		prompt_label.visible = true
		dialogue_panel.visible = false

func _on_body_exited(body):
	# Check if it's the player leaving
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = false
		player = null
		prompt_label.visible = false
		dialogue_panel.visible = false

func _show_dialogue():
	# Don't start new dialogue if already typing
	if is_typing:
		return
	
	# Calculate interaction position in front of the guard
	# Use the guard's -Z axis as forward (standard Godot convention)
	var guard_forward = -global_transform.basis.z
	guard_forward.y = 0  # Keep movement horizontal only
	guard_forward = guard_forward.normalized()
	
	var interaction_pos = global_position + guard_forward * interaction_distance
	interaction_pos.y = player.global_position.y  # Keep at player's current height
	
	# Debug: Print to verify positions
	print("Guard position: ", global_position)
	print("Guard forward: ", guard_forward)
	print("Interaction position: ", interaction_pos)
	print("Look at target: ", global_position + Vector3(0, 0.5, 0))
	
	# Tell player to move to position, look at guard, and zoom camera
	if player and player.has_method("start_dialogue"):
		player.start_dialogue(zoom_fov, zoom_duration, interaction_pos, global_position + Vector3(0, 0.5, 0))
	
	# Hide prompt and show dialogue panel
	prompt_label.visible = false
	dialogue_panel.visible = true
	dialogue_text.text = ""
	
	# Type out the text character by character
	is_typing = true
	print("Starting text typewriter...")
	for i in range(dialogue_message.length()):
		dialogue_text.text += dialogue_message[i]
		await get_tree().create_timer(typing_speed).timeout
	is_typing = false
	print("Text finished typing")
	print("Player rotation Y: ", rad_to_deg(player.rotation.y))
	print("Player look_rotation.y: ", rad_to_deg(player.look_rotation.y))
	
	# Auto-hide dialogue after a few seconds
	await get_tree().create_timer(3.0).timeout
	print("Before end_dialogue - Player rotation Y: ", rad_to_deg(player.rotation.y))
	
	# Tell player to unlock movement and zoom out
	if player and player.has_method("end_dialogue"):
		await player.end_dialogue(zoom_duration)
	
	if player_in_range:
		dialogue_panel.visible = false
		prompt_label.visible = true
	else:
		dialogue_panel.visible = false
