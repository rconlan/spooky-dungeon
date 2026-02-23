extends Resource
class_name TaskData

## A resource that stores task/quest information

@export var task_id: String = ""
@export var task_description: String = ""
@export var is_completed: bool = false
@export var auto_complete: bool = false  # If true, completes automatically when condition is met
