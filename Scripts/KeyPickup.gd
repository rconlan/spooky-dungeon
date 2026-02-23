extends Node3D

## Collectible key that can be picked up by the player

@onready var prompt_label: Label3D = $PromptLabel
@onready var interaction_area: Area3D = $InteractionArea
@onready var model: Node3D = $KeyModel

# Track if player is in range
var player_in_range: bool = false
var player: CharacterBody3D = null
var is_collected: bool = false

func _ready():
	# Hide prompt initially
	prompt_label.visible = false
	
	# Connect signals
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Add rotation animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(model, "rotation:y", TAU, 3.0)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not is_collected:
		_collect_key()

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = true
		player = body
		if not is_collected:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = false
		player = null
		prompt_label.visible = false

func _collect_key():
	is_collected = true
	prompt_label.visible = false
	
	# Notify TaskManager about key collection
	if TaskManager.has_method("increment_key_count"):
		TaskManager.increment_key_count()
	
	# Play pickup animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + 1.0, 0.5)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	await tween.finished
	
	queue_free()
