extends Node3D
class_name InteractableNPC

## Generic NPC that can display dialogue and give tasks

# References to UI elements
@onready var prompt_label: Label3D = $PromptLabel
@onready var dialogue_panel: ColorRect = $DialogueUI/DialoguePanel
@onready var dialogue_text: Label = $DialogueUI/DialoguePanel/DialogueText
@onready var interaction_area: Area3D = $InteractionArea

# Dialogue system
@export var dialogue_data: DialogueData
@export var zoom_fov: float = 50.0
@export var zoom_duration: float = 0.5
@export var rotation_duration: float = 0.3

# Track player interaction
var player_in_range: bool = false
var player: CharacterBody3D = null
var is_typing: bool = false
var original_rotation: float = 0.0
var current_line_index: int = 0
var has_given_tasks: bool = false
var given_task_ids: Array[String] = []
var has_given_second_tasks: bool = false

func _ready():
	# Hide UI initially
	prompt_label.visible = false
	dialogue_panel.visible = false
	
	# Connect signals
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Validate dialogue data
	if not dialogue_data:
		push_warning("No dialogue data assigned to " + name)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_start_dialogue()

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = true
		player = body
		prompt_label.visible = true
		dialogue_panel.visible = false

func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = false
		player = null
		prompt_label.visible = false
		dialogue_panel.visible = false

func _start_dialogue():
	if is_typing or not dialogue_data:
		return
	
	# Check if we should display task status instead of dialogue
	if has_given_tasks:
		_check_task_completion()
		return
	
	# Reset to first line
	current_line_index = 0
	
	# Store original rotation
	var start_rotation = rotation.y
	original_rotation = start_rotation
	
	# Rotate to face player
	var direction_to_player = player.global_position - global_position
	direction_to_player.y = 0
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
	
	# Lock player and zoom
	if player and player.has_method("start_dialogue"):
		player.start_dialogue(zoom_fov, zoom_duration)
	
	# Show first dialogue line
	_show_next_line()

func _show_next_line():
	if current_line_index >= dialogue_data.dialogue_lines.size():
		# All lines shown, give tasks and end
		_give_tasks()
		_end_dialogue()
		return
	
	# Hide prompt, show panel
	prompt_label.visible = false
	dialogue_panel.visible = true
	dialogue_text.text = ""
	
	# Type out current line
	is_typing = true
	var current_line = dialogue_data.dialogue_lines[current_line_index]
	var skipped = false
	
	for i in range(current_line.length()):
		# Check for skip input
		if Input.is_action_just_pressed("skip_dialogue"):
			dialogue_text.text = current_line  # Show full line immediately
			skipped = true
			break
		
		dialogue_text.text += current_line[i]
		await get_tree().create_timer(dialogue_data.typing_speed).timeout
	
	is_typing = false
	current_line_index += 1
	
	# Wait a bit before showing next line (or skip if R pressed)
	if not skipped:
		var wait_time = 0.0
		while wait_time < 2.0:
			if Input.is_action_just_pressed("skip_dialogue"):
				break
			await get_tree().create_timer(0.1).timeout
			wait_time += 0.1
	
	_show_next_line()

func _give_tasks():
	# Give all tasks specified in dialogue data
	for task_id in dialogue_data.tasks_to_give:
		# Task ID format: "task_id:Description of the task"
		var parts = task_id.split(":", false, 1)
		if parts.size() == 2:
			TaskManager.add_task(parts[0], parts[1])
			given_task_ids.append(parts[0])
	has_given_tasks = true

func _end_dialogue():
	# Unlock player and zoom out
	if player and player.has_method("end_dialogue"):
		await player.end_dialogue(zoom_duration)
	
	# Rotate back using lerp_angle
	var current_rot = rotation.y
	var return_tween = create_tween()
	return_tween.tween_method(
		func(t): rotation.y = lerp_angle(current_rot, original_rotation, t),
		0.0,
		1.0,
		rotation_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Show prompt if player still in range
	if player_in_range:
		dialogue_panel.visible = false
		prompt_label.visible = true
	else:
		dialogue_panel.visible = false

func _check_task_completion():
	# Store original rotation
	var start_rotation = rotation.y
	original_rotation = start_rotation
	
	# Rotate to face player
	var direction_to_player = player.global_position - global_position
	direction_to_player.y = 0
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
	
	# Lock player and zoom
	if player and player.has_method("start_dialogue"):
		player.start_dialogue(zoom_fov, zoom_duration)
	
	# Check if all tasks are completed
	var all_complete = true
	for task_id in given_task_ids:
		if not TaskManager.is_task_completed(task_id):
			all_complete = false
			break
	
	# Show appropriate message
	prompt_label.visible = false
	dialogue_panel.visible = true
	
	# Determine which messages to show
	var messages: Array[String] = []
	var should_open_gate = false
	if all_complete:
		# All tasks including escort are done
		if has_given_second_tasks:
			messages = ["Excellent. All tasks complete."]
		else:
			# Just the keys are done, give escort mission
			messages = ["Good...", "Prisoner 12 is being relocated", "Find him and bring him to block A."]
			TaskManager.remove_task("find_keys")
			TaskManager.add_task("escort_prisoner", "Escort Prisoner 12 to Containment Block A")
			given_task_ids.append("escort_prisoner")
			has_given_second_tasks = true
			should_open_gate = true
	else:
		# Check what's incomplete
		if has_given_second_tasks and not TaskManager.is_task_completed("escort_prisoner"):
			messages = ["Hurry up and escort Prisoner 12 to Block A."]
		else:
			messages = ["Find your keys Guard 287...."]
	
	# Show each message in the array
	for message in messages:
		dialogue_text.text = ""
		is_typing = true
		var skipped = false
		
		# Type out the message character by character
		for i in range(message.length()):
			# Check for skip input
			if Input.is_action_just_pressed("skip_dialogue"):
				dialogue_text.text = message  # Show full message immediately
				skipped = true
				break
			
			dialogue_text.text += message[i]
			await get_tree().create_timer(dialogue_data.typing_speed).timeout
		
		is_typing = false
		
		# Wait before showing next message (or skip if R pressed)
		if not skipped:
			var wait_time = 0.0
			while wait_time < 2.0:
				if Input.is_action_just_pressed("skip_dialogue"):
					break
				await get_tree().create_timer(0.1).timeout
				wait_time += 0.1
	
	# Unlock player and zoom out
	if player and player.has_method("end_dialogue"):
		await player.end_dialogue(zoom_duration)
	
	# Rotate back using lerp_angle
	var current_rot = rotation.y
	var return_tween = create_tween()
	return_tween.tween_method(
		func(t): rotation.y = lerp_angle(current_rot, original_rotation, t),
		0.0,
		1.0,
		rotation_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Open prison gate after dialogue finishes if keys were confirmed
	if should_open_gate:
		TaskManager.open_prison_gate.emit()
	
	# Show prompt if player still in range
	if player_in_range:
		dialogue_panel.visible = false
		prompt_label.visible = true
	else:
		dialogue_panel.visible = false
