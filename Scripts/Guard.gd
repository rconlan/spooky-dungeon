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
@export var rotation_duration: float = 0.3  # Time to rotate to face player

# Track if player is in range
var player_in_range: bool = false
var player: CharacterBody3D = null
# Dialogue settings
var typing_speed: float = 0.05  # Time between each character in seconds
var is_typing: bool = false
var original_rotation: float = 0.0  # Store original Y rotation

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
	
	# Store original rotation
	var start_rotation = rotation.y
	original_rotation = start_rotation
	
	# Rotate guard to face player
	var direction_to_player = player.global_position - global_position
	direction_to_player.y = 0  # Keep rotation horizontal only
	var target_rotation = atan2(direction_to_player.x, direction_to_player.z) + PI
	
	# Use lerp_angle for proper shortest-path rotation
	var tween = create_tween()
	tween.tween_method(
		func(t): rotation.y = lerp_angle(start_rotation, target_rotation, t),
		0.0,
		1.0,
		rotation_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	# Tell player to lock movement and zoom camera
	if player and player.has_method("start_dialogue"):
		player.start_dialogue(zoom_fov, zoom_duration)
	
	# Hide prompt and show dialogue panel
	prompt_label.visible = false
	dialogue_panel.visible = true
	dialogue_text.text = ""
	
	# Type out the text character by character
	is_typing = true
	for i in range(dialogue_message.length()):
		dialogue_text.text += dialogue_message[i]
		await get_tree().create_timer(typing_speed).timeout
	is_typing = false
	
	# Auto-hide dialogue after a few seconds
	await get_tree().create_timer(3.0).timeout
	
	# Tell player to unlock movement and zoom out
	if player and player.has_method("end_dialogue"):
		await player.end_dialogue(zoom_duration)
	
	# Rotate back to original rotation using lerp_angle
	var current_rot = rotation.y
	var return_tween = create_tween()
	return_tween.tween_method(
		func(t): rotation.y = lerp_angle(current_rot, original_rotation, t),
		0.0,
		1.0,
		rotation_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if player_in_range:
		dialogue_panel.visible = false
		prompt_label.visible = true
	else:
		dialogue_panel.visible = false
