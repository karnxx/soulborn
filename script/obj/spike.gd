extends StaticBody2D

var dmg = 20
var health = 100000

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('plr'):
		body.get_dmged(dmg, self.global_position)

func get_dmged(dmge):
	health -= dmge
	if health <= 0:
		dmg = 1000
