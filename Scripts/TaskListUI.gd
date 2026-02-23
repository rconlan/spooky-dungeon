extends Control

## UI that displays the player's active tasks

@onready var task_list_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer
@onready var panel: PanelContainer = $Panel

# Store task item nodes by task_id
var task_items: Dictionary = {}

func _ready():
	# Connect to TaskManager signals
	TaskManager.task_added.connect(_on_task_added)
	TaskManager.task_completed.connect(_on_task_completed)
	TaskManager.task_removed.connect(_on_task_removed)
	TaskManager.key_collected.connect(_on_key_collected)
	
	# Load any existing tasks
	_refresh_task_list()
	_update_visibility()

func _update_visibility():
	# Hide panel if no tasks
	panel.visible = TaskManager.get_all_tasks().size() > 0

func _refresh_task_list():
	# Clear existing items
	for child in task_list_container.get_children():
		child.queue_free()
	task_items.clear()
	
	# Add all active tasks
	for task in TaskManager.get_all_tasks():
		_create_task_item(task)

func _create_task_item(task: TaskData) -> void:
	var task_item = HBoxContainer.new()
	task_item.name = "Task_" + task.task_id
	task_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Checkbox
	var checkbox = CheckBox.new()
	checkbox.button_pressed = task.is_completed
	checkbox.disabled = true  # Don't allow manual checking
	checkbox.custom_minimum_size = Vector2(20, 20)
	checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Task description
	var label = Label.new()
	label.text = _get_task_display_text(task)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Strike through if completed
	if task.is_completed:
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	task_item.add_child(checkbox)
	task_item.add_child(label)
	task_list_container.add_child(task_item)
	
	# Store reference
	task_items[task.task_id] = {"container": task_item, "checkbox": checkbox, "label": label}

func _on_task_added(task_id: String):
	var task = TaskManager.get_task(task_id)
	if task:
		_create_task_item(task)
		_update_visibility()

func _on_task_completed(task_id: String):
	if task_items.has(task_id):
		var item = task_items[task_id]
		item.checkbox.button_pressed = true
		item.label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

func _on_task_removed(task_id: String):
	if task_items.has(task_id):
		var item = task_items[task_id]
		item.container.queue_free()
		task_items.erase(task_id)
		_update_visibility()

func _on_key_collected(_count: int):
	# Update the find_keys task label to show progress
	if task_items.has("find_keys"):
		var task = TaskManager.get_task("find_keys")
		if task:
			task_items["find_keys"].label.text = _get_task_display_text(task)

func _get_task_display_text(task: TaskData) -> String:
	# Special handling for find_keys task to show progress
	if task.task_id == "find_keys":
		var collected = TaskManager.get_key_count()
		var required = TaskManager.get_keys_required()
		return task.task_description + " (" + str(collected) + "/" + str(required) + ")"
	return task.task_description
