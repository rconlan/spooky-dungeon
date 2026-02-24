extends Node3D
class_name EscortableNPC

## NPC that can be escorted by the player

# References
@onready var prompt_label: Label3D = $PromptLabel
@onready var interaction_area: Area3D = $InteractionArea
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Configuration
@export var npc_name: String = "Prisoner"
@export var follow_distance: float = 2.5  # How far behind player to follow
@export var movement_speed: float = 3.5
@export var rotation_speed: float = 5.0
@export var escort_task_id: String = "escort_prisoner"
@export var final_position: Node3D = null  # Where to go when escort completes

# State
enum State { IDLE, FOLLOWING, MOVING_TO_FINAL }
var current_state: State = State.IDLE
var is_being_escorted: bool = false
var player: CharacterBody3D = null
var player_in_range: bool = false

func _ready():
	# Setup UI
	prompt_label.visible = false
	prompt_label.text = "E - Talk"
	
	# Connect interaction area
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Setup navigation agent
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	navigation_agent.avoidance_enabled = true
	
	# Wait for navigation to be ready
	call_deferred("_setup_navigation")

func _setup_navigation():
	await get_tree().physics_frame

func _process(_delta):
	# Check for interaction
	if player_in_range and Input.is_action_just_pressed("interact"):
		_interact()

func _physics_process(delta):
	if current_state == State.FOLLOWING and player:
		_follow_player(delta)
	elif current_state == State.MOVING_TO_FINAL and final_position:
		_move_to_final_position(delta)

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = true
		player = body
		if not is_being_escorted:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "ProtoController":
		player_in_range = false
		if not is_being_escorted:
			prompt_label.visible = false
			player = null

func _interact():
	if is_being_escorted:
		# Stop escorting
		stop_escort()
	else:
		# Check if escort task is active
		if TaskManager.active_tasks.has(escort_task_id) and not TaskManager.is_task_completed(escort_task_id):
			start_escort()
		else:
			# Not ready to be escorted yet
			print(npc_name + " is not ready to be escorted")

func start_escort():
	is_being_escorted = true
	current_state = State.FOLLOWING
	prompt_label.visible = false
	print(npc_name + " is now following you")

func stop_escort():
	is_being_escorted = false
	current_state = State.IDLE
	if player_in_range:
		prompt_label.visible = true
	print(npc_name + " stopped following")

func _follow_player(delta):
	if not player:
		return
	
	# Calculate position behind player
	var direction_to_player = global_position.direction_to(player.global_position)
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Always face the player while following
	direction_to_player.y = 0  # Keep rotation horizontal
	if direction_to_player.length() > 0:
		var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	# Only move if we're too far from the follow distance
	if distance_to_player > follow_distance + 0.5:
		# Set navigation target
		navigation_agent.target_position = player.global_position
		
		# Get next path position
		var next_position = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_position)
		direction.y = 0  # Keep movement horizontal
		
		if direction.length() > 0:
			# Move towards target
			var velocity = direction.normalized() * movement_speed * delta
			global_position += velocity
	elif distance_to_player < follow_distance - 0.5:
		# Too close, back away slightly
		var away_direction = -direction_to_player
		away_direction.y = 0
		var velocity = away_direction.normalized() * movement_speed * 0.5 * delta
		global_position += velocity

func get_is_escorted() -> bool:
	return is_being_escorted

func move_to_final_destination():
	"""Called by EscortZone when task completes"""
	is_being_escorted = false
	current_state = State.MOVING_TO_FINAL
	prompt_label.visible = false
	print(npc_name + " is moving to final position")
	
	if not final_position:
		print("WARNING: No final position set for " + npc_name)
		current_state = State.IDLE

func _move_to_final_position(delta):
	if not final_position:
		return
	
	var distance_to_target = global_position.distance_to(final_position.global_position)
	
	# If close enough to destination, stop
	if distance_to_target < 0.5:
		current_state = State.IDLE
		print(npc_name + " reached final position")
		return
	
	# Set navigation target
	navigation_agent.target_position = final_position.global_position
	
	# Get next path position
	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	direction.y = 0  # Keep movement horizontal
	
	if direction.length() > 0:
		# Move towards target
		var velocity = direction.normalized() * movement_speed * delta
		global_position += velocity
		
		# Rotate to face movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
