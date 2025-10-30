extends Node2D

@export var attack_cooldown := 0.25
@export var secondary_cooldown := 1.0
@export var dash_cooldown := 0.6
@export var dash_speed := 500
@export var dash_duration := 0.05
var hit_enemies := []
var can_attack := true
var can_dash := true
var can_secondary := true
var is_dashing := false
var mouse_target := Vector2.ZERO
var max_health := 200
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D

func _ready() -> void:
	$dash_enemy.monitoring = false
	await get_tree().create_timer(0.1).timeout
	player = get_tree().current_scene.get_node('plr')
	

func _physics_process(_delta):
	upd_face()
	upd_run()

func upd_face():
	if not player:
		return
	sprite.flip_h = player.facing == "left"

func upd_run():
	if not player or is_dashing or not can_attack:
		return
	if player.is_on_floor():
		if abs(player.velocity.x) > 15:
			if sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")
	elif sprite.animation != "jump":
		sprite.play("jump")

func upd_mouse(target: Vector2):
	mouse_target = target

func on_jump():
	if sprite.animation != "jump":
		sprite.play("jump")


func attack():
	if not can_attack or is_dashing:
		return
	can_attack = false
	player.is_attacking = true
	hit_enemies.clear()

	var hitbox
	if Input.is_action_pressed("ui_up"):
		sprite.play("attack_up")
		hitbox = $attack/up
	elif Input.is_action_pressed("ui_down") and not player.is_on_floor():
		sprite.play("attack_down")
		hitbox = $attack/down
	else:
		sprite.play("attack_side")
		hitbox = $attack/left if player.facing == "left" else $attack/right

	hitbox.monitoring = true
	sprite.flip_h = (player.facing == "left")
	await sprite.animation_finished
	hitbox.monitoring = false
	player.is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func secondary_attack():
	if not can_secondary or is_dashing:
		return

	can_secondary = false
	is_dashing = true
	player.is_dashing = true
	player.set_collision_layer_value(8, false)
	player.set_collision_layer_value(8, false)
	print(player.collision_layer,"and", player.collision_mask)
	sprite.play("dash")
	$dash_enemy.monitoring = true
	var dir := (mouse_target - player.global_position).normalized()
	sprite.flip_h = dir.x < 0
	var traveled := 0.0
	var max_distance := 250
	player.velocity = Vector2.ZERO
	while traveled < max_distance:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		player.velocity = dir * dash_speed
		player.move_and_slide()
		traveled += dash_speed * delta
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	$dash_enemy.monitoring = false
	player.set_collision_layer_value(8, true)
	player.set_collision_layer_value(8, true)
	is_dashing = false
	player.is_dashing = false

	var momentum_gain = clamp(traveled / 150.0, 0.5, 3.5)
	player.momentum += momentum_gain

	await get_tree().create_timer(secondary_cooldown).timeout
	can_secondary = true


func dash():
	if not can_dash or is_dashing:
		return
	can_dash = false
	is_dashing = true
	player.is_dashing = true
	var dir = Vector2.RIGHT if player.facing == "right" else Vector2.LEFT
	sprite.play("dash")
	player.velocity = dir * dash_speed
	var traveled := 0.0
	var max_distance := dash_speed * dash_duration
	while traveled < max_distance:
		await get_tree().process_frame
		var delta := get_physics_process_delta_time()
		traveled += (player.velocity * delta).length()
	await sprite.animation_finished
	player.velocity = Vector2.ZERO
	is_dashing = false
	player.is_dashing = false
	if Input.is_anything_pressed() == false:
		sprite.play("dash_stop")
		await sprite.animation_finished
	var momentum_gain = clamp(traveled / 200.0, 0.5, 2.5)
	player.momentum += momentum_gain
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func special():
	sprite.play("attack_side")

func _on_dash_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		body.get_dmged(50)

func _on_atk_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and not body in hit_enemies:
		hit_enemies.append(body)
		var dmg = 20 + player.momentum * 10
		print(dmg)
		body.get_dmged(dmg)
		player.rebound_from_attack(body.global_position)
		
