extends Camera3D

const leanSpeed = 1.5
const maxlean = 0.05

func lean(LOR,delta):# true => left
	var comingFrom = rotation.z < 0 # true => right
	delta *= leanSpeed
	
	if LOR == true or (LOR == null and comingFrom):
		rotation.z += delta
		
		if LOR == true and rotation.z > maxlean:
			rotation.z = maxlean
		elif LOR == null and rotation.z > 0:
			rotation.z = 0
	elif LOR == false or (LOR == null and not comingFrom):
		rotation.z -= delta
		
		if LOR == false and rotation.z < -maxlean:
			rotation.z = -maxlean
		elif LOR == null and rotation.z < 0:
			rotation.z = 0

func _process(delta):
	var player = get_parent()
	
	if not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		lean(null,delta)
	
	if Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		if player.wallrunning:
			lean(false,delta)
		else:
			lean(true,delta)
	
	if not Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"):
		if player.wallrunning:
			lean(true,delta)
		else:
			lean(false,delta)
