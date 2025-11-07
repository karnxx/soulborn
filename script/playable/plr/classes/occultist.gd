extends Node2D

@export var attack_cooldown := 0.25
@export var secondary_cooldown := 1.0
@export var max_health := 160
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D
var anchors := []
var can_atk := true
var can_secondary := true
var is_blinking := false
var moussy := Vector2.ZERO
var anc1 = Marker2D.new()
var anc2 = Marker2D.new()
var current_anc
var can_blink = true
var is_placing = false
var lastanchor
var hitbox
func _ready() -> void:
	player = get_parent()
	for anchor in anchors:
		anchor.visible = false

func _physics_process(_delta):
	if is_blinking:
		return
	upd_face()
	upd_run()

func upd_face():
	if not player:
		return
	sprite.flip_h = player.facing == "left"

func upd_run():
	if not player or is_blinking or not can_atk:
		return
	if player.is_on_floor():
		if abs(player.velocity.x) > 15:
			if sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.animation != "idle" and not is_placing:
				sprite.play("idle")

func upd_mouse(target: Vector2):
	moussy = target

func attack():
	if not can_atk or is_blinking:
		return
	can_atk = false
	player.is_attacking = true
	var attack_facing
	var aniama
	var andamain
	if !player.is_on_floor() or Input.is_action_pressed("ui_accept"):
		hitbox = $leftandright/right if attack_facing == "right" else $leftandright/left
		aniama = "aitatk"
		andamain = "prim2"
		attack_facing = player.facing
	else:
		hitbox = $aoeprim
		aniama = "secondary"
		andamain = "primary"
		attack_facing = player.facing
	sprite.play(aniama)
	sprite.flip_h = (attack_facing == "left")
	$AnimationPlayer.play(andamain)

	if aniama == "aitatk":
		var fake_enemy_pos = global_position + (Vector2.LEFT if attack_facing == "right" else Vector2.RIGHT)
		player.rebound_from_attack(fake_enemy_pos)


	await sprite.animation_finished
	player.is_attacking = false
	hitbox.monitoring = false
	player.is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_atk = true
	

func secondary_attack():
	if not can_secondary or is_blinking:
		return
	can_secondary = false
	place_anchor(player.global_position)
	player.velocity = Vector2.ZERO
	await get_tree().create_timer(secondary_cooldown).timeout
	can_secondary = true

func place_anchor(position: Vector2):
	var rayray = $left if player.facing == "left" else $right
	var pospos = position + (Vector2(24, 2) if player.facing == "right" else Vector2(-24, -1))
	if rayray.is_colliding():
		pospos = rayray.get_collision_point()
	is_placing = true
	$AnimatedSprite2D.play("anchor_place")
	await $AnimatedSprite2D.animation_finished
	is_placing = false
	var next_type = "1"
	if anchors.size() > 0:
		if anchors.back() != null and anchors.back().type == "1":
			next_type = "2"
	if anchors.size() >= 2:
			anchors.pop_front().queue_free()
	
	var anchr = preload("res://scenes/objs/occulanchor.tscn").instantiate()
	get_parent().get_parent().add_child(anchr)
	anchr.global_position = pospos
	anchr.type = next_type
	anchors.append(anchr)

func dash():
	if not anchors[0].visible and not anchors[1].visible:
		return
	if not can_atk or not can_blink:
		return
	var a = anchors
	var start = a[0] if player.global_position.distance_to(a[0].global_position) < player.global_position.distance_to(a[1].global_position) else a[1]
	var end = a[1] if start == a[0] else a[0]

	
	player.velocity = Vector2.ZERO
	is_blinking = true
	can_blink = false
	$blink.monitoring = true
	$AnimatedSprite2D.play("dash")
	await $AnimatedSprite2D.animation_finished
	player.global_position = start.global_position + Vector2(0, -10)
	player.set_collision_layer_value(8, false)
	player.set_collision_mask_value(8, false)
	var dir = (end.global_position - start.global_position).normalized()
	var dist = player.global_position.distance_to(end.global_position)
	var speed = 1500.0
	var moved = 0.0
	while moved < dist:
		await get_tree().process_frame
		var delta = get_process_delta_time()
		moved += speed * delta
		player.global_position = start.global_position + dir * min(moved, dist) + Vector2(0, -10)
		if not $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.play("orb_mode")
	
	$AnimatedSprite2D.play("dash_reverse")
	player.set_collision_layer_value(8, true)
	player.set_collision_mask_value(8, true)
	await $AnimatedSprite2D.animation_finished
	$blink.monitoring = false
	
	
	is_blinking = false
	player.velocity = Vector2.ZERO
	$ajak.start()
	


func prim():
	hitbox.monitoring = true


func _on_aoeprim_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		body.get_dmged(30)

func _on_blink_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		print(body)
		body.get_dmged(80)

func _on_ajak_timeout() -> void:
	can_blink = true
