extends Node3D

## Prison gate that opens when all keys are collected and guard confirms

@export var open_height: float = 5.0  # How far up the gate moves
@export var open_duration: float = 4.0  # How long it takes to open (slow)
@export var task_id: String = "find_keys"  # The task that triggers opening

var is_open: bool = false
var start_position: Vector3

func _ready():
	# Store the starting position
	start_position = position
	
	# Connect to TaskManager signal for gate opening
	if TaskManager:
		TaskManager.open_prison_gate.connect(_open_gate)

func _open_gate():
	if is_open:
		return
		
	is_open = true
	
	# Animate the gate sliding upward slowly
	var target_position = start_position + Vector3(0, open_height, 0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, open_duration)
	
	print("Prison gate opening...")
