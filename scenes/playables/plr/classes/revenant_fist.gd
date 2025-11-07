extends Node2D
var dir

func _physics_process(delta: float) -> void:
	global_position +=  dir*delta*300
	if dir == Vector2.LEFT:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		body.get_dmged(randi_range(120, 150))

func _on_timer_timeout() -> void:
	self.queue_free()
