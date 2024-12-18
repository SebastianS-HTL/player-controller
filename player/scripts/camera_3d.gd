extends Camera3D

const leanSpeed = 4
const maxlean = 5

func lean(goal,delta):
	if rotation.z != goal:
		return
	
	if goal - rotation.z < 0:
		delta *= -1
	
	rotation.z += delta
	
	if rotation.z > 5:
		rotation.z = 5
	
	if rotation.z < -5:
		rotation.z = -5
	
	if abs(goal - rotation.z) < 0.5:
		rotation.z = goal

func _process(delta):
	if not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		print("no")
		lean(0,delta)
	
	if Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		print("l")
		lean(5,delta)
	
	if not Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"):
		print("r")
		lean(-5,delta)
