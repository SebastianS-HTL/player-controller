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

func get_wall_vectors(ray_count: int = 16, max_distance: float = 5.0) -> Array:
	"""
	Casts rays in a circular pattern around the player and returns an array of vectors.
	
	Each vector represents the direction and length of the ray until it hits a wall or
	reaches the maximum allowed distance.
	
	Args:
		ray_count (int): The number of rays to cast (default: 16).
		max_distance (float): The maximum distance for each ray (default: 5.0).
	
	Returns:
		Array: An array of vectors representing the hit positions or maximum ray lengths.
	"""
	var space_state = get_world_3d().direct_space_state
	var ray_vectors = []
	var origin = global_transform.origin  # Player's position in the world
	
	for i in range(ray_count):
		var angle = i * (TAU / ray_count)  # TAU = 2 * PI
		var direction = Vector3(cos(angle), 0, sin(angle)).normalized()
		var ray_target = origin + direction * max_distance
		
		# Cast the ray
		var result = space_state.intersect_ray(ray_target)
		
		if result:
			# Add the vector to the hit point
			ray_vectors.append(result.position - origin)
		else:
			# Add the vector to the max ray length
			ray_vectors.append(direction * max_distance)
	
	return ray_vectors

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
