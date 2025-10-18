extends CharacterBody2D

@export var speed: float = 80.0
@export var gravity: float = 900.0
@export var jump_force: float = -420.0
@export var graph_node: Node2D
@export var re_path_time: float = 0.1

const slope := 24.0
const clearance := 40.0
const jump_align := 8.0

var is_plr: bool = false
var player: Node2D = null
var path: Array = []
var path_index := 0
var re_path_timer := 0.0
var is_jumping := false
var jump_start: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0.0
		is_jumping = false

	if is_plr and player:
		re_path_timer -= delta
		if re_path_timer <= 0.0:
			updpath()
			re_path_timer = re_path_time
		folo_path(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)

	move_and_slide()

func updpath() -> void:
	if not graph_node or not player:
		return
	path = graph_node.get_navigation_path(global_position, player.global_position)
	path_index = 0

func folo_path(delta: float) -> void:
	if path.is_empty() or path_index >= path.size():
		return
	
	var current_node = global_position
	var next_node = path[path_index]
	var dist_x = next_node.x - global_position.x
	var dist_y = next_node.y - global_position.y
	var dir = sign(dist_x)
	
	if abs(dist_y) <= slope:
		velocity.x = dir * speed
		jump_start = Vector2.ZERO
	elif dist_y < -slope and is_on_floor() and not is_jumping:
		jump_start = Vector2(next_node.x, global_position.y)
		if abs(global_position.x - jump_start.x) > jump_align:
			velocity.x = sign(jump_start.x - global_position.x) * speed
			return
		
		if hed_clearnace():
			velocity.y = jump_force
			is_jumping = true
		else:
			velocity.x = dir * speed
			return
	
	elif dist_y > slope:
		velocity.x = dir * speed
	
	if global_position.distance_to(next_node) < 12:
		path_index += 1
		if path_index >= path.size():
			path.clear()
			jump_start = Vector2.ZERO

func hed_clearnace() -> bool:
	var space = get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.new()
	params.from = global_position - Vector2(0, 4)
	params.to = params.from - Vector2(0, clearance)
	params.exclude = [self]
	var result = space.intersect_ray(params)
	return result.is_empty()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("plr"):
		is_plr = true
		player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("plr"):
		is_plr = false
		player = null
		path.clear()
