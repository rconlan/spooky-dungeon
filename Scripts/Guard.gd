extends Node3D

# References to UI elements
@onready var prompt_label: Label3D = $PromptLabel
@onready var dialogue_panel: ColorRect = $DialogueUI/DialoguePanel
@onready var dialogue_text: Label = $DialogueUI/DialoguePanel/DialogueText
@onready var interaction_area: Area3D = $InteractionArea
@export var dialogue_message: String = "Hello World"


# Track if player is in range
var player_in_range: bool = false
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
		prompt_label.visible = true
		dialogue_panel.visible = false

func _on_body_exited(body):
	# Check if it's the player leaving
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = false
		prompt_label.visible = false
		dialogue_panel.visible = false

func _show_dialogue():
	# Don't start new dialogue if already typing
	if is_typing:
		return
	
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
	if player_in_range:
		dialogue_panel.visible = false
		prompt_label.visible = true
	else:
		dialogue_panel.visible = false
