extends Label
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = "fps: " + str(1/delta)
