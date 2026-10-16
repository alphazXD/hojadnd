extends Node2D

const GRID_SIZE := 48.0
var world_size := Vector2(1200, 800)

func set_world_size(value: Vector2) -> void:
	world_size = value
	queue_redraw()

func _draw() -> void:
	var grid_color := Color("#aeb8c8", 0.72)
	var strong_color := Color("#7f8da2", 0.85)
	var columns := ceili(world_size.x / GRID_SIZE)
	var rows := ceili(world_size.y / GRID_SIZE)
	for column in range(columns + 1):
		var x := column * GRID_SIZE
		draw_line(Vector2(x, 0), Vector2(x, world_size.y), strong_color if column % 5 == 0 else grid_color, 2.0 if column % 5 == 0 else 1.0)
	for row in range(rows + 1):
		var y := row * GRID_SIZE
		draw_line(Vector2(0, y), Vector2(world_size.x, y), strong_color if row % 5 == 0 else grid_color, 2.0 if row % 5 == 0 else 1.0)
