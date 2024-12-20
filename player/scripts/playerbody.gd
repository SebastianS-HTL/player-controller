extends CharacterBody3D

const gravity = Vector3(0,-9.8,0)
var currentGravity = Vector3(0,-9.8,0)
const gravityWallrunnning = Vector3(0,-0.4,0)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var maxJumps = 2
var jumps = 0

var slideJumpExtraVelocity = 1 
var SJEVincrease = 0.2
var SJEVdecrease = 1
var SJEVdecreaseL = 0.5

var groundPoundJumpMultiplier = 1
var GPJMincrease = 0.2
var GPJMresetTime = 0.2
var GPJMtimer = 0

var sensitivity = 0 # editable from outside
var restrictedMovement = Vector3(0,0,0)
const groundPoundSpeed = -30

var can_slide = true
var can_crouch = true
var can_gp = true
var can_move = true
var can_wallrun = true

var crouched = false
var sliding = false
var groundPounding = false
var wallrunning = false

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

var crouchSpeed = 8

func groundPound():
	crouched = true
	if restrictedMovement != Vector3(0,groundPoundSpeed,0):
		restrictedMovement = Vector3(0,groundPoundSpeed,0)
	
	if is_on_floor():
		groundPoundJumpMultiplier += GPJMincrease
		GPJMtimer = 0
		
		if direction != Vector3(0,direction.y,0): #makes it so we cant do GPJM-increasion when we move 
			groundPoundJumpMultiplier = 1
		else: #if we dont move, take something off speed, it isn´t depleting when doing this
			if slideJumpExtraVelocity > 1:
				slideJumpExtraVelocity /= 2
			else:
				slideJumpExtraVelocity = 1
		
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
		if Input.is_action_just_pressed("ui_accept") and direction != Vector3(0,direction.y,0):
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
	
	#try to do a wallrun
	if is_on_wall() and not is_on_floor() and can_wallrun:
		wallrunning = true
		currentGravity = gravityWallrunnning
		velocity.y = gravityWallrunnning.y
	else:
		wallrunning = false
		currentGravity = gravity
	
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
		velocity += currentGravity * delta
	else: # abuse to reset jumps when on ground, also reset the higher jump after groundpound
		jumps = maxJumps
		
		if GPJMtimer >= GPJMresetTime:
			groundPoundJumpMultiplier = 1
			GPJMtimer = GPJMresetTime
		else:
			GPJMtimer += delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and jumps > 0:
		jumps -= 1
		velocity.y = JUMP_VELOCITY * groundPoundJumpMultiplier

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
