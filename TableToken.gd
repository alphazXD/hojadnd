extends Node2D

const GIF_PLAYBACK_SCRIPT := preload("res://GifPlayback.gd")

const RADIUS := 18.0
var token_color := Color("#d45d52")
var token_label := "1"
var image_path := ""
var sheet_file := ""
var status_effects: Array[String] = []
var character_name := ""
var hp_current := 0.0
var hp_max := 1.0
var vision_feet := 30.0
var owner_name := ""
var owner_id := ""
var selected := false
var portrait_gif_texture: Texture2D
var portrait_gif_frame := 0
var portrait_gif_elapsed := 0.0

@onready var portrait: Sprite2D = $Portrait

func _ready() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec2 p = UV - vec2(0.5); if(length(p) > 0.5) discard; COLOR = texture(TEXTURE, UV) * COLOR; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	portrait.material = material
	queue_redraw()
	set_process(true)

func _process(delta: float) -> void:
	if portrait_gif_texture == null:
		return
	var playback: Vector2 = GIF_PLAYBACK_SCRIPT.advance(portrait_gif_texture, portrait_gif_frame, portrait_gif_elapsed, delta)
	portrait_gif_frame = int(playback.x)
	portrait_gif_elapsed = playback.y
	portrait.queue_redraw()

func configure(data: Dictionary) -> void:
	position = data.get("position", Vector2.ZERO)
	token_color = data.get("color", token_color)
	token_label = str(data.get("label", token_label))
	image_path = str(data.get("image_path", ""))
	sheet_file = str(data.get("sheet_file", ""))
	character_name = str(data.get("character_name", ""))
	hp_current = float(data.get("hp_current", 0.0))
	hp_max = maxf(float(data.get("hp_max", 1.0)), 1.0)
	vision_feet = maxf(float(data.get("vision_feet", 30.0)), 0.0)
	owner_name = str(data.get("owner_name", "")).strip_edges()
	owner_id = str(data.get("owner_id", "")).strip_edges()
	status_effects.clear()
	for effect in data.get("status_effects", []):
		var clean := str(effect).strip_edges()
		if not clean.is_empty():
			status_effects.append(clean)
	_load_portrait()
	queue_redraw()

func set_portrait(path: String) -> bool:
	if path.get_extension().to_lower() == "gif":
		return _apply_gif(path)
	var image := Image.new()
	if image.load(path) != OK:
		return false
	image_path = path
	_apply_image(image)
	return true

func contains_point(world_point: Vector2) -> bool:
	return position.distance_to(world_point) <= RADIUS + 5.0

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func set_status_effects(value: Array) -> void:
	status_effects.clear()
	for effect in value:
		var clean := str(effect).strip_edges()
		if not clean.is_empty():
			status_effects.append(clean)
	queue_redraw()

func set_sheet_snapshot(new_name: String, current: float, maximum: float) -> void:
	character_name = new_name
	hp_current = current
	hp_max = maxf(maximum, 1.0)

func to_data() -> Dictionary:
	return {"position": position, "color": token_color, "label": token_label, "image_path": image_path, "sheet_file": sheet_file, "status_effects": status_effects, "character_name": character_name, "hp_current": hp_current, "hp_max": hp_max, "vision_feet": vision_feet, "owner_name": owner_name, "owner_id": owner_id}

func _load_portrait() -> void:
	portrait_gif_texture = null
	portrait_gif_frame = 0
	portrait_gif_elapsed = 0.0
	portrait.texture = null
	if image_path.is_empty():
		return
	if image_path.get_extension().to_lower() == "gif":
		_apply_gif(image_path)
		return
	var image := Image.new()
	if image.load(image_path) == OK:
		_apply_image(image)

func _apply_image(image: Image) -> void:
	portrait_gif_texture = null
	var side := mini(image.get_width(), image.get_height())
	var offset := Vector2i((image.get_width() - side) / 2, (image.get_height() - side) / 2)
	var square := image.get_region(Rect2i(offset, Vector2i(side, side)))
	square.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	portrait.texture = ImageTexture.create_from_image(square)
	portrait.scale = Vector2(32.0 / 64.0, 32.0 / 64.0)
	queue_redraw()

func _apply_gif(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var gif_texture: Texture2D = GIF_PLAYBACK_SCRIPT.load_texture(path)
	if gif_texture == null:
		return false
	image_path = path
	portrait_gif_texture = gif_texture
	portrait_gif_frame = 0
	portrait_gif_elapsed = 0.0
	portrait.texture = gif_texture
	var gif_size: Vector2 = gif_texture.get_size()
	var largest := maxf(gif_size.x, gif_size.y)
	portrait.scale = Vector2.ONE * (32.0 / maxf(largest, 1.0))
	queue_redraw()
	return true

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, token_color)
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE if selected else token_color.lightened(0.35), false, 3.0)
	if portrait.texture == null:
		draw_string(ThemeDB.fallback_font, Vector2(-7, 6), token_label, HORIZONTAL_ALIGNMENT_CENTER, 14, 15, Color.WHITE)
	if not status_effects.is_empty():
		draw_circle(Vector2(13, -14), 7.0, Color("#6f3fa6"))
		draw_string(ThemeDB.fallback_font, Vector2(9, -10), str(status_effects.size()), HORIZONTAL_ALIGNMENT_CENTER, 9, 11, Color.WHITE)
