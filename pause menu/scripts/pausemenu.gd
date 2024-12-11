extends Control

# Tracks the pause state
var is_paused: bool = false

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):  # "ui_cancel" is bound to Escape by default
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	if is_paused:
		# Pause the game
		get_tree().paused = true
		self.visible = true
		# Show and release the mouse
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Unpause the game
		get_tree().paused = false
		self.visible = false
		# Lock the mouse back to the center
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
