extends Node

## Singleton that manages all player tasks/quests

signal task_added(task_id: String)
signal task_completed(task_id: String)
signal task_removed(task_id: String)
signal key_collected(count: int)
signal open_prison_gate  # Emitted when guard confirms keys are collected

var active_tasks: Dictionary = {}  # task_id -> TaskData
var keys_collected: int = 0
var keys_required: int = 3
var debug_key_pressed: bool = false  # Debounce for debug key

func add_task(task_id: String, description: String) -> void:
	if active_tasks.has(task_id):
		push_warning("Task already exists: " + task_id)
		return
	
	var task = TaskData.new()
	task.task_id = task_id
	task.task_description = description
	task.is_completed = false
	
	active_tasks[task_id] = task
	task_added.emit(task_id)
	print("Task added: ", task_id, " - ", description)

func complete_task(task_id: String) -> void:
	if not active_tasks.has(task_id):
		push_warning("Task not found: " + task_id)
		return
	
	if not active_tasks[task_id].is_completed:
		active_tasks[task_id].is_completed = true
		task_completed.emit(task_id)
		print("Task completed: ", task_id)

func remove_task(task_id: String) -> void:
	if active_tasks.has(task_id):
		active_tasks.erase(task_id)
		task_removed.emit(task_id)
		print("Task removed: ", task_id)
	else:
		push_warning("Task not found: " + task_id)

func is_task_completed(task_id: String) -> bool:
	if active_tasks.has(task_id):
		return active_tasks[task_id].is_completed
	return false

func get_task(task_id: String) -> TaskData:
	return active_tasks.get(task_id, null)

func get_all_tasks() -> Array:
	return active_tasks.values()

func get_active_tasks() -> Array:
	var tasks = []
	for task in active_tasks.values():
		if not task.is_completed:
			tasks.append(task)
	return tasks

func increment_key_count() -> void:
	keys_collected += 1
	key_collected.emit(keys_collected)
	print("Keys collected: ", keys_collected, "/", keys_required)
	
	# Check if the find_keys task should be completed
	if keys_collected >= keys_required:
		complete_task("find_keys")

func get_key_count() -> int:
	return keys_collected

func get_keys_required() -> int:
	return keys_required

func _process(_delta):
	# Debug: Press T to skip to escort scenario
	if Input.is_physical_key_pressed(KEY_T):
		if not debug_key_pressed:
			debug_key_pressed = true
			skip_to_escort_scenario()
	else:
		debug_key_pressed = false

## Debug function: Skip key collection and jump to escort scenario
func skip_to_escort_scenario() -> void:
	# Set keys to required amount
	keys_collected = keys_required
	
	# Complete find_keys task if it exists
	if active_tasks.has("find_keys"):
		complete_task("find_keys")
	else:
		# Add it first if it doesn't exist
		add_task("find_keys", "Find your 3 keys")
		complete_task("find_keys")
	
	# Add escort task if not already added
	if not active_tasks.has("escort_prisoner"):
		add_task("escort_prisoner", "Escort Prisoner 12 to Containment Block A")
	
	# Open the prison gate
	open_prison_gate.emit()
	
	print("DEBUG: Skipped to escort scenario - Press E to interact with prisoner")
