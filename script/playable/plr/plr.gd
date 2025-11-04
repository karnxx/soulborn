extends CharacterBody2D

@export var max_spd: float = 250.0
@export var max_vel: float = 500.0
@export var grnd_accel: float = 12.0
@export var air_accel: float = 8.0
@export var grnd_fric: float = 14.0
@export var air_fric: float = 10.0
@export var jump: float = 450.0
@export var grav: float = 1200.0

var momentum: float = 0.0
@export var momentum_build_rate: float = 3.0
@export var momentum_decay_rate: float = 15.0
@export var momentum_max: float = 10.0
var cur_health := 0
var max_health : int
var facing := "right"
var is_dashing := false
var is_attacking := false
var current_class = null
var mouse_target := Vector2.ZERO
func _ready():
	set_class(preload("res://scenes/playables/plr/classes/revenant.tscn"))

func _physics_process(delta):
	$Label.text = str(cur_health)
	upd_mouse()
	class_inp()
	apply_grav(delta)
	upd_momentum(delta)
	if not is_attacking and not is_dashing:
		movement(delta)
	move_and_slide()

func apply_grav(delta):
	if not is_on_floor():
		velocity.y += grav * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump
		if current_class and current_class.has_method("on_jump"):
			current_class.on_jump()

func movement(delta):
	var input_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var accel := grnd_accel if is_on_floor() else air_accel
	var fric := grnd_fric if is_on_floor() else air_fric

	if abs(input_dir) > 0.01:
		facing = "right" if input_dir > 0 else "left"
		var target_speed = input_dir * max_spd + sign(input_dir) * momentum * 80
		velocity.x = move_toward(velocity.x, target_speed, accel * delta * max_spd)
	else:
		velocity.x = lerp(velocity.x, 0.0, fric * delta)

	if current_class and current_class.name != "vanguardian":
		velocity.x = clamp(velocity.x, -max_vel, max_vel)

func upd_momentum(delta):
	var limit = momentum_max if current_class == null or current_class.name != "vanguardian" else INF
	if abs(velocity.x) > 0.5 and is_on_floor():
		momentum = min(momentum + momentum_build_rate * delta, limit)
	elif not is_dashing:
		momentum = max(momentum - momentum_decay_rate * delta, 0.0)

func upd_mouse():
	mouse_target = get_global_mouse_position()

func class_inp():
	if current_class == null:
		return

	current_class.upd_mouse(mouse_target)

	if Input.is_action_just_pressed("primary"):
		if not is_dashing:
			is_attacking = true
			velocity.x = 0
			await current_class.attack()
			is_attacking = false

	if Input.is_action_just_pressed("secondary"):
		if not is_dashing:
			is_attacking = true
			await current_class.secondary_attack()
			is_attacking = false

	if Input.is_action_just_pressed("spec"):
		is_attacking = true
		await current_class.special()
		is_attacking = false

	if Input.is_action_just_pressed("dash"):
		if not is_dashing:
			is_dashing = true
			await current_class.dash()
			is_dashing = false

func set_class(class_scene: PackedScene):
	if current_class:
		current_class.queue_free()
	current_class = class_scene.instantiate()
	self.add_child(current_class)
	$CollisionShape2D.shape = current_class.get_node("collision").shape
	$CollisionShape2D.position = current_class.get_node("collision").position
	max_health = current_class.max_health
	cur_health = max_health

func rebound_from_attack(enemy_pos: Vector2):
	if not current_class:
		return

	if current_class.name == "vanguardian":
		var dir_to_enemy = enemy_pos - global_position
		var horizontal_strength = clamp(momentum * 300, 150, 800)
		var vertical_strength = clamp(momentum * 400, 250, 600)

		if dir_to_enemy.y > 20:
			velocity.y = -(vertical_strength + 100)
			velocity.x *= 0.5
		elif dir_to_enemy.y < -20:
			velocity.y = vertical_strength * 0.5
			velocity.x = 0
		else:
			velocity.y = -vertical_strength * 0.2
			velocity.x = -sign(dir_to_enemy.x) * horizontal_strength

		momentum = min(momentum + 2, momentum_max)
		is_attacking = true
		$CollisionShape2D.call_deferred("set_disabled", true)
		await get_tree().create_timer(0.1).timeout
		$CollisionShape2D.call_deferred("set_disabled", false)
		is_attacking = false

	elif current_class.name == "occultist":
		await get_tree().create_timer(0.5).timeout
		var dir = 1 if facing == "right" else -1
		var horizontal_strength = clamp(momentum * 250, 150, 700) * 30.0

		velocity.x = -dir * horizontal_strength

		momentum = min(momentum + 3, momentum_max)
		is_attacking = true
		await get_tree().create_timer(0.1).timeout
		is_attacking = false



	
func get_dmged(dmg, pos=null):
	cur_health -= dmg
	if pos != null:
		velocity.x = (global_position - pos).normalized().x * 300.0
		velocity.y = -400
	
