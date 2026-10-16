extends Node2D

## Mundo 2D de la mesa: cámara, mapa, fichas, gestos, niebla y dibujo.
## Los ajustes más habituales están documentados en res://GUIA_PROGRAMACION.md.

signal tokens_changed
signal token_motion_changed
signal tool_changed(mode: String)
signal token_selected(index: int)
signal token_double_clicked(index: int)
signal zoom_changed(value: float)
signal map_scale_changed(value: float)
signal fog_changed
signal locks_changed
signal history_changed(can_undo: bool, can_redo: bool)
signal drawings_changed

const GRID_SIZE := 48.0 # PERSONALIZACIÓN: píxeles de una casilla de 5 pies.
# Mesa temporal sin mapa: 12 000 px de lado (250 × 250 casillas). Es amplia
# para preparar encuentros, pero evita perderse a distancias prácticamente infinitas.
const EMPTY_WORLD_EXTENT := 6000.0 # Espacio cómodo disponible sin mapa.
const TOKEN_SCENE := preload("res://TableToken.tscn")
var tokens: Array[Node2D] = []
var selected_token := -1
var selected_tokens: Array[int] = []
var group_selection_mode := false
var dragging_token := false
var panning := false
var measuring := false
var fog_painting := false
var drawing_active := false
var drawing_color := Color("#e14f45")
var drawing_width := 6.0
var director_mode := true
var local_player_name := ""
var local_player_id := ""
# Copia de la lista del servidor: id de conexión -> nombre visible.
# Se usa para validar cambios recibidos; no confíes en el nombre enviado por la ficha.
var online_players: Dictionary = {}
var tokens_locked := false
var map_locked := false
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var history_restoring := false
const MAX_HISTORY := 30
var last_mouse := Vector2.ZERO
var active_touches := {}
var pinch_active := false
var pinch_start_distance := 1.0
var pinch_start_zoom := 1.0
var pinch_last_center := Vector2.ZERO
var suppress_single_touch := false
var zoom_level := 1.0
var target_zoom := 1.0
var zoom_focus := Vector2.ZERO
const ZOOM_SMOOTH_SPEED := 12.0
var map_path := ""
var map_scale := 1.0
var tool_mode := "select"
var world_size := Vector2(1200, 800)
var token_colors := [Color("#d45d52"), Color("#4f91d1"), Color("#69ae68"), Color("#c89a49"), Color("#9b6dca")]

@onready var map_sprite: Sprite2D = $Map
@onready var background: ColorRect = $Background
@onready var grid: Node2D = $Grid
@onready var token_layer: Node2D = $Tokens
@onready var measurement: Node2D = $Measurements
@onready var fog: Node2D = $Fog
@onready var drawings: Node2D = $Drawings
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	get_viewport().size_changed.connect(_viewport_resized)
	fog.changed.connect(func(): fog_changed.emit())
	drawings.changed.connect(func(): drawings_changed.emit())
	tokens_changed.connect(_update_fog_vision)
	_configure_empty_world()
	_viewport_resized()

