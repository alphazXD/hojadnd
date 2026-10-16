extends Node2D

const GRID_SIZE := 48.0
var mode := "select"
var start := Vector2.ZERO
var finish := Vector2.ZERO

func configure(new_mode: String, new_start: Vector2, new_finish: Vector2) -> void:
	mode = new_mode
	start = new_start
	finish = new_finish
	queue_redraw()

func clear() -> void:
	start = Vector2.ZERO
	finish = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if mode == "select" or start == finish:
		return
	var color := Color("#dc594f", 0.78)
	var square_delta := (finish - start).abs() / GRID_SIZE
	# Regla diagonal de D&D 5e: una casilla diagonal cuenta como 5 pies.
	var distance_feet := maxf(square_delta.x, square_delta.y) * 5.0
	if mode == "ruler":
		draw_line(start, finish, color, 4.0)
	elif mode == "sphere":
		draw_circle(start, start.distance_to(finish), Color(color, 0.18))
		draw_circle(start, start.distance_to(finish), color, false, 4.0)
	elif mode == "cone":
		var direction := (finish - start).normalized()
		var perpendicular := Vector2(-direction.y, direction.x)
		var half_width := start.distance_to(finish) * 0.5
		var points := PackedVector2Array([start, finish + perpendicular * half_width, finish - perpendicular * half_width])
		draw_colored_polygon(points, Color(color, 0.2))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), color, 4.0)
	draw_string(ThemeDB.fallback_font, finish + Vector2(10, -10), "%d pies" % roundi(distance_feet), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#7b1e1a"))
