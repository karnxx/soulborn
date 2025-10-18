class_name BaseClass
extends Node2D

var player: CharacterBody2D = null
var mouse_target: Vector2 = Vector2.ZERO

func _ready():
	pass

func set_player(p: CharacterBody2D):
	player = p

func set_mouse_target(pos: Vector2):
	mouse_target = pos

func attack():
	pass

func secondary_attack():
	pass

func special():
	pass

func dash():
	pass
