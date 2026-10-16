extends Control

signal tokens_changed
signal token_selected(index: int)
signal token_double_clicked(index: int)
signal zoom_changed(value: float)
signal map_scale_changed(value: float)

const GRID_SIZE := 48.0
var tokens: Array[Dictionary] = []
var selected_token := -1
var dragging := false
var token_colors := [Color("#d45d52"), Color("#4f91d1"), Color("#69ae68"), Color("#c89a49"), Color("#9b6dca")]
var zoom_level := 1.0
var map_texture: Texture2D
var map_path := ""
var map_scale := 1.0
var tool_mode := "select"
var measure_start := Vector2.ZERO
var measure_end := Vector2.ZERO
var measuring := false

func _ready() -> void:
	custom_minimum_size = Vector2(760, 620)
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#dce1eb"), true)
	if map_texture != null:
		var map_size := map_texture.get_size() * map_scale * zoom_level
		var map_offset := (size - map_size) * 0.5
		draw_texture_rect(map_texture, Rect2(map_offset, map_size), false)
	var grid_color := Color("#c7ceda")
	var strong_color := Color("#aeb8c8")
	var scaled_grid := GRID_SIZE * zoom_level
	var x := 0.0
	var column := 0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), strong_color if column % 5 == 0 else grid_color, 2.0 if column % 5 == 0 else 1.0)
		x += scaled_grid
		column += 1
	var y := 0.0
	var row := 0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), strong_color if row % 5 == 0 else grid_color, 2.0 if row % 5 == 0 else 1.0)
		y += scaled_grid
		row += 1
	for index in range(tokens.size()):
		var token: Dictionary = tokens[index]
		var position: Vector2 = token.position * zoom_level
		var color: Color = token.color
		draw_circle(position, 18.0, color)
		if token.get("texture") is Texture2D:
			draw_texture_rect(token.texture, Rect2(position - Vector2(16, 16), Vector2(32, 32)), false)
		draw_circle(position, 18.0, Color.WHITE if index == selected_token else color.lightened(0.35), false, 3.0)
		if not token.get("texture") is Texture2D:
			draw_string(ThemeDB.fallback_font, position + Vector2(-7, 6), str(token.label), HORIZONTAL_ALIGNMENT_CENTER, 14, 15, Color.WHITE)
	_draw_measurement()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(zoom_level + 0.1)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(zoom_level - 0.1)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			grab_focus()
			var world_position: Vector2 = event.position / zoom_level
			if tool_mode != "select":
				measure_start = world_position
				measure_end = world_position
				measuring = true
				queue_redraw()
				return
			selected_token = _token_at(world_position)
			if event.double_click and selected_token == -1:
				add_token(world_position)
			elif event.double_click and selected_token >= 0:
				dragging = false
				token_double_clicked.emit(selected_token)
			elif selected_token >= 0:
				dragging = true
				token_selected.emit(selected_token)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if measuring:
				measure_end = event.position / zoom_level
				measuring = false
				queue_redraw()
				return
			if dragging:
				tokens_changed.emit()
			dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var index := _token_at(event.position / zoom_level)
			if index >= 0:
				tokens.remove_at(index)
				selected_token = -1
				tokens_changed.emit()
				queue_redraw()
	elif event is InputEventMouseMotion and dragging and selected_token >= 0:
		tokens[selected_token].position = _snap_to_grid(event.position / zoom_level)
		queue_redraw()
	elif event is InputEventMouseMotion and measuring:
		measure_end = event.position / zoom_level
		queue_redraw()
	elif event is InputEventKey and event.pressed and selected_token >= 0:
		var direction := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: direction = Vector2.LEFT
			KEY_RIGHT: direction = Vector2.RIGHT
			KEY_UP: direction = Vector2.UP
			KEY_DOWN: direction = Vector2.DOWN
		if direction != Vector2.ZERO:
			tokens[selected_token].position += direction * GRID_SIZE
			tokens[selected_token].position = tokens[selected_token].position.clamp(Vector2(24, 24), size / zoom_level - Vector2(24, 24))
			tokens_changed.emit()
			queue_redraw()
			accept_event()

