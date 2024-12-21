extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var slideJumpExtraVelocity = 1 
var SJEVincrease = 0.2
var SJEVdecrease = 1
var SJEVdecreaseL = 0.5
var groundPoundJumpMultiplier = 1
var sensitivity = 0 # editable from outside
var restrictedMovement = Vector3(0,0,0)
const groundPoundSpeed = -30

var can_slide = true
var can_crouch = true
var can_gp = true
var can_move = true

var crouched = false
var sliding = false
var groundPounding = false

var direction = Vector3(0,0,0)
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

@export var crouchSpeed = 1

func groundPound():
	crouched = true
	if restrictedMovement != Vector3(0,groundPoundSpeed,0):
		restrictedMovement = Vector3(0,groundPoundSpeed,0)
	
	if is_on_floor():
		if Input.is_action_pressed("ctrl"):
			if not Input.is_action_pressed("ui_up") and not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right") and not Input.is_action_pressed("ui_down"):
				crouched = true
			else:
				sliding = true
		else:
			crouched = false
		
		restrictedMovement = Vector3(0,0,0)
		groundPounding = false

func crouch(delta): #transitioning between crouched and uncrouched
	delta *= crouchSpeed
	const camUp = 1.633
	const camDown = 0.633
	const targetUp = 1
	const targetDown = 0.5
	
	if (Input.is_action_just_released("ctrl") and not groundPounding) or not can_crouch or (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("ui_accept")):
		if Input.is_action_just_pressed("ui_accept") and velocity != Vector3(0,velocity.y,0):
			slideJumpExtraVelocity += SJEVincrease
		
		crouched = false
		sliding = false
	
	var playerhitbox = get_child(0)
	
	if crouched:
		playerhitbox.set_scale(playerhitbox.get_scale()-Vector3(delta,delta,delta))
		if playerhitbox.get_scale() < Vector3(targetDown,targetDown,targetDown):
			playerhitbox.set_scale(Vector3(targetDown,targetDown,targetDown))
		
		camera.position.y = (camera.position.y - delta*2)
		if camera.position.y < camDown:
			camera.position.y = camDown
	else:
		playerhitbox.set_scale(playerhitbox.get_scale()+Vector3(delta,delta,delta))
		if playerhitbox.get_scale() > Vector3(targetUp,targetUp,targetUp):
			playerhitbox.set_scale(Vector3(targetUp,targetUp,targetUp))
		
		camera.position.y = (camera.position.y + delta*2)
		if camera.position.y > camUp:
			camera.position.y = camUp
	
	get_child(0).position.y = get_child(0).get_scale().y

func _physics_process(delta): # "main"
	#Engine.max_fps = 30 # in case you think thats needed
	
	# decrease slideJumpExtraVelocity when needed
	if is_on_floor():
		if sliding:
			slideJumpExtraVelocity -= SJEVdecreaseL*delta
		else:
			slideJumpExtraVelocity -= SJEVdecrease*delta
		
		if slideJumpExtraVelocity < 1:
			slideJumpExtraVelocity = 1
	
	# check for crouch
	if Input.is_action_just_pressed("ctrl"):
		if is_on_floor():
			if can_crouch:
				crouched = true
			
			if velocity != Vector3(0,velocity.y,0) and can_slide:
				sliding = true
		else:
			if can_gp:
				groundPounding = true
	
	# trigger groundpound when needed
	if groundPounding:
		groundPound()
	
	# trigger crouch function
	crouch(delta)
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		# Move in the given direction
		velocity.x = direction.x * SPEED * slideJumpExtraVelocity
		velocity.z = direction.z * SPEED * slideJumpExtraVelocity
	else:
		# Stop instantly when no input is given
		velocity.x = 0
		velocity.z = 0
	
	if restrictedMovement != Vector3(0,0,0):
		velocity.x = 0
		velocity.z = 0
		velocity += restrictedMovement # need to keep gravity
	
	move_and_slide()

func _on_deathborder_body_shape_entered(body_rid, body, body_shape_index, local_shape_index): #reset position (respawn) when hitting a death barrier
	if body.position == position:
		position = Vector3(0,2,0)
