extends SubViewportContainer

## Puente público de la mesa. La interfaz principal debe hablar con este nodo,
## y este nodo delega dibujo/cámara/fichas a TabletopWorld.
## Guía completa: res://GUIA_PROGRAMACION.md

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
signal transfer_progress(label: String, percent: float)
signal transfer_failed(message: String)
signal sheet_received(filename: String)
signal library_entry_received(bytes: PackedByteArray, sender_peer_id: int)
signal music_received(filename: String, bytes: PackedByteArray, paused: bool)

const CHUNK_TRANSFER_SCRIPT := preload("res://ChunkTransfer.gd")
const GIF_PLAYBACK_SCRIPT := preload("res://GifPlayback.gd")
const SHARED_SHEETS_DIR := "user://character_sheets"
const MAX_SHARED_SHEET_BYTES := 2 * 1024 * 1024

@onready var world: Node2D = $Viewport/TabletopWorld
var media_player: VideoStreamPlayer
var media_image: TextureRect
var media_gif_texture: Texture2D
var media_gif_frame := 0
var media_gif_elapsed := 0.0
var effect_overlay: ColorRect
var effect_tween: Tween
var horizontal_scroll: HScrollBar
var vertical_scroll: VScrollBar
var chunk_transfer: Node

var selected_token: int:
	get: return world.selected_token
var map_path: String:
	get: return world.map_path
var map_scale: float:
	get: return world.map_scale
	set(value): world.set_map_scale(value)

func _ready() -> void:
	stretch = true
	focus_mode = Control.FOCUS_ALL
	world.tokens_changed.connect(func(): tokens_changed.emit())
	world.token_motion_changed.connect(func(): token_motion_changed.emit())
	world.tool_changed.connect(func(mode: String): tool_changed.emit(mode))
	world.token_selected.connect(func(index: int): token_selected.emit(index))
	world.token_double_clicked.connect(func(index: int): token_double_clicked.emit(index))
	world.zoom_changed.connect(func(value: float): zoom_changed.emit(value))
	world.map_scale_changed.connect(func(value: float): map_scale_changed.emit(value))
	world.fog_changed.connect(func(): fog_changed.emit())
	world.locks_changed.connect(func(): locks_changed.emit())
	world.history_changed.connect(func(can_undo: bool, can_redo: bool): history_changed.emit(can_undo, can_redo))
	world.drawings_changed.connect(func(): drawings_changed.emit())
	chunk_transfer = CHUNK_TRANSFER_SCRIPT.new()
	chunk_transfer.name = "ChunkTransfer"
	chunk_transfer.transfer_progress.connect(func(kind: String, filename: String, percent: float):
		var kind_name := "Mapa" if kind == "map" else ("Animación" if kind == "media" else ("Música" if kind == "music" else ("Biblioteca" if kind == "library" else "Hoja")))
		transfer_progress.emit("%s: %s" % [kind_name, filename], percent)
	)
	chunk_transfer.transfer_completed.connect(_on_chunk_transfer_completed)
	chunk_transfer.transfer_failed.connect(func(message: String): transfer_failed.emit(message))
	add_child(chunk_transfer)
	media_player = VideoStreamPlayer.new()
	media_player.name = "SharedMedia"
	media_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	media_player.expand = true
	media_player.loop = true
	media_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media_player.modulate.a = 0.82
	media_player.z_index = 40
	add_child(media_player)
	media_image = TextureRect.new()
	media_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	media_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	media_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	media_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media_image.modulate.a = 0.82
	media_image.z_index = 40
	media_image.hide()
	add_child(media_image)
	effect_overlay = ColorRect.new()
	effect_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.color = Color.TRANSPARENT
	effect_overlay.z_index = 41
	add_child(effect_overlay)
	horizontal_scroll = HScrollBar.new()
	horizontal_scroll.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	horizontal_scroll.offset_top = -18
	horizontal_scroll.offset_right = -18
	horizontal_scroll.z_index = 60
	horizontal_scroll.value_changed.connect(func(value: float): world.set_camera_scroll(value, true))
	add_child(horizontal_scroll)
	vertical_scroll = VScrollBar.new()
	vertical_scroll.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	vertical_scroll.offset_left = -18
	vertical_scroll.offset_bottom = -18
	vertical_scroll.z_index = 60
	vertical_scroll.value_changed.connect(func(value: float): world.set_camera_scroll(value, false))
	add_child(vertical_scroll)
	set_process(true)

