extends Node2D

@export var primary_cooldown := 0.25
@export var secondary_cooldown := 1.0
@export var dash_cooldown := 1.0
@export var max_health := 150

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D
var can_primary := true
var can_secondary := true
var can_dash := true
var busy := false
var mouse_position := Vector2.ZERO
var wason_floor := false
var hitbox
var is_diving = false
func _ready() -> void:
	player = get_parent()
	animani("idle")


func _physics_process(_delta):
	var on_floor = player.is_on_floor()
	if on_floor and not wason_floor:
		land()
	wason_floor = on_floor
	upd_Face()
	upd_anim()

func land():
	busy = true
	if is_diving:
		player.velocity = Vector2.ZERO
		animani("dive_land")
		is_diving = false
		await sprite.animation_finished
		can_primary = true
		$predive.monitoring = false
		$dived.monitoring = true
		get_tree().create_timer(0.2).timeout
		$dived.monitoring = false
	else:
		player.velocity = Vector2.ZERO
		animani("land")
		await sprite.animation_finished
	busy = false

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

var t = 0
func attack():
	if not can_primary or busy:
		return
	can_primary = false
	busy = true

	if Input.is_action_pressed("ui_down") and not player.is_on_floor() and not is_diving:
		is_diving = true
		player.velocity = Vector2.ZERO
		animani("dive")
		player.can_grav = false
		await sprite.animation_finished
		player.can_grav = true
		wason_floor = false
		player.velocity.y += 1200
		$predive.monitoring = true
		player.cur_health -= 20
	else:
		var skibidi = randi_range(t, 3)
		hitbox = $left if player.facing == "left" else $right
		if skibidi != t:
			animani("primary2")
			$AnimationPlayer.play("primary")
			t += 1
		else:
			animani("primary")
			$AnimationPlayer.play("primary2")
			t = 0
		await sprite.animation_finished
		busy = false
		await get_tree().create_timer(primary_cooldown).timeout
		can_primary = true

func acutally_atk():
	hitbox.monitoring = true
	await get_tree().create_timer(0.1).timeout
	hitbox.monitoring = false

func secondary_attack():
	if not can_secondary or busy or !player.is_on_floor():
		return
	can_secondary = false
	busy = true
	player.velocity.x = 0
	animani("secondary")
	$AnimationPlayer.play("secondary")
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

func fist_spawn():
	var fist = preload("res://scenes/playables/plr/classes/revenant_fist.tscn").instantiate()
	get_parent().get_parent().add_child(fist)
	fist.global_position = player.global_position + (Vector2(-50,0) if player.facing == 'left' else Vector2(50,0))
	fist.dir = Vector2.LEFT if player.facing == 'left' else Vector2.RIGHT

func dmg_madi(amt):
	player.cur_health -= amt

func _on_left_body_entered(body: Node2D) -> void:
	var dmg = randi_range(40,80)
	if body.is_in_group("enemy"):
		body.get_dmged(dmg)

func _on_dived_body_entered(body: Node2D) -> void:
	var dmg = randi_range(80,120)
	if body.is_in_group("enemy"):
		body.get_dmged(dmg)
