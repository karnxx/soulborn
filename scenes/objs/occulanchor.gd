extends Node2D
@export_enum("1", "2") var type

func _ready() -> void:
	await $AnimatedSprite2D.animation_finished
	if type == "1":
		$AnimatedSprite2D.play("anchor1")
	elif type == "2":
		$AnimatedSprite2D.play("anchor2")