func _process(delta: float) -> void:
	if media_gif_texture != null:
		var playback: Vector2 = GIF_PLAYBACK_SCRIPT.advance(media_gif_texture, media_gif_frame, media_gif_elapsed, delta)
		media_gif_frame = int(playback.x)
		media_gif_elapsed = playback.y
		media_image.queue_redraw()
	if world == null or horizontal_scroll == null or vertical_scroll == null:
		return
	var state: Dictionary = world.get_camera_scroll_state()
	horizontal_scroll.min_value = float(state.min_x)
	horizontal_scroll.max_value = float(state.max_x)
	horizontal_scroll.page = float(state.page_x)
	horizontal_scroll.set_value_no_signal(float(state.x))
	vertical_scroll.min_value = float(state.min_y)
	vertical_scroll.max_value = float(state.max_y)
	vertical_scroll.page = float(state.page_y)
	vertical_scroll.set_value_no_signal(float(state.y))

func add_token(position := Vector2(-1, -1)) -> void: world.add_token(position)
func nudge_selected_token_for_spawn(offset: Vector2) -> void: world.nudge_selected_token_for_spawn(offset)
func clear_tokens() -> void: world.clear_tokens()
func set_selected_color(color: Color) -> void: world.set_selected_color(color)
func set_selected_image(path: String) -> bool:
	var token_index: int = int(world.selected_token)
	var result: bool = world.set_selected_image(path)
	if not result:
		return false
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() <= 8 * 1024 * 1024:
			sync_token_image.rpc(token_index, path.get_file(), bytes)
	return true
func set_selected_sheet(filename: String) -> void:
	world.set_selected_sheet(filename)
	var peer := multiplayer.multiplayer_peer
	if multiplayer.is_server() and peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		share_sheet_to_all(filename)
func set_selected_sheet_snapshot(character_name: String, current: float, maximum: float) -> void: world.set_selected_sheet_snapshot(character_name, current, maximum)
func set_token_hit_points(token_index: int, current: float, maximum: float) -> void: world.set_token_hit_points(token_index, current, maximum)
func get_selected_sheet() -> String: return world.get_selected_sheet()
func set_selected_status_effects(effects: Array) -> void: world.set_selected_status_effects(effects)
func set_token_status_effects(token_index: int, effects: Array) -> void: world.set_token_status_effects(token_index, effects)
func get_selected_status_effects() -> Array[String]: return world.get_selected_status_effects()
func set_selected_vision(feet: float) -> void: world.set_selected_vision(feet)
func get_selected_vision() -> float: return world.get_selected_vision()
func set_local_player_name(value: String) -> void: world.set_local_player_name(value)
func set_selected_owner(value: String, player_id := "") -> void: world.set_selected_owner(value, player_id)
func get_selected_owner() -> String: return world.get_selected_owner()
func get_selected_owner_id() -> String: return world.get_selected_owner_id()
func set_local_player_id(value: String) -> void: world.set_local_player_id(value)
func set_online_players(players: Dictionary) -> void:
	# La interfaz se construye antes de que @onready resuelva el mundo interno.
	if world != null:
		world.set_online_players(players)
