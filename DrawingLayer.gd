extends Node2D

# Capa independiente de anotaciones. Los puntos se exportan como números para
# que el archivo JSON funcione igual en Windows y Android.
signal changed

var strokes: Array[Dictionary] = []
var active_stroke := -1

func _draw() -> void:
	for stroke in strokes:
		var points: PackedVector2Array = stroke.get("points", PackedVector2Array())
		if points.size() >= 2:
			draw_polyline(points, stroke.get("color", Color.WHITE), float(stroke.get("width", 5.0)), true)
		elif points.size() == 1:
			draw_circle(points[0], float(stroke.get("width", 5.0)) * 0.5, stroke.get("color", Color.WHITE))

func begin_stroke(point: Vector2, color: Color, width: float) -> void:
	var points := PackedVector2Array([point])
	strokes.append({"points": points, "color": color, "width": clampf(width, 1.0, 40.0)})
	active_stroke = strokes.size() - 1
	queue_redraw()

func add_point(point: Vector2) -> void:
	if active_stroke < 0 or active_stroke >= strokes.size():
		return
	var points: PackedVector2Array = strokes[active_stroke].points
	if not points.is_empty() and points[-1].distance_to(point) < 3.0:
		return
	points.append(point)
	strokes[active_stroke].points = points
	queue_redraw()

func finish_stroke() -> void:
	if active_stroke < 0:
		return
	active_stroke = -1
	changed.emit()

func erase_at(point: Vector2, radius := 28.0) -> void:
	for index in range(strokes.size() - 1, -1, -1):
		var points: PackedVector2Array = strokes[index].points
		for stroke_point in points:
			if stroke_point.distance_to(point) <= radius:
				strokes.remove_at(index)
				queue_redraw()
				changed.emit()
				return

func clear_all() -> void:
	if strokes.is_empty():
		return
	strokes.clear()
	active_stroke = -1
	queue_redraw()
	changed.emit()

func export_state() -> Array:
	var result := []
	for stroke in strokes:
		var serialized_points := []
		var points: PackedVector2Array = stroke.points
		for point in points:
			serialized_points.append([point.x, point.y])
		result.append({"points": serialized_points, "color": Color(stroke.color).to_html(true), "width": float(stroke.width)})
	return result

func import_state(data: Array) -> void:
	strokes.clear()
	active_stroke = -1
	for saved in data:
		if not saved is Dictionary:
			continue
		var points := PackedVector2Array()
		for saved_point in saved.get("points", []):
			if saved_point is Array and saved_point.size() >= 2:
				points.append(Vector2(float(saved_point[0]), float(saved_point[1])))
		if not points.is_empty():
			strokes.append({"points": points, "color": Color.from_string(str(saved.get("color", "ffffffff")), Color.WHITE), "width": clampf(float(saved.get("width", 5.0)), 1.0, 40.0)})
	queue_redraw()
