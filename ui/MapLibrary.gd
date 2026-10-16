class_name MapLibraryView
extends PanelContainer

## Biblioteca de mapas de la mesa.
##
## NOTA PARA EL FUTURO:
## Este archivo es el lugar correcto para modificar todo lo relacionado con
## guardar, listar, abrir o eliminar mapas. La cámara, cuadrícula y movimiento
## de fichas siguen en TabletopWorld.gd.

signal add_map_requested
signal status_requested(message: String, is_error: bool)
signal state_changed

# PERSONALIZACIÓN: cambia esta ruta si quieres otra carpeta de almacenamiento.
const MAP_LIBRARY_DIR := "user://map_library"
const MAX_MAP_FILE_SIZE := 30 * 1024 * 1024

# Estas referencias se entregan desde CharacterSheet.gd mediante setup().
var table_board: Control
var current_map_id := ""
var current_map_display_name := ""
var loading_map := false

var map_list: ItemList

func setup(board: Control) -> void:
	table_board = board

func _ready() -> void:
	_build_interface()
	refresh_library()

func _build_interface() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	var title := Label.new()
	title.text = "▦  BIBLIOTECA DE MAPAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23) # PERSONALIZACIÓN: tamaño del título.
	body.add_child(title)
	var hint := Label.new()
	hint.text = "Cada mapa conserva su escala y la posición de todas sus fichas."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("#a99f89"))
	body.add_child(hint)
	map_list = ItemList.new()
	map_list.custom_minimum_size.y = 340 # PERSONALIZACIÓN: altura de la lista.
	map_list.item_activated.connect(func(_index: int): load_selected_map())
	body.add_child(map_list)
	var buttons := HFlowContainer.new()
	body.add_child(buttons)
	_add_button(buttons, "＋ Añadir mapa", func(): add_map_requested.emit())
	_add_button(buttons, "↗ Abrir", load_selected_map)
	_add_button(buttons, "✓ Guardar ahora", save_button_pressed)
	_add_button(buttons, "× Eliminar", remove_selected_map)

func _add_button(parent: Container, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func refresh_library() -> void:
	if map_list == null:
		return
	map_list.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_LIBRARY_DIR))
	var directory := DirAccess.open(MAP_LIBRARY_DIR)
	if directory == null:
		return
	var filenames := directory.get_files()
	filenames.sort()
	for filename in filenames:
		if not filename.ends_with(".map.json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(MAP_LIBRARY_DIR + "/" + filename))
		if not (data is Dictionary):
			continue
		var map_name: String = str(data.get("name", "Mapa"))
		var saved_tokens: Array = data.get("tokens", [])
		var index := map_list.add_item("%s  •  %d fichas" % [map_name, saved_tokens.size()])
		map_list.set_item_metadata(index, str(data.get("id", filename.trim_suffix(".map.json"))))

func import_map(source_path: String) -> void:
	if table_board == null:
		_send_status("La mesa todavía no está disponible.", true)
		return
	if source_path.get_extension().to_lower() not in ["png", "jpg", "jpeg"]:
		_send_status("Formato de mapa no compatible. Usa PNG, JPG o JPEG.", true)
		return
	var stored_path := _store_map_image(source_path)
	if stored_path.is_empty():
		_send_status("No se pudo guardar el mapa en la biblioteca.", true)
		return
	var map_id: String = stored_path.get_file().get_basename()
	if FileAccess.file_exists(_state_path(map_id)):
		load_map(map_id)
		return
	save_current_state()
	loading_map = true
	if table_board.load_map(stored_path):
		current_map_id = map_id
		current_map_display_name = source_path.get_file().get_basename()
		table_board.fit_map()
		loading_map = false
		save_current_state()
		refresh_library()
		state_changed.emit()
		_send_status("Mapa añadido a la biblioteca. Cada casilla representa 5 pies.")
	else:
		loading_map = false
		_send_status("No se pudo cargar el mapa seleccionado.", true)

func save_current_state() -> void:
	if loading_map or current_map_id.is_empty() or table_board == null or str(table_board.map_path).is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_LIBRARY_DIR))
	var state_file_path := _state_path(current_map_id)
	var existing = JSON.parse_string(FileAccess.get_file_as_string(state_file_path)) if FileAccess.file_exists(state_file_path) else {}
	var fallback_name: String = current_map_display_name if not current_map_display_name.is_empty() else str(table_board.map_path).get_file().get_basename()
	var map_name: String = str(existing.get("name", fallback_name)) if existing is Dictionary else fallback_name
	var data := {
		"id": current_map_id,
		"name": map_name,
		"map_path": str(table_board.map_path),
		"map_scale": float(table_board.map_scale),
		"tokens": table_board.export_tokens(),
		"fog": table_board.export_fog(),
		"drawings": table_board.export_drawings(),
		"updated_at": Time.get_datetime_string_from_system()
	}
	var file := FileAccess.open(state_file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "  "))

func save_button_pressed() -> void:
	if current_map_id.is_empty():
		_send_status("Carga primero un mapa de la biblioteca.", true)
		return
	save_current_state()
	refresh_library()
	_send_status("Mapa, escala y posiciones de fichas guardados.")