func export_tokens() -> Array: return world.export_tokens()
func export_token_positions() -> Array: return world.export_token_positions()
func import_tokens(data: Array) -> void: world.import_tokens(data)
func set_zoom(value: float) -> void: world.set_zoom(value)
func zoom_in() -> void: world.zoom_in()
func zoom_out() -> void: world.zoom_out()
func reset_zoom() -> void: world.reset_zoom()
func load_map(path: String) -> bool: return world.load_map(path)
func grow_map() -> void: world.grow_map()
func shrink_map() -> void: world.shrink_map()
func fit_map() -> void: world.fit_map()
func clear_map() -> void: world.clear_map()
func set_map_scale(value: float) -> void: world.set_map_scale(value)
func set_tool(mode: String) -> void: world.set_tool(mode)
func clear_template() -> void: world.clear_template()
func set_director_mode(enabled: bool) -> void: world.set_director_mode(enabled)
func cover_with_fog() -> void: world.cover_with_fog()
func clear_fog() -> void: world.clear_fog()
func export_fog() -> Dictionary: return world.export_fog()
func import_fog(data: Dictionary) -> void: world.import_fog(data)
func set_tokens_locked(value: bool) -> void: world.set_tokens_locked(value)
func set_map_locked(value: bool) -> void: world.set_map_locked(value)
func export_locks() -> Dictionary: return world.export_locks()
func import_locks(data: Dictionary) -> void: world.import_locks(data)
func undo() -> void: world.undo()
func redo() -> void: world.redo()
func clear_history() -> void: world.clear_history()
func set_group_selection_mode(enabled: bool) -> void: world.set_group_selection_mode(enabled)
func duplicate_selected_tokens() -> void: world.duplicate_selected_tokens()
func set_drawing_style(color: Color, width: float) -> void: world.set_drawing_style(color, width)
func clear_drawings() -> void: world.clear_drawings()
func export_drawings() -> Array: return world.export_drawings()
func import_drawings(data: Array) -> void: world.import_drawings(data)
func cancel_transfers() -> void:
	if chunk_transfer != null:
		chunk_transfer.cancel_all()

func send_map_to_peer(peer_id: int) -> void:
	if world.map_path.is_empty() or not FileAccess.file_exists(world.map_path):
		sync_map_image.rpc_id(peer_id, "", PackedByteArray(), 1.0)
		return
	var prepared: Dictionary = _prepare_map_transfer(world.map_path)
	if not prepared.is_empty():
		var bytes: PackedByteArray = prepared.get("bytes", PackedByteArray())
		chunk_transfer.queue_transfer(peer_id, "map", str(prepared.get("filename", "mapa.jpg")), bytes, {"scale": world.map_scale})

func send_sheet_to_peer(peer_id: int, filename: String) -> bool:
	if not multiplayer.is_server():
		return false
	var safe_name := filename.get_file().validate_filename()
	if safe_name.get_extension().to_lower() != "json":
		return false
	var path := SHARED_SHEETS_DIR + "/" + safe_name
	if not FileAccess.file_exists(path):
		return false
	var bytes := FileAccess.get_file_as_bytes(path)
	if not _valid_shared_sheet(bytes):
		return false
	return chunk_transfer.queue_transfer(peer_id, "sheet", safe_name, bytes)

func send_token_images_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id not in multiplayer.get_peers():
		return
	var token_data: Array = world.export_tokens()
	for token_index in range(token_data.size()):
		if not token_data[token_index] is Dictionary:
			continue
		var image_path := str(token_data[token_index].get("image_path", ""))
		if image_path.is_empty() or not FileAccess.file_exists(image_path):
			continue
		var bytes := FileAccess.get_file_as_bytes(image_path)
		if bytes.is_empty() or bytes.size() > 8 * 1024 * 1024:
			continue
		sync_token_image.rpc_id(peer_id, token_index, image_path.get_file(), bytes)

func share_sheet_to_all(filename: String) -> bool:
	if not multiplayer.is_server():
		return false
	var queued := false
	for peer_id in multiplayer.get_peers():
		queued = send_sheet_to_peer(peer_id, filename) or queued
	return queued

func share_library_entry_to_all(filename: String, bytes: PackedByteArray) -> bool:
	if not multiplayer.is_server() or bytes.is_empty() or bytes.size() > 8 * 1024 * 1024:
		return false
	return chunk_transfer.queue_transfer_to_all("library", filename.get_file(), bytes)

func share_library_entry(filename: String, bytes: PackedByteArray) -> bool:
	if bytes.is_empty() or bytes.size() > 8 * 1024 * 1024:
		return false
	if multiplayer.is_server():
		return share_library_entry_to_all(filename, bytes)
	return chunk_transfer.queue_transfer(1, "library", filename.get_file(), bytes)

