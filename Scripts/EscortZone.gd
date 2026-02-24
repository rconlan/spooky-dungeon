extends Area3D
class_name EscortZone

## Area that completes the escort task when prisoner enters while being escorted

@export var zone_name: String = "Containment Block A"
@export var task_id: String = "escort_prisoner"

var prisoner_inside: bool = false
var player_inside: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area):
	# Check if it's the prisoner's detection area
	if area.get_parent() and area.get_parent().name == "Prisoner":
		prisoner_inside = true
		print("Prisoner entered escort zone!")
		_check_completion(area.get_parent())

func _on_area_exited(area):
	if area.get_parent() and area.get_parent().name == "Prisoner":
		prisoner_inside = false
		print("Prisoner left escort zone!")

func _on_body_entered(body):
	if body.name == "Prisoner":
		prisoner_inside = true
		_check_completion(body)
	elif body.is_in_group("Player") or body.name == "ProtoController":
		player_inside = true

func _on_body_exited(body):
	if body.name == "Prisoner":
		prisoner_inside = false
	elif body.is_in_group("Player") or body.name == "ProtoController":
		player_inside = false

func _check_completion(prisoner):
	print("Checking completion - prisoner: ", prisoner.name)
	# Check if the prisoner is being escorted
	if prisoner.has_method("get_is_escorted"):
		var is_escorted = prisoner.get_is_escorted()
		print("Prisoner is_escorted: ", is_escorted)
		if is_escorted:
			if not TaskManager.is_task_completed(task_id):
				TaskManager.complete_task(task_id)
				print("SUCCESS! Prisoner delivered to " + zone_name + "!")
				# Tell prisoner to move to final position
				if prisoner.has_method("move_to_final_destination"):
					prisoner.move_to_final_destination()
			else:
				print("Task already completed")
		else:
			print("Prisoner is not being escorted yet - interact with them first!")
	else:
		print("ERROR: Prisoner doesn't have get_is_escorted method")
