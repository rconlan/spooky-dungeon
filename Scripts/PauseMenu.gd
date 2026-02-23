extends CanvasLayer

# Menu panels
@onready var main_menu: Panel = $MainMenu
@onready var settings_menu: Panel = $SettingsMenu

# Main menu buttons
@onready var resume_button: Button = $MainMenu/VBoxContainer/ResumeButton
@onready var settings_button: Button = $MainMenu/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MainMenu/VBoxContainer/QuitButton

# Settings menu elements
@onready var volume_slider: HSlider = $SettingsMenu/VBoxContainer/VolumeSlider
@onready var back_button: Button = $SettingsMenu/VBoxContainer/BackButton

var is_paused: bool = false

func _ready():
	# Hide menu initially
	visible = false
	
	# Connect main menu buttons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect settings menu elements
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Load saved volume
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0)) * 100

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		if is_paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	is_paused = true
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Show mouse cursor
	show_main_menu()

func resume_game():
	is_paused = false
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Hide mouse cursor

func show_main_menu():
	main_menu.visible = true
	settings_menu.visible = false

func show_settings_menu():
	main_menu.visible = false
	settings_menu.visible = true

# Main menu button callbacks
func _on_resume_pressed():
	resume_game()

func _on_settings_pressed():
	show_settings_menu()

func _on_quit_pressed():
	get_tree().quit()

# Settings menu callbacks
func _on_volume_changed(value: float):
	# Convert 0-100 slider to decibels
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, volume_db)

func _on_back_pressed():
	show_main_menu()
