extends Area2D

var path_follow: PathFollow2D

func setup(new_path_follow: PathFollow2D):
	path_follow = new_path_follow
	
func _process(delta: float) -> void:
	path_follow.progress += 200 * delta
	if path_follow.progress_ratio > 0.99:
		print("damage")
		queue_free()
		
