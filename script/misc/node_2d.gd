extends Node2D

const TESTTEXTURE: PackedScene = preload("res://scenes/world/testtexture.tscn")

@export var tilemap_path: NodePath
@export var cell_size: int = 16
@export var jump_height: int = 3      # tiles you can jump upward
@export var drop_height: int = 6      # tiles you can drop downward

var tilemap: TileMap
var graph: AStar2D = AStar2D.new()
var next_id: int = 1
var point_ids: Array[int] = []
var point_positions: Dictionary = {}  # int -> Vector2i

func _ready() -> void:
	tilemap = get_node_or_null(tilemap_path)
	if tilemap == null:
		push_error("TileMap not found! Check 'tilemap_path' in inspector.")
		return
	
	create_points()
	connect_points()
	print("✅ Nodes:", graph.get_point_count())

func create_points() -> void:
	point_ids.clear()
	point_positions.clear()
	next_id = 1

	var cells: Array[Vector2i] = tilemap.get_used_cells(0)
	for cell: Vector2i in cells:
		var above: Vector2i = Vector2i(cell.x, cell.y - 1)
		if not cells.has(above):
			var pos: Vector2 = tilemap.map_to_local(above) + Vector2(cell_size / 2, cell_size / 2)

			# visual marker
			var marker: Node2D = TESTTEXTURE.instantiate()
			marker.position = pos
			add_child(marker)

			graph.add_point(next_id, pos)
			point_ids.append(next_id)
			point_positions[next_id] = cell
			next_id += 1

func connect_points() -> void:
	for id_a: int in point_ids:
		var cell_a: Vector2i = point_positions[id_a]
		var pos_a: Vector2 = graph.get_point_position(id_a)

		for id_b: int in point_ids:
			if id_a == id_b:
				continue

			var cell_b: Vector2i = point_positions[id_b]
			var pos_b: Vector2 = graph.get_point_position(id_b)

			var dx: int = cell_b.x - cell_a.x
			var dy: int = cell_b.y - cell_a.y

			# Walk (flat)
			if dy == 0 and abs(dx) == 1:
				graph.connect_points(id_a, id_b, true)

			# Jump (up)
			elif dy < 0 and abs(dx) <= 2 and abs(dy) <= jump_height:
				graph.connect_points(id_a, id_b, true)

			# Drop (down)
			elif dy > 0 and abs(dx) <= 2 and abs(dy) <= drop_height:
				graph.connect_points(id_a, id_b, true)

# Returns positions array
func get_astar_path(from_pos: Vector2, to_pos: Vector2) -> Array[Vector2]:
	if graph.get_point_count() == 0:
		return []
	var from_id: int = graph.get_closest_point(from_pos)
	var to_id: int = graph.get_closest_point(to_pos)
	var packed_path: PackedVector2Array = graph.get_point_path(from_id, to_id)
	var path: Array[Vector2] = []
	for pos in packed_path:
		path.append(pos)
	return path
