extends Resource
class_name DialogueData

## A resource that stores dialogue information for NPCs

@export var character_name: String = "Unknown"
@export_multiline var dialogue_lines: Array[String] = []
@export var tasks_to_give: Array[String] = []  # Task IDs to give when dialogue completes
@export var typing_speed: float = 0.05