func _viewport_resized() -> void:
	var visible := Vector2(get_viewport().size) / zoom_level
	if map_sprite.texture == null:
		_configure_empty_world()
		return
	world_size = world_size.max(visible)
	grid.set_world_size(world_size)
	fog.set_world_size(world_size)
	if camera.position == Vector2.ZERO:
		camera.position = visible * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and (pinch_active or suppress_single_touch):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(target_zoom + 0.1, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(target_zoom - 0.1, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			last_mouse = event.position
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_point := get_global_mouse_position()
			if tool_mode in ["draw", "erase_draw"] and director_mode:
				_record_history()
				drawing_active = true
				if tool_mode == "draw": drawings.begin_stroke(world_point, drawing_color, drawing_width)
				else: drawings.erase_at(world_point)
			elif tool_mode in ["fog_reveal", "fog_hide"] and director_mode:
				_record_history()
				fog_painting = true
				fog.paint(world_point, tool_mode == "fog_reveal")
			elif tool_mode != "select":
				world_point = _snap_measure(world_point)
				measuring = true
				measurement.configure(tool_mode, world_point, world_point)
			else:
				_select_at(world_point)
				if event.double_click:
					if selected_token >= 0:
						token_double_clicked.emit(selected_token)
					elif not tokens_locked and director_mode:
						add_token(world_point)
				elif selected_token >= 0 and not tokens_locked and _can_control_token(selected_token):
					_record_history()
					dragging_token = true
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if dragging_token:
				_snap_selected_tokens()
				tokens_changed.emit()
			dragging_token = false
			measuring = false
			fog_painting = false
			if drawing_active and tool_mode == "draw":
				drawings.finish_stroke()
			drawing_active = false
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and tool_mode == "select" and not tokens_locked and director_mode:
			var index := _token_at(get_global_mouse_position())
			if index >= 0:
				_remove_token(index)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if panning:
			camera.position -= event.relative / zoom_level
			_clamp_camera()
		elif dragging_token and selected_token >= 0:
			_move_selected_to(get_global_mouse_position())
			_update_fog_vision()
		elif measuring:
			measurement.configure(tool_mode, measurement.start, _snap_measure(get_global_mouse_position()))
		elif fog_painting and director_mode:
			fog.paint(get_global_mouse_position(), tool_mode == "fog_reveal")
		elif drawing_active and director_mode:
			if tool_mode == "draw": drawings.add_point(get_global_mouse_position())
			else: drawings.erase_at(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			if active_touches.size() >= 2:
				if not pinch_active:
					_begin_pinch()
			else:
				var touch_world: Vector2 = get_canvas_transform().affine_inverse() * event.position
				if tool_mode in ["draw", "erase_draw"] and director_mode:
					_record_history()
					drawing_active = true
					if tool_mode == "draw": drawings.begin_stroke(touch_world, drawing_color, drawing_width)
					else: drawings.erase_at(touch_world)
				elif tool_mode in ["fog_reveal", "fog_hide"] and director_mode:
					_record_history()
					fog_painting = true
					fog.paint(touch_world, tool_mode == "fog_reveal")
				elif tool_mode != "select":
					touch_world = _snap_measure(touch_world)
					measuring = true
					measurement.configure(tool_mode, touch_world, touch_world)
				else:
					_select_at(touch_world)
					if event.double_tap:
						if selected_token >= 0:
							token_double_clicked.emit(selected_token)
						elif not tokens_locked and director_mode:
							add_token(touch_world)
					elif selected_token >= 0 and not tokens_locked and _can_control_token(selected_token):
						_record_history()
						dragging_token = true
		else:
			active_touches.erase(event.index)
			if pinch_active or suppress_single_touch:
				pinch_active = active_touches.size() >= 2
				dragging_token = false
				measuring = false
				fog_painting = false
				if drawing_active and tool_mode == "draw": drawings.finish_stroke()
				drawing_active = false
				if active_touches.is_empty():
					suppress_single_touch = false
			else:
				if dragging_token and selected_token >= 0:
					_snap_selected_tokens()
					tokens_changed.emit()
				dragging_token = false
				measuring = false
				fog_painting = false
				if drawing_active and tool_mode == "draw": drawings.finish_stroke()
				drawing_active = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		active_touches[event.index] = event.position
		if pinch_active and active_touches.size() >= 2:
			_update_pinch()
		elif not suppress_single_touch:
			var drag_world: Vector2 = get_canvas_transform().affine_inverse() * event.position
			if dragging_token and selected_token >= 0:
				_move_selected_to(drag_world)
				_update_fog_vision()
			elif measuring:
				measurement.configure(tool_mode, measurement.start, _snap_measure(drag_world))
			elif fog_painting and director_mode:
				fog.paint(drag_world, tool_mode == "fog_reveal")
			elif drawing_active and director_mode:
				if tool_mode == "draw": drawings.add_point(drag_world)
				else: drawings.erase_at(drag_world)
			elif tool_mode == "select" and selected_token < 0:
				camera.position -= event.relative / zoom_level
				_clamp_camera()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and selected_token >= 0 and tool_mode == "select" and not tokens_locked and _can_control_token(selected_token):
		var direction := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: direction = Vector2.LEFT
			KEY_RIGHT: direction = Vector2.RIGHT
			KEY_UP: direction = Vector2.UP
			KEY_DOWN: direction = Vector2.DOWN
		if direction != Vector2.ZERO:
			_record_history()
			for index in _active_controlled_selection():
				tokens[index].position = _snap(tokens[index].position + direction * GRID_SIZE)
			tokens_changed.emit()
			get_viewport().set_input_as_handled()

func _pinch_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for touch_index in active_touches:
		points.append(active_touches[touch_index])
		if points.size() == 2:
			break
	return points

func _begin_pinch() -> void:
	var points := _pinch_points()
	if points.size() < 2:
		return
	if dragging_token and selected_token >= 0:
		_snap_selected_tokens()
		tokens_changed.emit()
	dragging_token = false
	measuring = false
	fog_painting = false
	if drawing_active and tool_mode == "draw": drawings.finish_stroke()
	drawing_active = false
	pinch_active = true
	suppress_single_touch = true
	pinch_start_distance = maxf(points[0].distance_to(points[1]), 1.0)
	pinch_start_zoom = zoom_level
	pinch_last_center = (points[0] + points[1]) * 0.5

func _update_pinch() -> void:
	var points := _pinch_points()
	if points.size() < 2:
		return
	var center := (points[0] + points[1]) * 0.5
	var distance := maxf(points[0].distance_to(points[1]), 1.0)
	var target_zoom := pinch_start_zoom * distance / pinch_start_distance
	_zoom_at(target_zoom, center)
	var center_delta := center - pinch_last_center
	camera.position -= center_delta / zoom_level
	pinch_last_center = center
	_clamp_camera()

func add_token(position := Vector2(-1, -1)) -> void:
	if tokens_locked or not director_mode:
		return
	_record_history()
	var target: Vector2 = position
	if target.x < 0:
		target = camera.position
	var number := tokens.size() + 1
	var token := TOKEN_SCENE.instantiate()
	token_layer.add_child(token)
	token.configure({"position": _snap(target), "color": token_colors[(number - 1) % token_colors.size()], "label": str(number)})
	tokens.append(token)
	_select_token(tokens.size() - 1)
	tokens_changed.emit()

# Se usa al desplegar encuentros para repartir las nuevas fichas en una rejilla
# alrededor del centro de la cámara en vez de apilarlas en un solo punto.
func nudge_selected_token_for_spawn(offset: Vector2) -> void:
	if selected_token < 0 or selected_token >= tokens.size() or not director_mode:
		return
	var center := camera.position
	tokens[selected_token].position = _snap(center + offset)
	tokens[selected_token].queue_redraw()
	tokens_changed.emit()

func clear_tokens() -> void:
	if tokens_locked or not director_mode:
		return
	_record_history()
	for token in tokens:
		token.queue_free()
	tokens.clear()
	selected_token = -1
	selected_tokens.clear()
	tokens_changed.emit()

func set_selected_color(color: Color) -> void:
	if selected_token < 0 or not _can_control_token(selected_token):
		return
	tokens[selected_token].token_color = color
	tokens[selected_token].queue_redraw()
	tokens_changed.emit()

func set_selected_image(path: String) -> bool:
	if selected_token < 0 or not _can_control_token(selected_token):
		return false
	var result: bool = tokens[selected_token].set_portrait(path)
	if result:
		tokens_changed.emit()
	return result

func set_token_image(index: int, path: String, notify_change := true) -> bool:
	if index < 0 or index >= tokens.size():
		return false
	var result: bool = tokens[index].set_portrait(path)
	if result and notify_change:
		tokens_changed.emit()
	return result

func set_selected_sheet(filename: String) -> void:
	if selected_token >= 0 and _can_control_token(selected_token):
		tokens[selected_token].sheet_file = filename
		tokens_changed.emit()

func set_selected_sheet_snapshot(character_name: String, current: float, maximum: float) -> void:
	if selected_token >= 0 and _can_control_token(selected_token):
		tokens[selected_token].set_sheet_snapshot(character_name, current, maximum)
		tokens_changed.emit()

func set_token_hit_points(token_index: int, current: float, maximum: float) -> void:
	if token_index < 0 or token_index >= tokens.size() or not _can_control_token(token_index):
		return
	_record_history()
	tokens[token_index].set_sheet_snapshot(tokens[token_index].character_name, current, maximum)
	tokens_changed.emit()

func get_selected_sheet() -> String:
	return "" if selected_token < 0 else tokens[selected_token].sheet_file

func set_selected_status_effects(effects: Array) -> void:
	if selected_token >= 0 and _can_control_token(selected_token):
		_record_history()
		tokens[selected_token].set_status_effects(effects)
		tokens_changed.emit()

func set_token_status_effects(token_index: int, effects: Array) -> void:
	if token_index < 0 or token_index >= tokens.size() or not _can_control_token(token_index):
		return
	_record_history()
	tokens[token_index].set_status_effects(effects)
	tokens_changed.emit()

func set_selected_vision(feet: float) -> void:
	if selected_token < 0 or selected_token >= tokens.size() or not _can_control_token(selected_token):
		return
	_record_history()
	tokens[selected_token].vision_feet = maxf(feet, 0.0)
	_update_fog_vision()
	tokens_changed.emit()

func get_selected_vision() -> float:
	return 0.0 if selected_token < 0 else float(tokens[selected_token].vision_feet)

func set_local_player_name(value: String) -> void:
	local_player_name = value.strip_edges().to_lower()

func set_local_player_id(value: String) -> void:
	local_player_id = value.strip_edges()

func set_online_players(players: Dictionary) -> void:
	online_players = players.duplicate(true)

func set_selected_owner(value: String, player_id := "") -> void:
	if not director_mode or selected_token < 0 or selected_token >= tokens.size():
		return
	_record_history()
	tokens[selected_token].owner_name = value.strip_edges()
	tokens[selected_token].owner_id = player_id.strip_edges()
	tokens_changed.emit()

func get_selected_owner() -> String:
	return "" if selected_token < 0 else str(tokens[selected_token].owner_name)

func get_selected_owner_id() -> String:
	return "" if selected_token < 0 else str(tokens[selected_token].owner_id)

func _can_control_token(index: int) -> bool:
	if index < 0 or index >= tokens.size():
		return false
	if director_mode:
		return true
	var stable_owner_id: String = str(tokens[index].owner_id).strip_edges()
	if not stable_owner_id.is_empty():
		return stable_owner_id == local_player_id
	var owner: String = str(tokens[index].owner_name).strip_edges().to_lower()
	return not owner.is_empty() and owner == local_player_name

# Validación equivalente para peticiones recibidas por red. El servidor usa el
# identificador persistente siempre que exista y conserva el nombre como respaldo
# para partidas antiguas guardadas antes de incorporar los IDs de jugador.
func can_peer_control_token(peer_id: int, index: int) -> bool:
	if index < 0 or index >= tokens.size():
		return false
	if peer_id == 1:
		return true
	var player_data: Variant = online_players.get(str(peer_id), {})
	if not player_data is Dictionary:
		return false
	var player_id: String = str(player_data.get("id", "")).strip_edges()
	var player_name: String = str(player_data.get("name", "")).strip_edges().to_lower()
	var owner_id: String = str(tokens[index].owner_id).strip_edges()
	if not owner_id.is_empty():
		return not player_id.is_empty() and owner_id == player_id
	var owner_name: String = str(tokens[index].owner_name).strip_edges().to_lower()
	return not owner_name.is_empty() and owner_name == player_name

func validate_peer_token_data(peer_id: int, proposed: Array) -> Array:
	# Punto de entrada público para TabletopView. Mantener la validación en el
	# mundo evita que dos rutas de red terminen aplicando reglas diferentes.
	return _validate_client_token_data(peer_id, proposed)

func set_group_selection_mode(enabled: bool) -> void:
	if enabled and not group_selection_mode:
		_set_group_selection([])
	group_selection_mode = enabled

func duplicate_selected_tokens() -> void:
	if tokens_locked or selected_token < 0 or not director_mode:
		return
	_record_history()
	var source_indices: Array[int] = _active_selection()
	var new_indices: Array[int] = []
	for source_index in source_indices:
		if source_index < 0 or source_index >= tokens.size():
			continue
		var data: Dictionary = tokens[source_index].to_data().duplicate(true)
		data.position = _snap(Vector2(data.position) + Vector2(GRID_SIZE, GRID_SIZE))
		data.label = str(tokens.size() + 1)
		var duplicate := TOKEN_SCENE.instantiate()
		token_layer.add_child(duplicate)
		duplicate.configure(data)
		tokens.append(duplicate)
		new_indices.append(tokens.size() - 1)
	_set_group_selection(new_indices)
	tokens_changed.emit()

func _update_fog_vision() -> void:
	var sources: Array[Dictionary] = []
	for token in tokens:
		sources.append({"position": token.position, "feet": token.vision_feet})
	fog.set_vision_sources(sources)

func get_selected_status_effects() -> Array[String]:
	var result: Array[String] = []
	if selected_token < 0 or selected_token >= tokens.size():
		return result
	# Copiamos los valores para conservar el tipo Array[String], incluso cuando
	# la propiedad procede de un nodo cargado dinámicamente.
	for effect in tokens[selected_token].status_effects:
		result.append(str(effect))
	return result

func set_tool(mode: String) -> void:
	if mode in ["fog_reveal", "fog_hide", "draw", "erase_draw"] and not director_mode:
		if tool_mode != "select":
			tool_mode = "select"
			tool_changed.emit(tool_mode)
		return
	if tool_mode == mode:
		return
	tool_mode = mode
	if mode == "select":
		measurement.clear()
	tool_changed.emit(tool_mode)

func clear_template() -> void:
	measurement.clear()

func set_director_mode(enabled: bool) -> void:
	director_mode = enabled
	if not enabled and tool_mode in ["fog_reveal", "fog_hide", "draw", "erase_draw"]:
		set_tool("select")

func set_tokens_locked(value: bool) -> void:
	if not director_mode:
		return
	tokens_locked = value
	dragging_token = false
	locks_changed.emit()

func set_map_locked(value: bool) -> void:
	if not director_mode:
		return
	map_locked = value
	locks_changed.emit()

func export_locks() -> Dictionary:
	return {"tokens_locked": tokens_locked, "map_locked": map_locked}

func import_locks(data: Dictionary) -> void:
	tokens_locked = bool(data.get("tokens_locked", false))
	map_locked = bool(data.get("map_locked", false))
	dragging_token = false
	locks_changed.emit()

func cover_with_fog() -> void:
	if director_mode:
		_record_history()
		fog.cover_all()

func clear_fog() -> void:
	if director_mode:
		_record_history()
		fog_painting = false
		set_tool("select")
		fog.clear_all()

func export_fog() -> Dictionary:
	return fog.export_state()

func import_fog(data: Dictionary) -> void:
	fog.import_state(data)

func set_drawing_style(color: Color, width: float) -> void:
	drawing_color = color
	drawing_width = clampf(width, 1.0, 40.0)

func clear_drawings() -> void:
	if not director_mode or drawings.strokes.is_empty():
		return
	_record_history()
	drawings.clear_all()

func export_drawings() -> Array:
	return drawings.export_state()

func import_drawings(data: Array) -> void:
	drawings.import_state(data)

func set_zoom(value: float) -> void:
	_zoom_at(value, Vector2(get_viewport().size) * 0.5)

func zoom_in() -> void: set_zoom(target_zoom + 0.1)
func zoom_out() -> void: set_zoom(target_zoom - 0.1)
func reset_zoom() -> void: set_zoom(1.0)

func get_camera_scroll_state() -> Dictionary:
	var visible := Vector2(get_viewport().size) / zoom_level
	var origin := -Vector2.ONE * EMPTY_WORLD_EXTENT if map_sprite.texture == null else Vector2.ZERO
	var extent := Vector2.ONE * (EMPTY_WORLD_EXTENT * 2.0) if map_sprite.texture == null else world_size
	return {
		"x": camera.position.x - visible.x * 0.5,
		"y": camera.position.y - visible.y * 0.5,
		"min_x": origin.x,
		"min_y": origin.y,
		"max_x": origin.x + extent.x,
		"max_y": origin.y + extent.y,
		"page_x": visible.x,
		"page_y": visible.y
	}

func set_camera_scroll(value: float, horizontal: bool) -> void:
	var visible := Vector2(get_viewport().size) / zoom_level
	if horizontal:
		camera.position.x = value + visible.x * 0.5
	else:
		camera.position.y = value + visible.y * 0.5
	_clamp_camera()

func load_map(path: String) -> bool:
	if map_locked:
		return false
	var image := Image.new()
	if image.load(path) != OK:
		return false
	var largest := maxi(image.get_width(), image.get_height())
	if largest > 4096:
		var ratio := 4096.0 / float(largest)
		image.resize(roundi(image.get_width() * ratio), roundi(image.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
	map_sprite.texture = ImageTexture.create_from_image(image)
	map_path = path
	map_scale = 1.0
	_update_map()
	return true

func grow_map() -> void: set_map_scale(map_scale * 1.25)
func shrink_map() -> void: set_map_scale(map_scale * 0.8)

func set_map_scale(value: float) -> void:
	if map_locked:
		return
	map_scale = clampf(value, 0.1, 5.0)
	_update_map()

func fit_map() -> void:
	if map_locked:
		return
	if map_sprite.texture == null:
		return
	var visible := Vector2(get_viewport().size) / zoom_level
	map_scale = maxf(visible.x / map_sprite.texture.get_width(), visible.y / map_sprite.texture.get_height())
	_update_map()
	camera.position = visible * 0.5

func clear_map() -> void:
	if map_locked:
		return
	map_sprite.texture = null
	map_path = ""
	map_scale = 1.0
	_configure_empty_world()
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()

func export_tokens() -> Array:
	var result := []
	for token in tokens:
		var data: Dictionary = token.to_data()
		result.append({"x": data.position.x, "y": data.position.y, "color": data.color.to_html(true), "label": data.label, "image_path": data.image_path, "sheet_file": data.sheet_file, "status_effects": data.status_effects, "character_name": data.character_name, "hp_current": data.hp_current, "hp_max": data.hp_max, "vision_feet": data.vision_feet, "owner_name": data.owner_name, "owner_id": data.owner_id})
	return result

func export_token_positions() -> Array:
	var result: Array = []
	for token in tokens:
		result.append({"x": token.position.x, "y": token.position.y})
	return result

func apply_token_positions(data: Array) -> void:
	if data.size() != tokens.size():
		return
	for index in range(tokens.size()):
		if not data[index] is Dictionary:
			continue
		var position_data: Dictionary = data[index]
		var fallback: Vector2 = tokens[index].position
		tokens[index].position = Vector2(
			_safe_network_number(position_data.get("x", fallback.x), fallback.x, -1000000.0, 1000000.0),
			_safe_network_number(position_data.get("y", fallback.y), fallback.y, -1000000.0, 1000000.0)
		)
	_update_fog_vision()

func apply_peer_token_positions(peer_id: int, data: Array) -> void:
	if data.size() != tokens.size():
		return
	for index in range(tokens.size()):
		if not can_peer_control_token(peer_id, index) or not data[index] is Dictionary:
			continue
		var position_data: Dictionary = data[index]
		var fallback: Vector2 = tokens[index].position
		tokens[index].position = Vector2(
			_safe_network_number(position_data.get("x", fallback.x), fallback.x, -1000000.0, 1000000.0),
			_safe_network_number(position_data.get("y", fallback.y), fallback.y, -1000000.0, 1000000.0)
		)
	_update_fog_vision()

func import_tokens(data: Array) -> void:
	for token in tokens:
		token.queue_free()
	tokens.clear()
	for saved in data:
		if not saved is Dictionary:
			continue
		var token := TOKEN_SCENE.instantiate()
		token_layer.add_child(token)
		token.configure({"position": Vector2(float(saved.get("x", 48)), float(saved.get("y", 48))), "color": Color.from_string(str(saved.get("color", "d45d52ff")), Color("#d45d52")), "label": str(saved.get("label", tokens.size() + 1)), "image_path": str(saved.get("image_path", "")), "sheet_file": str(saved.get("sheet_file", "")), "status_effects": saved.get("status_effects", []), "character_name": str(saved.get("character_name", "")), "hp_current": float(saved.get("hp_current", 0.0)), "hp_max": float(saved.get("hp_max", 1.0)), "vision_feet": float(saved.get("vision_feet", 30.0)), "owner_name": str(saved.get("owner_name", "")), "owner_id": str(saved.get("owner_id", ""))})
		tokens.append(token)
	selected_token = -1
	selected_tokens.clear()
	_update_fog_vision()

@rpc("any_peer", "call_remote", "reliable")
func sync_tokens(data: Array) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and sender_id != 0:
		# Un cliente solamente puede editar fichas que el anfitrión le asignó.
		# El servidor conserva propietarios, cantidad y orden para impedir suplantaciones.
		var safe_data: Array = _validate_client_token_data(sender_id, data)
		import_tokens(safe_data)
		sync_tokens.rpc(safe_data)
		return
	import_tokens(data)

func _validate_client_token_data(sender_id: int, proposed: Array) -> Array:
	var current: Array = export_tokens()
	var player_data: Variant = online_players.get(str(sender_id), {})
	var player_name: String = str(player_data.get("name", "") if player_data is Dictionary else player_data).strip_edges().to_lower()
	var player_id: String = str(player_data.get("id", "") if player_data is Dictionary else "").strip_edges()
	if (player_name.is_empty() and player_id.is_empty()) or proposed.size() != current.size():
		return current
	for index in range(current.size()):
		if not proposed[index] is Dictionary:
			continue
		var existing: Dictionary = current[index]
		var owner: String = str(existing.get("owner_name", "")).strip_edges().to_lower()
		var owner_id: String = str(existing.get("owner_id", "")).strip_edges()
		if (not owner_id.is_empty() and owner_id != player_id) or (owner_id.is_empty() and owner != player_name):
			continue
		var incoming: Dictionary = proposed[index]
		# Campos que el propietario puede modificar. Los valores se normalizan para
		# que un cliente averiado no pueda crear coordenadas infinitas, textos enormes
		# o listas capaces de bloquear el guardado de la mesa.
		existing["x"] = _safe_network_number(incoming.get("x", existing.get("x", 0.0)), float(existing.get("x", 0.0)), -1000000.0, 1000000.0)
		existing["y"] = _safe_network_number(incoming.get("y", existing.get("y", 0.0)), float(existing.get("y", 0.0)), -1000000.0, 1000000.0)
		existing["hp_current"] = _safe_network_number(incoming.get("hp_current", existing.get("hp_current", 0.0)), float(existing.get("hp_current", 0.0)), -1000000000.0, 1000000000.0)
		existing["hp_max"] = _safe_network_number(incoming.get("hp_max", existing.get("hp_max", 1.0)), float(existing.get("hp_max", 1.0)), 1.0, 1000000000.0)
		existing["vision_feet"] = _safe_network_number(incoming.get("vision_feet", existing.get("vision_feet", 30.0)), float(existing.get("vision_feet", 30.0)), 0.0, 100000.0)
		if incoming.has("color"):
			existing["color"] = Color.from_string(str(incoming.color).substr(0, 16), Color.from_string(str(existing.get("color", "d45d52ff")), Color("#d45d52"))).to_html(true)
		for key in ["label", "character_name"]:
			if incoming.has(key):
				existing[key] = str(incoming[key]).strip_edges().substr(0, 64)
		for key in ["image_path", "sheet_file"]:
			if incoming.has(key):
				existing[key] = str(incoming[key]).substr(0, 512)
		if incoming.has("status_effects") and incoming.status_effects is Array:
			var safe_effects: Array[String] = []
			for effect in incoming.status_effects:
				var clean_effect: String = str(effect).strip_edges().substr(0, 48)
				if not clean_effect.is_empty() and safe_effects.size() < 16:
					safe_effects.append(clean_effect)
			existing["status_effects"] = safe_effects
		current[index] = existing
	return current

func _safe_network_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	var number: float = float(value)
	if is_nan(number) or is_inf(number):
		return clampf(fallback, minimum, maximum)
	return clampf(number, minimum, maximum)

func _update_map() -> void:
	map_sprite.scale = Vector2.ONE * map_scale
	world_size = map_sprite.texture.get_size() * map_scale if map_sprite.texture != null else Vector2(get_viewport().size)
	world_size = world_size.max(Vector2(get_viewport().size) / zoom_level)
	grid.position = Vector2.ZERO
	background.position = Vector2.ZERO
	background.size = world_size
	grid.set_world_size(world_size)
	fog.set_world_size(world_size)
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()
	_clamp_camera()

func _zoom_at(value: float, screen_point: Vector2) -> void:
	target_zoom = clampf(value, 0.35, 3.0)
	zoom_focus = screen_point

func _process(delta: float) -> void:
	if is_equal_approx(zoom_level, target_zoom):
		return
	var weight := 1.0 - exp(-ZOOM_SMOOTH_SPEED * delta)
	var next_zoom := lerpf(zoom_level, target_zoom, weight)
	if absf(next_zoom - target_zoom) < 0.001:
		next_zoom = target_zoom
	_apply_zoom(next_zoom, zoom_focus)

func _apply_zoom(value: float, screen_point: Vector2) -> void:
	var before := get_canvas_transform().affine_inverse() * screen_point
	zoom_level = value
	camera.zoom = Vector2.ONE * zoom_level
	var after := get_canvas_transform().affine_inverse() * screen_point
	camera.position += before - after
	zoom_changed.emit(zoom_level)
	_clamp_camera()

func _select_at(point: Vector2) -> void:
	var index := _token_at(point)
	if group_selection_mode:
		_toggle_group_token(index)
	elif index in selected_tokens and selected_tokens.size() > 1:
		selected_token = index
		token_selected.emit(selected_token)
	else:
		_select_token(index)

func _select_token(index: int) -> void:
	var selection: Array[int] = []
	if index >= 0:
		selection.append(index)
	_set_group_selection(selection)

func _toggle_group_token(index: int) -> void:
	if index < 0:
		_set_group_selection([])
		return
	var next_selection: Array[int] = []
	for selected_index in selected_tokens:
		next_selection.append(selected_index)
	if index in next_selection:
		next_selection.erase(index)
	else:
		next_selection.append(index)
	_set_group_selection(next_selection)

func _set_group_selection(indices: Array[int]) -> void:
	for token in tokens:
		token.set_selected(false)
	selected_tokens.clear()
	for index in indices:
		if index >= 0 and index < tokens.size() and index not in selected_tokens:
			selected_tokens.append(index)
			tokens[index].set_selected(true)
	selected_token = selected_tokens.back() if not selected_tokens.is_empty() else -1
	token_selected.emit(selected_token)

func _active_selection() -> Array[int]:
	var active: Array[int] = []
	for index in selected_tokens:
		if index >= 0 and index < tokens.size():
			active.append(index)
	if active.is_empty() and selected_token >= 0:
		active.append(selected_token)
	return active

func _active_controlled_selection() -> Array[int]:
	var controlled: Array[int] = []
	for index in _active_selection():
		if _can_control_token(index):
			controlled.append(index)
	return controlled

func _move_selected_to(target: Vector2) -> void:
	if selected_token < 0 or selected_token >= tokens.size():
		return
	var delta := target - tokens[selected_token].position
	for index in _active_controlled_selection():
		tokens[index].position += delta
	_update_fog_vision()
	token_motion_changed.emit()

func _snap_selected_tokens() -> void:
	for index in _active_controlled_selection():
		tokens[index].position = _snap(tokens[index].position)

func _token_at(point: Vector2) -> int:
	for index in range(tokens.size() - 1, -1, -1):
		if tokens[index].contains_point(point):
			return index
	return -1

func _remove_token(index: int) -> void:
	_record_history()
	tokens[index].queue_free()
	tokens.remove_at(index)
	selected_token = -1
	selected_tokens.clear()
	tokens_changed.emit()

func _history_snapshot() -> Dictionary:
	return {"tokens": export_tokens(), "fog": export_fog(), "drawings": export_drawings()}

func _record_history() -> void:
	if history_restoring:
		return
	var snapshot := _history_snapshot()
	if not undo_stack.is_empty() and JSON.stringify(undo_stack.back()) == JSON.stringify(snapshot):
		return
	undo_stack.append(snapshot)
	if undo_stack.size() > MAX_HISTORY:
		undo_stack.pop_front()
	redo_stack.clear()
	history_changed.emit(not undo_stack.is_empty(), false)

func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(_history_snapshot())
	_restore_history_snapshot(undo_stack.pop_back())

func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(_history_snapshot())
	_restore_history_snapshot(redo_stack.pop_back())

func clear_history() -> void:
	undo_stack.clear()
	redo_stack.clear()
	history_changed.emit(false, false)

func _restore_history_snapshot(snapshot: Dictionary) -> void:
	history_restoring = true
	import_tokens(snapshot.get("tokens", []))
	import_fog(snapshot.get("fog", {}))
	import_drawings(snapshot.get("drawings", []))
	history_restoring = false
	tokens_changed.emit()
	fog_changed.emit()
	drawings_changed.emit()
	history_changed.emit(not undo_stack.is_empty(), not redo_stack.is_empty())

func _snap(point: Vector2) -> Vector2:
	var snapped := Vector2(floor(point.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE * 0.5, floor(point.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE * 0.5)
	if map_sprite.texture == null:
		return snapped.clamp(Vector2.ONE * (-EMPTY_WORLD_EXTENT + GRID_SIZE * 0.5), Vector2.ONE * (EMPTY_WORLD_EXTENT - GRID_SIZE * 0.5))
	return snapped.clamp(Vector2(24, 24), world_size - Vector2(24, 24))

func _snap_measure(point: Vector2) -> Vector2:
	var snapped := Vector2(round(point.x / GRID_SIZE) * GRID_SIZE, round(point.y / GRID_SIZE) * GRID_SIZE)
	if map_sprite.texture == null:
		return snapped.clamp(Vector2.ONE * -EMPTY_WORLD_EXTENT, Vector2.ONE * EMPTY_WORLD_EXTENT)
	return snapped.clamp(Vector2.ZERO, world_size)

func _configure_empty_world() -> void:
	var extent := Vector2.ONE * EMPTY_WORLD_EXTENT
	world_size = extent * 2.0
	grid.position = -extent
	grid.set_world_size(world_size)
	background.position = -extent
	background.size = world_size
	# La niebla conserva un área razonable; la cuadrícula sí continúa en todas direcciones.
	fog.set_world_size(Vector2(4096, 4096))

func _clamp_camera() -> void:
	if map_sprite.texture == null:
		var empty_half_visible := Vector2(get_viewport().size) / zoom_level * 0.5
		var empty_minimum := Vector2.ONE * -EMPTY_WORLD_EXTENT + empty_half_visible
		var empty_maximum := Vector2.ONE * EMPTY_WORLD_EXTENT - empty_half_visible
		empty_maximum = empty_maximum.max(empty_minimum)
		camera.position = camera.position.clamp(empty_minimum, empty_maximum)
		return
	var half_visible := Vector2(get_viewport().size) / zoom_level * 0.5
	var minimum := half_visible
	var maximum: Vector2 = world_size - half_visible
	if maximum.x < minimum.x: maximum.x = minimum.x
	if maximum.y < minimum.y: maximum.y = minimum.y
	camera.position = camera.position.clamp(minimum, maximum)
