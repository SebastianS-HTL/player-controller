extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var sensitivity = 0 #editable from outside

@onready var camera = $Camera3D
var mouse_delta = Vector2.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func _process(delta):
	handle_mouse_look()

func handle_mouse_look():
	# Apply mouse movement to camera and body
	var rotation_x = -mouse_delta.y * sensitivity
	var rotation_y = -mouse_delta.x * sensitivity

	# Clamp vertical rotation to prevent flipping
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x + rotation_x, -90, 90)
	
	# Rotate the character body horizontally
	rotation_degrees.y += rotation_y

	# Reset mouse_delta to avoid repeating the motion
	mouse_delta = Vector2.ZERO

func _physics_process(delta): # "main"
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		# Move in the given direction
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Stop instantly when no input is given
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _on_deathborder_body_shape_entered(body_rid, body, body_shape_index, local_shape_index): #reset position (respawn) when hitting a death barrier
	if body.position == position:
		position = Vector3(0,0,0)
