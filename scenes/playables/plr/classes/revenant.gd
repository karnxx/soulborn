extends Node2D

@export var primary_cooldown := 0.25
@export var secondary_cooldown := 1.0
@export var dash_cooldown := 1.0
@export var max_health := 200

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D
var can_primary := true
var can_secondary := true
var can_dash := true
var busy := false
var mouse_position := Vector2.ZERO
var wason_floor = false

func _ready() -> void:
	player = get_parent()
	animani("idle")

func _physics_process(_delta: float) -> void:
	if busy:
		return
	var on_floor = player.is_on_floor()
	if on_floor and not wason_floor:
		animani("land")
		print('asdk ')
	wason_floor = on_floor
	upd_Face()
	upd_anim()

func upd_Face():
	if not player:
		return
	sprite.flip_h = player.facing == "left"

func upd_anim():
	if not player or busy:
		return
	if player.is_on_floor():
		if abs(player.velocity.x) > 15:
			animani("walk")
		else:
			animani("idle")
	else:
		animani("air")

func upd_mouse(target):
	mouse_position = target

func on_jump():
	animani("jump")

func animani(name):
	if sprite.animation != name:
		sprite.play(name)

func attack():
	if not can_primary or busy:
		return
	can_primary = false
	busy = true
	animani("primary")
	await sprite.animation_finished
	busy = false
	await get_tree().create_timer(primary_cooldown).timeout
	can_primary = true

func secondary():
	if not can_secondary or busy:
		return
	can_secondary = false
	busy = true
	animani("secondary")
	await sprite.animation_finished
	busy = false
	await get_tree().create_timer(secondary_cooldown).timeout
	can_secondary = true

func dash():
	if not can_dash or busy:
		return
	can_dash = false
	busy = true
	animani("dash")
	await sprite.animation_finished
	busy = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