func _valid_shared_sheet(bytes: PackedByteArray) -> bool:
	if bytes.is_empty() or bytes.size() > MAX_SHARED_SHEET_BYTES:
		return false
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK:
		return false
	var parsed: Variant = parser.data
	return parsed is Dictionary and parsed.get("metadata", {}) is Dictionary and parsed.get("fields", {}) is Dictionary

func share_current_map() -> void:
	if world.map_path.is_empty() or not FileAccess.file_exists(world.map_path):
		sync_map_image.rpc("", PackedByteArray(), 1.0)
		return
	var prepared: Dictionary = _prepare_map_transfer(world.map_path)
	if not prepared.is_empty():
		var bytes: PackedByteArray = prepared.get("bytes", PackedByteArray())
		chunk_transfer.queue_transfer_to_all("map", str(prepared.get("filename", "mapa.jpg")), bytes, {"scale": world.map_scale})

func _prepare_map_transfer(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		transfer_failed.emit("El archivo del mapa ya no está disponible.")
		return {}
	var original: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	if image.load(path) != OK:
		transfer_failed.emit("No se pudo preparar el mapa para enviarlo.")
		return {}
	var largest: int = maxi(image.get_width(), image.get_height())
	# Los mapas pequeños mantienen el archivo original. Los grandes se reducen y
	# comprimen para ahorrar memoria y datos móviles.
	if largest <= 4096 and original.size() <= 8 * 1024 * 1024:
		return {"filename": path.get_file(), "bytes": original}
	if largest > 4096:
		var ratio: float = 4096.0 / float(largest)
		image.resize(roundi(image.get_width() * ratio), roundi(image.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	var optimized: PackedByteArray = image.save_jpg_to_buffer(0.88)
	if optimized.is_empty() or optimized.size() > 30 * 1024 * 1024:
		transfer_failed.emit("El mapa sigue siendo demasiado grande después de optimizarlo.")
		return {}
	return {"filename": path.get_basename().get_file() + "_optimizado.jpg", "bytes": optimized}

func share_map_scale(scale: float) -> void:
	sync_map_scale.rpc(scale)

@rpc("authority", "call_remote", "reliable")
func sync_map_scale(scale: float) -> void:
	var was_locked: bool = world.map_locked
	world.map_locked = false
	world.set_map_scale(scale)
	world.map_locked = was_locked

@rpc("authority", "call_remote", "reliable")
func sync_map_image(filename: String, bytes: PackedByteArray, scale: float) -> void:
	var was_locked: bool = world.map_locked
	world.map_locked = false
	if filename.is_empty():
		world.clear_map()
	else:
		var safe_name: String = filename.get_file().validate_filename()
		if safe_name.get_extension().to_lower() not in ["png", "jpg", "jpeg"] or bytes.is_empty() or bytes.size() > 30 * 1024 * 1024:
			world.map_locked = was_locked
			return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shared_maps"))
		var path := "user://shared_maps/" + safe_name
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			world.map_locked = was_locked
			return
		file.store_buffer(bytes)
		file.close()
		if world.load_map(path):
			world.set_map_scale(scale)
	world.map_locked = was_locked

@rpc("authority", "call_remote", "reliable")
func sync_fog(data: Dictionary) -> void:
	world.import_fog(data)

@rpc("authority", "call_remote", "reliable")
func sync_locks(data: Dictionary) -> void:
	world.import_locks(data)

@rpc("authority", "call_remote", "reliable")
func sync_drawings(data: Array) -> void:
	world.import_drawings(data)

func play_table_video(path: String) -> bool:
	if path.get_extension().to_lower() != "ogv" or not FileAccess.file_exists(path):
		return false
	_stop_builtin_effect()
	var stream := VideoStreamTheora.new()
	stream.file = path
	media_gif_texture = null
	media_gif_frame = 0
	media_gif_elapsed = 0.0
	media_player.stream = stream
	media_image.hide()
	media_player.show()
	media_player.play()
	return true

func play_table_gif(path: String) -> bool:
	if path.get_extension().to_lower() != "gif" or not FileAccess.file_exists(path):
		return false
	_stop_builtin_effect()
	var gif_texture: Texture2D = GIF_PLAYBACK_SCRIPT.load_texture(path)
	if gif_texture == null:
		return false
	media_player.stop()
	media_player.hide()
	media_gif_texture = gif_texture
	media_gif_frame = 0
	media_gif_elapsed = 0.0
	media_image.texture = gif_texture
	media_image.show()
	return true

func stop_table_media() -> void:
	_stop_builtin_effect()
	media_player.stop()
	media_player.stream = null
	media_gif_texture = null
	media_gif_frame = 0
	media_gif_elapsed = 0.0
	media_image.texture = null
	media_image.hide()
	effect_overlay.color = Color.TRANSPARENT

func _stop_builtin_effect() -> void:
	if effect_tween != null and effect_tween.is_valid():
		effect_tween.kill()
	effect_tween = null
	if effect_overlay != null:
		effect_overlay.color = Color.TRANSPARENT

func stop_and_share_table_media() -> void:
	stop_table_media()
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		sync_stop_table_media.rpc()

@rpc("authority", "call_remote", "reliable")
func sync_stop_table_media() -> void:
	stop_table_media()

func play_builtin_effect(kind: String) -> void:
	# Una sola escena global puede estar activa. Esto evita que Tweens antiguos
	# vuelvan a encender la pantalla después de pulsar Detener.
	media_player.stop()
	media_player.stream = null
	media_player.hide()
	media_gif_texture = null
	media_image.texture = null
	media_image.hide()
	_stop_builtin_effect()
	var color := Color(0.44, 0.21, 0.79, 0.0)
	match kind:
		"Fuego": color = Color(0.95, 0.18, 0.05, 0.0)
		"Hielo": color = Color(0.2, 0.75, 1.0, 0.0)
		"Oscuridad": color = Color(0.02, 0.01, 0.08, 0.0)
		"Curación": color = Color(0.1, 0.95, 0.4, 0.0)
		_: color = Color(0.55, 0.18, 0.95, 0.0)
	effect_tween = create_tween()
	var active_tween := effect_tween
	active_tween.set_loops(3)
	active_tween.tween_property(effect_overlay, "color", Color(color, 0.38), 0.32)
	active_tween.tween_property(effect_overlay, "color", Color(color, 0.04), 0.55)
	active_tween.finished.connect(func():
		if effect_tween == active_tween:
			effect_overlay.color = Color.TRANSPARENT
			effect_tween = null
	)

func share_table_media(path: String) -> bool:
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var transfer_size: int = FileAccess.get_file_as_bytes(path).size()
		if transfer_size > 50 * 1024 * 1024:
			transfer_failed.emit("La animación supera 50 MB. Convierte el vídeo a menor resolución o duración.")
			return false
	var extension := path.get_extension().to_lower()
	# Tipo explícito: evita que el analizador pierda la inferencia si alguna rama cambia.
	var played: bool = play_table_gif(path) if extension == "gif" else play_table_video(path)
	if not played:
		return false
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() <= 50 * 1024 * 1024:
			chunk_transfer.queue_transfer_to_all("media", path.get_file(), bytes)
	return true

func send_table_media_to_peer(peer_id: int, path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() <= 50 * 1024 * 1024:
		chunk_transfer.queue_transfer(peer_id, "media", path.get_file(), bytes)
	else:
		transfer_failed.emit("La animación supera 50 MB y no puede enviarse al jugador que acaba de entrar.")

func send_music_to_peer(peer_id: int, path: String, paused := false) -> bool:
	if not multiplayer.is_server() or peer_id not in multiplayer.get_peers() or not FileAccess.file_exists(path):
		return false
	if path.get_extension().to_lower() not in ["mp3", "ogg", "wav"]:
		return false
	return chunk_transfer.queue_transfer(peer_id, "music", path.get_file(), FileAccess.get_file_as_bytes(path), {"paused": paused})

func share_music_to_all(path: String) -> bool:
	if not multiplayer.is_server() or not FileAccess.file_exists(path):
		return false
	if path.get_extension().to_lower() not in ["mp3", "ogg", "wav"]:
		return false
	return chunk_transfer.queue_transfer_to_all("music", path.get_file(), FileAccess.get_file_as_bytes(path))

## Punto central de recepción: cada `kind` debe validarse antes de tocar disco.
func _on_chunk_transfer_completed(kind: String, filename: String, bytes: PackedByteArray, metadata: Dictionary) -> void:
	if kind == "map":
		sync_map_image(filename, bytes, float(metadata.get("scale", 1.0)))
	elif kind == "media":
		sync_table_media(filename, bytes)
	elif kind == "sheet":
		_store_received_sheet(filename, bytes)
	elif kind == "music" and bytes.size() <= 25 * 1024 * 1024:
		music_received.emit(filename, bytes, bool(metadata.get("paused", false)))
	elif kind == "library" and bytes.size() <= 8 * 1024 * 1024:
		library_entry_received.emit(bytes, int(metadata.get("sender_peer_id", 0)))

func _store_received_sheet(filename: String, bytes: PackedByteArray) -> void:
	if multiplayer.is_server():
		return
	var safe_name := _save_valid_sheet_file(filename, bytes)
	if safe_name.is_empty():
		return
	sheet_received.emit(safe_name)

func _save_valid_sheet_file(filename: String, bytes: PackedByteArray) -> String:
	if not _valid_shared_sheet(bytes):
		return ""
	var safe_name := filename.get_file().validate_filename()
	if safe_name.get_extension().to_lower() != "json":
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHARED_SHEETS_DIR))
	var path := SHARED_SHEETS_DIR + "/" + safe_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_buffer(bytes)
	file.close()
	return safe_name

@rpc("authority", "call_remote", "reliable")
func sync_table_media(filename: String, bytes: PackedByteArray) -> void:
	if bytes.is_empty() or bytes.size() > 50 * 1024 * 1024:
		return
	var safe_name := filename.get_file().validate_filename()
	if safe_name.get_extension().to_lower() not in ["ogv", "gif"]:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shared_table_media"))
	var path := "user://shared_table_media/" + safe_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(bytes)
	file.close()
	if safe_name.get_extension().to_lower() == "gif":
		play_table_gif(path)
	else:
		play_table_video(path)

@rpc("authority", "call_remote", "reliable")
func sync_builtin_effect(kind: String) -> void:
	play_builtin_effect(kind)

@rpc("any_peer", "call_remote", "reliable")
func sync_token_image(token_index: int, filename: String, bytes: PackedByteArray) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	# El anfitrión rechaza imágenes destinadas a fichas ajenas antes de escribirlas
	# en disco o compartirlas con el resto de la mesa.
	if multiplayer.is_server() and sender_id != 0 and not world.can_peer_control_token(sender_id, token_index):
		return
	if bytes.is_empty() or bytes.size() > 8 * 1024 * 1024:
		return
	var safe_name := filename.get_file().validate_filename()
	if safe_name.get_extension().to_lower() not in ["png", "jpg", "jpeg", "webp", "gif"]:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shared_token_media"))
	var path := "user://shared_token_media/%d_%s" % [token_index, safe_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(bytes)
	file.close()
	# En los clientes, una imagen recibida del servidor es estado remoto y no
	# debe disparar tokens_changed: hacerlo reenviaría una ruta user:// privada.
	var notify_local_change := multiplayer.is_server() and sender_id != 0
	world.set_token_image(token_index, path, notify_local_change)
	if multiplayer.is_server() and sender_id != 0:
		sync_token_image.rpc(token_index, filename, bytes)

@rpc("any_peer", "call_remote", "reliable")
func sync_tokens(data: Array) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and sender_id != 0:
		# Nunca se retransmite directamente el estado propuesto por un cliente.
		# Solo se aplican los campos de las fichas que realmente le pertenecen.
		var safe_data: Array = world.validate_peer_token_data(sender_id, data)
		world.import_tokens(safe_data)
		sync_tokens.rpc(safe_data)
		return
	world.import_tokens(data)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func sync_token_positions(data: Array) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and sender_id != 0:
		world.apply_peer_token_positions(sender_id, data)
		var safe_positions: Array = world.export_token_positions()
		# El jugador que originó el movimiento ya tiene esa posición localmente.
		# Evitar devolvérsela mantiene intacto su arrastre y selección.
		for peer_id in multiplayer.get_peers():
			if peer_id != sender_id:
				sync_token_positions.rpc_id(peer_id, safe_positions)
		return
	world.apply_token_positions(data)