func add_token(position := Vector2(-1, -1)) -> void:
	var target: Vector2 = position
	if target.x < 0:
		target = Vector2(size.x * 0.5, size.y * 0.5)
	var number := tokens.size() + 1
	tokens.append({"position": _snap_to_grid(target), "color": token_colors[(number - 1) % token_colors.size()], "label": str(number), "image_path": "", "texture": null, "sheet_file": ""})
	selected_token = tokens.size() - 1
	token_selected.emit(selected_token)
	tokens_changed.emit()
	queue_redraw()

func clear_tokens() -> void:
	tokens.clear()
	selected_token = -1
	tokens_changed.emit()
	queue_redraw()

func set_selected_color(color: Color) -> void:
	if selected_token < 0 or selected_token >= tokens.size():
		return
	tokens[selected_token].color = color
	tokens_changed.emit()
	queue_redraw()

func set_selected_image(path: String) -> bool:
	if selected_token < 0 or selected_token >= tokens.size():
		return false
	var image := Image.new()
	if image.load(path) != OK:
		return false
	var texture := _make_round_texture(image)
	tokens[selected_token].image_path = path
	tokens[selected_token].texture = texture
	tokens_changed.emit()
	queue_redraw()
	return true

func set_selected_sheet(filename: String) -> void:
	if selected_token < 0 or selected_token >= tokens.size():
		return
	tokens[selected_token].sheet_file = filename
	tokens_changed.emit()

func get_selected_sheet() -> String:
	if selected_token < 0 or selected_token >= tokens.size():
		return ""
	return str(tokens[selected_token].get("sheet_file", ""))

func export_tokens() -> Array:
	var result := []
	for token in tokens:
		result.append({
			"x": token.position.x,
			"y": token.position.y,
			"color": token.color.to_html(true),
			"label": token.label,
			"image_path": token.get("image_path", ""),
			"sheet_file": token.get("sheet_file", "")
		})
	return result

func import_tokens(data: Array) -> void:
	tokens.clear()
	for saved in data:
		if not saved is Dictionary:
			continue
		var image_path := str(saved.get("image_path", ""))
		var texture: Texture2D = null
		if not image_path.is_empty():
			var image := Image.new()
			if image.load(image_path) == OK:
				texture = _make_round_texture(image)
		tokens.append({
			"position": Vector2(float(saved.get("x", 48)), float(saved.get("y", 48))),
			"color": Color.from_string(str(saved.get("color", "d45d52ff")), Color("#d45d52")),
			"label": str(saved.get("label", tokens.size() + 1)),
			"image_path": image_path,
			"texture": texture,
			"sheet_file": str(saved.get("sheet_file", ""))
		})
	selected_token = -1
	queue_redraw()

func _token_at(position: Vector2) -> int:
	for index in range(tokens.size() - 1, -1, -1):
		if position.distance_to(tokens[index].position) <= 22.0:
			return index
	return -1