func load_selected_map() -> void:
	var selected := map_list.get_selected_items()
	if selected.is_empty():
		_send_status("Selecciona un mapa guardado.", true)
		return
	load_map(str(map_list.get_item_metadata(selected[0])))

func load_map(map_id: String) -> void:
	if table_board == null:
		return
	var state_file_path := _state_path(map_id)
	if not FileAccess.file_exists(state_file_path):
		_send_status("No se encontró el mapa guardado.", true)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(state_file_path))
	if not (data is Dictionary):
		_send_status("El estado del mapa no es válido.", true)
		return
	var image_path: String = str(data.get("map_path", ""))
	if not FileAccess.file_exists(image_path):
		_send_status("No se encontró la imagen de este mapa.", true)
		return
	save_current_state()
	loading_map = true
	current_map_id = map_id
	current_map_display_name = str(data.get("name", image_path.get_file().get_basename()))
	if not table_board.load_map(image_path):
		loading_map = false
		_send_status("No se pudo cargar la imagen del mapa.", true)
		return
	table_board.set_map_scale(float(data.get("map_scale", 1.0)))
	table_board.import_tokens(data.get("tokens", []))
	if data.get("fog", {}) is Dictionary:
		table_board.import_fog(data.get("fog", {}))
	if data.get("drawings", []) is Array:
		table_board.import_drawings(data.get("drawings", []))
	table_board.clear_history()
	loading_map = false
	state_changed.emit()
	_send_status("Mapa restaurado con sus fichas y posiciones.")

func remove_selected_map() -> void:
	var selected := map_list.get_selected_items()
	if selected.is_empty():
		_send_status("Selecciona un mapa para eliminarlo.", true)
		return
	var map_id: String = str(map_list.get_item_metadata(selected[0]))
	var state_file_path := _state_path(map_id)
	var data = JSON.parse_string(FileAccess.get_file_as_string(state_file_path)) if FileAccess.file_exists(state_file_path) else {}
	if data is Dictionary:
		var image_path: String = str(data.get("map_path", ""))
		var absolute_image_path := ProjectSettings.globalize_path(image_path)
		var absolute_library := ProjectSettings.globalize_path(MAP_LIBRARY_DIR)
		var managed_file := absolute_image_path.begins_with(absolute_library + "/") or absolute_image_path.begins_with(absolute_library + "\\")
		if managed_file and FileAccess.file_exists(image_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(image_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state_file_path))
	if current_map_id == map_id:
		current_map_id = ""
		current_map_display_name = ""
		table_board.clear_map()
	refresh_library()
	state_changed.emit()
	_send_status("Mapa eliminado de la biblioteca.")

func clear_current_map() -> void:
	if table_board == null:
		return
	save_current_state()
	current_map_id = ""
	current_map_display_name = ""
	table_board.clear_map()
	state_changed.emit()
	_send_status("Mapa quitado de la mesa; sigue disponible en la biblioteca.")

func restore_current_map_id(map_id: String) -> void:
	current_map_id = map_id
	if map_id.is_empty() or not FileAccess.file_exists(_state_path(map_id)):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(_state_path(map_id)))
	if data is Dictionary:
		current_map_display_name = str(data.get("name", ""))

func _store_map_image(source_path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(source_path)
	if bytes.is_empty() or bytes.size() > MAX_MAP_FILE_SIZE:
		return ""
	var extension := source_path.get_extension().to_lower()
	if extension not in ["png", "jpg", "jpeg"]:
		return ""
	if not _has_valid_image_signature(bytes, extension):
		return ""
	# No basta con confiar en la extensión: se comprueba que los bytes formen
	# una imagen válida antes de copiarlos al almacenamiento de la aplicación.
	var image := Image.new()
	var decode_error := image.load_png_from_buffer(bytes) if extension == "png" else image.load_jpg_from_buffer(bytes)
	if decode_error != OK or image.is_empty():
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_LIBRARY_DIR))
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_MD5)
	hash_context.update(bytes)
	var map_id := hash_context.finish().hex_encode().left(16)
	var target := MAP_LIBRARY_DIR + "/" + map_id + "." + extension
	if not FileAccess.file_exists(target):
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			return ""
		file.store_buffer(bytes)
		file.close()
	return target

func _has_valid_image_signature(bytes: PackedByteArray, extension: String) -> bool:
	if extension == "png":
		var png_signature := PackedByteArray([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
		return bytes.size() >= png_signature.size() and bytes.slice(0, png_signature.size()) == png_signature
	# JPEG comienza con FF D8 y finaliza con FF D9. Comprobar ambos extremos
	# evita invocar el decodificador con archivos renombrados o truncados.
	return bytes.size() >= 4 and bytes[0] == 0xff and bytes[1] == 0xd8 and bytes[bytes.size() - 2] == 0xff and bytes[bytes.size() - 1] == 0xd9

func _state_path(map_id: String) -> String:
	return MAP_LIBRARY_DIR + "/" + map_id.validate_filename() + ".map.json"

func _send_status(message: String, is_error := false) -> void:
	status_requested.emit(message, is_error)
