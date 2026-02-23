# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false
## Can we toggle the spotlight?
@export var can_toggle_light : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to toggle spotlight.
@export var input_toggle_light : String = "toggle_light"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var in_dialogue : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collider: CollisionShape3D = $Collider
@onready var spotlight: SpotLight3D = $Head/Camera3D/SpotLight3D

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Block all input during dialogue
	if in_dialogue:
		return
	
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()
	
	# Toggle spotlight
	if can_toggle_light and Input.is_action_just_pressed(input_toggle_light):
		toggle_spotlight()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func toggle_spotlight():
	if spotlight:
		spotlight.visible = not spotlight.visible


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
	if can_toggle_light and not InputMap.has_action(input_toggle_light):
		push_error("Light toggle disabled. No InputAction found for input_toggle_light: " + input_toggle_light)
		can_toggle_light = false


## Dialogue interaction methods
func start_dialogue(zoom_fov: float = 50.0, zoom_duration: float = 0.5, target_position: Vector3 = Vector3.ZERO, look_at_target: Vector3 = Vector3.ZERO):
	"""Lock movement and zoom camera for dialogue"""
	in_dialogue = true
	can_move = false
	
	# Move to interaction position and look at target
	if target_position != Vector3.ZERO and look_at_target != Vector3.ZERO:
		# Calculate direction to face the target
		var horizontal_direction = Vector3(look_at_target.x - target_position.x, 0, look_at_target.z - target_position.z).normalized()
		var target_rotation_y = atan2(horizontal_direction.x, horizontal_direction.z)
		
		# Calculate head tilt to look at target
		var head_look_pos = target_position + Vector3(0, 1.7, 0)  # Eye height
		var head_direction = (look_at_target - head_look_pos).normalized()
		var target_head_rotation_x = -asin(head_direction.y)
		
		# Debug output
		print("Player moving to: ", target_position)
		print("Looking at: ", look_at_target)
		print("Horizontal direction: ", horizontal_direction)
		print("Target rotation Y (radians): ", target_rotation_y)
		print("Target rotation Y (degrees): ", rad_to_deg(target_rotation_y))
		print("Current rotation Y (degrees): ", rad_to_deg(rotation.y))
		print("Current look_rotation.y (degrees): ", rad_to_deg(look_rotation.y))
		
		# Create smooth movement tween
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "global_position", target_position, zoom_duration)
		# Tween the look_rotation variables instead of direct rotation
		tween.tween_property(self, "look_rotation:y", target_rotation_y, zoom_duration)
		tween.tween_property(self, "look_rotation:x", target_head_rotation_x, zoom_duration)
		
		await tween.finished
		
		# Apply rotations manually after tween
		transform.basis = Basis()
		rotate_y(look_rotation.y)
		head.transform.basis = Basis()
		head.rotate_x(look_rotation.x)
		
		# Debug: Check final rotation
		print("AFTER TWEEN - look_rotation.y (degrees): ", rad_to_deg(look_rotation.y))
		print("AFTER TWEEN - look_rotation.x (degrees): ", rad_to_deg(look_rotation.x))
		print("AFTER TWEEN - Rotation Y (degrees): ", rad_to_deg(rotation.y))
		print("AFTER TWEEN - Head rotation X (degrees): ", rad_to_deg(head.rotation.x))
	
	# Zoom camera
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "fov", zoom_fov, zoom_duration)


func end_dialogue(zoom_duration: float = 0.5):
	"""Unlock movement and restore camera zoom"""
	print("END_DIALOGUE called - Current rotation Y: ", rad_to_deg(rotation.y))
	print("END_DIALOGUE - look_rotation.y: ", rad_to_deg(look_rotation.y))
	
	# Zoom out first, THEN re-enable input
	if camera:
		var original_fov = 75.0  # Default FOV
		var tween = create_tween()
		tween.tween_property(camera, "fov", original_fov, zoom_duration)
		await tween.finished
		print("After zoom out - Rotation Y: ", rad_to_deg(rotation.y))
		print("After zoom out - look_rotation.y: ", rad_to_deg(look_rotation.y))
	
	# Re-enable input AFTER zoom completes
	in_dialogue = false
	can_move = true
	print("Input re-enabled - Final rotation Y: ", rad_to_deg(rotation.y))
	return true  # Signal completion
