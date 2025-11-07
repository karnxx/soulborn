extends CharacterBody2D

signal died

@export var health = 1000
var can_dmg = true
func get_dmged(dmg):
	if can_dmg:
		can_dmg = false
		health -= dmg
		var twen = create_tween()
		twen.tween_property(self, "modulate", Color.ORANGE_RED, 0.2)
		twen.tween_property(self, "modulate", Color.WHITE, 0.2)
		can_dmg = true
		if health <= 0:
			emit_signal("died")
			queue_free()