func _snap_to_grid(position: Vector2) -> Vector2:
	return Vector2(floor(position.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE * 0.5, floor(position.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE * 0.5).clamp(Vector2(24, 24), size / zoom_level - Vector2(24, 24))

func _make_round_texture(source: Image) -> ImageTexture:
	var side := mini(source.get_width(), source.get_height())
	var offset := Vector2i((source.get_width() - side) / 2, (source.get_height() - side) / 2)
	var image := source.get_region(Rect2i(offset, Vector2i(side, side)))
	image.convert(Image.FORMAT_RGBA8)
	image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	var center := Vector2(63.5, 63.5)
	for y in range(128):
		for x in range(128):
			if Vector2(x, y).distance_to(center) > 63.5:
				var pixel := image.get_pixel(x, y)
				pixel.a = 0.0
				image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func set_zoom(value: float) -> void:
	zoom_level = clampf(value, 0.5, 2.5)
	_update_map_canvas_size()
	zoom_changed.emit(zoom_level)
	queue_redraw()

func zoom_in() -> void:
	set_zoom(zoom_level + 0.1)

func zoom_out() -> void:
	set_zoom(zoom_level - 0.1)

func reset_zoom() -> void:
	set_zoom(1.0)

func set_tool(mode: String) -> void:
	tool_mode = mode
	measuring = false
	if mode == "select":
		measure_start = Vector2.ZERO
		measure_end = Vector2.ZERO
	queue_redraw()

func clear_template() -> void:
	measure_start = Vector2.ZERO
	measure_end = Vector2.ZERO
	measuring = false
	queue_redraw()

func load_map(path: String) -> bool:
	var image := Image.new()
	if image.load(path) != OK:
		return false
	var largest_side := maxi(image.get_width(), image.get_height())
	if largest_side > 4096:
		var reduction := 4096.0 / float(largest_side)
		image.resize(maxi(1, roundi(image.get_width() * reduction)), maxi(1, roundi(image.get_height() * reduction)), Image.INTERPOLATE_LANCZOS)
	map_texture = ImageTexture.create_from_image(image)
	map_path = path
	map_scale = 1.0
	_update_map_canvas_size()
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()
	queue_redraw()
	return true

func grow_map() -> void:
	map_scale = clampf(map_scale * 1.25, 0.1, 5.0)
	_update_map_canvas_size()
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()
	queue_redraw()

func set_map_scale(value: float) -> void:
	map_scale = clampf(value, 0.1, 5.0)
	_update_map_canvas_size()
	map_scale_changed.emit(map_scale)
	queue_redraw()

func shrink_map() -> void:
	map_scale = clampf(map_scale * 0.8, 0.1, 5.0)
	_update_map_canvas_size()
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()
	queue_redraw()

func fit_map() -> void:
	if map_texture == null:
		return
	var visible_size := size
	if get_parent() is ScrollContainer:
		visible_size = get_parent().size
	# Modo "cubrir": llena el tablero y recorta el exceso de forma centrada.
	map_scale = maxf(visible_size.x / map_texture.get_width(), visible_size.y / map_texture.get_height()) / zoom_level
	custom_minimum_size = visible_size
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()
	queue_redraw()

func clear_map() -> void:
	map_texture = null
	map_path = ""
	map_scale = 1.0
	custom_minimum_size = Vector2(760, 620)
	map_scale_changed.emit(map_scale)
	tokens_changed.emit()
	queue_redraw()

func _update_map_canvas_size() -> void:
	if map_texture == null:
		return
	var scaled_size := map_texture.get_size() * map_scale * zoom_level
	custom_minimum_size = Vector2(maxf(760.0, scaled_size.x), maxf(620.0, scaled_size.y))

func _draw_measurement() -> void:
	if measure_start == measure_end:
		return
	var start := measure_start * zoom_level
	var finish := measure_end * zoom_level
	var color := Color("#dc594f", 0.75)
	var distance_feet := measure_start.distance_to(measure_end) / GRID_SIZE * 5.0
	if tool_mode == "ruler":
		draw_line(start, finish, color, 4.0)
	elif tool_mode == "sphere":
		draw_circle(start, start.distance_to(finish), color, false, 4.0)
	elif tool_mode == "cone":
		var direction := (finish - start).normalized()
		var perpendicular := Vector2(-direction.y, direction.x)
		var half_width := start.distance_to(finish) * 0.5
		var points := PackedVector2Array([start, finish + perpendicular * half_width, finish - perpendicular * half_width])
		draw_colored_polygon(points, Color(color, 0.25))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), color, 4.0)
	var label_position := finish + Vector2(10, -10)
	draw_string(ThemeDB.fallback_font, label_position, "%d pies" % roundi(distance_feet), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#7b1e1a"))

@rpc("any_peer", "call_remote", "reliable")
func sync_tokens(data: Array) -> void:
	import_tokens(data)
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		sync_tokens.rpc(data)
