extends Node2D

@export var tilemap: TileMap
@export var max_jumpp: float = 160.0
@export var max_jump_dis: float = 300.0
@export var min_jump_height: float = 32.0

var astar := AStar2D.new()
var points: Array[Vector2] = []

func _ready() -> void:
	tilemap = $"../TileMap"
	build_graph()

func build_graph() -> void:
	astar.clear()
	points.clear()

	var used = tilemap.get_used_cells(0)
	var id := 0
	for cell in used:
		var world_pos = tilemap.map_to_local(cell)
		var above = tilemap.get_cell_source_id(0, cell + Vector2i(0, -1))
		if above == -1:
			astar.add_point(id, world_pos)
			points.append(world_pos)
			id += 1
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			var a = points[i]
			var b = points[j]
			if abs(a.y - b.y) < 10 and abs(a.x - b.x) < 100:
				astar.connect_points(i, j)
	for i in range(points.size()):
		for j in range(points.size()):
			if i == j:
				continue
			var a = points[i]
			var b = points[j]
			var dist = a.distance_to(b)
			var height_diff = b.y - a.y

			if height_diff < -min_jump_height and abs(height_diff) <= max_jumpp and dist <= max_jump_dis:
				astar.connect_points(i, j, dist * 1.2)
			elif height_diff > min_jump_height and height_diff <= max_jumpp and dist <= max_jump_dis:
				astar.connect_points(i, j, dist * 1.1)

func get_navigation_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	if astar.get_point_count() == 0:
		return PackedVector2Array()
	var start_id = astar.get_closest_point(from_pos)
	var end_id = astar.get_closest_point(to_pos)
	return astar.get_point_path(start_id, end_id)

func _process(delta: float) -> void:
	queue_redraw()

func _on_draw() -> void:
	for id in astar.get_point_ids():
		var pos = astar.get_point_position(id)
		draw_circle(to_local(pos), 4, Color.GREEN)
		for conn in astar.get_point_connections(id):
			var other = astar.get_point_position(conn)
			draw_line(to_local(pos), to_local(other), Color.YELLOW, 1.2)
