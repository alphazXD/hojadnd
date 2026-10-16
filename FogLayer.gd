extends Node2D

# Niebla por celdas: es ligera, serializable y funciona igual en PC y Android.
signal changed

const CELL_SIZE := 48.0
const MAX_FOG_SIZE := 4096.0
var covered := false
var revealed: Dictionary = {}
var world_size := Vector2(1200, 800)
var brush_radius := 2
var fog_color := Color(0.025, 0.025, 0.035, 0.86)
var vision_sources: Array[Dictionary] = []

func _draw() -> void:
	if not covered:
		return
	var fog_extent := world_size.min(Vector2(MAX_FOG_SIZE, MAX_FOG_SIZE))
	var columns := ceili(fog_extent.x / CELL_SIZE)
	var rows := ceili(fog_extent.y / CELL_SIZE)
	for y in range(rows):
		for x in range(columns):
			if not revealed.has(_key(x, y)) and not _visible_from_token(x, y):
				draw_rect(Rect2(Vector2(x, y) * CELL_SIZE, Vector2.ONE * (CELL_SIZE + 1.0)), fog_color)

func set_vision_sources(sources: Array) -> void:
	vision_sources.clear()
	for source in sources:
		if source is Dictionary:
			vision_sources.append(source)
	queue_redraw()

func _visible_from_token(cell_x: int, cell_y: int) -> bool:
	var center := (Vector2(cell_x, cell_y) + Vector2(0.5, 0.5)) * CELL_SIZE
	for source in vision_sources:
		var feet: float = maxf(float(source.get("feet", 0.0)), 0.0)
		var radius_pixels: float = feet / 5.0 * CELL_SIZE
		if radius_pixels > 0.0 and center.distance_to(source.get("position", Vector2.ZERO)) <= radius_pixels:
			return true
	return false

func set_world_size(value: Vector2) -> void:
	world_size = value
	queue_redraw()

func cover_all() -> void:
	covered = true
	revealed.clear()
	queue_redraw()
	changed.emit()

func clear_all() -> void:
	covered = false
	revealed.clear()
	queue_redraw()
	changed.emit()

func paint(world_position: Vector2, reveal_area: bool) -> void:
	if not covered:
		# Revelar sobre una mesa sin niebla no debe volver a encenderla. Si se usa
		# Ocultar, empezamos con todo revelado para cubrir únicamente la zona pintada.
		if reveal_area:
			return
		covered = true
		_reveal_entire_world()
	var center := Vector2i(floori(world_position.x / CELL_SIZE), floori(world_position.y / CELL_SIZE))
	var modified := false
	for y in range(center.y - brush_radius, center.y + brush_radius + 1):
		for x in range(center.x - brush_radius, center.x + brush_radius + 1):
			if x < 0 or y < 0 or Vector2(x, y).distance_to(Vector2(center)) > brush_radius + 0.35:
				continue
			var cell_key := _key(x, y)
			if reveal_area and not revealed.has(cell_key):
				revealed[cell_key] = true
				modified = true
			elif not reveal_area and revealed.erase(cell_key):
				modified = true
	if modified:
		queue_redraw()
		changed.emit()

func _reveal_entire_world() -> void:
	revealed.clear()
	var fog_extent := world_size.min(Vector2(MAX_FOG_SIZE, MAX_FOG_SIZE))
	var columns := ceili(fog_extent.x / CELL_SIZE)
	var rows := ceili(fog_extent.y / CELL_SIZE)
	for y in range(rows):
		for x in range(columns):
			revealed[_key(x, y)] = true

func export_state() -> Dictionary:
	return {"covered": covered, "revealed": revealed.keys(), "brush_radius": brush_radius}

func import_state(data: Dictionary) -> void:
	covered = bool(data.get("covered", false))
	brush_radius = clampi(int(data.get("brush_radius", 2)), 1, 8)
	revealed.clear()
	for cell_key in data.get("revealed", []):
		revealed[str(cell_key)] = true
	queue_redraw()

func _key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]
