extends Control

## Controlador principal de la aplicación. Construye páginas, guarda hojas y
## coordina la mesa online. Antes de editarlo consulta
## res://GUIA_PROGRAMACION.md para encontrar la sección correcta.

const SAVE_PATH := "user://character_sheet.json"
const SHEETS_DIR := "user://character_sheets"
const TABLE_SAVE_PATH := "user://table_state.json"
const TABLE_BACKUP_DIR := "user://table_backups"
const TABLE_TEMP_PATH := "user://table_state.tmp"
const TABLE_PREVIOUS_PATH := "user://table_state.previous"
const MUSIC_DIR := "user://music_library"
const SHEET_BACKUP_DIR := "user://sheet_backups"
const SHEET_RECOVERY_PATH := "user://sheet_recovery.json"
const ONLINE_ID_PATH := "user://online_player_id.txt"
const APPEARANCE_PATH := "user://appearance.json"
const WINDOW_LAYOUT_PATH := "user://floating_windows.json"
const TABLE_MEDIA_LIBRARY_PATH := "user://table_media_library.json"
const TABLE_MEDIA_LIBRARY_DIR := "user://table_media_library"
const MAX_TABLE_MEDIA_ITEMS := 30
const GASTER_GIF_PATH := "res://assets/easter_eggs/gaster.gif"
const GIF_PLAYBACK_SCRIPT := preload("res://GifPlayback.gd")
const LIBRARY_CATALOG_PATH := "user://library_catalog.json"
const LIBRARY_ASSETS_DIR := "user://library_assets"
const ENCOUNTERS_PATH := "user://encounters.json"
const CAMPAIGN_BACKUP_DIR := "user://campaign_backups"
const CAMPAIGN_EXTENSION := "dndcampaign"
const MAX_CAMPAIGN_ARCHIVE_BYTES := 512 * 1024 * 1024
const LIBRARY_ENTRY_EXTENSION := "dndentry"
const LIBRARY_COLLECTION_EXTENSION := "dndlibrary"
const LIBRARY_CATEGORIES := ["Objeto", "Raza", "Clase", "Enemigo", "Conjuro", "Regla", "Lugar", "PNJ", "Otro"]
const MAX_LIBRARY_CATALOG_ENTRIES := 5000
const MAX_LIBRARY_ENTRY_IMAGE_BYTES := 6 * 1024 * 1024
const MAX_LIBRARY_IMPORT_BYTES := 10 * 1024 * 1024
const MAX_LIBRARY_COLLECTION_IMPORT_BYTES := 64 * 1024 * 1024
const SHEET_TYPES := ["Personaje", "PNJ", "Monstruo", "Compañero", "Personalizada"]
const AUTOSAVE_SECONDS := 5.0
const MAX_SHEET_BACKUPS := 10
const MAX_TABLE_BACKUPS := 10
const TABLE_BACKUP_INTERVAL_SECONDS := 300
const MAX_CHAT_MESSAGE_LENGTH := 400
const CHAT_RATE_LIMIT_MS := 500
const CHAT_WINDOW_SCENE := preload("res://ui/ChatWindow.tscn")
const DECK_WINDOW_SCENE := preload("res://ui/DeckWindow.tscn")
const MAP_LIBRARY_SCENE := preload("res://ui/MapLibrary.tscn")
const MUSIC_LIBRARY_SCENE := preload("res://ui/MusicLibrary.tscn")
const ONLINE_PANEL_SCENE := preload("res://ui/OnlinePanel.tscn")
const SHEETS_MANAGER_SCENE := preload("res://ui/SheetsManager.tscn")
const TOKEN_SHEET_WINDOW_SCENE := preload("res://ui/TokenSheetWindow.tscn")
const MONSTER_SHEET_SCENE := preload("res://ui/MonsterSheetView.tscn")
const INITIATIVE_TRACKER_SCENE := preload("res://ui/InitiativeTracker.tscn")
const CHARACTER_SHEET_VIEW_SCENE := preload("res://ui/CharacterSheetView.tscn")
const SHEET_ZOOM_CONTAINER_SCRIPT := preload("res://SheetZoomContainer.gd")
const INK := Color("#eadfc4")
const MUTED := Color("#a99f89")
const GOLD := Color("#c99a52")
const PANEL := Color("#211f22")
const FIELD := Color("#171619")
# PERSONALIZACIÓN: cada skin define los cinco colores básicos de toda la app.
# Usa textos hexadecimales para que sea sencillo copiar un preset nuevo.
const SKIN_PRESETS := {
	"Minimalista": {
		"background": "#f2f4f7", "panel": "#ffffff", "field": "#e8ecf1",
		"accent": "#3569b8", "text": "#18212c",
		"radius": 2, "border": 0, "padding": 10, "spacing": 6,
		"button_height": 36, "title_size": 15, "accent_width": 2
	},
	"Medieval antiguo": {
		"background": "#120d09", "panel": "#2a1b12", "field": "#1a110c",
		"accent": "#b8893f", "text": "#ead9b8",
		"radius": 12, "border": 2, "padding": 18, "spacing": 12,
		"button_height": 44, "title_size": 18, "accent_width": 5, "shadow": 5
	},
	"Arcano cristal": {
		"background": "#0b0920", "panel": "#171238", "field": "#0f0d28",
		"accent": "#65d8e8", "text": "#eeeaff",
		"radius": 16, "border": 1, "padding": 14, "spacing": 10,
		"button_height": 42, "title_size": 18, "accent_width": 3, "shadow": 8
	},
	"Forja industrial": {
		"background": "#111315", "panel": "#25292c", "field": "#171a1c",
		"accent": "#e7792d", "text": "#edf0f1",
		"radius": 0, "border": 2, "padding": 12, "spacing": 8,
		"button_height": 40, "title_size": 16, "accent_width": 7, "shadow": 0
	}
}
const XP_THRESHOLDS := [0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000, 85000, 100000, 120000, 140000, 165000, 195000, 225000, 265000, 305000, 355000]
const ENCOUNTER_EASY_XP := [25, 50, 75, 125, 250, 300, 350, 450, 550, 600, 800, 1000, 1100, 1250, 1400, 1600, 2000, 2100, 2400, 2800]
const ENCOUNTER_MEDIUM_XP := [50, 100, 150, 250, 500, 600, 750, 900, 1100, 1200, 1600, 2000, 2200, 2500, 2800, 3200, 3900, 4200, 4900, 5700]
const ENCOUNTER_HARD_XP := [75, 150, 225, 375, 750, 900, 1100, 1400, 1600, 1900, 2400, 3000, 3400, 3800, 4300, 4800, 5900, 6300, 7300, 8500]
const ENCOUNTER_DEADLY_XP := [100, 200, 400, 500, 1100, 1400, 1700, 2100, 2400, 2800, 3600, 4500, 5100, 5700, 6400, 7200, 8800, 9500, 10900, 12700]

var fields := {}
var option_fields := {}
var stat_spins := {}
var stat_mods := {}
var skill_fields: Dictionary = {}
var skill_proficiency_label: Label
var sheet_roll_mode_option: OptionButton
var skill_rows: Array[BoxContainer] = []
var attributes_grid: GridContainer
var identity_layout: BoxContainer
var attribute_cards: Array[PanelContainer] = []
var responsive_sheet_rows: Array[BoxContainer] = []
var section_accents: Array[ColorRect] = []
var section_titles: Array[Label] = []
var hp_bar: ProgressBar
var status_label: Label
var columns: BoxContainer
var character_sheet_content: Control
var character_sheet_view: Control
var monster_sheet_content: Control
var monster_sheet_view: Control
var magic_bonus_label: Label
var ui_theme: Theme
var background_rect: ColorRect
var root_margin: MarginContainer
var regular_panels: Array[PanelContainer] = []
var spell_cards: Array[PanelContainer] = []
var spell_cards_container: GridContainer
var spell_count := 0
var spell_mechanic_tracks: Dictionary = {}
var spell_mechanic_options: Dictionary = {}
var inventory_rows_container: VBoxContainer
var inventory_rows: Array[BoxContainer] = []
var inventory_count := 0
var mechanic_rows_container: VBoxContainer
var mechanic_rows: Array[BoxContainer] = []
var mechanic_tracks := {}
var mechanic_count := 0
# Listas dinámicas de resistencias, idiomas y competencias.
var proficiency_lists: Dictionary = {}
var proficiency_list_containers: Dictionary = {}
var xp_bar: ProgressBar
var xp_progress_label: Label
var appearance_popup: Window
var page_tabs: TabContainer
var library_layout: BoxContainer
var library_sidebar_panel: PanelContainer
var library_tabs_control: TabContainer
var table_layout: BoxContainer
var table_left_rail: BoxContainer
var table_left_scroll: ScrollContainer
var table_left_panel: PanelContainer
var table_right_panel: PanelContainer
var table_right_rail: VBoxContainer
var table_section_headers: Array[Button] = []
var table_mobile_layout_active := false
var table_tool_hint_label: Label
var sheets_popup: Window
var sheets_list: ItemList
var sheets_search: LineEdit
var sheets_count_label: Label
var sheet_name_edit: LineEdit
var sheet_type_option: OptionButton
var header_sheet_type_option: OptionButton
var header_layout: BoxContainer
var header_left_slot: Control
var header_type_slot: VBoxContainer
var header_navigation: HFlowContainer
var current_sheet_file := ""
var autosave_timer: Timer
var last_sheet_fingerprint := ""
var recovery_dialog: ConfirmationDialog
var pending_recovery_data: Dictionary = {}
var sheet_export_dialog: FileDialog
var sheet_import_dialog: FileDialog
var pending_export_sheet := ""
var sheet_import_loading_popup: Window
var sheet_import_busy := false
var dice_result_label: Label
var dice_count_spin: SpinBox
var dice_modifier_spin: SpinBox
var table_board: Control
var token_image_dialog: FileDialog
var map_image_dialog: FileDialog
var table_media_dialog: FileDialog
var current_table_media_path := ""
var table_media_playing := false
var table_media_popup: Window
var table_media_list: ItemList
var table_media_library: Array[Dictionary] = []
var table_media_count_label: Label
var table_media_search: LineEdit
var table_media_preview: TextureRect
var table_media_video_preview: VideoStreamPlayer
var table_media_preview_texture: Texture2D
var table_media_preview_frame := 0
var table_media_preview_elapsed := 0.0
var table_media_name_edit: LineEdit
var table_media_preview_layout: BoxContainer
var table_media_delete_dialog: ConfirmationDialog
var pending_table_media_delete_path := ""
var token_status_edit: LineEdit
var token_status_duration_spin: SpinBox
var token_status_list: ItemList
var token_status_preset: OptionButton
var token_vision_spin: SpinBox
var token_owner_edit: LineEdit
var token_owner_option: OptionButton
var portrait_gallery_box: GridContainer
var portrait_gallery_title: Label
var portrait_gallery: Array[String] = []
var loading_table_state := false
var last_table_backup_time := 0
var token_sheet_popup: Window
var deck_popup: Window
var deck_cards_grid: GridContainer
var deck_card_nodes: Array[Control] = []
var chat_popup: Window
var chat_log: RichTextLabel
var chat_health_box: VBoxContainer
var chat_input: LineEdit
var chat_messages: Array[Dictionary] = []
var chat_last_message_time: Dictionary = {}
var gaster_texture: Texture2D
var gaster_gif_frame := 0
var gaster_gif_elapsed := 0.0
var initiative_popup: Window
var initiative_view: Control
var loading_initiative_state := false
var director_only_buttons: Array[Button] = []
var token_lock_button: Button
var map_lock_button: Button
var undo_button: Button
var redo_button: Button
var history_can_undo := false
var history_can_redo := false
var group_selection_button: Button
var group_selection_enabled := false
var music_popup: Window
var music_file_dialog: FileDialog
var music_list: ItemList
var music_player: AudioStreamPlayer
var music_now_label: Label
var music_loop_enabled := true
var current_music_path := ""
var music_play_for_table := true
var music_is_shared := false
var music_general_volume := 0.7
var music_personal_volume := 1.0
var music_general_slider: HSlider
var online_popup: Window
var online_ip_edit: LineEdit
var online_port_edit: LineEdit
var online_room_code_edit: LineEdit
var online_public_address_edit: LineEdit
var online_public_port_edit: LineEdit
var online_name_edit: LineEdit
var online_status_label: Label
var online_players_list: ItemList
var online_kick_button: Button
var online_players: Dictionary = {}
var online_banned_ids: Dictionary = {}
var online_player_id := ""
var pending_token_owner_id := ""
var floating_window_layout: Dictionary = {}
var online_reconnect_timer: Timer
var online_should_reconnect := false
var online_reconnect_attempts := 0
var online_last_ip := ""
var online_last_port := 7000
const MAX_RECONNECT_ATTEMPTS := 8
var online_ping_timer: Timer
var table_live_sync_timer: Timer
var table_save_debounce_timer: Timer
var pending_fog_sync := false
var pending_drawings_sync := false
var pending_token_motion_sync := false
var table_tool_buttons: Dictionary = {}
var zoom_label: Label
var map_scale_label: Label
var transfer_progress_bar: ProgressBar
var transfer_progress_label: Label
var transfer_cancel_button: Button
var map_library_popup: Window
var table_backups_window: Window
var table_backups_list: ItemList
var encounter_popup: Window
var encounter_name_edit: LineEdit
var encounter_enemy_option: OptionButton
var encounter_quantity_spin: SpinBox
var encounter_composition_list: ItemList
var encounter_saved_list: ItemList
var encounter_summary_label: Label
var encounter_party_size_spin: SpinBox
var encounter_party_level_spin: SpinBox
var encounter_add_initiative_check: CheckBox
var encounter_announce_check: CheckBox
var campaign_popup: Window
var campaign_export_dialog: FileDialog
var campaign_import_dialog: FileDialog
var campaign_import_confirmation: ConfirmationDialog
var pending_campaign_import_path := ""
var campaign_summary_label: Label
var encounter_composition: Array[Dictionary] = []
var saved_encounters: Array[Dictionary] = []
# Se mantiene como Control para que el proyecto pueda arrancar incluso antes de
# que Godot haya actualizado su caché de clases globales.
var map_library_view: Control
var library_pdf_dialog: FileDialog
var library_list: ItemList
var library_question: LineEdit
var library_answer: TextEdit
var library_status: Label
var library_catalog_list: ItemList
var library_catalog_search: LineEdit
var library_catalog_filter: OptionButton
var library_catalog_count_label: Label
var library_catalog_category: OptionButton
var library_catalog_name: LineEdit
var library_catalog_source: LineEdit
var library_catalog_notes: TextEdit
var library_catalog_entries: Array[Dictionary] = []
var library_catalog_selected := -1
var library_catalog_layout: BoxContainer
var library_catalog_import_dialog: FileDialog
var library_catalog_export_dialog: FileDialog
var library_catalog_image_dialog: FileDialog
var pending_library_catalog_export: Dictionary = {}
var library_catalog_export_all := false
var library_catalog_image_preview: TextureRect
var library_catalog_image_hint: Label
var library_catalog_image_data := ""
var library_catalog_image_format := ""
var spell_library_list: ItemList
var spell_library_search: LineEdit
var spell_library_count_label: Label
var pdf_viewer_popup: Window
var pdf_page_texture: TextureRect
var pdf_page_label: Label
var pdf_current_path := ""
var pdf_current_page := 1
var pdf_page_count := 0
var library_thread: Thread
var palette := {
	"background": Color("#111013"),
	"panel": PANEL,
	"field": FIELD,
	"accent": GOLD,
	"text": INK
}
var active_skin := "Medieval antiguo"
var palette_apply_timer: Timer
var appearance_save_timer: Timer
var applying_skin := false
var pending_palette_keys: Dictionary = {}
var palette_font_controls: Array[Control] = []
var skin_managed_panels: Array[PanelContainer] = []
var skin_style_cache: Dictionary = {}
# Zoom táctil de las hojas. La Mesa conserva su propio zoom independiente.
const SHEET_ZOOM_MIN := 0.50
const SHEET_ZOOM_MAX := 2.50
var sheet_zoom := 1.0
var sheet_zoom_label: Button
var sheet_zoom_controls: Array[Control] = []
var sheet_zoom_pages: Array[Control] = []
var sheet_scroll: ScrollContainer
var sheet_touch_points: Dictionary = {}
var sheet_pinch_distance := 0.0
var startup_overlay: ColorRect

func _ready() -> void:
	# Android necesita poder dibujar algo antes de construir la hoja completa.
	# Esta portada cuesta muy poco y evita varios segundos de pantalla negra.
	online_player_id = _load_or_create_online_player_id()
	_load_floating_window_layout()
	_load_appearance()
	_make_theme()
	_show_startup_overlay()
	await get_tree().process_frame
	# Registrar los controles mientras se crean evita recorrer después todo el
	# árbol de interfaz únicamente para llenar las cachés de colores y paneles.
	get_tree().node_added.connect(_on_palette_node_added)
	_build_ui()
	_hide_startup_overlay()
	# La interfaz ya puede mostrarse; el acabado completo del skin se aplica en
	# el siguiente ciclo sin retrasar el primer fotograma útil en el teléfono.
	_apply_palette.call_deferred()
	palette_apply_timer = Timer.new()
	palette_apply_timer.one_shot = true
	palette_apply_timer.wait_time = 0.07
	palette_apply_timer.timeout.connect(_flush_palette_changes)
	add_child(palette_apply_timer)
	appearance_save_timer = Timer.new()
	appearance_save_timer.one_shot = true
	appearance_save_timer.wait_time = 0.65
	appearance_save_timer.timeout.connect(func(): _save_appearance(active_skin))
	add_child(appearance_save_timer)
	# Los controles creados después (cartas, objetos, mecánicas) también se
	# incorporan automáticamente a las cachés anteriores.
	online_reconnect_timer = Timer.new()
	online_reconnect_timer.one_shot = true
	online_reconnect_timer.timeout.connect(_attempt_online_reconnect)
	add_child(online_reconnect_timer)
	online_ping_timer = Timer.new()
	online_ping_timer.wait_time = 2.0
	online_ping_timer.timeout.connect(_send_online_ping)
	add_child(online_ping_timer)
	online_ping_timer.start()
	# La niebla y los dibujos pueden generar decenas de cambios por segundo.
	# La red se actualiza en pequeños lotes y el disco espera a que pare el trazo.
	table_live_sync_timer = Timer.new()
	table_live_sync_timer.one_shot = true
	table_live_sync_timer.wait_time = 0.10
	table_live_sync_timer.timeout.connect(_flush_table_live_sync)
	add_child(table_live_sync_timer)
	table_save_debounce_timer = Timer.new()
	table_save_debounce_timer.one_shot = true
	table_save_debounce_timer.wait_time = 0.65
	table_save_debounce_timer.timeout.connect(func(): _save_table_state(false))
	add_child(table_save_debounce_timer)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_setup_sheet_protection()
	_check_sheet_recovery.call_deferred()
	set_process(true)

# Pantalla mínima de inicio. No carga imágenes ni escenas adicionales, así que
# también funciona en celulares modestos y durante el primer arranque del APK.
func _show_startup_overlay() -> void:
	startup_overlay = ColorRect.new()
	startup_overlay.color = palette.background
	startup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	startup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	startup_overlay.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	add_child(startup_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	startup_overlay.add_child(center)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	center.add_child(content)
	var title := Label.new()
	title.text = "D20"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", palette.accent)
	content.add_child(title)
	var message := Label.new()
	message.text = "Preparando tu mesa…"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", palette.text)
	content.add_child(message)

func _hide_startup_overlay() -> void:
	if startup_overlay != null and is_instance_valid(startup_overlay):
		startup_overlay.queue_free()
	startup_overlay = null

func _process(delta: float) -> void:
	if gaster_texture != null:
		var playback: Vector2 = GIF_PLAYBACK_SCRIPT.advance(gaster_texture, gaster_gif_frame, gaster_gif_elapsed, delta)
		gaster_gif_frame = int(playback.x)
		gaster_gif_elapsed = playback.y
		if chat_log != null:
			chat_log.queue_redraw()
	if table_media_preview_texture != null and table_media_popup != null and table_media_popup.visible:
		var preview_playback: Vector2 = GIF_PLAYBACK_SCRIPT.advance(table_media_preview_texture, table_media_preview_frame, table_media_preview_elapsed, delta)
		table_media_preview_frame = int(preview_playback.x)
		table_media_preview_elapsed = preview_playback.y
		if table_media_preview != null:
			table_media_preview.queue_redraw()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_persist_appearance_now()
		return
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	# En Android, Atrás cierra primero el menú emergente visible en vez de
	# abandonar accidentalmente toda la mesa.
	var windows := _floating_windows()
	windows.reverse()
	for window in windows:
		if window.visible:
			_close_floating_window(window)
			return
	_persist_appearance_now()
	get_tree().quit()

func _input(event: InputEvent) -> void:
	# En la Mesa y Biblioteca no tocamos los gestos: cada vista maneja su entrada.
	if page_tabs == null or page_tabs.current_tab > 2:
		sheet_touch_points.clear()
		sheet_pinch_distance = 0.0
		return
	if event is InputEventMagnifyGesture:
		_set_sheet_zoom(sheet_zoom * event.factor)
		get_viewport().set_input_as_handled()
		return
	# En PC, Ctrl + rueda amplía la ficha y la rueda sola conserva el scroll.
	if event is InputEventMouseButton and event.pressed and event.ctrl_pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_sheet_zoom(sheet_zoom + 0.10)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_sheet_zoom(sheet_zoom - 0.10)
			get_viewport().set_input_as_handled()
			return
	# Atajos habituales de navegador/documentos para teclado principal y numérico.
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed:
		if event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
			_set_sheet_zoom(sheet_zoom + 0.10)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_set_sheet_zoom(sheet_zoom - 0.10)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_0, KEY_KP_0]:
			_set_sheet_zoom(1.0)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenTouch:
		if event.pressed:
			sheet_touch_points[event.index] = event.position
		else:
			sheet_touch_points.erase(event.index)
			sheet_pinch_distance = 0.0
		_update_sheet_pinch()
	elif event is InputEventScreenDrag:
		sheet_touch_points[event.index] = event.position
		_update_sheet_pinch()

func _update_sheet_pinch() -> void:
	if sheet_touch_points.size() < 2:
		sheet_pinch_distance = 0.0
		return
	var touch_ids: Array = sheet_touch_points.keys()
	var first_position: Vector2 = sheet_touch_points[touch_ids[0]]
	var second_position: Vector2 = sheet_touch_points[touch_ids[1]]
	var distance: float = first_position.distance_to(second_position)
	# Ignora dedos prácticamente superpuestos y limita saltos grandes causados
	# por algunos dispositivos Android al reasignar un índice táctil.
	if distance < 20.0:
		return
	if sheet_pinch_distance >= 20.0:
		var ratio := clampf(distance / sheet_pinch_distance, 0.75, 1.25)
		if absf(ratio - 1.0) >= 0.002:
			_set_sheet_zoom(sheet_zoom * ratio)
	sheet_pinch_distance = distance
	get_viewport().set_input_as_handled()

func _set_sheet_zoom(value: float) -> void:
	sheet_zoom = clampf(value, SHEET_ZOOM_MIN, SHEET_ZOOM_MAX)
	# El contenedor escala la página completa sin cambiar el Theme ni provocar
	# redistribuciones de texto durante el movimiento de los dedos.
	for zoom_page in sheet_zoom_pages:
		if is_instance_valid(zoom_page):
			zoom_page.call("set_zoom", sheet_zoom)
	if page_tabs != null:
		page_tabs.update_minimum_size()
		page_tabs.queue_redraw()
	if sheet_scroll != null:
		sheet_scroll.update_minimum_size()
	if sheet_zoom_label != null:
		sheet_zoom_label.text = "%d%%" % roundi(sheet_zoom * 100.0)

func _make_theme() -> void:
	var t := Theme.new()
	ui_theme = t
	var mobile_device := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	t.default_font_size = 17 if mobile_device else 16
	for type_name in ["Label", "Button", "LineEdit", "TextEdit", "SpinBox", "OptionButton", "CheckBox"]:
		t.set_color("font_color", type_name, INK)
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_color("font_placeholder_color", "TextEdit", MUTED)
	for type_name in ["LineEdit", "TextEdit", "SpinBox", "OptionButton"]:
		t.set_stylebox("normal", type_name, _box(FIELD, 8, Color("#4a4239"), 1, 8))
		t.set_stylebox("focus", type_name, _box(FIELD, 8, GOLD, 2, 8))
	var button_padding := 12 if mobile_device else 10
	t.set_stylebox("normal", "Button", _box(Color("#3b3027"), 8, Color("#745a38"), 1, button_padding))
	t.set_stylebox("hover", "Button", _box(Color("#51402e"), 8, GOLD, 1, button_padding))
	t.set_stylebox("pressed", "Button", _box(Color("#271f1b"), 8, GOLD, 2, button_padding))
	t.set_stylebox("background", "ProgressBar", _box(FIELD, 8, Color("#4a4239"), 1, 2))
	t.set_stylebox("fill", "ProgressBar", _box(Color("#8f3c35"), 8, Color("#bd6658"), 1, 2))
	t.set_color("font_color", "ProgressBar", Color.WHITE)
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	theme = t

func _box(color: Color, radius: int, border := Color.TRANSPARENT, width := 0, padding := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(padding)
	return s

func _skin_box(color: Color, radius: int, border: Color, width: int, padding: int, shadow_size: int) -> StyleBoxFlat:
	var style := _box(color, radius, border, width, padding)
	if shadow_size > 0:
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, maxf(shadow_size * 0.35, 1.0))
		style.shadow_color = Color(0, 0, 0, 0.32)
	return style

func _cached_skin_box(color: Color, radius: int, border: Color, width: int, padding: int, shadow_size: int) -> StyleBoxFlat:
	var cache_key := "%s|%d|%s|%d|%d|%d" % [color.to_html(true), radius, border.to_html(true), width, padding, shadow_size]
	if skin_style_cache.has(cache_key):
		return skin_style_cache[cache_key]
	var style := _skin_box(color, radius, border, width, padding, shadow_size)
	skin_style_cache[cache_key] = style
	return style

func _configure_external_file_dialog(dialog: FileDialog) -> void:
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	# Android 10+ ofrece su selector de documentos mediante el diálogo nativo.
	# Así Android 13 concede acceso solo al archivo elegido y no exige permiso
	# general para leer todo el almacenamiento del dispositivo.
	dialog.use_native_dialog = OS.has_feature("android")
	dialog.mode_overrides_title = true

func _show_external_file_dialog(dialog: FileDialog) -> void:
	if dialog.use_native_dialog:
		dialog.popup_file_dialog()
	else:
		dialog.popup_centered_ratio(0.8)

func _style_table_tool_grid(grid: GridContainer) -> void:
	# Estilo común del inspector de la Mesa. Centralizarlo aquí permite cambiar
	# todos los grupos de herramientas sin buscar cada botón por separado.
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for child in grid.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, 38)
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.add_theme_font_size_override("font_size", 13)
			_apply_table_tool_button_style(child, false)

func _register_table_tool_button(mode: String, button: Button) -> void:
	if not table_tool_buttons.has(mode):
		table_tool_buttons[mode] = []
	var buttons: Array = table_tool_buttons[mode]
	buttons.append(button)
	table_tool_buttons[mode] = buttons

func _register_table_context_help(button: Button, description: String) -> void:
	button.tooltip_text = description
	var show_help := func():
		if table_tool_hint_label != null:
			table_tool_hint_label.text = description
	button.mouse_entered.connect(show_help)
	button.focus_entered.connect(show_help)
	button.button_down.connect(show_help)

func _on_table_tool_changed(active_mode: String) -> void:
	for mode in table_tool_buttons:
		for button in table_tool_buttons[mode]:
			if is_instance_valid(button):
				_apply_table_tool_button_style(button, str(mode) == active_mode)
	if table_tool_hint_label != null:
		var readable: Dictionary = {"select": "Mover fichas y recorrer la mesa", "ruler": "Medir distancias: cada casilla equivale a 5 pies", "cone": "Dibujar un área de cono", "sphere": "Dibujar un área circular", "fog_reveal": "Revelar zonas de la niebla", "fog_hide": "Volver a ocultar zonas", "draw": "Dibujar sobre la mesa", "erase_draw": "Borrar trazos manualmente"}
		table_tool_hint_label.text = "ACTIVA  ·  " + str(readable.get(active_mode, active_mode))

func _apply_table_tool_button_style(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", Color("#fff4d6"))
		button.add_theme_stylebox_override("normal", _box(Color("#825331"), 7, GOLD.lightened(0.18), 2, 7))
		button.add_theme_stylebox_override("hover", _box(Color("#96613a"), 7, GOLD.lightened(0.3), 2, 7))
		button.add_theme_stylebox_override("pressed", _box(Color("#613d26"), 7, Color("#f0bd68"), 2, 7))
	else:
		button.remove_theme_color_override("font_color")
		button.add_theme_stylebox_override("normal", _box(Color("#39332e"), 7, Color("#725a38"), 1, 7))
		button.add_theme_stylebox_override("hover", _box(Color("#514231"), 7, GOLD, 1, 7))
		button.add_theme_stylebox_override("pressed", _box(Color("#241f1c"), 7, GOLD, 2, 7))

func _configure_table_section_header(header: Button, title: String, controls: Array) -> void:
	header.text = "▾  " + title
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.flat = true
	header.focus_mode = Control.FOCUS_NONE
	header.custom_minimum_size.y = 32
	header.tooltip_text = "Toca para plegar o desplegar esta sección"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", GOLD)
	header.add_theme_color_override("font_hover_color", GOLD.lightened(0.22))
	header.set_meta("section_title", title)
	header.set_meta("section_controls", controls)
	table_section_headers.append(header)
	header.pressed.connect(func():
		var expanded: bool = false
		for control in controls:
			if is_instance_valid(control) and control.visible:
				expanded = true
				break
		_set_table_section_expanded(header, not expanded)
	)

func _set_table_section_expanded(header: Button, expanded: bool) -> void:
	var controls: Array = header.get_meta("section_controls", [])
	for control in controls:
		if is_instance_valid(control):
			control.visible = expanded
	var title: String = str(header.get_meta("section_title", header.text))
	header.text = ("▾  " if expanded else "▸  ") + title

func _popup_centered_safe(popup: Window, desired_size: Vector2i) -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	var window_size := DisplayServer.window_get_size()
	if window_size.x > 0 and window_size.y > 0:
		viewport_size.x = mini(viewport_size.x, window_size.x)
		viewport_size.y = mini(viewport_size.y, window_size.y)
	var margin := 8 if _is_phone_layout() else 24
	var available := Vector2i(maxi(viewport_size.x - margin * 2, 280), maxi(viewport_size.y - margin * 2, 260))
	var target := available if _is_phone_layout() else Vector2i(mini(desired_size.x, available.x), mini(desired_size.y, available.y))
	popup.popup_centered(target)

func _toggle_floating_window(window: Window, desired_size: Vector2i, window_title: String) -> bool:
	if window.visible:
		_save_floating_window(window)
		if window == table_media_popup:
			_stop_table_media_preview()
		window.hide()
		return false
	window.title = window_title
	window.borderless = false
	window.unresizable = false
	window.transient = true
	window.exclusive = false
	# En Android las subventanas se integran dentro de la app. Esto evita que
	# queden detrás de la actividad o fuera de pantalla al cambiar orientación.
	window.always_on_top = OS.has_feature("mobile")
	# En teléfonos una ventana mínima de 280 px podía quedar fuera del área útil
	# al rotar el dispositivo. El límite real se recalcula también en _resize().
	var viewport_size := Vector2i(get_viewport_rect().size)
	window.min_size = Vector2i(mini(280, maxi(viewport_size.x - 16, 220)), mini(220, maxi(viewport_size.y - 16, 180)))
	for child in window.get_children():
		if child is Control:
			child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not window.has_meta("floating_configured"):
		window.close_requested.connect(_close_floating_window.bind(window))
		window.set_meta("floating_configured", true)
	if floating_window_layout.has(window_title) and not _is_phone_layout():
		var saved: Dictionary = floating_window_layout[window_title]
		window.size = Vector2i(clampi(int(saved.get("w", desired_size.x)), window.min_size.x, maxi(viewport_size.x, window.min_size.x)), clampi(int(saved.get("h", desired_size.y)), window.min_size.y, maxi(viewport_size.y, window.min_size.y)))
		window.position = Vector2i(clampi(int(saved.get("x", 20)), 0, maxi(viewport_size.x - window.size.x, 0)), clampi(int(saved.get("y", 20)), 0, maxi(viewport_size.y - window.size.y, 0)))
		window.popup()
	elif window.has_meta("opened_once"):
		window.popup()
	else:
		_popup_centered_safe(window, desired_size)
		window.set_meta("opened_once", true)
	return true

func _close_floating_window(window: Window) -> void:
	_save_floating_window(window)
	if window == table_media_popup:
		_stop_table_media_preview()
	window.hide()

func _load_floating_window_layout() -> void:
	if not FileAccess.file_exists(WINDOW_LAYOUT_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WINDOW_LAYOUT_PATH))
	if parsed is Dictionary:
		floating_window_layout = parsed

func _save_floating_window(window: Window) -> void:
	if window.title.is_empty():
		return
	floating_window_layout[window.title] = {"x": window.position.x, "y": window.position.y, "w": window.size.x, "h": window.size.y}
	var file := FileAccess.open(WINDOW_LAYOUT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(floating_window_layout, "  "))

# Devuelve solo las ventanas que ya existen. Mantener la lista aquí facilita
# añadir una ventana nueva en el futuro sin repetir la lógica responsive.
func _floating_windows() -> Array[Window]:
	var windows: Array[Window] = []
	for candidate in [sheets_popup, token_sheet_popup, deck_popup, chat_popup, initiative_popup, encounter_popup, campaign_popup, music_popup, online_popup, map_library_popup, table_backups_window, table_media_popup, appearance_popup, pdf_viewer_popup]:
		if candidate is Window and is_instance_valid(candidate):
			windows.append(candidate)
	return windows

# Impide que una ventana emergente quede cortada después de rotar el celular,
# reducir la app o pasar de pantalla completa a ventana. No cierra ventanas.
func _fit_floating_windows_to_viewport() -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var margin := 8
	var maximum_size := Vector2i(maxi(viewport_size.x - margin * 2, 220), maxi(viewport_size.y - margin * 2, 180))
	for window in _floating_windows():
		window.min_size = Vector2i(mini(280, maximum_size.x), mini(220, maximum_size.y))
		if not window.visible:
			continue
		window.size = Vector2i(clampi(window.size.x, window.min_size.x, maximum_size.x), clampi(window.size.y, window.min_size.y, maximum_size.y))
		window.position = Vector2i(clampi(window.position.x, margin, maxi(viewport_size.x - window.size.x - margin, margin)), clampi(window.position.y, margin, maxi(viewport_size.y - window.size.y - margin, margin)))

func _is_phone_layout() -> bool:
	# Con stretch="canvas_items" un teléfono vertical puede conservar 1200 px
	# lógicos de ancho. La relación de aspecto permite detectarlo correctamente.
	var viewport_size := get_viewport_rect().size
	var mobile_device := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	return viewport_size.x < 700.0 or (mobile_device and viewport_size.x < viewport_size.y * 1.15)

func _build_ui() -> void:
	background_rect = ColorRect.new()
	background_rect.color = palette.background
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)
	var scroll := ScrollContainer.new()
	sheet_scroll = scroll
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# AUTO permite desplazar lateralmente la hoja cuando el usuario la amplía.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var margin := MarginContainer.new()
	root_margin = margin
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)
	page.add_child(_header())
	page_tabs = TabContainer.new()
	page_tabs.tabs_visible = false
	page_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(page_tabs)
	var sheet_zoom_page: Control = SHEET_ZOOM_CONTAINER_SCRIPT.new()
	sheet_zoom_page.name = "Hoja"
	sheet_zoom_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_zoom_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_tabs.add_child(sheet_zoom_page)
	sheet_zoom_pages.append(sheet_zoom_page)
	var sheet_page := VBoxContainer.new()
	sheet_page.add_theme_constant_override("separation", 18)
	sheet_zoom_page.add_child(sheet_page)
	character_sheet_content = _create_character_sheet_view()
	sheet_page.add_child(character_sheet_content)
	monster_sheet_content = _create_monster_sheet_view()
	monster_sheet_content.visible = false
	sheet_page.add_child(monster_sheet_content)
	sheet_page.add_child(_footer())
	var inventory_page := _inventory()
	inventory_page.custom_minimum_size.y = 650
	var inventory_zoom_page: Control = SHEET_ZOOM_CONTAINER_SCRIPT.new()
	inventory_zoom_page.name = "Inventario"
	inventory_zoom_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_zoom_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_tabs.add_child(inventory_zoom_page)
	sheet_zoom_pages.append(inventory_zoom_page)
	inventory_zoom_page.add_child(inventory_page)
	var spells_page := _spells_tab()
	spells_page.custom_minimum_size.y = 720
	var spells_zoom_page: Control = SHEET_ZOOM_CONTAINER_SCRIPT.new()
	spells_zoom_page.name = "Conjuros"
	spells_zoom_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spells_zoom_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_tabs.add_child(spells_zoom_page)
	sheet_zoom_pages.append(spells_zoom_page)
	spells_zoom_page.add_child(spells_page)
	var table_page := _table_page()
	table_page.name = "Mesa"
	page_tabs.add_child(table_page)
	var library_page := _library_page()
	library_page.name = "Biblioteca"
	page_tabs.add_child(library_page)
	page_tabs.current_tab = 3

func _header() -> Control:
	var row := BoxContainer.new()
	row.vertical = false
	header_layout = row
	var left_slot := Control.new()
	header_left_slot = left_slot
	left_slot.hide()
	row.add_child(left_slot)
	var navigation := HFlowContainer.new()
	header_navigation = navigation
	navigation.alignment = FlowContainer.ALIGNMENT_BEGIN
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for d in [["Hoja de personaje", 0], ["Inventario", 1], ["Conjuros", 2], ["Mesa", 3], ["Biblioteca", 4]]:
		var navigation_button := Button.new()
		navigation_button.text = d[0]
		navigation_button.pressed.connect(func(): _show_page(d[1]))
		navigation.add_child(navigation_button)
	var load_button := Button.new()
	load_button.text = "Cargar"
	# Siempre abre la biblioteca. Antes, tras cargar una hoja, este botón solo
	# recargaba la misma y ya no permitía elegir otra diferente.
	load_button.pressed.connect(_show_sheets_manager)
	navigation.add_child(load_button)
	var save_button := Button.new()
	save_button.text = "Guardar"
	save_button.pressed.connect(save_sheet)
	navigation.add_child(save_button)
	var skins_button := Button.new()
	skins_button.text = "Skins"
	skins_button.tooltip_text = "Elegir un estilo visual o personalizar sus colores"
	skins_button.custom_minimum_size.y = 42
	skins_button.pressed.connect(_show_appearance)
	navigation.add_child(skins_button)
	var campaign_button := Button.new()
	campaign_button.text = "Campaña"
	campaign_button.tooltip_text = "Exportar o importar todos los datos de la campaña"
	campaign_button.pressed.connect(_show_campaign_manager)
	navigation.add_child(campaign_button)
	var zoom_out := Button.new()
	zoom_out.text = "−"
	zoom_out.tooltip_text = "Alejar la hoja"
	zoom_out.custom_minimum_size.x = 38
	zoom_out.pressed.connect(func(): _set_sheet_zoom(sheet_zoom - 0.10))
	navigation.add_child(zoom_out)
	sheet_zoom_controls.append(zoom_out)
	sheet_zoom_label = Button.new()
	sheet_zoom_label.text = "100%"
	sheet_zoom_label.tooltip_text = "Restablecer zoom al 100 %"
	sheet_zoom_label.custom_minimum_size.x = 64
	sheet_zoom_label.pressed.connect(func(): _set_sheet_zoom(1.0))
	navigation.add_child(sheet_zoom_label)
	sheet_zoom_controls.append(sheet_zoom_label)
	var zoom_in := Button.new()
	zoom_in.text = "+"
	zoom_in.tooltip_text = "Acercar la hoja"
	zoom_in.custom_minimum_size.x = 38
	zoom_in.pressed.connect(func(): _set_sheet_zoom(sheet_zoom + 0.10))
	navigation.add_child(zoom_in)
	sheet_zoom_controls.append(zoom_in)
	for zoom_control in sheet_zoom_controls:
		zoom_control.hide()
	row.add_child(navigation)
	appearance_popup = Window.new()
	appearance_popup.borderless = false
	add_child(appearance_popup)
	appearance_popup.hide()
	var appearance_content := _appearance()
	# Mantener un mínimo pequeño evita que el contenido fuerce la ventana fuera
	# de una pantalla vertical. El ScrollContainer se ocupa del espacio restante.
	appearance_content.custom_minimum_size = Vector2(280, 180)
	appearance_popup.add_child(appearance_content)
	sheets_popup = Window.new()
	sheets_popup.borderless = false
	add_child(sheets_popup)
	sheets_popup.hide()
	sheets_popup.add_child(_sheets_manager())
	sheet_export_dialog = FileDialog.new()
	sheet_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_configure_external_file_dialog(sheet_export_dialog)
	sheet_export_dialog.add_filter("*.dndsheet", "Hoja de personaje portátil", "application/octet-stream")
	sheet_export_dialog.file_selected.connect(_export_sheet_to_path)
	add_child(sheet_export_dialog)
	sheet_import_dialog = FileDialog.new()
	sheet_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(sheet_import_dialog)
	sheet_import_dialog.add_filter("*.dndsheet,*.json", "Hojas de personaje", "application/json,application/octet-stream")
	sheet_import_dialog.file_selected.connect(_import_sheet_from_path)
	add_child(sheet_import_dialog)
	_setup_sheet_import_loading_popup()
	_setup_campaign_manager()
	var type_slot := VBoxContainer.new()
	header_type_slot = type_slot
	type_slot.custom_minimum_size.x = 150
	type_slot.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(type_slot)
	var type_label := Label.new()
	type_label.text = "TIPO DE HOJA"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", MUTED)
	type_slot.add_child(type_label)
	header_sheet_type_option = OptionButton.new()
	header_sheet_type_option.fit_to_longest_item = false
	header_sheet_type_option.custom_minimum_size = Vector2(150, 34)
	header_sheet_type_option.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for type_name in SHEET_TYPES:
		header_sheet_type_option.add_item(type_name)
	header_sheet_type_option.item_selected.connect(_on_sheet_type_selected)
	type_slot.add_child(header_sheet_type_option)
	return row

func _show_page(index: int) -> void:
	if page_tabs != null:
		page_tabs.current_tab = index
		# Hoja, Inventario y Conjuros comparten zoom; los controles se ocultan en
		# Mesa/Biblioteca porque esas vistas manejan su propia escala.
		for zoom_control in sheet_zoom_controls:
			zoom_control.visible = index <= 2
		if index <= 2:
			_set_sheet_zoom(sheet_zoom)
		sheet_touch_points.clear()
		sheet_pinch_distance = 0.0
		if index == 4:
			_refresh_library()

func _library_page() -> Control:
	var page := BoxContainer.new()
	page.vertical = false
	library_layout = page
	page.custom_minimum_size.y = 680
	page.add_theme_constant_override("separation", 16)
	var sidebar_panel := PanelContainer.new()
	library_sidebar_panel = sidebar_panel
	sidebar_panel.custom_minimum_size.x = 285
	sidebar_panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.5), 1, 16))
	page.add_child(sidebar_panel)
	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 10)
	sidebar_panel.add_child(sidebar)
	var title := Label.new()
	title.text = "▦  BIBLIOTECA PERSONAL"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	sidebar.add_child(title)
	var notice := Label.new()
	notice.text = "Importa únicamente libros que tengas derecho a utilizar. Los archivos permanecen en tu equipo."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 12)
	notice.add_theme_color_override("font_color", MUTED)
	sidebar.add_child(notice)
	library_list = ItemList.new()
	library_list.custom_minimum_size.y = 310
	library_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library_list.item_selected.connect(_show_library_book)
	sidebar.add_child(library_list)
	var library_buttons := HFlowContainer.new()
	library_buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	var import_button := Button.new()
	import_button.text = "+ PDF"
	import_button.tooltip_text = "Importar e indexar un libro PDF"
	import_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_button.pressed.connect(func(): _show_external_file_dialog(library_pdf_dialog))
	library_buttons.add_child(import_button)
	var remove_button := Button.new()
	remove_button.text = "× Quitar"
	remove_button.pressed.connect(_remove_library_book)
	library_buttons.add_child(remove_button)
	var view_button := Button.new()
	view_button.text = "▣ Ver PDF"
	view_button.pressed.connect(_view_selected_pdf)
	library_buttons.add_child(view_button)
	sidebar.add_child(library_buttons)
	library_status = Label.new()
	library_status.text = "Sin documentos importados."
	library_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	library_status.add_theme_font_size_override("font_size", 12)
	library_status.add_theme_color_override("font_color", MUTED)
	sidebar.add_child(library_status)
	var library_tabs := TabContainer.new()
	library_tabs_control = library_tabs
	library_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	library_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library_tabs.add_theme_stylebox_override("panel", _box(Color("#171619"), 12, GOLD.darkened(0.55), 1, 10))
	page.add_child(library_tabs)
	var assistant_panel := PanelContainer.new()
	assistant_panel.name = "Consulta PDF"
	assistant_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	assistant_panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.45), 1, 20))
	library_tabs.add_child(assistant_panel)
	var assistant := VBoxContainer.new()
	assistant_panel.add_child(assistant)
	var assistant_title := Label.new()
	assistant_title.text = "⌕  ASISTENTE DE CONSULTA"
	assistant_title.add_theme_font_size_override("font_size", 22)
	assistant_title.add_theme_color_override("font_color", GOLD)
	assistant.add_child(assistant_title)
	var assistant_hint := Label.new()
	assistant_hint.text = "Busca exclusivamente en los PDF importados y muestra el libro y la página de cada resultado."
	assistant_hint.add_theme_color_override("font_color", MUTED)
	assistant.add_child(assistant_hint)
	var question_row := HBoxContainer.new()
	assistant.add_child(question_row)
	library_question = LineEdit.new()
	library_question.placeholder_text = "Pregunta por una regla, criatura, conjuro, objeto…"
	library_question.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	library_question.text_submitted.connect(func(_text: String): _ask_library())
	question_row.add_child(library_question)
	var ask_button := Button.new()
	ask_button.text = "Consultar"
	ask_button.pressed.connect(_ask_library)
	question_row.add_child(ask_button)
	library_answer = TextEdit.new()
	library_answer.editable = false
	library_answer.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	library_answer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library_answer.text = "Importa uno o más PDF y escribe una consulta."
	assistant.add_child(library_answer)
	var catalog_panel := _library_catalog_panel()
	catalog_panel.name = "Catálogo"
	library_tabs.add_child(catalog_panel)
	library_pdf_dialog = FileDialog.new()
	library_pdf_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(library_pdf_dialog)
	library_pdf_dialog.add_filter("*.pdf", "Documentos PDF", "application/pdf")
	library_pdf_dialog.file_selected.connect(_import_library_pdf)
	add_child(library_pdf_dialog)
	library_catalog_import_dialog = FileDialog.new()
	library_catalog_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_configure_external_file_dialog(library_catalog_import_dialog)
	library_catalog_import_dialog.add_filter("*.dndentry,*.dndlibrary,*.json", "Contenido portátil de biblioteca", "application/json,application/octet-stream")
	library_catalog_import_dialog.files_selected.connect(_import_library_catalog_files)
	add_child(library_catalog_import_dialog)
	library_catalog_export_dialog = FileDialog.new()
	library_catalog_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_configure_external_file_dialog(library_catalog_export_dialog)
	library_catalog_export_dialog.add_filter("*.dndentry,*.dndlibrary", "Contenido portátil de biblioteca", "application/octet-stream")
	library_catalog_export_dialog.file_selected.connect(_export_library_catalog_to_path)
	add_child(library_catalog_export_dialog)
	library_catalog_image_dialog = FileDialog.new()
	library_catalog_image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(library_catalog_image_dialog)
	library_catalog_image_dialog.add_filter("*.png,*.jpg,*.jpeg,*.webp", "Imagen del objeto", "image/png,image/jpeg,image/webp")
	library_catalog_image_dialog.file_selected.connect(_load_library_catalog_image)
	add_child(library_catalog_image_dialog)
	pdf_viewer_popup = Window.new()
	pdf_viewer_popup.borderless = false
	add_child(pdf_viewer_popup)
	pdf_viewer_popup.hide()
	pdf_viewer_popup.add_child(_pdf_viewer_panel())
	_refresh_library.call_deferred()
	_load_library_catalog.call_deferred()
	return page

func _library_catalog_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.45), 1, 20))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	body.add_child(heading)
	var title := Label.new()
	title.text = "▦  CATÁLOGO DE REFERENCIA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var new_top_button := Button.new()
	new_top_button.text = "+ Nueva ficha"
	new_top_button.tooltip_text = "Crear una entrada vacía"
	new_top_button.pressed.connect(_new_library_catalog_entry)
	heading.add_child(new_top_button)
	var hint := Label.new()
	hint.text = "Guarda objetos, enemigos, conjuros y reglas con el libro o página de origen. El asistente también consulta estas fichas."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	body.add_child(hint)
	library_catalog_search = LineEdit.new()
	library_catalog_search.placeholder_text = "⌕  Buscar objetos, enemigos, conjuros, reglas…"
	library_catalog_search.text_changed.connect(func(_text: String): _refresh_library_catalog())
	body.add_child(library_catalog_search)
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 10)
	body.add_child(filter_row)
	library_catalog_filter = OptionButton.new()
	library_catalog_filter.custom_minimum_size.x = 180
	library_catalog_filter.add_item("Todas las categorías")
	for category in LIBRARY_CATEGORIES:
		library_catalog_filter.add_item(category)
	library_catalog_filter.item_selected.connect(func(_index: int): _refresh_library_catalog())
	filter_row.add_child(library_catalog_filter)
	library_catalog_count_label = Label.new()
	library_catalog_count_label.text = "0 entradas"
	library_catalog_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	library_catalog_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	library_catalog_count_label.add_theme_color_override("font_color", MUTED)
	filter_row.add_child(library_catalog_count_label)
	var columns := BoxContainer.new()
	columns.vertical = false
	library_catalog_layout = columns
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size.x = 300
	list_panel.add_theme_stylebox_override("panel", _box(FIELD, 10, GOLD.darkened(0.55), 1, 10))
	columns.add_child(list_panel)
	library_catalog_list = ItemList.new()
	library_catalog_list.custom_minimum_size = Vector2(280, 390)
	library_catalog_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library_catalog_list.fixed_icon_size = Vector2i(56, 56)
	library_catalog_list.icon_mode = ItemList.ICON_MODE_LEFT
	library_catalog_list.item_selected.connect(_select_library_catalog_entry)
	list_panel.add_child(library_catalog_list)
	var form_panel := PanelContainer.new()
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.add_theme_stylebox_override("panel", _box(FIELD, 10, GOLD.darkened(0.55), 1, 14))
	columns.add_child(form_panel)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.add_child(form)
	var form_title := Label.new()
	form_title.text = "DETALLES DE LA ENTRADA"
	form_title.add_theme_color_override("font_color", GOLD)
	form_title.add_theme_font_size_override("font_size", 16)
	form.add_child(form_title)
	var summary_row := BoxContainer.new()
	# El editor ocupa una columna estrecha junto a la lista. Mantener imagen y
	# campos en horizontal provocaba cortes y una barra lateral innecesaria.
	summary_row.vertical = true
	summary_row.add_theme_constant_override("separation", 14)
	form.add_child(summary_row)
	var image_card := PanelContainer.new()
	image_card.custom_minimum_size = Vector2(190, 210)
	image_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_card.add_theme_stylebox_override("panel", _box(Color("#111013"), 10, GOLD.darkened(0.35), 1, 8))
	summary_row.add_child(image_card)
	var image_box := VBoxContainer.new()
	image_box.add_theme_constant_override("separation", 6)
	image_card.add_child(image_box)
	library_catalog_image_preview = TextureRect.new()
	library_catalog_image_preview.custom_minimum_size = Vector2(174, 145)
	library_catalog_image_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	library_catalog_image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_box.add_child(library_catalog_image_preview)
	library_catalog_image_hint = Label.new()
	library_catalog_image_hint.text = "Sin imagen"
	library_catalog_image_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	library_catalog_image_hint.add_theme_color_override("font_color", MUTED)
	image_box.add_child(library_catalog_image_hint)
	var image_actions := HBoxContainer.new()
	image_box.add_child(image_actions)
	var choose_image := Button.new()
	choose_image.text = "Elegir"
	choose_image.tooltip_text = "Añadir PNG, JPG o WebP (máximo 6 MB)"
	choose_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose_image.pressed.connect(func(): _show_external_file_dialog(library_catalog_image_dialog))
	image_actions.add_child(choose_image)
	var remove_image := Button.new()
	remove_image.text = "Quitar"
	remove_image.tooltip_text = "Quitar la imagen de esta entrada"
	remove_image.pressed.connect(_clear_library_catalog_image)
	image_actions.add_child(remove_image)
	var basic_fields := VBoxContainer.new()
	basic_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic_fields.add_theme_constant_override("separation", 8)
	summary_row.add_child(basic_fields)
	var category_label := Label.new()
	category_label.text = "CATEGORÍA"
	category_label.add_theme_font_size_override("font_size", 11)
	category_label.add_theme_color_override("font_color", MUTED)
	basic_fields.add_child(category_label)
	library_catalog_category = OptionButton.new()
	for category in LIBRARY_CATEGORIES:
		library_catalog_category.add_item(category)
	basic_fields.add_child(library_catalog_category)
	var name_label := Label.new()
	name_label.text = "NOMBRE"
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", MUTED)
	basic_fields.add_child(name_label)
	library_catalog_name = LineEdit.new()
	library_catalog_name.placeholder_text = "Nombre de la entrada"
	basic_fields.add_child(library_catalog_name)
	var source_label := Label.new()
	source_label.text = "FUENTE"
	source_label.add_theme_font_size_override("font_size", 11)
	source_label.add_theme_color_override("font_color", MUTED)
	basic_fields.add_child(source_label)
	library_catalog_source = LineEdit.new()
	library_catalog_source.placeholder_text = "Libro, capítulo o página"
	basic_fields.add_child(library_catalog_source)
	var notes_label := Label.new()
	notes_label.text = "INFORMACIÓN Y ESTADÍSTICAS"
	notes_label.add_theme_font_size_override("font_size", 11)
	notes_label.add_theme_color_override("font_color", MUTED)
	form.add_child(notes_label)
	library_catalog_notes = TextEdit.new()
	library_catalog_notes.placeholder_text = "Estadísticas, descripción, reglas, precio, daño, habilidades…"
	# Parte las líneas largas y elimina la barra horizontal del editor.
	library_catalog_notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	# El formulario no siempre recibe espacio vertical del contenedor principal;
	# este mínimo garantiza una zona útil para escribir información extensa.
	library_catalog_notes.custom_minimum_size.y = 260
	library_catalog_notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(library_catalog_notes)
	var buttons := HFlowContainer.new()
	form.add_child(buttons)
	for definition in [["✓ Guardar", _save_library_catalog_entry], ["⧉ Duplicar", _duplicate_library_catalog_entry], ["⇩ Importar", _choose_library_catalog_import], ["⇧ Exportar ficha", _choose_library_catalog_export], ["⇧ Exportar todo", _choose_library_catalog_export_all], ["▣ Usar PDF", _use_selected_pdf_as_catalog_source], ["× Eliminar", _delete_library_catalog_entry]]:
		var button := Button.new()
		button.text = definition[0]
		button.pressed.connect(definition[1])
		buttons.add_child(button)
	var play_label := Label.new()
	play_label.text = "USAR EN LA PARTIDA"
	play_label.add_theme_font_size_override("font_size", 10)
	play_label.add_theme_color_override("font_color", MUTED)
	form.add_child(play_label)
	var play_actions := HFlowContainer.new()
	play_actions.add_theme_constant_override("h_separation", 8)
	play_actions.add_theme_constant_override("v_separation", 8)
	form.add_child(play_actions)
	for definition in [["🎒 Enviar al inventario", _send_catalog_object_to_inventory], ["✦ Añadir al mazo", _send_catalog_spell_to_deck], ["☠ Crear enemigo en mesa", _create_enemy_from_catalog]]:
		var action := Button.new()
		action.text = definition[0]
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.pressed.connect(definition[1])
		play_actions.add_child(action)
	return panel

func _pdf_viewer_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 400)
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.45), 1, 14))
	var body := VBoxContainer.new()
	panel.add_child(body)
	var toolbar := HFlowContainer.new()
	body.add_child(toolbar)
	var previous := Button.new()
	previous.text = "← Anterior"
	previous.pressed.connect(func(): _change_pdf_page(-1))
	toolbar.add_child(previous)
	pdf_page_label = Label.new()
	pdf_page_label.text = "Página —"
	pdf_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pdf_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(pdf_page_label)
	var next := Button.new()
	next.text = "Siguiente →"
	next.pressed.connect(func(): _change_pdf_page(1))
	toolbar.add_child(next)
	var external := Button.new()
	external.text = "Abrir original"
	external.pressed.connect(func(): OS.shell_open(pdf_current_path) if not pdf_current_path.is_empty() else OK)
	toolbar.add_child(external)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(scroll)
	pdf_page_texture = TextureRect.new()
	pdf_page_texture.custom_minimum_size = Vector2(920, 1200)
	pdf_page_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pdf_page_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scroll.add_child(pdf_page_texture)
	return panel

func _library_dir() -> String:
	return "user://library_index"

func _refresh_library() -> void:
	if library_list == null:
		return
	library_list.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_library_dir()))
	var directory := DirAccess.open(_library_dir())
	if directory == null:
		return
	var files := directory.get_files()
	files.sort()
	for filename in files:
		if not filename.ends_with(".json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(_library_dir() + "/" + filename))
		if not data is Dictionary:
			continue
		var index := library_list.add_item("%s\n%d páginas" % [str(data.get("title", filename.get_basename())), int(data.get("page_count", 0))])
		library_list.set_item_metadata(index, filename)
	library_status.text = "%d documento(s) disponibles." % library_list.item_count

func _python_for_pdf() -> String:
	var profile := OS.get_environment("USERPROFILE")
	var bundled := profile.path_join(".cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe")
	if FileAccess.file_exists(bundled):
		return bundled
	return "python"

func _import_library_pdf(path: String) -> void:
	if library_thread != null and library_thread.is_alive():
		library_status.text = "Espera a que termine la importación actual."
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_library_dir()))
	var target := _library_dir() + "/book_%d.json" % Time.get_ticks_msec()
	library_status.text = "Indexando %s…" % path.get_file()
	library_thread = Thread.new()
	library_thread.start(_index_pdf_thread.bind(path, target))

func _index_pdf_thread(source: String, target: String) -> void:
	var output: Array[String] = []
	var script_path := ProjectSettings.globalize_path("res://pdf_indexer.py")
	var target_path := ProjectSettings.globalize_path(target)
	var exit_code := OS.execute(_python_for_pdf(), PackedStringArray([script_path, source, target_path]), output, true)
	_finish_pdf_import.call_deferred(exit_code, target, "\n".join(output))

func _finish_pdf_import(exit_code: int, target: String, output: String) -> void:
	if library_thread != null:
		library_thread.wait_to_finish()
		library_thread = null
	if exit_code == 0 and FileAccess.file_exists(target):
		var detected_count := _add_pdf_detected_entries(target)
		library_status.text = "PDF importado e indexado. %d entrada(s) detectada(s), marcadas para revisar en Catálogo." % detected_count
		_refresh_library()
	else:
		library_status.text = "No se pudo extraer el PDF. Comprueba que Python y pypdf estén disponibles. " + output.left(160)

# Convierte las sugerencias conservadoras del indexador en entradas editables.
# Ninguna se trata como definitiva: quedan marcadas para que el director pueda
# corregir nombre, categoría, texto o eliminarlas desde la pestaña Catálogo.
func _add_pdf_detected_entries(index_path: String) -> int:
	var indexed: Variant = JSON.parse_string(FileAccess.get_file_as_string(index_path))
	if not indexed is Dictionary or not indexed.get("suggestions", []) is Array:
		return 0
	var book_title := str(indexed.get("title", "PDF importado")).strip_edges()
	var known: Dictionary = {}
	for existing in library_catalog_entries:
		if existing is Dictionary:
			known[_library_catalog_identity(existing)] = true
	var added := 0
	for suggestion_value in indexed.suggestions:
		if added >= 80 or library_catalog_entries.size() >= MAX_LIBRARY_CATALOG_ENTRIES:
			break
		if not suggestion_value is Dictionary:
			continue
		var category := str(suggestion_value.get("category", "Otro"))
		if category not in LIBRARY_CATEGORIES:
			category = "Otro"
		var name := str(suggestion_value.get("name", "")).strip_edges().substr(0, 120)
		if name.is_empty():
			continue
		var page := maxi(int(suggestion_value.get("page", 0)), 0)
		var source := book_title + (" · página %d" % page if page > 0 else "")
		var entry := _sanitize_library_catalog_entry({
			"category": category,
			"name": name,
			"source": source,
			"notes": str(suggestion_value.get("notes", "")).strip_edges().substr(0, 20000),
			"updated_at": Time.get_datetime_string_from_system(),
			"needs_review": true
		})
		if entry.is_empty():
			continue
		var identity := _library_catalog_identity(entry)
		if known.has(identity):
			continue
		entry["needs_review"] = true
		entry["detected_from_pdf"] = book_title
		known[identity] = true
		library_catalog_entries.append(entry)
		added += 1
	if added > 0:
		_write_library_catalog()
		_refresh_library_catalog()
	return added

func _show_library_book(index: int) -> void:
	var filename := str(library_list.get_item_metadata(index))
	var data = JSON.parse_string(FileAccess.get_file_as_string(_library_dir() + "/" + filename))
	if data is Dictionary:
		library_status.text = "%s • %d páginas\n%s" % [str(data.get("title", "Libro")), int(data.get("page_count", 0)), str(data.get("source_path", ""))]

func _view_selected_pdf() -> void:
	var selected := library_list.get_selected_items()
	if selected.is_empty():
		library_status.text = "Selecciona un documento para visualizarlo."
		return
	var filename := str(library_list.get_item_metadata(selected[0]))
	var data = JSON.parse_string(FileAccess.get_file_as_string(_library_dir() + "/" + filename))
	if not data is Dictionary:
		return
	pdf_current_path = str(data.get("source_path", ""))
	pdf_page_count = int(data.get("page_count", 0))
	pdf_current_page = 1
	if not FileAccess.file_exists(pdf_current_path):
		library_status.text = "El PDF original ya no existe en su ubicación."
		return
	_render_pdf_page()
	_toggle_floating_window(pdf_viewer_popup, Vector2i(1020, 740), "Biblioteca PDF")

func _poppler_executable() -> String:
	var profile := OS.get_environment("USERPROFILE")
	var bundled := profile.path_join(".cache/codex-runtimes/codex-primary-runtime/dependencies/native/poppler/Library/bin/pdftoppm.exe")
	if FileAccess.file_exists(bundled):
		return bundled
	return "pdftoppm"

func _change_pdf_page(direction: int) -> void:
	var target := clampi(pdf_current_page + direction, 1, maxi(pdf_page_count, 1))
	if target == pdf_current_page:
		return
	pdf_current_page = target
	_render_pdf_page()

func _render_pdf_page() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://library_cache"))
	var prefix := ProjectSettings.globalize_path("user://library_cache/current_page")
	var output: Array[String] = []
	var args := PackedStringArray(["-f", str(pdf_current_page), "-l", str(pdf_current_page), "-scale-to", "1500", "-png", "-singlefile", pdf_current_path, prefix])
	var exit_code := OS.execute(_poppler_executable(), args, output, true)
	var rendered := prefix + ".png"
	if exit_code != 0 or not FileAccess.file_exists(rendered):
		pdf_page_label.text = "No se pudo renderizar la página"
		return
	var image := Image.new()
	if image.load(rendered) == OK:
		pdf_page_texture.texture = ImageTexture.create_from_image(image)
		pdf_page_texture.custom_minimum_size = Vector2(920, 920.0 * image.get_height() / maxf(image.get_width(), 1.0))
		pdf_page_label.text = "Página %d de %d" % [pdf_current_page, pdf_page_count]

func _remove_library_book() -> void:
	var selected := library_list.get_selected_items()
	if selected.is_empty():
		library_status.text = "Selecciona un documento para quitarlo."
		return
	var filename := str(library_list.get_item_metadata(selected[0]))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_library_dir() + "/" + filename))
	_refresh_library()

func _load_library_catalog() -> void:
	library_catalog_entries.clear()
	if FileAccess.file_exists(LIBRARY_CATALOG_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LIBRARY_CATALOG_PATH))
		if parsed is Array:
			for entry in parsed:
				if entry is Dictionary:
					library_catalog_entries.append(entry.duplicate(true))
	_refresh_library_catalog()

func _write_library_catalog() -> void:
	var file := FileAccess.open(LIBRARY_CATALOG_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(library_catalog_entries, "  "))

func _refresh_library_catalog() -> void:
	if library_catalog_list == null:
		_refresh_spell_library()
		return
	library_catalog_list.clear()
	var query: String = library_catalog_search.text.strip_edges().to_lower() if library_catalog_search != null else ""
	var category_filter := ""
	if library_catalog_filter != null and library_catalog_filter.selected > 0:
		category_filter = library_catalog_filter.get_item_text(library_catalog_filter.selected)
	var visible_count := 0
	for index in range(library_catalog_entries.size()):
		var entry: Dictionary = library_catalog_entries[index]
		var searchable := "%s %s %s %s" % [entry.get("category", ""), entry.get("name", ""), entry.get("source", ""), entry.get("notes", "")]
		if not query.is_empty() and query not in searchable.to_lower():
			continue
		var category: String = str(entry.get("category", "Otro"))
		if not category_filter.is_empty() and category != category_filter:
			continue
		var category_icon: String = str({"Objeto": "◆", "Raza": "◈", "Clase": "⚑", "Enemigo": "☠", "Conjuro": "✦", "Regla": "§", "Lugar": "⌂", "PNJ": "●", "Otro": "◇"}.get(category, "◇"))
		var review_mark := "  ·  REVISAR" if bool(entry.get("needs_review", false)) else ""
		var item := library_catalog_list.add_item("%s  %s  ·  %s%s\n%s" % [category_icon, category, entry.get("name", "Sin nombre"), review_mark, entry.get("source", "Sin fuente")])
		library_catalog_list.set_item_metadata(item, index)
		var icon := _library_catalog_texture(str(entry.get("image_data", "")), str(entry.get("image_format", "")), 56)
		if icon != null:
			library_catalog_list.set_item_icon(item, icon)
		visible_count += 1
	if library_catalog_count_label != null:
		library_catalog_count_label.text = "%d de %d entradas" % [visible_count, library_catalog_entries.size()]
	_refresh_spell_library()

func _select_library_catalog_entry(item_index: int) -> void:
	var entry_index: int = int(library_catalog_list.get_item_metadata(item_index))
	if entry_index < 0 or entry_index >= library_catalog_entries.size():
		return
	library_catalog_selected = entry_index
	var entry: Dictionary = library_catalog_entries[entry_index]
	var wanted_category: String = str(entry.get("category", "Otro"))
	for index in range(library_catalog_category.item_count):
		if library_catalog_category.get_item_text(index) == wanted_category:
			library_catalog_category.select(index)
			break
	library_catalog_name.text = str(entry.get("name", ""))
	library_catalog_source.text = str(entry.get("source", ""))
	library_catalog_notes.text = str(entry.get("notes", ""))
	library_catalog_image_data = str(entry.get("image_data", ""))
	library_catalog_image_format = str(entry.get("image_format", ""))
	_refresh_library_catalog_image_preview()

func _new_library_catalog_entry() -> void:
	library_catalog_selected = -1
	if library_catalog_category != null:
		library_catalog_category.select(0)
	library_catalog_name.clear()
	library_catalog_source.clear()
	library_catalog_notes.clear()
	_clear_library_catalog_image()
	library_catalog_name.grab_focus()

func _save_library_catalog_entry() -> void:
	var entry_name: String = library_catalog_name.text.strip_edges().substr(0, 120)
	if entry_name.is_empty():
		_set_status("Escribe un nombre para la entrada del catálogo.", true)
		return
	var entry: Dictionary = {
		"category": library_catalog_category.get_item_text(library_catalog_category.selected),
		"name": entry_name,
		"source": library_catalog_source.text.strip_edges().substr(0, 240),
		"notes": library_catalog_notes.text.substr(0, 20000),
		"image_data": library_catalog_image_data,
		"image_format": library_catalog_image_format,
		"updated_at": Time.get_datetime_string_from_system()
	}
	# Al guardar manualmente, la entrada ya fue revisada por el usuario.
	entry["needs_review"] = false
	if library_catalog_selected >= 0 and library_catalog_selected < library_catalog_entries.size() and library_catalog_entries[library_catalog_selected].has("spell_data") and str(entry.category) == "Conjuro":
		entry["spell_data"] = library_catalog_entries[library_catalog_selected].spell_data
	if library_catalog_selected >= 0 and library_catalog_selected < library_catalog_entries.size() and library_catalog_entries[library_catalog_selected].has("monster_data") and str(entry.category) == "Enemigo":
		entry["monster_data"] = library_catalog_entries[library_catalog_selected].monster_data
	if library_catalog_selected >= 0 and library_catalog_selected < library_catalog_entries.size():
		library_catalog_entries[library_catalog_selected] = entry
	else:
		library_catalog_entries.append(entry)
		library_catalog_selected = library_catalog_entries.size() - 1
	_write_library_catalog()
	_refresh_library_catalog()
	_select_library_catalog_by_entry_index(library_catalog_selected)
	_set_status("Entrada guardada en el catálogo: %s." % entry_name)

func _select_library_catalog_by_entry_index(entry_index: int) -> void:
	if library_catalog_list == null:
		return
	for item_index in range(library_catalog_list.item_count):
		if int(library_catalog_list.get_item_metadata(item_index)) == entry_index:
			library_catalog_list.select(item_index)
			library_catalog_list.ensure_current_is_visible()
			return

func _duplicate_library_catalog_entry() -> void:
	if library_catalog_selected < 0 or library_catalog_selected >= library_catalog_entries.size():
		_set_status("Selecciona primero una entrada para duplicarla.", true)
		return
	if library_catalog_entries.size() >= MAX_LIBRARY_CATALOG_ENTRIES:
		_set_status("El catálogo alcanzó su límite de entradas.", true)
		return
	var duplicate: Dictionary = library_catalog_entries[library_catalog_selected].duplicate(true)
	duplicate["name"] = "%s (copia)" % str(duplicate.get("name", "Entrada"))
	duplicate["updated_at"] = Time.get_datetime_string_from_system()
	library_catalog_entries.append(duplicate)
	library_catalog_selected = library_catalog_entries.size() - 1
	_write_library_catalog()
	_refresh_library_catalog()
	_select_library_catalog_by_entry_index(library_catalog_selected)
	library_catalog_name.text = str(duplicate.get("name", ""))
	library_catalog_source.text = str(duplicate.get("source", ""))
	library_catalog_notes.text = str(duplicate.get("notes", ""))
	library_catalog_image_data = str(duplicate.get("image_data", ""))
	library_catalog_image_format = str(duplicate.get("image_format", ""))
	_refresh_library_catalog_image_preview()
	_set_status("Copia creada. Modifícala y pulsa Guardar.")

func _delete_library_catalog_entry() -> void:
	if library_catalog_selected < 0 or library_catalog_selected >= library_catalog_entries.size():
		_set_status("Selecciona una entrada del catálogo para eliminarla.", true)
		return
	library_catalog_entries.remove_at(library_catalog_selected)
	library_catalog_selected = -1
	_write_library_catalog()
	_new_library_catalog_entry()
	_refresh_library_catalog()
	_set_status("Entrada eliminada del catálogo.")

func _load_library_catalog_image(source: String) -> void:
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		_set_status("No se pudo abrir la imagen seleccionada.", true)
		return
	var byte_count: int = int(file.get_length())
	if byte_count <= 0 or byte_count > MAX_LIBRARY_ENTRY_IMAGE_BYTES:
		file.close()
		_set_status("La imagen debe ocupar menos de 6 MB.", true)
		return
	var bytes: PackedByteArray = file.get_buffer(byte_count)
	file.close()
	var decoded := _decode_library_catalog_image(bytes, source.get_extension().to_lower())
	if decoded.is_empty():
		_set_status("La imagen no es un PNG, JPG o WebP válido.", true)
		return
	library_catalog_image_data = Marshalls.raw_to_base64(bytes)
	library_catalog_image_format = str(decoded.get("format", ""))
	_refresh_library_catalog_image_preview()
	_set_status("Imagen añadida. Pulsa Guardar para conservarla con el objeto.")

func _clear_library_catalog_image() -> void:
	library_catalog_image_data = ""
	library_catalog_image_format = ""
	_refresh_library_catalog_image_preview()

func _refresh_library_catalog_image_preview() -> void:
	if library_catalog_image_preview == null:
		return
	library_catalog_image_preview.texture = _library_catalog_texture(library_catalog_image_data, library_catalog_image_format, 480)
	if library_catalog_image_hint != null:
		library_catalog_image_hint.text = "Imagen del objeto" if library_catalog_image_preview.texture != null else "Sin imagen"

func _decode_library_catalog_image(bytes: PackedByteArray, preferred_format: String) -> Dictionary:
	var formats: Array[String] = []
	var normalized := "jpg" if preferred_format == "jpeg" else preferred_format
	if normalized in ["png", "jpg", "webp"]:
		formats.append(normalized)
	for fallback in ["png", "jpg", "webp"]:
		if fallback not in formats:
			formats.append(fallback)
	for format in formats:
		var image := Image.new()
		var error := ERR_FILE_UNRECOGNIZED
		match format:
			"png": error = image.load_png_from_buffer(bytes)
			"jpg": error = image.load_jpg_from_buffer(bytes)
			"webp": error = image.load_webp_from_buffer(bytes)
		if error == OK and not image.is_empty():
			return {"image": image, "format": format}
	return {}

func _library_catalog_texture(encoded: String, image_format: String, maximum_side: int) -> Texture2D:
	if encoded.is_empty():
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	if bytes.is_empty() or bytes.size() > MAX_LIBRARY_ENTRY_IMAGE_BYTES:
		return null
	var decoded := _decode_library_catalog_image(bytes, image_format)
	if decoded.is_empty():
		return null
	var image: Image = decoded.get("image")
	var largest_side: int = maxi(image.get_width(), image.get_height())
	if largest_side > maximum_side:
		var ratio: float = float(maximum_side) / float(largest_side)
		image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func _choose_library_catalog_import() -> void:
	_show_external_file_dialog(library_catalog_import_dialog)

func _choose_library_catalog_export() -> void:
	if library_catalog_selected < 0 or library_catalog_selected >= library_catalog_entries.size():
		_set_status("Selecciona primero un objeto o entrada guardada para exportarla.", true)
		return
	pending_library_catalog_export = library_catalog_entries[library_catalog_selected].duplicate(true)
	library_catalog_export_all = false
	var portable_name := str(pending_library_catalog_export.get("name", "objeto")).validate_filename()
	if portable_name.is_empty():
		portable_name = "objeto"
	library_catalog_export_dialog.current_file = portable_name + "." + LIBRARY_ENTRY_EXTENSION
	_show_external_file_dialog(library_catalog_export_dialog)

func _choose_library_catalog_export_all() -> void:
	if library_catalog_entries.is_empty():
		_set_status("La biblioteca está vacía; todavía no hay nada que exportar.", true)
		return
	pending_library_catalog_export.clear()
	library_catalog_export_all = true
	library_catalog_export_dialog.current_file = "mi_biblioteca." + LIBRARY_COLLECTION_EXTENSION
	_show_external_file_dialog(library_catalog_export_dialog)

func _export_library_catalog_to_path(destination: String) -> void:
	if pending_library_catalog_export.is_empty() and not library_catalog_export_all:
		_set_status("No hay una entrada preparada para exportar.", true)
		return
	var final_path := destination
	var expected_extension := LIBRARY_COLLECTION_EXTENSION if library_catalog_export_all else LIBRARY_ENTRY_EXTENSION
	if final_path.get_extension().to_lower() != expected_extension:
		final_path += "." + expected_extension
	var output := FileAccess.open(final_path, FileAccess.WRITE)
	if output == null:
		_set_status("No se pudo escribir el objeto exportado.", true)
		return
	var exported_entries: Array = library_catalog_entries.duplicate(true) if library_catalog_export_all else [pending_library_catalog_export]
	var portable := {
		"format": "dnd-library-collection" if library_catalog_export_all else "dnd-library-entry",
		"version": 1,
		"exported_at": Time.get_datetime_string_from_system(),
		"entries": exported_entries
	}
	output.store_string(JSON.stringify(portable, "  "))
	output.close()
	var exported_name := "%d entradas" % exported_entries.size() if library_catalog_export_all else str(pending_library_catalog_export.get("name", "Entrada"))
	pending_library_catalog_export.clear()
	library_catalog_export_all = false
	_set_status("%s exportado. Ya puedes enviarlo a otro jugador." % exported_name)

func _import_library_catalog_files(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return
	var previous_count := library_catalog_entries.size()
	for path in paths:
		_import_library_catalog_from_path(path)
	var added_count := library_catalog_entries.size() - previous_count
	if added_count > 0:
		_set_status("Importación terminada: %d entrada(s) nueva(s) desde %d archivo(s)." % [added_count, paths.size()])

func _import_library_catalog_from_path(source: String) -> void:
	var source_file := FileAccess.open(source, FileAccess.READ)
	if source_file == null:
		_set_status("No se pudo abrir el objeto recibido.", true)
		return
	var import_limit := MAX_LIBRARY_COLLECTION_IMPORT_BYTES if source.get_extension().to_lower() == LIBRARY_COLLECTION_EXTENSION else MAX_LIBRARY_IMPORT_BYTES
	if source_file.get_length() > import_limit:
		source_file.close()
		_set_status("El archivo de biblioteca es demasiado grande.", true)
		return
	var parsed: Variant = JSON.parse_string(source_file.get_as_text())
	source_file.close()
	var incoming: Array = []
	if parsed is Dictionary and parsed.get("entries", []) is Array:
		incoming = parsed.get("entries", [])
	elif parsed is Dictionary and parsed.has("name"):
		incoming = [parsed]
	elif parsed is Array:
		incoming = parsed
	else:
		_set_status("El archivo no contiene objetos o entradas válidas.", true)
		return
	var known: Dictionary = {}
	for entry in library_catalog_entries:
		known[_library_catalog_identity(entry)] = true
	var imported_count := 0
	var skipped_count := 0
	for value in incoming:
		if library_catalog_entries.size() >= MAX_LIBRARY_CATALOG_ENTRIES:
			break
		if not value is Dictionary:
			skipped_count += 1
			continue
		var clean_entry := _sanitize_library_catalog_entry(value)
		if clean_entry.is_empty():
			skipped_count += 1
			continue
		var identity := _library_catalog_identity(clean_entry)
		if known.has(identity):
			skipped_count += 1
			continue
		known[identity] = true
		library_catalog_entries.append(clean_entry)
		library_catalog_selected = library_catalog_entries.size() - 1
		imported_count += 1
	if imported_count <= 0:
		_set_status("No se importaron entradas nuevas; pueden estar duplicadas o ser inválidas.", true)
		return
	_write_library_catalog()
	if library_catalog_search != null:
		library_catalog_search.text = ""
	_refresh_library_catalog()
	_set_status("%d entrada(s) importada(s)%s." % [imported_count, " · %d omitida(s)" % skipped_count if skipped_count > 0 else ""])

func _sanitize_spell_library_data(value: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	var allowed := ["name", "level", "level_bonus", "casting_time", "magic_cost", "school", "range", "target", "duration", "effect", "components", "description", "mechanic_name", "mechanic_cost", "mechanic_max", "mechanic_value"]
	for key in allowed:
		if not value.has(key):
			continue
		if key in ["mechanic_cost", "mechanic_max", "mechanic_value"]:
			clean[key] = clampf(float(value[key]), 0.0, 1000000.0)
		else:
			var limit := 20000 if key == "description" else 500
			clean[key] = str(value[key]).substr(0, limit)
	return clean

func _sanitize_monster_library_data(value: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	for key in value:
		var field_name := str(key)
		if not field_name.begins_with("monster_") or field_name.length() > 80:
			continue
		var stored: Variant = value[key]
		if stored is float or stored is int:
			clean[field_name] = clampf(float(stored), -1000000000.0, 1000000000.0)
		else:
			clean[field_name] = str(stored).substr(0, 30000)
	return clean

func _sanitize_library_catalog_entry(value: Dictionary) -> Dictionary:
	var name := str(value.get("name", "")).strip_edges().substr(0, 120)
	if name.is_empty():
		return {}
	var category := str(value.get("category", "Otro"))
	if category not in LIBRARY_CATEGORIES:
		category = "Otro"
	var image_data := str(value.get("image_data", ""))
	var image_format := str(value.get("image_format", "")).to_lower()
	if image_format not in ["png", "jpg", "jpeg", "webp"] or image_data.length() > MAX_LIBRARY_ENTRY_IMAGE_BYTES * 2:
		image_data = ""
		image_format = ""
	elif not image_data.is_empty() and Marshalls.base64_to_raw(image_data).size() > MAX_LIBRARY_ENTRY_IMAGE_BYTES:
		image_data = ""
		image_format = ""
	var clean_entry := {
		"category": category,
		"name": name,
		"source": str(value.get("source", "")).strip_edges().substr(0, 240),
		"notes": str(value.get("notes", "")).substr(0, 20000),
		"image_data": image_data,
		"image_format": image_format,
		"updated_at": str(value.get("updated_at", Time.get_datetime_string_from_system())),
		"imported_at": Time.get_datetime_string_from_system()
	}
	if category == "Conjuro" and value.get("spell_data", {}) is Dictionary:
		clean_entry["spell_data"] = _sanitize_spell_library_data(value.spell_data)
	if category == "Enemigo" and value.get("monster_data", {}) is Dictionary:
		clean_entry["monster_data"] = _sanitize_monster_library_data(value.monster_data)
	return clean_entry

func _library_catalog_identity(entry: Dictionary) -> String:
	return "%s|%s|%s" % [str(entry.get("category", "Otro")).to_lower(), str(entry.get("name", "")).strip_edges().to_lower(), str(entry.get("source", "")).strip_edges().to_lower()]

func _selected_library_catalog_entry() -> Dictionary:
	if library_catalog_selected < 0 or library_catalog_selected >= library_catalog_entries.size():
		_set_status("Selecciona primero una entrada guardada de la biblioteca.", true)
		return {}
	return library_catalog_entries[library_catalog_selected]

func _send_catalog_object_to_inventory() -> void:
	var entry := _selected_library_catalog_entry()
	if entry.is_empty():
		return
	if str(entry.get("category", "")) != "Objeto":
		_set_status("Esta acción solo está disponible para entradas de categoría Objeto.", true)
		return
	var target_index := -1
	for index in range(inventory_count):
		if fields.has("item_%d_name" % index) and fields["item_%d_name" % index].text.strip_edges().is_empty():
			target_index = index
			break
	if target_index < 0:
		_add_inventory_row()
		target_index = inventory_count - 1
	var item_name := str(entry.get("name", "Objeto"))
	var source := str(entry.get("source", "")).strip_edges()
	fields["item_%d_name" % target_index].text = item_name
	if fields.has("item_%d_description" % target_index):
		var notes := str(entry.get("notes", "")).strip_edges()
		fields["item_%d_description" % target_index].text = notes + ("\nFuente: " + source if not source.is_empty() else "")
	fields["item_%d_weight" % target_index].text = _catalog_weight_from_notes(str(entry.get("notes", "")))
	_update_inventory_weight()
	_set_status("%s se añadió al inventario." % item_name)

func _catalog_weight_from_notes(notes: String) -> String:
	var expression := RegEx.new()
	expression.compile("(?i)peso\\s*[:=]?\\s*([0-9]+(?:[.,][0-9]+)?)\\s*(kg|lb|lbs)?")
	var result := expression.search(notes)
	if result == null:
		return "0 kg"
	var number_text := result.get_string(1).replace(",", ".")
	var weight := float(number_text) if number_text.is_valid_float() else 0.0
	var unit := result.get_string(2).to_lower()
	if unit.begins_with("lb"):
		weight *= 0.453592
	return ("%.2f" % weight).trim_suffix("0").trim_suffix(".") + " kg"

func _send_catalog_spell_to_deck() -> void:
	var entry := _selected_library_catalog_entry()
	if entry.is_empty():
		return
	if str(entry.get("category", "")) != "Conjuro":
		_set_status("Esta acción solo está disponible para entradas de categoría Conjuro.", true)
		return
	_add_spell_card()
	var index := spell_count - 1
	fields["spell_%d_name" % index].text = str(entry.get("name", "Conjuro"))
	var notes := str(entry.get("notes", ""))
	var source := str(entry.get("source", "")).strip_edges()
	fields["spell_%d_description" % index].text = notes + ("\n\nFuente: " + source if not source.is_empty() else "")
	var spell_data: Dictionary = entry.get("spell_data", {})
	for suffix in spell_data:
		var key := "spell_%d_%s" % [index, suffix]
		if not fields.has(key):
			continue
		if fields[key] is LineEdit or fields[key] is TextEdit:
			fields[key].text = str(spell_data[suffix])
		elif fields[key] is SpinBox:
			fields[key].value = float(spell_data[suffix])
	_refresh_spell_mechanic_options()
	_refresh_spell_layout()
	_set_status("%s se añadió al mazo de conjuros." % str(entry.get("name", "Conjuro")))

func _create_enemy_from_catalog() -> void:
	var entry := _selected_library_catalog_entry()
	if entry.is_empty():
		return
	if str(entry.get("category", "")) != "Enemigo":
		_set_status("Esta acción solo está disponible para entradas de categoría Enemigo.", true)
		return
	if table_board == null or not _is_table_director():
		_set_status("Solo el director puede crear enemigos en la mesa.", true)
		return
	var enemy_name := str(entry.get("name", "Enemigo"))
	var notes := str(entry.get("notes", ""))
	var hp_max := _catalog_number_from_notes(notes, "(?i)(?:PV|HP|Puntos de golpe)\\s*[:=]?\\s*(\\d+)", 1)
	var hp_current := hp_max
	var armor_class := _catalog_number_from_notes(notes, "(?i)(?:CA|AC|Clase de armadura)\\s*[:=]?\\s*(\\d+)", 10)
	var sheet_data: Dictionary = {"fields": {}, "stats": {}, "options": {}, "colors": {}, "proficiency_lists": {}, "spell_count": 0, "inventory_count": 0, "mechanic_count": 0}
	for color_key in palette:
		sheet_data.colors[color_key] = palette[color_key].to_html(true)
	sheet_data["metadata"] = {"name": enemy_name, "type": "Monstruo", "updated_at": Time.get_datetime_string_from_system()}
	var saved_fields: Dictionary = {}
	for field_key in fields:
		if not str(field_key).begins_with("monster_"):
			continue
		var control = fields[field_key]
		saved_fields[field_key] = 10.0 if control is SpinBox else ""
	var monster_data: Dictionary = entry.get("monster_data", {})
	if monster_data.is_empty():
		saved_fields["monster_name"] = enemy_name
		saved_fields["monster_description"] = str(entry.get("source", ""))
		saved_fields["monster_ac"] = str(armor_class)
		saved_fields["monster_hp_current"] = str(hp_max)
		saved_fields["monster_hp_max"] = str(hp_max)
		saved_fields["monster_traits"] = notes
		saved_fields["monster_actions"] = notes
	else:
		for key in monster_data:
			saved_fields[key] = monster_data[key]
		enemy_name = str(saved_fields.get("monster_name", enemy_name))
		hp_max = maxi(int(saved_fields.get("monster_hp_max", hp_max)), 1)
		hp_current = int(saved_fields.get("monster_hp_current", hp_max))
	sheet_data["fields"] = saved_fields
	var filename := "%d_%d.json" % [int(Time.get_unix_time_from_system()), randi_range(1000, 9999)]
	if not _write_sheet_file(filename, sheet_data):
		_set_status("No se pudo crear la hoja del enemigo.", true)
		return
	var previous_selection := int(table_board.selected_token)
	table_board.add_token()
	if int(table_board.selected_token) == previous_selection:
		_set_status("No se pudo crear la ficha del enemigo en la mesa.", true)
		return
	table_board.set_selected_sheet(filename)
	table_board.set_selected_sheet_snapshot(enemy_name, float(hp_current), float(hp_max))
	var portrait_path := _store_library_entry_image(entry)
	if not portrait_path.is_empty():
		table_board.set_selected_image(portrait_path)
	_refresh_sheets_list()
	_save_table_state()
	_set_status("%s fue creado con hoja de monstruo y añadido a la mesa." % enemy_name)

func _save_current_monster_to_library() -> void:
	var monster_name: String = fields.monster_name.text.strip_edges().substr(0, 120)
	if monster_name.is_empty():
		_set_status("Escribe un nombre para el monstruo antes de guardarlo.", true)
		return
	var monster_data: Dictionary = {}
	for key in fields:
		if not str(key).begins_with("monster_"):
			continue
		var control = fields[key]
		if control is LineEdit or control is TextEdit:
			monster_data[key] = control.text
		elif control is SpinBox:
			monster_data[key] = control.value
	var entry := {
		"category": "Enemigo", "name": monster_name,
		"source": fields.monster_description.text.strip_edges().substr(0, 240),
		"notes": fields.monster_lore.text.substr(0, 20000),
		"image_data": "", "image_format": "", "monster_data": monster_data,
		"updated_at": Time.get_datetime_string_from_system()
	}
	var existing_index := -1
	for index in range(library_catalog_entries.size()):
		if str(library_catalog_entries[index].get("category", "")) == "Enemigo" and str(library_catalog_entries[index].get("name", "")).nocasecmp_to(monster_name) == 0:
			existing_index = index
			break
	if existing_index >= 0:
		entry.image_data = library_catalog_entries[existing_index].get("image_data", "")
		entry.image_format = library_catalog_entries[existing_index].get("image_format", "")
		library_catalog_entries[existing_index] = entry
		library_catalog_selected = existing_index
	else:
		if library_catalog_entries.size() >= MAX_LIBRARY_CATALOG_ENTRIES:
			_set_status("La biblioteca alcanzó su límite de entradas.", true)
			return
		library_catalog_entries.append(entry)
		library_catalog_selected = library_catalog_entries.size() - 1
	_write_library_catalog()
	_refresh_library_catalog()
	_set_status("Monstruo guardado como plantilla: %s." % monster_name)

func _share_current_monster_online() -> void:
	var monster_name: String = fields.monster_name.text.strip_edges().substr(0, 120)
	if monster_name.is_empty():
		_set_status("Escribe un nombre para el monstruo antes de compartirlo.", true)
		return
	_save_current_monster_to_library()
	for index in range(library_catalog_entries.size()):
		if str(library_catalog_entries[index].get("category", "")) == "Enemigo" and str(library_catalog_entries[index].get("name", "")).nocasecmp_to(monster_name) == 0:
			library_catalog_selected = index
			_share_selected_library_entry_online("Enemigo")
			return

func _open_monster_bestiary() -> void:
	_show_page(4)
	if library_catalog_filter != null:
		for index in range(library_catalog_filter.item_count):
			if library_catalog_filter.get_item_text(index) == "Enemigo":
				library_catalog_filter.select(index)
				break
	_refresh_library_catalog()
	if library_catalog_search != null:
		library_catalog_search.grab_focus.call_deferred()
	_set_status("Bestiario abierto: mostrando las plantillas de enemigos.")

func _send_monster_block_to_chat() -> void:
	var monster_name: String = fields.monster_name.text.strip_edges()
	if monster_name.is_empty():
		monster_name = "Monstruo"
	var header := "CA %s • PV %s/%s • Velocidad %s • Desafío %s" % [
		fields.monster_ac.text, fields.monster_hp_current.text, fields.monster_hp_max.text,
		fields.monster_speed.text, fields.monster_challenge.text
	]
	var attributes := "FUE %d • DES %d • CON %d • INT %d • SAB %d • CAR %d" % [
		int(fields.monster_str.value), int(fields.monster_dex.value), int(fields.monster_con.value),
		int(fields.monster_int.value), int(fields.monster_wis.value), int(fields.monster_cha.value)
	]
	var sections: Array[String] = [header, attributes]
	for definition in [["Rasgos", "monster_traits"], ["Acciones", "monster_actions"], ["Reacciones", "monster_reactions"], ["Acciones legendarias", "monster_legendary_actions"]]:
		var content: String = fields[definition[1]].text.strip_edges()
		if not content.is_empty():
			sections.append("%s: %s" % [definition[0], content])
	var message := "\n".join(sections).substr(0, MAX_CHAT_MESSAGE_LENGTH)
	_post_chat(monster_name, message)
	_show_chat()
	_set_status("Bloque de %s enviado al chat." % monster_name)

func _catalog_number_from_notes(notes: String, pattern: String, fallback: int) -> int:
	var expression := RegEx.new()
	if expression.compile(pattern) != OK:
		return fallback
	var result := expression.search(notes)
	return maxi(int(result.get_string(1)), 1) if result != null else fallback

func _store_library_entry_image(entry: Dictionary) -> String:
	var encoded := str(entry.get("image_data", ""))
	var format := str(entry.get("image_format", "")).to_lower()
	if encoded.is_empty() or format not in ["png", "jpg", "jpeg", "webp"]:
		return ""
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	if bytes.is_empty() or bytes.size() > MAX_LIBRARY_ENTRY_IMAGE_BYTES:
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LIBRARY_ASSETS_DIR))
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(bytes)
	var target := LIBRARY_ASSETS_DIR + "/" + hash_context.finish().hex_encode().left(20) + "." + ("jpg" if format == "jpeg" else format)
	if not FileAccess.file_exists(target):
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			return ""
		file.store_buffer(bytes)
		file.close()
	return target

func _setup_campaign_manager() -> void:
	campaign_popup = Window.new()
	campaign_popup.borderless = false
	add_child(campaign_popup)
	campaign_popup.hide()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 14, GOLD.darkened(0.4), 1, 22))
	campaign_popup.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	var title := Label.new()
	title.text = "▣  CAMPAÑA PORTÁTIL"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	var hint := Label.new()
	hint.text = "Reúne hojas, catálogo, encuentros, mesa, mapas, música y animaciones en un único archivo para respaldar o mover la partida."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	body.add_child(hint)
	campaign_summary_label = Label.new()
	campaign_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_summary_label.add_theme_stylebox_override("normal", _box(FIELD, 10, GOLD.darkened(0.55), 1, 12))
	body.add_child(campaign_summary_label)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	var export_button := Button.new()
	export_button.text = "⇧ Exportar campaña completa"
	export_button.custom_minimum_size.y = 46
	export_button.pressed.connect(_choose_campaign_export)
	actions.add_child(export_button)
	var import_button := Button.new()
	import_button.text = "⇩ Importar campaña"
	import_button.custom_minimum_size.y = 46
	import_button.tooltip_text = "Se crea un respaldo automático antes de importar"
	import_button.pressed.connect(func(): _show_external_file_dialog(campaign_import_dialog))
	actions.add_child(import_button)
	var warning := Label.new()
	warning.text = "Al importar se combinan archivos y se reemplazan aquellos que tengan el mismo nombre. Antes se crea una copia recuperable."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_font_size_override("font_size", 12)
	warning.add_theme_color_override("font_color", Color("#d9a96d"))
	body.add_child(warning)
	campaign_export_dialog = FileDialog.new()
	campaign_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_configure_external_file_dialog(campaign_export_dialog)
	campaign_export_dialog.add_filter("*.dndcampaign", "Campaña portátil", "application/zip,application/octet-stream")
	campaign_export_dialog.file_selected.connect(_export_campaign_to_path)
	add_child(campaign_export_dialog)
	campaign_import_dialog = FileDialog.new()
	campaign_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(campaign_import_dialog)
	campaign_import_dialog.add_filter("*.dndcampaign", "Campaña portátil", "application/zip,application/octet-stream")
	campaign_import_dialog.file_selected.connect(_request_campaign_import)
	add_child(campaign_import_dialog)
	campaign_import_confirmation = ConfirmationDialog.new()
	campaign_import_confirmation.title = "Importar campaña"
	campaign_import_confirmation.dialog_text = "Se creará un respaldo de la campaña actual y después se importarán los datos seleccionados."
	campaign_import_confirmation.ok_button_text = "Crear respaldo e importar"
	campaign_import_confirmation.confirmed.connect(_confirm_campaign_import)
	add_child(campaign_import_confirmation)

func _show_campaign_manager() -> void:
	_refresh_campaign_summary()
	_toggle_floating_window(campaign_popup, Vector2i(560, 430), "Campaña portátil")

func _refresh_campaign_summary() -> void:
	if campaign_summary_label == null:
		return
	var sheet_count := _count_files_recursive(SHEETS_DIR)
	var map_count := _count_files_recursive("user://map_library", ".map.json")
	var music_count := _count_files_recursive(MUSIC_DIR)
	var media_count := _count_files_recursive(TABLE_MEDIA_LIBRARY_DIR)
	campaign_summary_label.text = "%d hojas  •  %d entradas de biblioteca  •  %d encuentros\n%d mapas  •  %d pistas  •  %d animaciones" % [sheet_count, library_catalog_entries.size(), saved_encounters.size(), map_count, music_count, media_count]

func _count_files_recursive(directory_path: String, suffix := "") -> int:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return 0
	var total := 0
	for filename in directory.get_files():
		if suffix.is_empty() or filename.ends_with(suffix):
			total += 1
	for child_directory in directory.get_directories():
		total += _count_files_recursive(directory_path.path_join(child_directory), suffix)
	return total

func _choose_campaign_export() -> void:
	campaign_export_dialog.current_file = "mi_campaña." + CAMPAIGN_EXTENSION
	_show_external_file_dialog(campaign_export_dialog)

func _export_campaign_to_path(destination: String) -> void:
	_save_table_state(false)
	_write_library_catalog()
	_write_encounters()
	_save_table_media_library()
	var final_path := destination
	if final_path.get_extension().to_lower() != CAMPAIGN_EXTENSION:
		final_path += "." + CAMPAIGN_EXTENSION
	var temporary := "user://campaign_export_pending." + CAMPAIGN_EXTENSION
	if not _write_campaign_archive(temporary):
		_set_status("No se pudo crear el paquete de campaña.", true)
		return
	var bytes := FileAccess.get_file_as_bytes(temporary)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	var output := FileAccess.open(final_path, FileAccess.WRITE)
	if output == null:
		_set_status("No se pudo escribir la campaña en el destino elegido.", true)
		return
	output.store_buffer(bytes)
	output.close()
	_set_status("Campaña exportada correctamente (%s)." % _format_file_size(bytes.size()))

func _write_campaign_archive(destination: String) -> bool:
	if FileAccess.file_exists(destination):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination))
	var packer := ZIPPacker.new()
	if packer.open(destination) != OK:
		return false
	var manifest := {"format": "dnd-campaign", "version": 1, "created_at": Time.get_datetime_string_from_system(), "app": "HojaPersonaje"}
	if packer.start_file("manifest.json") != OK or packer.write_file(JSON.stringify(manifest, "  ").to_utf8_buffer()) != OK:
		packer.close()
		return false
	packer.close_file()
	for source in _campaign_source_files():
		var bytes := FileAccess.get_file_as_bytes(str(source.get("source", "")))
		if packer.start_file(str(source.get("archive", ""))) != OK or packer.write_file(bytes) != OK:
			packer.close()
			return false
		packer.close_file()
	packer.close()
	return true

func _campaign_source_files() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in [[TABLE_SAVE_PATH, "data/table_state.json"], [LIBRARY_CATALOG_PATH, "data/library_catalog.json"], [ENCOUNTERS_PATH, "data/encounters.json"], [TABLE_MEDIA_LIBRARY_PATH, "data/table_media_library.json"]]:
		if FileAccess.file_exists(definition[0]):
			result.append({"source": definition[0], "archive": definition[1]})
	for definition in [[SHEETS_DIR, "data/character_sheets"], ["user://map_library", "data/map_library"], [MUSIC_DIR, "data/music_library"], [TABLE_MEDIA_LIBRARY_DIR, "data/table_media_library"], [LIBRARY_ASSETS_DIR, "data/library_assets"], [_library_dir(), "data/library_index"]]:
		_collect_campaign_directory(definition[0], definition[1], result)
	return result

func _collect_campaign_directory(source_directory: String, archive_directory: String, result: Array[Dictionary]) -> void:
	var directory := DirAccess.open(source_directory)
	if directory == null:
		return
	for filename in directory.get_files():
		result.append({"source": source_directory.path_join(filename), "archive": archive_directory.path_join(filename).replace("\\", "/")})
	for child_directory in directory.get_directories():
		_collect_campaign_directory(source_directory.path_join(child_directory), archive_directory.path_join(child_directory), result)

func _request_campaign_import(source: String) -> void:
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null or file.get_length() <= 0 or file.get_length() > MAX_CAMPAIGN_ARCHIVE_BYTES:
		if file != null:
			file.close()
		_set_status("El archivo de campaña no es válido o supera 512 MB.", true)
		return
	file.close()
	pending_campaign_import_path = source
	_popup_centered_safe(campaign_import_confirmation, Vector2i(520, 210))

func _confirm_campaign_import() -> void:
	if pending_campaign_import_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAMPAIGN_BACKUP_DIR))
	var backup_path := CAMPAIGN_BACKUP_DIR + "/antes_de_importar_%d.%s" % [int(Time.get_unix_time_from_system()), CAMPAIGN_EXTENSION]
	_save_table_state(false)
	if not _write_campaign_archive(backup_path):
		_set_status("No se pudo crear el respaldo previo; la importación fue cancelada.", true)
		return
	var source := FileAccess.open(pending_campaign_import_path, FileAccess.READ)
	if source == null:
		_set_status("No se pudo volver a abrir la campaña elegida.", true)
		return
	var temporary := "user://campaign_import_pending." + CAMPAIGN_EXTENSION
	var temporary_file := FileAccess.open(temporary, FileAccess.WRITE)
	if temporary_file == null:
		source.close()
		return
	temporary_file.store_buffer(source.get_buffer(source.get_length()))
	temporary_file.close()
	source.close()
	pending_campaign_import_path = ""
	var imported := _extract_campaign_archive(temporary)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	if imported < 0:
		_set_status("El paquete no es una campaña válida. Se conservó el respaldo previo.", true)
		return
	_reload_campaign_data()
	_set_status("Campaña importada: %d archivo(s). Respaldo previo conservado." % imported)

func _extract_campaign_archive(archive_path: String) -> int:
	var reader := ZIPReader.new()
	if reader.open(archive_path) != OK or not reader.file_exists("manifest.json"):
		return -1
	var manifest: Variant = JSON.parse_string(reader.read_file("manifest.json").get_string_from_utf8())
	if not manifest is Dictionary or str(manifest.get("format", "")) != "dnd-campaign":
		reader.close()
		return -1
	var allowed_roots := ["table_state.json", "library_catalog.json", "encounters.json", "table_media_library.json", "character_sheets", "map_library", "music_library", "library_assets", "library_index"]
	var total_bytes := 0
	var imported := 0
	for archive_file in reader.get_files():
		if archive_file == "manifest.json" or archive_file.ends_with("/"):
			continue
		if not archive_file.begins_with("data/") or ".." in archive_file or "\\" in archive_file:
			reader.close()
			return -1
		var relative := archive_file.trim_prefix("data/")
		var root_name := relative.get_slice("/", 0)
		if root_name not in allowed_roots:
			continue
		var bytes := reader.read_file(archive_file)
		total_bytes += bytes.size()
		if total_bytes > MAX_CAMPAIGN_ARCHIVE_BYTES:
			reader.close()
			return -1
		var target := "user://" + relative
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
		var output := FileAccess.open(target, FileAccess.WRITE)
		if output == null:
			continue
		output.store_buffer(bytes)
		output.close()
		imported += 1
	reader.close()
	return imported

func _reload_campaign_data() -> void:
	_load_library_catalog()
	_load_encounters()
	_load_table_media_library()
	_refresh_table_media_library()
	_refresh_music_library()
	_refresh_sheets_list()
	_refresh_library()
	if map_library_view != null:
		map_library_view.refresh_library()
	_load_table_state()
	_refresh_campaign_summary()

func _setup_encounter_manager() -> void:
	encounter_popup = Window.new()
	encounter_popup.borderless = false
	add_child(encounter_popup)
	encounter_popup.hide()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 14, GOLD.darkened(0.4), 1, 20))
	encounter_popup.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	var title := Label.new()
	title.text = "⚔  ENCUENTROS PREPARADOS"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	var hint := Label.new()
	hint.text = "Combina enemigos de la biblioteca, guarda el grupo y despliega todas sus fichas en la mesa."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	body.add_child(hint)
	encounter_name_edit = LineEdit.new()
	encounter_name_edit.placeholder_text = "Nombre del encuentro: Emboscada del bosque…"
	body.add_child(encounter_name_edit)
	var enemy_row := HFlowContainer.new()
	body.add_child(enemy_row)
	encounter_enemy_option = OptionButton.new()
	encounter_enemy_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_row.add_child(encounter_enemy_option)
	encounter_quantity_spin = SpinBox.new()
	encounter_quantity_spin.min_value = 1
	encounter_quantity_spin.max_value = 50
	encounter_quantity_spin.value = 1
	encounter_quantity_spin.custom_minimum_size.x = 90
	encounter_quantity_spin.tooltip_text = "Cantidad de este enemigo"
	enemy_row.add_child(encounter_quantity_spin)
	var add_enemy := Button.new()
	add_enemy.text = "＋ Añadir"
	add_enemy.pressed.connect(_add_enemy_to_encounter)
	enemy_row.add_child(add_enemy)
	var composition_label := Label.new()
	composition_label.text = "COMPOSICIÓN ACTUAL"
	composition_label.add_theme_font_size_override("font_size", 11)
	composition_label.add_theme_color_override("font_color", MUTED)
	body.add_child(composition_label)
	encounter_composition_list = ItemList.new()
	encounter_composition_list.custom_minimum_size.y = 150
	body.add_child(encounter_composition_list)
	var party_row := HFlowContainer.new()
	body.add_child(party_row)
	var party_label := Label.new()
	party_label.text = "Grupo"
	party_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	party_row.add_child(party_label)
	encounter_party_size_spin = SpinBox.new()
	encounter_party_size_spin.min_value = 1
	encounter_party_size_spin.max_value = 12
	encounter_party_size_spin.value = 4
	encounter_party_size_spin.prefix = "Personajes: "
	encounter_party_size_spin.value_changed.connect(func(_value: float): _refresh_encounter_summary())
	party_row.add_child(encounter_party_size_spin)
	encounter_party_level_spin = SpinBox.new()
	encounter_party_level_spin.min_value = 1
	encounter_party_level_spin.max_value = 20
	encounter_party_level_spin.value = 1
	encounter_party_level_spin.prefix = "Nivel: "
	encounter_party_level_spin.value_changed.connect(func(_value: float): _refresh_encounter_summary())
	party_row.add_child(encounter_party_level_spin)
	encounter_summary_label = Label.new()
	encounter_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	encounter_summary_label.add_theme_stylebox_override("normal", _box(FIELD, 8, GOLD.darkened(0.55), 1, 8))
	encounter_summary_label.add_theme_color_override("font_color", GOLD)
	body.add_child(encounter_summary_label)
	var deploy_options := HFlowContainer.new()
	body.add_child(deploy_options)
	encounter_add_initiative_check = CheckBox.new()
	encounter_add_initiative_check.text = "Agregar a iniciativa"
	encounter_add_initiative_check.button_pressed = true
	deploy_options.add_child(encounter_add_initiative_check)
	encounter_announce_check = CheckBox.new()
	encounter_announce_check.text = "Anunciar en chat"
	encounter_announce_check.button_pressed = true
	deploy_options.add_child(encounter_announce_check)
	var composition_actions := HFlowContainer.new()
	body.add_child(composition_actions)
	for definition in [["× Quitar seleccionado", _remove_enemy_from_encounter], ["Limpiar", _clear_encounter_composition], ["✓ Guardar encuentro", _save_encounter]]:
		var button := Button.new()
		button.text = definition[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(definition[1])
		composition_actions.add_child(button)
	var saved_label := Label.new()
	saved_label.text = "ENCUENTROS GUARDADOS"
	saved_label.add_theme_font_size_override("font_size", 11)
	saved_label.add_theme_color_override("font_color", MUTED)
	body.add_child(saved_label)
	encounter_saved_list = ItemList.new()
	encounter_saved_list.custom_minimum_size.y = 150
	encounter_saved_list.item_activated.connect(func(_index: int): _load_selected_encounter())
	body.add_child(encounter_saved_list)
	var saved_actions := HFlowContainer.new()
	body.add_child(saved_actions)
	for definition in [["↗ Cargar", _load_selected_encounter], ["▶ Desplegar en mesa", _deploy_selected_encounter], ["× Eliminar", _delete_selected_encounter]]:
		var button := Button.new()
		button.text = definition[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(definition[1])
		saved_actions.add_child(button)
	_load_encounters()

func _show_encounter_manager() -> void:
	if not _is_table_director():
		_set_status("Solo el director puede preparar encuentros.", true)
		return
	_refresh_encounter_enemy_options()
	_refresh_encounter_lists()
	_toggle_floating_window(encounter_popup, Vector2i(650, 720), "Encuentros preparados")

func _refresh_encounter_enemy_options() -> void:
	if encounter_enemy_option == null:
		return
	encounter_enemy_option.clear()
	for entry in library_catalog_entries:
		if str(entry.get("category", "")) != "Enemigo":
			continue
		encounter_enemy_option.add_item(str(entry.get("name", "Enemigo")))
		encounter_enemy_option.set_item_metadata(encounter_enemy_option.item_count - 1, _library_catalog_identity(entry))
	if encounter_enemy_option.item_count == 0:
		encounter_enemy_option.add_item("No hay enemigos en la biblioteca")
		encounter_enemy_option.set_item_disabled(0, true)

func _add_enemy_to_encounter() -> void:
	if encounter_enemy_option.selected < 0 or encounter_enemy_option.is_item_disabled(encounter_enemy_option.selected):
		_set_status("Añade primero algún enemigo a la biblioteca.", true)
		return
	var identity := str(encounter_enemy_option.get_selected_metadata())
	var quantity := int(encounter_quantity_spin.value)
	for member in encounter_composition:
		if str(member.get("identity", "")) == identity:
			member["quantity"] = clampi(int(member.get("quantity", 1)) + quantity, 1, 99)
			_refresh_encounter_lists()
			return
	encounter_composition.append({"identity": identity, "name": encounter_enemy_option.get_item_text(encounter_enemy_option.selected), "quantity": quantity})
	_refresh_encounter_lists()

func _remove_enemy_from_encounter() -> void:
	var selected := encounter_composition_list.get_selected_items()
	if selected.is_empty():
		return
	encounter_composition.remove_at(selected[0])
	_refresh_encounter_lists()

func _clear_encounter_composition() -> void:
	encounter_composition.clear()
	_refresh_encounter_lists()

func _save_encounter() -> void:
	var encounter_name := encounter_name_edit.text.strip_edges().substr(0, 100)
	if encounter_name.is_empty() or encounter_composition.is_empty():
		_set_status("Escribe un nombre y añade al menos un enemigo.", true)
		return
	var encounter := {"name": encounter_name, "enemies": encounter_composition.duplicate(true), "party_size": int(encounter_party_size_spin.value), "party_level": int(encounter_party_level_spin.value), "updated_at": Time.get_datetime_string_from_system()}
	var replaced := false
	for index in range(saved_encounters.size()):
		if str(saved_encounters[index].get("name", "")).to_lower() == encounter_name.to_lower():
			saved_encounters[index] = encounter
			replaced = true
			break
	if not replaced:
		saved_encounters.append(encounter)
	_write_encounters()
	_refresh_encounter_lists()
	_set_status("Encuentro guardado: %s." % encounter_name)

func _load_selected_encounter() -> void:
	var selected := encounter_saved_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona un encuentro guardado.", true)
		return
	var encounter: Dictionary = saved_encounters[selected[0]]
	encounter_name_edit.text = str(encounter.get("name", ""))
	encounter_composition.assign(encounter.get("enemies", []))
	encounter_party_size_spin.value = clampi(int(encounter.get("party_size", 4)), 1, 12)
	encounter_party_level_spin.value = clampi(int(encounter.get("party_level", 1)), 1, 20)
	_refresh_encounter_lists()

func _delete_selected_encounter() -> void:
	var selected := encounter_saved_list.get_selected_items()
	if selected.is_empty():
		return
	saved_encounters.remove_at(selected[0])
	_write_encounters()
	_refresh_encounter_lists()

func _deploy_selected_encounter() -> void:
	var selected := encounter_saved_list.get_selected_items()
	var encounter: Dictionary = saved_encounters[selected[0]] if not selected.is_empty() else {"name": encounter_name_edit.text, "enemies": encounter_composition}
	var enemies: Array = encounter.get("enemies", [])
	if enemies.is_empty():
		_set_status("El encuentro no contiene enemigos.", true)
		return
	var previous_catalog_selection := library_catalog_selected
	var created := 0
	var missing := 0
	for member in enemies:
		var entry_index := _find_library_catalog_identity(str(member.get("identity", "")))
		if entry_index < 0:
			missing += int(member.get("quantity", 1))
			continue
		for _copy in range(clampi(int(member.get("quantity", 1)), 1, 99)):
			library_catalog_selected = entry_index
			_create_enemy_from_catalog()
			if table_board.has_method("nudge_selected_token_for_spawn"):
				table_board.nudge_selected_token_for_spawn(Vector2((created % 5) * 48, floori(float(created) / 5.0) * 48))
			if encounter_add_initiative_check.button_pressed:
				if initiative_popup == null:
					_setup_initiative_tracker()
				_add_selected_to_initiative()
			created += 1
	library_catalog_selected = previous_catalog_selection
	_save_table_state()
	if encounter_announce_check.button_pressed and created > 0:
		_post_chat("Iniciativa", "El director desplegó “%s”: %d enemigo(s). %s" % [str(encounter.get("name", "Encuentro")), created, encounter_summary_label.text.replace("\n", " ")])
	_set_status("Encuentro desplegado: %d enemigo(s)%s." % [created, " · %d no encontrado(s)" % missing if missing > 0 else ""])

func _find_library_catalog_identity(identity: String) -> int:
	for index in range(library_catalog_entries.size()):
		if _library_catalog_identity(library_catalog_entries[index]) == identity:
			return index
	return -1

func _refresh_encounter_lists() -> void:
	if encounter_composition_list != null:
		encounter_composition_list.clear()
		for member in encounter_composition:
			encounter_composition_list.add_item("%d × %s" % [int(member.get("quantity", 1)), str(member.get("name", "Enemigo"))])
	if encounter_saved_list != null:
		encounter_saved_list.clear()
		for encounter in saved_encounters:
			var total := 0
			for member in encounter.get("enemies", []):
				total += int(member.get("quantity", 1))
			encounter_saved_list.add_item("⚔  %s  ·  %d criaturas" % [str(encounter.get("name", "Encuentro")), total])
	_refresh_encounter_summary()

func _refresh_encounter_summary() -> void:
	if encounter_summary_label == null:
		return
	var base_xp := 0
	var creature_count := 0
	for member in encounter_composition:
		var quantity := clampi(int(member.get("quantity", 1)), 1, 99)
		creature_count += quantity
		var entry_index := _find_library_catalog_identity(str(member.get("identity", "")))
		if entry_index >= 0:
			base_xp += _catalog_xp_from_notes(str(library_catalog_entries[entry_index].get("notes", ""))) * quantity
	var multiplier := _encounter_quantity_multiplier(creature_count, int(encounter_party_size_spin.value))
	var adjusted_xp := roundi(base_xp * multiplier)
	var difficulty := _encounter_difficulty(adjusted_xp, int(encounter_party_size_spin.value), int(encounter_party_level_spin.value))
	encounter_summary_label.text = "%d criatura(s)  •  %s PX base  •  %s PX ajustados (×%.1f)\nDificultad estimada: %s" % [creature_count, _format_number(base_xp), _format_number(adjusted_xp), multiplier, difficulty]

func _catalog_xp_from_notes(notes: String) -> int:
	for pattern in ["(?i)(?:PX|XP|EXP)\\s*[:=]?\\s*([0-9][0-9.,]*)", "(?i)([0-9][0-9.,]*)\\s*(?:PX|XP)"]:
		var expression := RegEx.new()
		if expression.compile(pattern) != OK:
			continue
		var result := expression.search(notes)
		if result != null:
			var clean := result.get_string(1).replace(".", "").replace(",", "")
			if clean.is_valid_int():
				return maxi(int(clean), 0)
	return 0

func _encounter_quantity_multiplier(creature_count: int, party_size: int) -> float:
	if creature_count <= 0:
		return 1.0
	var multipliers: Array[float] = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0]
	var tier := 0 if creature_count == 1 else (1 if creature_count == 2 else (2 if creature_count <= 6 else (3 if creature_count <= 10 else (4 if creature_count <= 14 else 5))))
	if party_size < 3:
		tier = mini(tier + 1, multipliers.size() - 1)
	elif party_size >= 6:
		tier = maxi(tier - 1, 0)
	return multipliers[tier]

func _encounter_difficulty(adjusted_xp: int, party_size: int, party_level: int) -> String:
	if adjusted_xp <= 0:
		return "Sin PX en las fichas"
	var index := clampi(party_level, 1, 20) - 1
	var easy: int = int(ENCOUNTER_EASY_XP[index]) * party_size
	var medium: int = int(ENCOUNTER_MEDIUM_XP[index]) * party_size
	var hard: int = int(ENCOUNTER_HARD_XP[index]) * party_size
	var deadly: int = int(ENCOUNTER_DEADLY_XP[index]) * party_size
	if adjusted_xp < easy:
		return "Trivial"
	if adjusted_xp < medium:
		return "Fácil"
	if adjusted_xp < hard:
		return "Media"
	if adjusted_xp < deadly:
		return "Difícil"
	return "Mortal"

func _load_encounters() -> void:
	saved_encounters.clear()
	if FileAccess.file_exists(ENCOUNTERS_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTERS_PATH))
		if parsed is Array:
			for encounter in parsed:
				if encounter is Dictionary and encounter.get("enemies", []) is Array:
					saved_encounters.append(encounter.duplicate(true))
	_refresh_encounter_lists()

func _write_encounters() -> void:
	var file := FileAccess.open(ENCOUNTERS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(saved_encounters, "  "))
		file.close()

func _use_selected_pdf_as_catalog_source() -> void:
	var selected := library_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona primero un PDF de la biblioteca.", true)
		return
	var filename := str(library_list.get_item_metadata(selected[0]))
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_library_dir() + "/" + filename))
	if not data is Dictionary:
		return
	var source := str(data.get("title", "Libro"))
	if pdf_current_path == str(data.get("source_path", "")) and pdf_current_page > 0:
		source += " · página %d" % pdf_current_page
	library_catalog_source.text = source

func _ask_library() -> void:
	var query := library_question.text.to_lower().strip_edges()
	if query.is_empty():
		library_answer.text = "Escribe una pregunta o varias palabras clave."
		return
	var keywords := []
	for word in query.split(" ", false):
		var clean := str(word).strip_edges().trim_suffix("?").trim_suffix(",").trim_suffix(".")
		if clean.length() >= 3 and clean not in keywords:
			keywords.append(clean)
	var matches: Array[Dictionary] = []
	for entry in library_catalog_entries:
		var catalog_text := "%s %s %s %s" % [entry.get("category", ""), entry.get("name", ""), entry.get("source", ""), entry.get("notes", "")]
		var catalog_lower := catalog_text.to_lower()
		var catalog_score := 0
		for keyword in keywords:
			catalog_score += catalog_lower.count(keyword) * 2
		if catalog_score > 0:
			matches.append({"score": catalog_score, "title": "CATÁLOGO · %s · %s" % [entry.get("category", "Otro"), entry.get("name", "Sin nombre")], "page": 0, "snippet": "%s\n%s" % [entry.get("source", "Sin fuente"), entry.get("notes", "")]})
	for item_index in range(library_list.item_count):
		var filename := str(library_list.get_item_metadata(item_index))
		var data = JSON.parse_string(FileAccess.get_file_as_string(_library_dir() + "/" + filename))
		if not data is Dictionary:
			continue
		for page in data.get("pages", []):
			var page_text := str(page.get("text", ""))
			var lower := page_text.to_lower()
			var score := 0
			var first_position := -1
			for keyword in keywords:
				var occurrences := lower.count(keyword)
				score += occurrences
				if first_position < 0 and occurrences > 0:
					first_position = lower.find(keyword)
			if score > 0:
				var start := maxi(first_position - 180, 0)
				var snippet := page_text.substr(start, 520).replace("\n", " ").strip_edges()
				matches.append({"score": score, "title": str(data.get("title", "Libro")), "page": int(page.get("page", 0)), "snippet": snippet})
	matches.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.score) > int(b.score))
	if matches.is_empty():
		library_answer.text = "No encontré información relacionada en los documentos importados. Prueba con términos más concretos."
		return
	var response := "Resultados basados en tu biblioteca:\n\n"
	for index in range(mini(matches.size(), 5)):
		var match: Dictionary = matches[index]
		var location := str(match.title) if int(match.page) <= 0 else "%s — página %d" % [match.title, match.page]
		response += "[%s]\n%s\n\n" % [location, match.snippet]
	library_answer.text = response

func _table_page() -> Control:
	var page := BoxContainer.new()
	page.vertical = false
	table_layout = page
	page.add_theme_constant_override("separation", 0)
	page.custom_minimum_size.y = 720
	var left_panel := PanelContainer.new()
	table_left_panel = left_panel
	left_panel.custom_minimum_size.x = 72
	left_panel.add_theme_stylebox_override("panel", _box(Color("#202124"), 0, Color.TRANSPARENT, 0, 8))
	var left_rail := BoxContainer.new()
	left_rail.vertical = true
	table_left_rail = left_rail
	left_rail.alignment = BoxContainer.ALIGNMENT_BEGIN
	var left_scroll := ScrollContainer.new()
	table_left_scroll = left_scroll
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left_scroll)
	left_scroll.add_child(left_rail)
	var brand := Label.new()
	brand.text = "D20"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 20)
	brand.add_theme_color_override("font_color", GOLD)
	left_rail.add_child(brand)
	var separator := HSeparator.new()
	left_rail.add_child(separator)
	var sheets_button := Button.new()
	sheets_button.text = "HOJAS"
	sheets_button.tooltip_text = "Crear, abrir y organizar hojas"
	sheets_button.custom_minimum_size.y = 46
	sheets_button.add_theme_stylebox_override("normal", _box(Color("#8a5035"), 8, GOLD, 1, 6))
	sheets_button.pressed.connect(_show_sheets_manager)
	left_rail.add_child(sheets_button)
	var deck_button := Button.new()
	deck_button.text = "MAZO"
	deck_button.tooltip_text = "Abrir los conjuros de la ficha seleccionada"
	deck_button.custom_minimum_size.y = 42
	deck_button.pressed.connect(_open_selected_token_deck)
	left_rail.add_child(deck_button)
	var chat_button := Button.new()
	chat_button.text = "CHAT"
	chat_button.tooltip_text = "Abrir el chat de la sesión"
	chat_button.custom_minimum_size.y = 42
	chat_button.pressed.connect(_show_chat)
	left_rail.add_child(chat_button)
	undo_button = Button.new()
	undo_button.text = "DESHACER"
	undo_button.tooltip_text = "Deshacer el último cambio de la mesa"
	undo_button.disabled = true
	undo_button.pressed.connect(_undo_table_change)
	left_rail.add_child(undo_button)
	redo_button = Button.new()
	redo_button.text = "REHACER"
	redo_button.tooltip_text = "Recuperar el cambio deshecho"
	redo_button.disabled = true
	redo_button.pressed.connect(_redo_table_change)
	left_rail.add_child(redo_button)
	group_selection_button = Button.new()
	group_selection_button.text = "GRUPO"
	group_selection_button.tooltip_text = "Activar para tocar varias fichas y formar un grupo"
	group_selection_button.pressed.connect(_toggle_group_selection)
	left_rail.add_child(group_selection_button)
	var duplicate_button := Button.new()
	duplicate_button.text = "DUPLICAR"
	duplicate_button.tooltip_text = "Duplicar la ficha o grupo seleccionado"
	duplicate_button.pressed.connect(_duplicate_table_selection)
	left_rail.add_child(duplicate_button)
	director_only_buttons.append(duplicate_button)
	var initiative_button := Button.new()
	initiative_button.text = "INICIATIVA"
	initiative_button.tooltip_text = "Orden de turnos, rondas, vida y estados"
	initiative_button.custom_minimum_size.y = 42
	initiative_button.pressed.connect(_show_initiative)
	left_rail.add_child(initiative_button)
	var encounters_button := Button.new()
	encounters_button.text = "ENCUENTROS"
	encounters_button.tooltip_text = "Preparar y desplegar grupos de enemigos"
	encounters_button.custom_minimum_size.y = 42
	encounters_button.pressed.connect(_show_encounter_manager)
	left_rail.add_child(encounters_button)
	director_only_buttons.append(encounters_button)
	var music_button := Button.new()
	music_button.text = "MÚSICA"
	music_button.tooltip_text = "Abrir la biblioteca musical de la mesa"
	music_button.custom_minimum_size.y = 42
	music_button.pressed.connect(_show_music_library)
	left_rail.add_child(music_button)
	var online_button := Button.new()
	online_button.text = "ONLINE"
	online_button.tooltip_text = "Crear una partida o unirse con nombre de jugador"
	online_button.custom_minimum_size.y = 42
	online_button.pressed.connect(_show_online)
	left_rail.add_child(online_button)
	var backups_button := Button.new()
	backups_button.text = "RESPALDOS"
	backups_button.tooltip_text = "Crear o restaurar versiones anteriores de la mesa"
	backups_button.custom_minimum_size.y = 42
	backups_button.pressed.connect(_show_table_backups)
	left_rail.add_child(backups_button)
	director_only_buttons.append(backups_button)
	_setup_table_backups_window()
	_setup_encounter_manager()
	page.add_child(left_panel)
	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", _box(Color("#dce1eb"), 0, Color("#34363a"), 1, 0))
	var board_scene: PackedScene = load("res://Tabletop.tscn")
	var board: Control = board_scene.instantiate()
	table_board = board
	board.token_double_clicked.connect(_open_token_sheet)
	board.tokens_changed.connect(_save_table_state)
	board.tokens_changed.connect(_refresh_token_status_list)
	board.token_motion_changed.connect(_on_token_motion_changed)
	board.tool_changed.connect(_on_table_tool_changed)
	board.token_selected.connect(_on_table_token_selected)
	board.fog_changed.connect(_on_fog_changed)
	board.locks_changed.connect(_on_table_locks_changed)
	board.history_changed.connect(_on_table_history_changed)
	board.drawings_changed.connect(_on_drawings_changed)
	board.transfer_progress.connect(_on_table_transfer_progress)
	board.transfer_failed.connect(_on_table_transfer_failed)
	board.sheet_received.connect(_on_shared_sheet_received)
	board.library_entry_received.connect(_on_shared_library_entry_received)
	board.music_received.connect(_on_shared_music_received)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_child(board)
	_setup_initiative_tracker()
	_load_table_state.call_deferred()
	page.add_child(board_panel)
	var right_panel := PanelContainer.new()
	table_right_panel = right_panel
	# 210 px evita que las acciones largas se corten y sigue dejando la mayor
	# parte de la pantalla para el mapa, incluso en formato horizontal de móvil.
	right_panel.custom_minimum_size.x = 210
	right_panel.add_theme_stylebox_override("panel", _box(Color("#303236"), 0, Color.TRANSPARENT, 0, 8))
	var right_rail := VBoxContainer.new()
	table_right_rail = right_rail
	right_rail.add_theme_constant_override("separation", 8)
	right_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_scroll := ScrollContainer.new()
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_scroll)
	right_scroll.add_child(right_rail)
	var zoom_row := HBoxContainer.new()
	var zoom_out_button := Button.new()
	zoom_out_button.text = "−"
	zoom_out_button.pressed.connect(board.zoom_out)
	zoom_row.add_child(zoom_out_button)
	zoom_label = Label.new()
	zoom_label.text = "100%"
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_row.add_child(zoom_label)
	var zoom_in_button := Button.new()
	zoom_in_button.text = "+"
	zoom_in_button.pressed.connect(board.zoom_in)
	zoom_row.add_child(zoom_in_button)
	# roundi evita mostrar 44%, 54%, etc. por pequeños errores decimales internos.
	board.zoom_changed.connect(func(value: float): zoom_label.text = "%d%%" % roundi(value * 100.0))
	right_rail.add_child(zoom_row)
	table_tool_hint_label = Label.new()
	table_tool_hint_label.text = "Selecciona una herramienta"
	table_tool_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	table_tool_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_tool_hint_label.custom_minimum_size.y = 34
	table_tool_hint_label.add_theme_font_size_override("font_size", 11)
	table_tool_hint_label.add_theme_color_override("font_color", MUTED)
	right_rail.add_child(table_tool_hint_label)
	var map_title := Button.new()
	right_rail.add_child(map_title)
	var map_grid := GridContainer.new()
	map_grid.columns = 2
	for d in [["↑  Cargar", _choose_map_image, "Importar una imagen como mapa"], ["▦  Biblioteca", _show_map_library, "Abrir los mapas guardados"], ["−  Encoger", board.shrink_map, "Reducir el tamaño físico del mapa"], ["+  Ampliar", board.grow_map, "Aumentar el tamaño físico del mapa"], ["⤢  Ajustar", board.fit_map, "Ajustar el mapa al área visible"], ["×  Quitar", _clear_current_map, "Retirar el mapa y conservar la cuadrícula"]]:
		var map_button := Button.new()
		map_button.text = d[0]
		map_button.pressed.connect(d[1])
		_register_table_context_help(map_button, str(d[2]))
		map_grid.add_child(map_button)
		director_only_buttons.append(map_button)
	_style_table_tool_grid(map_grid)
	right_rail.add_child(map_grid)
	map_scale_label = Label.new()
	map_scale_label.text = "Escala del mapa: 100%"
	map_scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_scale_label.add_theme_font_size_override("font_size", 11)
	board.map_scale_changed.connect(_on_table_map_scale_changed)
	right_rail.add_child(map_scale_label)
	_configure_table_section_header(map_title, "▣  MAPA", [map_grid, map_scale_label])
	transfer_progress_label = Label.new()
	transfer_progress_label.text = "TRANSFERENCIA ONLINE"
	transfer_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transfer_progress_label.add_theme_font_size_override("font_size", 10)
	transfer_progress_label.hide()
	right_rail.add_child(transfer_progress_label)
	transfer_progress_bar = ProgressBar.new()
	transfer_progress_bar.min_value = 0
	transfer_progress_bar.max_value = 100
	transfer_progress_bar.show_percentage = true
	transfer_progress_bar.hide()
	right_rail.add_child(transfer_progress_bar)
	transfer_cancel_button = Button.new()
	transfer_cancel_button.text = "Cancelar transferencia"
	transfer_cancel_button.pressed.connect(_cancel_table_transfers)
	transfer_cancel_button.hide()
	right_rail.add_child(transfer_cancel_button)
	var media_title := Button.new()
	right_rail.add_child(media_title)
	var media_grid := GridContainer.new()
	media_grid.columns = 2
	var library_media := Button.new()
	library_media.text = "Biblioteca"
	library_media.tooltip_text = "Efectos incluidos y hasta 30 GIF o vídeos guardados"
	library_media.pressed.connect(_show_table_media_library)
	media_grid.add_child(library_media)
	director_only_buttons.append(library_media)
	var stop_media := Button.new()
	stop_media.text = "Detener"
	stop_media.pressed.connect(_stop_uploaded_table_media)
	media_grid.add_child(stop_media)
	director_only_buttons.append(stop_media)
	_style_table_tool_grid(media_grid)
	right_rail.add_child(media_grid)
	_configure_table_section_header(media_title, "◆  ESCENA ANIMADA", [media_grid])
	_setup_table_media_library()
	var rules_title := Button.new()
	right_rail.add_child(rules_title)
	var rules_grid := GridContainer.new()
	rules_grid.columns = 2
	for d in [["↖  Mover", "select", "Seleccionar y mover fichas"], ["╱  Regla", "ruler", "Medir distancias en pies"], ["△  Cono", "cone", "Marcar un área de efecto en cono"], ["○  Esfera", "sphere", "Marcar un área circular"]]:
		var rule_button := Button.new()
		rule_button.text = d[0]
		rule_button.pressed.connect(func(): board.set_tool(d[1]))
		rules_grid.add_child(rule_button)
		_register_table_tool_button(str(d[1]), rule_button)
		_register_table_context_help(rule_button, str(d[2]))
	_style_table_tool_grid(rules_grid)
	right_rail.add_child(rules_grid)
	var clear_rule := Button.new()
	clear_rule.text = "×  Borrar plantilla"
	clear_rule.custom_minimum_size.y = 38
	clear_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_rule.pressed.connect(board.clear_template)
	right_rail.add_child(clear_rule)
	_configure_table_section_header(rules_title, "◇  PLANTILLAS  ·  5 PIES", [rules_grid, clear_rule])
	var fog_title := Button.new()
	right_rail.add_child(fog_title)
	var fog_grid := GridContainer.new()
	fog_grid.columns = 2
	for definition in [["■  Cubrir todo", board.cover_with_fog, "", "Cubrir el mapa completo con niebla"], ["◌  Revelar", func(): board.set_tool("fog_reveal"), "fog_reveal", "Pintar zonas visibles para los jugadores"], ["●  Ocultar", func(): board.set_tool("fog_hide"), "fog_hide", "Volver a cubrir zonas del mapa"], ["×  Quitar niebla", board.clear_fog, "", "Eliminar toda la niebla del mapa"]]:
		var fog_button := Button.new()
		fog_button.text = definition[0]
		fog_button.pressed.connect(definition[1])
		fog_grid.add_child(fog_button)
		if not str(definition[2]).is_empty():
			_register_table_tool_button(str(definition[2]), fog_button)
		_register_table_context_help(fog_button, str(definition[3]))
		director_only_buttons.append(fog_button)
	_style_table_tool_grid(fog_grid)
	right_rail.add_child(fog_grid)
	_configure_table_section_header(fog_title, "◐  NIEBLA  ·  DIRECTOR", [fog_grid])
	var drawing_title := Button.new()
	right_rail.add_child(drawing_title)
	var drawing_style := HBoxContainer.new()
	var drawing_color := ColorPickerButton.new()
	drawing_color.color = Color("#e14f45")
	drawing_color.tooltip_text = "Color del lápiz"
	drawing_style.add_child(drawing_color)
	var drawing_width := SpinBox.new()
	drawing_width.min_value = 1
	drawing_width.max_value = 40
	drawing_width.value = 6
	drawing_width.suffix = " px"
	drawing_width.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawing_style.add_child(drawing_width)
	var update_drawing_style := func(_value = null): board.set_drawing_style(drawing_color.color, drawing_width.value)
	drawing_color.color_changed.connect(update_drawing_style)
	drawing_width.value_changed.connect(update_drawing_style)
	right_rail.add_child(drawing_style)
	var drawing_grid := GridContainer.new()
	drawing_grid.columns = 2
	for definition in [["✎  Lápiz", func(): board.set_tool("draw"), "draw", "Dibujar libremente sobre el mapa"], ["⌫  Borrador", func(): board.set_tool("erase_draw"), "erase_draw", "Borrar trazos tocándolos"], ["×  Limpiar", board.clear_drawings, "", "Eliminar todos los dibujos"], ["↖  Mover", func(): board.set_tool("select"), "select", "Volver a seleccionar y mover fichas"]]:
		var drawing_button := Button.new()
		drawing_button.text = definition[0]
		drawing_button.pressed.connect(definition[1])
		drawing_grid.add_child(drawing_button)
		if not str(definition[2]).is_empty():
			_register_table_tool_button(str(definition[2]), drawing_button)
		_register_table_context_help(drawing_button, str(definition[3]))
		director_only_buttons.append(drawing_button)
	_style_table_tool_grid(drawing_grid)
	right_rail.add_child(drawing_grid)
	_on_table_tool_changed.call_deferred("select")
	_configure_table_section_header(drawing_title, "✎  DIBUJO  ·  DIRECTOR", [drawing_style, drawing_grid])
	var lock_title := Button.new()
	right_rail.add_child(lock_title)
	var lock_grid := GridContainer.new()
	lock_grid.columns = 2
	map_lock_button = Button.new()
	map_lock_button.text = "Bloquear mapa"
	map_lock_button.pressed.connect(_toggle_map_lock)
	lock_grid.add_child(map_lock_button)
	director_only_buttons.append(map_lock_button)
	token_lock_button = Button.new()
	token_lock_button.text = "Bloquear fichas"
	token_lock_button.pressed.connect(_toggle_token_lock)
	lock_grid.add_child(token_lock_button)
	director_only_buttons.append(token_lock_button)
	_style_table_tool_grid(lock_grid)
	right_rail.add_child(lock_grid)
	_configure_table_section_header(lock_title, "▣  BLOQUEOS  ·  DIRECTOR", [lock_grid])
	_update_director_permissions.call_deferred()
	var token_color := ColorPickerButton.new()
	token_color.text = "COLOR"
	token_color.tooltip_text = "Cambiar el color de la ficha seleccionada"
	token_color.color = Color("#d45d52")
	token_color.color_changed.connect(board.set_selected_color)
	right_rail.add_child(token_color)
	var image_button := Button.new()
	image_button.text = "IMAGEN"
	image_button.tooltip_text = "Importar retrato PNG, JPG, WebP o GIF animado"
	image_button.pressed.connect(_choose_token_image)
	right_rail.add_child(image_button)
	portrait_gallery_title = Label.new()
	portrait_gallery_title.text = "RECIENTES"
	portrait_gallery_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_gallery_title.add_theme_font_size_override("font_size", 11)
	portrait_gallery_title.add_theme_color_override("font_color", GOLD)
	portrait_gallery_title.hide()
	right_rail.add_child(portrait_gallery_title)
	portrait_gallery_box = GridContainer.new()
	portrait_gallery_box.columns = 5
	portrait_gallery_box.add_theme_constant_override("h_separation", 3)
	portrait_gallery_box.hide()
	right_rail.add_child(portrait_gallery_box)
	_refresh_portrait_gallery()
	var status_title := Label.new()
	status_title.text = "EFECTOS DE ESTADO"
	status_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_title.add_theme_font_size_override("font_size", 11)
	status_title.add_theme_color_override("font_color", GOLD)
	right_rail.add_child(status_title)
	token_status_preset = OptionButton.new()
	for preset in ["Elegir estado rápido…", "Agarrado", "Asustado", "Aturdido", "Cegado", "Derribado", "Encantado", "Ensordecido", "Envenenado", "Incapacitado", "Invisible", "Paralizado", "Petrificado", "Restringido", "Inconsciente"]:
		token_status_preset.add_item(preset)
	token_status_preset.item_selected.connect(_select_token_status_preset)
	right_rail.add_child(token_status_preset)
	token_status_edit = LineEdit.new()
	token_status_edit.placeholder_text = "Ej.: Envenenado"
	token_status_edit.tooltip_text = "Puedes separar varios efectos con comas"
	right_rail.add_child(token_status_edit)
	var duration_row := HBoxContainer.new()
	right_rail.add_child(duration_row)
	var duration_label := Label.new()
	duration_label.text = "TURNOS"
	duration_label.tooltip_text = "0 significa que el efecto es permanente"
	duration_row.add_child(duration_label)
	token_status_duration_spin = SpinBox.new()
	token_status_duration_spin.min_value = 0
	token_status_duration_spin.max_value = 999
	token_status_duration_spin.value = 0
	token_status_duration_spin.tooltip_text = "Duración; usa 0 para un estado permanente"
	token_status_duration_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duration_row.add_child(token_status_duration_spin)
	var status_button := Button.new()
	status_button.text = "+ AÑADIR EFECTO"
	status_button.pressed.connect(_apply_token_statuses)
	right_rail.add_child(status_button)
	token_status_list = ItemList.new()
	token_status_list.custom_minimum_size.y = 92
	token_status_list.tooltip_text = "Estados activos de la ficha seleccionada"
	right_rail.add_child(token_status_list)
	var remove_status_button := Button.new()
	remove_status_button.text = "− QUITAR EFECTO"
	remove_status_button.pressed.connect(_remove_selected_token_status)
	right_rail.add_child(remove_status_button)
	var vision_row := HBoxContainer.new()
	var vision_label := Label.new()
	vision_label.text = "VISIÓN"
	vision_label.tooltip_text = "Cada 5 pies equivalen a un cuadro del mapa"
	vision_row.add_child(vision_label)
	token_vision_spin = SpinBox.new()
	token_vision_spin.min_value = 0
	token_vision_spin.max_value = 1000
	token_vision_spin.step = 5
	token_vision_spin.value = 30
	token_vision_spin.editable = false
	token_vision_spin.suffix = " pies"
	token_vision_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_vision_spin.tooltip_text = "Alcance que esta ficha revela dentro de la niebla"
	token_vision_spin.value_changed.connect(func(value: float):
		if table_board != null and table_board.selected_token >= 0:
			table_board.set_selected_vision(value)
	)
	vision_row.add_child(token_vision_spin)
	right_rail.add_child(vision_row)
	token_owner_edit = LineEdit.new()
	token_owner_edit.placeholder_text = "Propietario: nombre online"
	token_owner_edit.tooltip_text = "Debe coincidir con el nombre que usa el jugador al conectarse"
	right_rail.add_child(token_owner_edit)
	token_owner_option = OptionButton.new()
	token_owner_option.tooltip_text = "Jugadores conectados disponibles"
	token_owner_option.item_selected.connect(_select_token_owner_from_list)
	right_rail.add_child(token_owner_option)
	_refresh_online_players()
	var owner_button := Button.new()
	owner_button.text = "ASIGNAR PROPIETARIO"
	owner_button.pressed.connect(_assign_selected_token_owner)
	right_rail.add_child(owner_button)
	director_only_buttons.append(owner_button)
	var link_sheet_button := Button.new()
	link_sheet_button.text = "VINCULAR"
	link_sheet_button.tooltip_text = "Asignar una hoja de la biblioteca a la ficha"
	link_sheet_button.pressed.connect(_show_sheets_manager)
	right_rail.add_child(link_sheet_button)
	var dice_title := Label.new()
	dice_title.text = "LANZADOR DE DADOS"
	dice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_title.add_theme_color_override("font_color", GOLD)
	right_rail.add_child(dice_title)
	dice_result_label = Label.new()
	dice_result_label.text = "Elige un dado"
	dice_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice_result_label.custom_minimum_size.y = 48
	dice_result_label.add_theme_font_size_override("font_size", 18)
	dice_result_label.add_theme_color_override("font_color", GOLD)
	dice_result_label.add_theme_stylebox_override("normal", _box(Color("#222326"), 8, GOLD.darkened(0.4), 1, 6))
	right_rail.add_child(dice_result_label)
	var dice_options := HBoxContainer.new()
	dice_count_spin = SpinBox.new()
	dice_count_spin.min_value = 1
	dice_count_spin.max_value = 20
	dice_count_spin.value = 1
	dice_count_spin.tooltip_text = "Cantidad de dados"
	dice_count_spin.custom_minimum_size.x = 62
	dice_options.add_child(dice_count_spin)
	dice_modifier_spin = SpinBox.new()
	dice_modifier_spin.min_value = -99
	dice_modifier_spin.max_value = 99
	dice_modifier_spin.value = 0
	dice_modifier_spin.tooltip_text = "Modificador de la tirada"
	dice_modifier_spin.custom_minimum_size.x = 62
	dice_options.add_child(dice_modifier_spin)
	right_rail.add_child(dice_options)
	var dice_row := GridContainer.new()
	dice_row.columns = 2
	for sides in [4, 6, 8, 10, 12, 20]:
		var die := Button.new()
		die.text = "d%d" % sides
		die.custom_minimum_size = Vector2(58, 34)
		die.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		die.pressed.connect(func(): _roll_die(sides))
		dice_row.add_child(die)
	right_rail.add_child(dice_row)
	page.add_child(right_panel)
	token_image_dialog = FileDialog.new()
	token_image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(token_image_dialog)
	token_image_dialog.add_filter("*.png,*.jpg,*.jpeg,*.webp,*.gif", "Imágenes y GIF", "image/png,image/jpeg,image/webp,image/gif")
	token_image_dialog.file_selected.connect(_set_token_image)
	add_child(token_image_dialog)
	map_image_dialog = FileDialog.new()
	map_image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(map_image_dialog)
	map_image_dialog.add_filter("*.png,*.jpg,*.jpeg", "Mapas", "image/png,image/jpeg")
	map_image_dialog.file_selected.connect(_set_map_image)
	add_child(map_image_dialog)
	map_library_popup = Window.new()
	map_library_popup.borderless = false
	add_child(map_library_popup)
	map_library_popup.hide()
	map_library_popup.add_child(_map_library_panel())
	table_media_dialog = FileDialog.new()
	table_media_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(table_media_dialog)
	table_media_dialog.add_filter("*.gif,*.ogv", "GIF o vídeo Ogg", "image/gif,video/ogg")
	table_media_dialog.file_selected.connect(_set_table_media)
	add_child(table_media_dialog)
	token_sheet_popup = Window.new()
	token_sheet_popup.borderless = false
	add_child(token_sheet_popup)
	token_sheet_popup.hide()
	deck_popup = Window.new()
	deck_popup.borderless = false
	add_child(deck_popup)
	deck_popup.hide()
	chat_popup = Window.new()
	chat_popup.borderless = false
	add_child(chat_popup)
	chat_popup.hide()
	chat_popup.add_child(_chat_panel())
	music_popup = Window.new()
	music_popup.borderless = false
	add_child(music_popup)
	music_popup.hide()
	music_popup.add_child(_music_library_panel())
	music_file_dialog = FileDialog.new()
	music_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_configure_external_file_dialog(music_file_dialog)
	music_file_dialog.add_filter("*.mp3,*.ogg,*.wav", "Música", "audio/mpeg,audio/ogg,audio/wav")
	music_file_dialog.file_selected.connect(_import_music_file)
	add_child(music_file_dialog)
	music_player = AudioStreamPlayer.new()
	music_player.name = "TableMusicPlayer"
	music_player.volume_db = linear_to_db(0.7)
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	online_popup = Window.new()
	online_popup.borderless = false
	add_child(online_popup)
	online_popup.hide()
	online_popup.add_child(_online_panel())
	multiplayer.peer_connected.connect(_online_peer_connected)
	multiplayer.peer_disconnected.connect(_online_peer_disconnected)
	multiplayer.connected_to_server.connect(_online_connected)
	multiplayer.connection_failed.connect(_online_connection_failed)
	multiplayer.server_disconnected.connect(_online_server_disconnected)
	return page

func _roll_die(sides: int) -> void:
	var count := int(dice_count_spin.value)
	var modifier := int(dice_modifier_spin.value)
	var rolls: Array[int] = []
	var total := modifier
	for _index in range(count):
		var roll := randi_range(1, sides)
		rolls.append(roll)
		total += roll
	var modifier_text: String = (" + %d" % modifier) if modifier > 0 else ((" − %d" % absi(modifier)) if modifier < 0 else "")
	dice_result_label.text = "%dd%d%s = %d\n%s" % [count, sides, modifier_text, total, str(rolls)]
	_post_chat("Dados", dice_result_label.text.replace("\n", " "))

func _roll_stat(key: String, display_name: String) -> void:
	if not stat_spins.has(key):
		return
	var score := int(stat_spins[key].value)
	var modifier := floori((score - 10) / 2.0)
	_roll_sheet_check(display_name, modifier)

func _roll_skill(key: String) -> void:
	if not skill_fields.has(key):
		return
	_commit_skill_value(key)
	var data: Dictionary = skill_fields[key]
	var clean := str(data.value.text).strip_edges().replace("+", "")
	var modifier := int(clean) if clean.is_valid_int() else 0
	_roll_sheet_check(str(data.get("name", "Habilidad")), modifier)

func _roll_initiative_from_sheet() -> void:
	var modifier := _signed_modifier_from_text(fields.initiative.text)
	_roll_sheet_check("Iniciativa", modifier)

func _roll_active_attack() -> void:
	var attack_text: String = fields.attacks.text.strip_edges()
	if attack_text.is_empty():
		_set_status("Escribe al menos un ataque antes de tirar.", true)
		return
	var lines: PackedStringArray = fields.attacks.text.split("\n")
	var line_index: int = clampi(fields.attacks.get_caret_line(), 0, maxi(lines.size() - 1, 0))
	var active_line: String = lines[line_index].strip_edges()
	if active_line.is_empty():
		_set_status("Coloca el cursor en una línea que contenga un ataque.", true)
		return
	var expression := RegEx.new()
	expression.compile("(^|\\s)([+-]\\s*\\d+)")
	var result := expression.search(active_line)
	var modifier: int = 0
	var attack_name: String = active_line
	if result != null:
		modifier = _signed_modifier_from_text(result.get_string(2))
		attack_name = active_line.left(result.get_start()).strip_edges().trim_suffix("•").strip_edges()
	if attack_name.is_empty():
		attack_name = "Ataque"
	_roll_sheet_check(attack_name, modifier)

func _signed_modifier_from_text(value: String) -> int:
	var clean: String = value.strip_edges().replace(" ", "").replace("+", "")
	return int(clean) if clean.is_valid_int() else 0

func _roll_sheet_check(check_name: String, modifier: int) -> void:
	var mode: int = sheet_roll_mode_option.selected if sheet_roll_mode_option != null else 0
	var first_roll: int = randi_range(1, 20)
	var rolls: Array[int] = [first_roll]
	var chosen_roll: int = first_roll
	if mode in [1, 2]:
		var second_roll: int = randi_range(1, 20)
		rolls.append(second_roll)
		chosen_roll = maxi(first_roll, second_roll) if mode == 1 else mini(first_roll, second_roll)
	var total: int = chosen_roll + modifier
	var mode_text: String = ["NORMAL", "VENTAJA", "DESVENTAJA"][mode]
	var modifier_text: String = ("+%d" % modifier) if modifier >= 0 else str(modifier)
	var dice_text: String = str(chosen_roll) if rolls.size() == 1 else "%s → %d" % [str(rolls), chosen_roll]
	var natural_result: String = " • CRÍTICO NATURAL" if chosen_roll == 20 else (" • FALLO NATURAL" if chosen_roll == 1 else "")
	var actor: String = fields.name.text.strip_edges() if fields.has("name") and not fields.name.text.strip_edges().is_empty() else "Personaje"
	var message: String = "%s • %s: %s %s = %d [%s]%s" % [actor, check_name, dice_text, modifier_text, total, mode_text, natural_result]
	_post_chat("Dados", message)
	_set_status("Tirada enviada al chat: %s = %d." % [check_name, total])

func _open_selected_token_deck() -> void:
	if deck_popup.visible:
		deck_popup.hide()
		return
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona una ficha de la Mesa para abrir su mazo.", true)
		return
	var filename: String = table_board.get_selected_sheet()
	if filename.is_empty():
		_set_status("La ficha seleccionada no tiene una hoja vinculada.", true)
		return
	current_sheet_file = filename
	load_sheet()
	_build_deck_window()
	_toggle_floating_window(deck_popup, Vector2i(1100, 760), "Mazo de conjuros")

func _build_deck_window() -> void:
	for child in deck_popup.get_children():
		child.queue_free()
	var panel: PanelContainer = DECK_WINDOW_SCENE.instantiate()
	panel.add_theme_stylebox_override("panel", _box(palette.panel, 12, palette.accent, 1, 18))
	var body := VBoxContainer.new()
	panel.add_child(body)
	var title := Label.new()
	title.text = "✦  MAZO DE %s" % (fields.name.text.to_upper() if not fields.name.text.is_empty() else "CONJUROS")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", palette.accent)
	body.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var cards := GridContainer.new()
	deck_cards_grid = cards
	deck_card_nodes.clear()
	cards.columns = _responsive_spell_columns()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	scroll.add_child(cards)
	for index in range(spell_count):
		var card := _deck_card(index)
		deck_card_nodes.append(card)
		var angles := [-4.0, -1.5, 1.5, 4.0]
		var resting_angle: float = angles[index % 4] if cards.columns >= 4 else 0.0
		card.rotation_degrees = resting_angle
		card.set_meta("deck_resting_angle", resting_angle)
		card.pivot_offset = Vector2(140, 190)
		card.mouse_entered.connect(func(): _focus_deck_card(card))
		card.mouse_exited.connect(func(): _unfocus_deck_card(card, float(card.get_meta("deck_resting_angle", 0.0))))
		cards.add_child(card)
	deck_popup.add_child(panel)

func _deck_card(index: int) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(275, 385)
	card.add_theme_stylebox_override("panel", _box(palette.panel.lightened(0.07), 10, palette.accent, 2, 14))
	var body := VBoxContainer.new()
	card.add_child(body)
	var name := Label.new()
	var spell_name: String = fields["spell_%d_name" % index].text
	name.text = spell_name if not spell_name.is_empty() else "CONJURO SIN NOMBRE"
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 19)
	name.add_theme_color_override("font_color", palette.accent)
	body.add_child(name)
	var summary := Label.new()
	summary.text = "Nivel %s • %s • Magia %s\nLanzamiento: %s • Objetivo: %s\nMecánica: %s\nAlcance %s • %s\n%s • %s" % [
		_value_or_dash("spell_%d_level" % index), _value_or_dash("spell_%d_school" % index),
		_value_or_dash("spell_%d_magic_cost" % index), _value_or_dash("spell_%d_casting_time" % index),
		_value_or_dash("spell_%d_target" % index), _spell_mechanic_summary(index),
		_value_or_dash("spell_%d_range" % index),
		_value_or_dash("spell_%d_duration" % index),
		_value_or_dash("spell_%d_components" % index), _value_or_dash("spell_%d_effect" % index)
	]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(summary)
	var description := Label.new()
	description.text = _value_or_dash("spell_%d_description" % index)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 145
	description.clip_text = true
	body.add_child(description)
	var use := Button.new()
	use.text = "✦ Usar conjuro"
	use.pressed.connect(_use_spell.bind(index))
	body.add_child(use)
	var send := Button.new()
	send.text = "Enviar al chat"
	send.pressed.connect(func(): _send_spell_to_chat(index))
	body.add_child(send)
	return card

func _focus_deck_card(card: Control) -> void:
	card.z_index = 20
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "rotation_degrees", 0.0, 0.14)
	tween.tween_property(card, "scale", Vector2(1.06, 1.06), 0.14)

func _unfocus_deck_card(card: Control, angle: float) -> void:
	card.z_index = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "rotation_degrees", angle, 0.14)
	tween.tween_property(card, "scale", Vector2.ONE, 0.14)

func _value_or_dash(key: String) -> String:
	if not fields.has(key) or fields[key].text.strip_edges().is_empty():
		return "—"
	return fields[key].text.strip_edges()

func _send_spell_to_chat(index: int) -> void:
	var spell_name: String = _value_or_dash("spell_%d_name" % index)
	var message: String = "%s — Nivel %s, %s. Magia utilizada: %s. Lanzamiento: %s. Objetivo: %s. Mecánica: %s. Alcance: %s. Duración: %s. Efecto: %s. %s" % [
		spell_name, _value_or_dash("spell_%d_level" % index), _value_or_dash("spell_%d_school" % index),
		_value_or_dash("spell_%d_magic_cost" % index), _value_or_dash("spell_%d_casting_time" % index),
		_value_or_dash("spell_%d_target" % index), _spell_mechanic_summary(index),
		_value_or_dash("spell_%d_range" % index),
		_value_or_dash("spell_%d_duration" % index),
		_value_or_dash("spell_%d_effect" % index), _value_or_dash("spell_%d_description" % index)
	]
	_post_chat(fields.name.text if not fields.name.text.is_empty() else "Personaje", message)
	_show_chat()

func _chat_panel() -> Control:
	var panel: PanelContainer = CHAT_WINDOW_SCENE.instantiate()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.4), 1, 18))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	var title_row := HBoxContainer.new()
	body.add_child(title_row)
	var title := Label.new()
	title.text = "◉  CHAT DE LA MESA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var clear_chat_button := Button.new()
	clear_chat_button.text = "× Limpiar"
	clear_chat_button.tooltip_text = "Borrar el chat para todos los jugadores"
	clear_chat_button.pressed.connect(_clear_chat_for_all)
	title_row.add_child(clear_chat_button)
	director_only_buttons.append(clear_chat_button)
	chat_health_box = VBoxContainer.new()
	chat_health_box.add_theme_constant_override("separation", 5)
	body.add_child(chat_health_box)
	chat_log = RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.fit_content = false
	chat_log.scroll_following = true
	chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(chat_log)
	var row := HBoxContainer.new()
	body.add_child(row)
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Escribe un mensaje…"
	chat_input.max_length = MAX_CHAT_MESSAGE_LENGTH
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(func(_text: String): _send_chat_input())
	row.add_child(chat_input)
	var send := Button.new()
	send.text = "Enviar  ➜"
	send.pressed.connect(_send_chat_input)
	row.add_child(send)
	return panel

func _show_chat() -> void:
	if not _toggle_floating_window(chat_popup, Vector2i(660, 600), "Chat de la mesa"):
		return
	_refresh_chat()
	chat_input.grab_focus.call_deferred()

func _setup_initiative_tracker() -> void:
	if initiative_popup != null:
		return
	initiative_popup = Window.new()
	initiative_popup.borderless = false
	add_child(initiative_popup)
	initiative_popup.hide()
	initiative_view = INITIATIVE_TRACKER_SCENE.instantiate()
	initiative_view.add_theme_stylebox_override("panel", _box(palette.panel, 12, palette.accent, 1, 20))
	initiative_popup.add_child(initiative_view)
	initiative_view.connect("add_selected_requested", _add_selected_to_initiative)
	initiative_view.connect("turn_announced", func(message: String): _post_chat("Iniciativa", message))
	initiative_view.connect("state_changed", _on_initiative_changed)
	initiative_view.connect("status_effects_changed", _on_initiative_status_effects_changed)
	initiative_view.connect("hit_points_changed", _on_initiative_hit_points_changed)

func _show_initiative() -> void:
	if initiative_popup == null:
		_setup_initiative_tracker()
	initiative_view.call("set_editable", _is_table_director())
	_toggle_floating_window(initiative_popup, Vector2i(660, 610), "Iniciativa")

func _add_selected_to_initiative() -> void:
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona primero una ficha de la mesa.", true)
		return
	var token_index: int = table_board.selected_token
	var tokens: Array = table_board.export_tokens()
	if token_index >= tokens.size() or not tokens[token_index] is Dictionary:
		return
	var token_data: Dictionary = tokens[token_index]
	var modifier: int = _initiative_modifier_from_sheet(str(token_data.get("sheet_file", "")))
	initiative_view.call("add_combatant", token_index, token_data, modifier)
	_set_status("Ficha añadida a iniciativa con modificador %s%d." % ["+" if modifier >= 0 else "", modifier])

func _initiative_modifier_from_sheet(filename: String) -> int:
	if filename.is_empty():
		return 0
	var path := SHEETS_DIR + "/" + filename
	if not FileAccess.file_exists(path):
		return 0
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return 0
	var metadata: Dictionary = parsed.get("metadata", {})
	var score: int = 10
	if str(metadata.get("type", "Personaje")) == "Monstruo":
		var saved_fields: Dictionary = parsed.get("fields", {})
		score = int(saved_fields.get("monster_dex", 10))
	else:
		var saved_stats: Dictionary = parsed.get("stats", {})
		score = int(saved_stats.get("destreza", 10))
	return floori((score - 10) / 2.0)

func _on_initiative_changed() -> void:
	if loading_initiative_state or not _is_table_director():
		return
	_save_table_state()
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_sync_initiative_state.rpc(initiative_view.call("export_state"))

@rpc("authority", "call_remote", "reliable")
func _sync_initiative_state(data: Dictionary) -> void:
	if initiative_view == null:
		return
	loading_initiative_state = true
	initiative_view.call("import_state", data)
	loading_initiative_state = false

func _send_chat_input() -> void:
	var text: String = chat_input.text.strip_edges().substr(0, MAX_CHAT_MESSAGE_LENGTH)
	if text.is_empty():
		return
	var connected: bool = multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	_post_chat(_online_player_name() if connected else (fields.name.text if not fields.name.text.is_empty() else "Mesa"), text)
	chat_input.clear()

func _post_chat(author: String, message: String) -> void:
	var message_id := "%d_%d" % [multiplayer.get_unique_id(), Time.get_ticks_usec()]
	var peer := multiplayer.multiplayer_peer
	var connected: bool = peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	if connected and not multiplayer.is_server():
		_receive_chat_message.rpc(message_id, author, message)
		return
	_receive_chat_message(message_id, author, message)
	if connected:
		_receive_chat_message.rpc(message_id, author, message)

@rpc("any_peer", "call_remote", "reliable")
func _receive_chat_message(message_id: String, author: String, message: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and sender_id != 0:
		var now: int = Time.get_ticks_msec()
		var last_time: int = int(chat_last_message_time.get(str(sender_id), 0))
		if now - last_time < CHAT_RATE_LIMIT_MS:
			return
		chat_last_message_time[str(sender_id)] = now
		message = message.strip_edges().substr(0, MAX_CHAT_MESSAGE_LENGTH)
		if message.is_empty():
			return
		var player_data: Variant = online_players.get(str(sender_id), {})
		var player_name: String = str(player_data.get("name", "Jugador %d" % sender_id) if player_data is Dictionary else player_data).substr(0, 32)
		var category: String = author.strip_edges()
		author = "%s · %s" % [player_name, category] if category in ["Dados", "Carta", "Música", "Iniciativa"] else player_name
		message_id = "%d_%s" % [sender_id, message_id.substr(0, 80)]
	elif message.length() > MAX_CHAT_MESSAGE_LENGTH:
		message = message.substr(0, MAX_CHAT_MESSAGE_LENGTH)
	for existing in chat_messages:
		if existing.id == message_id:
			return
	chat_messages.append({"id": message_id, "author": author, "message": message})
	if chat_messages.size() > 200:
		chat_messages.pop_front()
	_refresh_chat()
	_save_table_state()
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		_receive_chat_message.rpc(message_id, author, message)

func _clear_chat_for_all() -> void:
	if not _is_table_director():
		_set_status("Solo el director puede limpiar el chat.", true)
		return
	chat_messages.clear()
	_refresh_chat()
	_save_table_state()
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_sync_clear_chat.rpc()
	_set_status("Chat limpiado para toda la mesa.")

@rpc("authority", "call_remote", "reliable")
func _sync_clear_chat() -> void:
	chat_messages.clear()
	_refresh_chat()
	_save_table_state()

@rpc("authority", "call_remote", "reliable")
func _sync_chat_history(entries: Array) -> void:
	var safe_messages: Array = []
	var start_index := maxi(entries.size() - 200, 0)
	for index in range(start_index, entries.size()):
		if not entries[index] is Dictionary:
			continue
		var entry: Dictionary = entries[index]
		var message_id := str(entry.get("id", "")).substr(0, 96)
		var author := str(entry.get("author", "Sistema")).strip_edges().substr(0, 48)
		var message := str(entry.get("message", "")).substr(0, MAX_CHAT_MESSAGE_LENGTH)
		if message_id.is_empty() or message.is_empty():
			continue
		safe_messages.append({"id": message_id, "author": author, "message": message})
	chat_messages = safe_messages
	_refresh_chat()

func _refresh_chat() -> void:
	if chat_log == null:
		return
	_refresh_chat_health()
	chat_log.clear()
	for entry in chat_messages:
		chat_log.push_color(GOLD)
		chat_log.push_bold()
		chat_log.add_text(str(entry.author))
		chat_log.pop()
		chat_log.pop()
		var message_text: String = str(entry.message)
		if message_text.strip_edges().to_lower() == "!gaster":
			chat_log.add_text("\n")
			var texture := _get_gaster_texture()
			if texture != null:
				chat_log.add_image(texture, 240, 245)
				chat_log.add_text("\n")
				chat_log.push_color(Color("#4a4052"))
				chat_log.push_italics()
				chat_log.add_text("Oscuro, oscuro y más oscuro…")
				chat_log.pop()
				chat_log.pop()
				chat_log.add_text("\n\n")
			else:
				chat_log.add_text("Oscuro, oscuro y más oscuro…\n\n")
		else:
			chat_log.add_text("\n" + message_text + "\n\n")

func _get_gaster_texture() -> Texture2D:
	if gaster_texture != null:
		return gaster_texture
	gaster_texture = GIF_PLAYBACK_SCRIPT.load_texture(GASTER_GIF_PATH)
	if gaster_texture == null:
		gaster_texture = ResourceLoader.load(GASTER_GIF_PATH) as Texture2D
	return gaster_texture

func _refresh_chat_health() -> void:
	if chat_health_box == null:
		return
	for child in chat_health_box.get_children():
		child.queue_free()
	if table_board == null:
		return
	var tokens: Array = table_board.export_tokens()
	for token_data in tokens:
		var sheet_file := str(token_data.get("sheet_file", ""))
		if sheet_file.is_empty():
			continue
		var snapshot := _read_sheet_snapshot(sheet_file)
		var current: float = float(snapshot.current) if bool(snapshot.valid) else float(token_data.get("hp_current", 0.0))
		var maximum: float = maxf(float(snapshot.maximum) if bool(snapshot.valid) else float(token_data.get("hp_max", 1.0)), 1.0)
		var character_name: String = str(snapshot.name) if bool(snapshot.valid) else str(token_data.get("character_name", "Ficha %s" % token_data.get("label", "")))
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = character_name
		name_label.custom_minimum_size.x = 80
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = maximum
		bar.value = clampf(current, 0.0, maximum)
		bar.show_percentage = false
		bar.tooltip_text = "%d / %d PV" % [int(current), int(maximum)]
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 20
		bar.add_theme_stylebox_override("fill", _box(Color("#a84646") if current <= maximum * 0.25 else Color("#4f9f62"), 6))
		row.add_child(bar)
		var value_label := Label.new()
		value_label.text = "%d/%d" % [int(current), int(maximum)]
		value_label.custom_minimum_size.x = 58
		row.add_child(value_label)
		var effects: Array = token_data.get("status_effects", [])
		if not effects.is_empty():
			var state_label := Label.new()
			state_label.text = " • " + ", ".join(effects)
			state_label.tooltip_text = "Efectos de estado"
			state_label.add_theme_color_override("font_color", Color("#c58cff"))
			row.add_child(state_label)
		chat_health_box.add_child(row)

func _music_library_panel() -> Control:
	var panel: PanelContainer = MUSIC_LIBRARY_SCENE.instantiate()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.4), 1, 18))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	var title := Label.new()
	title.text = "♫  BIBLIOTECA DE MÚSICA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	var music_hint := Label.new()
	music_hint.text = "Organiza el ambiente de la partida y decide quién escucha cada pista."
	music_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	music_hint.add_theme_color_override("font_color", MUTED)
	body.add_child(music_hint)
	music_now_label = Label.new()
	music_now_label.text = "No hay ninguna pista reproduciéndose"
	music_now_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_now_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(music_now_label)
	music_list = ItemList.new()
	music_list.custom_minimum_size.y = 320
	music_list.item_activated.connect(func(_index: int): _play_selected_music())
	body.add_child(music_list)
	var target_row := HFlowContainer.new()
	body.add_child(target_row)
	var target_label := Label.new()
	target_label.text = "Reproducir para"
	target_row.add_child(target_label)
	var target_option := OptionButton.new()
	target_option.add_item("Toda la mesa")
	target_option.add_item("Solo yo")
	target_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_option.item_selected.connect(func(index: int): music_play_for_table = index == 0)
	target_row.add_child(target_option)
	var controls := HFlowContainer.new()
	body.add_child(controls)
	for definition in [["＋ Añadir", _choose_music_file], ["▶ Reproducir", _play_selected_music], ["Ⅱ Pausa", _toggle_music_pause], ["■ Detener", _stop_music], ["× Quitar", _remove_selected_music]]:
		var button := Button.new()
		button.text = definition[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(definition[1])
		controls.add_child(button)
	var options := HFlowContainer.new()
	body.add_child(options)
	var volume_label := Label.new()
	volume_label.text = "Mi volumen"
	options.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.value = 100
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.value_changed.connect(_set_personal_music_volume)
	options.add_child(volume)
	var loop_check := CheckBox.new()
	loop_check.text = "Repetir"
	loop_check.button_pressed = true
	loop_check.toggled.connect(func(value: bool): music_loop_enabled = value)
	options.add_child(loop_check)
	var general_options := HFlowContainer.new()
	body.add_child(general_options)
	var general_label := Label.new()
	general_label.text = "Volumen general"
	general_options.add_child(general_label)
	music_general_slider = HSlider.new()
	music_general_slider.min_value = 0
	music_general_slider.max_value = 100
	music_general_slider.value = 70
	music_general_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_general_slider.value_changed.connect(_set_general_music_volume)
	general_options.add_child(music_general_slider)
	return panel

func _show_music_library() -> void:
	if not _toggle_floating_window(music_popup, Vector2i(640, 600), "Biblioteca de música"):
		return
	_refresh_music_library()

func _refresh_music_library() -> void:
	if music_list == null:
		return
	music_list.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MUSIC_DIR))
	var directory := DirAccess.open(MUSIC_DIR)
	if directory == null:
		return
	var filenames := directory.get_files()
	filenames.sort()
	for filename in filenames:
		if filename.get_extension().to_lower() not in ["mp3", "ogg", "wav"]:
			continue
		var index := music_list.add_item(filename.get_basename())
		music_list.set_item_metadata(index, MUSIC_DIR + "/" + filename)

func _choose_music_file() -> void:
	_show_external_file_dialog(music_file_dialog)

func _import_music_file(source: String) -> void:
	var extension := source.get_extension().to_lower()
	if extension not in ["mp3", "ogg", "wav"]:
		_set_status("Formato musical no compatible. Usa MP3, OGG o WAV.", true)
		return
	var bytes := FileAccess.get_file_as_bytes(source)
	if bytes.is_empty():
		_set_status("No se pudo leer la pista musical.", true)
		return
	if bytes.size() > 25 * 1024 * 1024:
		_set_status("La pista supera el límite de 25 MB.", true)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MUSIC_DIR))
	var target := MUSIC_DIR + "/" + source.get_file().validate_filename()
	if FileAccess.file_exists(target):
		target = MUSIC_DIR + "/%d_%s" % [int(Time.get_unix_time_from_system()), source.get_file().validate_filename()]
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		_set_status("No se pudo guardar la pista en la biblioteca.", true)
		return
	file.store_buffer(bytes)
	file.close()
	_refresh_music_library()
	_set_status("Pista añadida a la biblioteca musical.")

func _selected_music_path() -> String:
	var selected := music_list.get_selected_items()
	return "" if selected.is_empty() else str(music_list.get_item_metadata(selected[0]))

func _play_selected_music() -> void:
	if music_play_for_table and not _is_table_director():
		_set_status("Solo el director puede reproducir música para toda la mesa.", true)
		return
	var path := _selected_music_path()
	if path.is_empty():
		_set_status("Selecciona una pista de la biblioteca.", true)
		return
	if not _play_music_path(path):
		_set_status("No se pudo reproducir la pista seleccionada.", true)
		return
	music_is_shared = music_play_for_table
	var peer := multiplayer.multiplayer_peer
	if music_play_for_table and peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not table_board.share_music_to_all(path):
			_set_status("La música se reproduce localmente, pero no pudo enviarse a la mesa.", true)
	if music_play_for_table:
		_post_chat("Música", "Reproduciendo para la mesa: " + path.get_file().get_basename())
	else:
		_set_status("Reproduciendo solo para ti: " + path.get_file().get_basename())

func _play_music_path(path: String) -> bool:
	var stream: AudioStream
	match path.get_extension().to_lower():
		"mp3": stream = AudioStreamMP3.load_from_file(path)
		"ogg": stream = AudioStreamOggVorbis.load_from_file(path)
		"wav": stream = AudioStreamWAV.load_from_file(path)
		_: return false
	if stream == null:
		return false
	music_player.stream = stream
	music_player.stream_paused = false
	music_player.play()
	current_music_path = path
	_apply_music_volume()
	music_now_label.text = "Reproduciendo: " + path.get_file().get_basename()
	return true

func _toggle_music_pause() -> void:
	if music_is_shared and not _is_table_director():
		_set_status("Solo el director puede pausar la música compartida.", true)
		return
	if music_player.stream == null:
		return
	music_player.stream_paused = not music_player.stream_paused
	music_now_label.text = "En pausa" if music_player.stream_paused else "Reproduciendo música"
	if music_is_shared:
		_send_music_control("pause", music_player.stream_paused)

func _set_personal_music_volume(value: float) -> void:
	music_personal_volume = value / 100.0
	_apply_music_volume()

func _set_general_music_volume(value: float) -> void:
	if not _is_table_director():
		music_general_slider.set_value_no_signal(music_general_volume * 100.0)
		_set_status("Solo el director puede cambiar el volumen general.", true)
		return
	music_general_volume = value / 100.0
	_apply_music_volume()
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_sync_music_volume.rpc(music_general_volume)

func _apply_music_volume() -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(maxf(music_general_volume * music_personal_volume, 0.001))

@rpc("authority", "call_remote", "reliable")
func _sync_music_volume(value: float) -> void:
	music_general_volume = clampf(value, 0.0, 1.0)
	if music_general_slider != null:
		music_general_slider.set_value_no_signal(music_general_volume * 100.0)
	_apply_music_volume()

func _stop_music() -> void:
	if music_is_shared and not _is_table_director():
		_set_status("Solo el director puede detener la música compartida.", true)
		return
	music_player.stop()
	music_player.stream = null
	current_music_path = ""
	music_now_label.text = "No hay ninguna pista reproduciéndose"
	if music_is_shared:
		_send_music_control("stop", false)
	music_is_shared = false

func _send_music_control(action: String, paused: bool) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_sync_music_control.rpc(action, paused)

@rpc("authority", "call_remote", "reliable")
func _sync_music_control(action: String, paused: bool) -> void:
	if action == "stop":
		music_player.stop()
		music_player.stream = null
		current_music_path = ""
		music_is_shared = false
		music_now_label.text = "No hay ninguna pista reproduciéndose"
	elif action == "pause" and music_player.stream != null:
		music_player.stream_paused = paused
		music_now_label.text = "En pausa" if paused else "Reproduciendo música"

func _on_music_finished() -> void:
	if music_loop_enabled and music_player.stream != null:
		music_player.play()

func _remove_selected_music() -> void:
	var path := _selected_music_path()
	if path.is_empty():
		_set_status("Selecciona una pista para quitarla.", true)
		return
	if music_player.stream != null and path == current_music_path:
		music_player.stop()
		music_player.stream = null
		current_music_path = ""
		music_now_label.text = "No hay ninguna pista reproduciéndose"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_refresh_music_library()
	_set_status("Pista eliminada de la biblioteca.")

@rpc("authority", "call_remote", "reliable")
func _sync_table_music(filename: String, bytes: PackedByteArray) -> void:
	if bytes.is_empty() or bytes.size() > 25 * 1024 * 1024:
		return
	var safe_name := filename.get_file().validate_filename()
	if safe_name.get_extension().to_lower() not in ["mp3", "ogg", "wav"]:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MUSIC_DIR))
	var path := MUSIC_DIR + "/compartida_" + safe_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(bytes)
	file.close()
	_play_music_path(path)
	music_is_shared = true
	_refresh_music_library()

func _on_shared_music_received(filename: String, bytes: PackedByteArray, paused: bool) -> void:
	_sync_table_music(filename, bytes)
	if paused and music_player.stream != null:
		music_player.stream_paused = true
		music_now_label.text = "En pausa"

func _read_sheet_snapshot(filename: String) -> Dictionary:
	var fallback := {"valid": false, "name": "Ficha", "current": 0.0, "maximum": 1.0}
	var path := SHEETS_DIR + "/" + filename
	if not FileAccess.file_exists(path):
		return fallback
	var sheet = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not sheet is Dictionary:
		return fallback
	var saved_fields: Dictionary = sheet.get("fields", {})
	var metadata: Dictionary = sheet.get("metadata", {})
	var is_monster: bool = str(metadata.get("type", "Personaje")) == "Monstruo"
	var hp_current_key: String = "monster_hp_current" if is_monster else "hp_current"
	var hp_max_key: String = "monster_hp_max" if is_monster else "hp_max"
	return {
		"valid": true,
		"name": str(metadata.get("name", "Ficha")),
		"current": float(str(saved_fields.get(hp_current_key, "0"))),
		"maximum": maxf(float(str(saved_fields.get(hp_max_key, "1"))), 1.0)
	}

func _online_panel() -> Control:
	var panel: PanelContainer = ONLINE_PANEL_SCENE.instantiate()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.4), 1, 22))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var title := Label.new()
	title.text = "◎  MESA ONLINE"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	var hint := Label.new()
	hint.text = "Crea una partida o escribe la IP del anfitrión para unirte."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	body.add_child(hint)
	var name_holder := VBoxContainer.new()
	body.add_child(name_holder)
	var name_label := Label.new()
	name_label.text = "NOMBRE DEL JUGADOR"
	name_label.add_theme_font_size_override("font_size", 12)
	name_holder.add_child(name_label)
	online_name_edit = LineEdit.new()
	online_name_edit.placeholder_text = "Nombre que verán los demás"
	online_name_edit.max_length = 32
	name_holder.add_child(online_name_edit)
	var connection_row := HBoxContainer.new()
	body.add_child(connection_row)
	_add_field(connection_row, "Dirección IP", "online_ip", "127.0.0.1")
	online_ip_edit = fields.online_ip
	online_ip_edit.text = "127.0.0.1"
	_add_field(connection_row, "Puerto", "online_port", "7000")
	online_port_edit = fields.online_port
	online_port_edit.text = "7000"
	var room_label := Label.new()
	room_label.text = "CÓDIGO DE SALA (misma red Wi-Fi/LAN)"
	room_label.add_theme_font_size_override("font_size", 12)
	body.add_child(room_label)
	var room_row := HBoxContainer.new()
	body.add_child(room_row)
	online_room_code_edit = LineEdit.new()
	online_room_code_edit.placeholder_text = "Crea una mesa o pega aquí un código"
	online_room_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_row.add_child(online_room_code_edit)
	var copy_code_button := Button.new()
	copy_code_button.text = "COPIAR"
	copy_code_button.pressed.connect(_copy_online_room_code)
	room_row.add_child(copy_code_button)
	var join_code_button := Button.new()
	join_code_button.text = "UNIRSE CON CÓDIGO"
	join_code_button.pressed.connect(_join_online_room_code)
	body.add_child(join_code_button)
	var public_title := Label.new()
	public_title.text = "PLAYIT.GG / TÚNEL EXTERNO"
	public_title.add_theme_font_size_override("font_size", 12)
	public_title.add_theme_color_override("font_color", GOLD)
	body.add_child(public_title)
	var public_hint := Label.new()
	public_hint.text = "Crea en Playit un túnel UDP hacia 127.0.0.1:7000 y pega aquí la dirección pública recibida."
	public_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(public_hint)
	var public_row := HBoxContainer.new()
	body.add_child(public_row)
	online_public_address_edit = LineEdit.new()
	online_public_address_edit.placeholder_text = "ejemplo.gl.at.ply.gg"
	online_public_address_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	public_row.add_child(online_public_address_edit)
	online_public_port_edit = LineEdit.new()
	online_public_port_edit.placeholder_text = "Puerto público"
	online_public_port_edit.custom_minimum_size.x = 130
	public_row.add_child(online_public_port_edit)
	var external_code_button := Button.new()
	external_code_button.text = "GENERAR CÓDIGO EXTERNO"
	external_code_button.pressed.connect(_generate_external_room_code)
	body.add_child(external_code_button)
	var buttons := HBoxContainer.new()
	body.add_child(buttons)
	var host_button := Button.new()
	host_button.text = "＋ Crear mesa"
	host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_button.pressed.connect(_host_online_table)
	buttons.add_child(host_button)
	var join_button := Button.new()
	join_button.text = "➜ Unirse"
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.pressed.connect(_join_online_table)
	buttons.add_child(join_button)
	var disconnect_button := Button.new()
	disconnect_button.text = "× Desconectar"
	disconnect_button.pressed.connect(_disconnect_online)
	buttons.add_child(disconnect_button)
	online_status_label = Label.new()
	online_status_label.text = "Sin conexión"
	online_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_status_label.add_theme_color_override("font_color", MUTED)
	body.add_child(online_status_label)
	var players_title := Label.new()
	players_title.text = "JUGADORES CONECTADOS"
	players_title.add_theme_font_size_override("font_size", 12)
	players_title.add_theme_color_override("font_color", GOLD)
	body.add_child(players_title)
	online_players_list = ItemList.new()
	online_players_list.custom_minimum_size.y = 90
	online_players_list.select_mode = ItemList.SELECT_SINGLE
	body.add_child(online_players_list)
	online_kick_button = Button.new()
	online_kick_button.text = "EXPULSAR JUGADOR"
	online_kick_button.tooltip_text = "Solo el anfitrión puede expulsar jugadores"
	online_kick_button.pressed.connect(_kick_selected_online_player)
	body.add_child(online_kick_button)
	_refresh_online_players()
	return panel

func _show_online() -> void:
	_toggle_floating_window(online_popup, Vector2i(580, 760), "Mesa online")

func _online_port() -> int:
	var text := online_port_edit.text.strip_edges()
	return clampi(int(text) if text.is_valid_int() else 7000, 1, 65535)

func _host_online_table() -> void:
	if not _validate_online_name():
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(_online_port(), 16)
	if error != OK:
		_set_online_status("No se pudo abrir el puerto: %s" % error_string(error), true)
		return
	multiplayer.multiplayer_peer = peer
	online_should_reconnect = false
	online_reconnect_attempts = 0
	online_players.clear()
	online_banned_ids.clear()
	online_players["1"] = {"name": _online_player_name(), "id": online_player_id, "latency": 0}
	if online_room_code_edit != null:
		online_room_code_edit.text = _make_online_room_code(_preferred_local_ip(), _online_port())
	_refresh_online_players()
	_update_director_permissions()
	_set_online_status("Mesa creada por %s en el puerto %d." % [_online_player_name(), _online_port()])

func _preferred_local_ip() -> String:
	var fallback := "127.0.0.1"
	for address in IP.get_local_addresses():
		if ":" in address or address.begins_with("127."):
			continue
		fallback = address
		if address.begins_with("192.168.") or address.begins_with("10.") or address.begins_with("172."):
			return address
	return fallback

func _make_online_room_code(address: String, port: int) -> String:
	var payload := JSON.stringify({"ip": address, "port": port})
	return "DND-" + Marshalls.raw_to_base64(payload.to_utf8_buffer())

func _decode_online_room_code(code: String) -> Dictionary:
	var clean := code.strip_edges()
	if not clean.begins_with("DND-"):
		return {}
	var decoded_bytes: PackedByteArray = Marshalls.base64_to_raw(clean.trim_prefix("DND-"))
	if decoded_bytes.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(decoded_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return {}
	var address: String = str(parsed.get("ip", "")).strip_edges()
	var port: int = int(parsed.get("port", 0))
	if address.is_empty() or port < 1 or port > 65535:
		return {}
	return {"ip": address, "port": port}

func _copy_online_room_code() -> void:
	if online_room_code_edit == null or online_room_code_edit.text.strip_edges().is_empty():
		_set_online_status("Primero crea una mesa para generar el código.", true)
		return
	DisplayServer.clipboard_set(online_room_code_edit.text.strip_edges())
	_set_online_status("Código de sala copiado.")

func _generate_external_room_code() -> void:
	var address: String = online_public_address_edit.text.strip_edges() if online_public_address_edit != null else ""
	var port_text: String = online_public_port_edit.text.strip_edges() if online_public_port_edit != null else ""
	if address.is_empty():
		_set_online_status("Pega la dirección pública entregada por Playit.", true)
		return
	if not port_text.is_valid_int():
		_set_online_status("Escribe el puerto público entregado por Playit.", true)
		return
	var public_port: int = int(port_text)
	if public_port < 1 or public_port > 65535:
		_set_online_status("El puerto público debe estar entre 1 y 65535.", true)
		return
	if online_room_code_edit != null:
		online_room_code_edit.text = _make_online_room_code(address, public_port)
	DisplayServer.clipboard_set(online_room_code_edit.text)
	_set_online_status("Código externo generado y copiado. Ya puedes enviarlo a los jugadores.")

func _join_online_room_code() -> void:
	if not _validate_online_name():
		return
	var room: Dictionary = _decode_online_room_code(online_room_code_edit.text if online_room_code_edit != null else "")
	if room.is_empty():
		_set_online_status("El código de sala no es válido.", true)
		return
	online_ip_edit.text = str(room.ip)
	online_port_edit.text = str(room.port)
	_join_online_table()

func _join_online_table() -> void:
	if not _validate_online_name():
		return
	online_last_ip = online_ip_edit.text.strip_edges()
	online_last_port = _online_port()
	online_should_reconnect = true
	online_reconnect_attempts = 0
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(online_last_ip, online_last_port)
	if error != OK:
		_schedule_online_reconnect("No se pudo iniciar la conexión: %s." % error_string(error))
		return
	multiplayer.multiplayer_peer = peer
	_update_director_permissions()
	_set_online_status("Conectando como %s…" % _online_player_name())

func _online_connected() -> void:
	online_reconnect_attempts = 0
	if online_reconnect_timer != null:
		online_reconnect_timer.stop()
	_register_online_player.rpc_id(1, _online_player_name(), online_player_id)
	_update_director_permissions()
	if table_board != null:
		table_board.clear_history()
	_set_online_status("Conectado como %s." % _online_player_name())
	_post_chat("Sistema", "%s se ha unido a la mesa." % _online_player_name())

func _online_player_name() -> String:
	if online_name_edit == null:
		return "Jugador"
	var value := online_name_edit.text.strip_edges()
	return value if not value.is_empty() else "Jugador"

func _load_or_create_online_player_id() -> String:
	if FileAccess.file_exists(ONLINE_ID_PATH):
		var saved_id: String = FileAccess.get_file_as_string(ONLINE_ID_PATH).strip_edges()
		if not saved_id.is_empty():
			return saved_id
	# Este identificador se guarda en user:// y permanece estable entre reconexiones.
	var source := "%s:%s:%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]
	var created_id: String = source.sha256_text().substr(0, 24)
	var file := FileAccess.open(ONLINE_ID_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(created_id)
	return created_id

func _validate_online_name() -> bool:
	if online_name_edit.text.strip_edges().is_empty():
		_set_online_status("Escribe un nombre antes de conectarte.", true)
		online_name_edit.grab_focus()
		return false
	return true

func _disconnect_online() -> void:
	online_should_reconnect = false
	online_reconnect_attempts = 0
	if online_reconnect_timer != null:
		online_reconnect_timer.stop()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online_players.clear()
	_refresh_online_players()
	if table_board != null:
		table_board.clear_history()
	_update_director_permissions()
	_set_online_status("Sin conexión")

func _online_connection_failed() -> void:
	_schedule_online_reconnect("No se pudo conectar con el anfitrión.")

func _online_server_disconnected() -> void:
	_schedule_online_reconnect("Se perdió la conexión con el anfitrión.")

func _schedule_online_reconnect(reason: String) -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online_players.clear()
	_refresh_online_players()
	if not online_should_reconnect or online_last_ip.is_empty():
		_set_online_status(reason, true)
		return
	if online_reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
		online_should_reconnect = false
		_set_online_status("No se pudo reconectar tras %d intentos. Pulsa Unirse para probar otra vez." % MAX_RECONNECT_ATTEMPTS, true)
		return
	var delay: float = minf(2.0 + online_reconnect_attempts * 1.5, 10.0)
	_set_online_status("%s Reintentando en %.0f s… (%d/%d)" % [reason, delay, online_reconnect_attempts + 1, MAX_RECONNECT_ATTEMPTS], true)
	if online_reconnect_timer != null:
		online_reconnect_timer.start(delay)

func _attempt_online_reconnect() -> void:
	if not online_should_reconnect:
		return
	online_reconnect_attempts += 1
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(online_last_ip, online_last_port)
	if error != OK:
		_schedule_online_reconnect("Falló el intento %d." % online_reconnect_attempts)
		return
	multiplayer.multiplayer_peer = peer
	_update_director_permissions()
	_set_online_status("Reconectando como %s… (%d/%d)" % [_online_player_name(), online_reconnect_attempts, MAX_RECONNECT_ATTEMPTS])

func _set_online_status(message: String, is_error := false) -> void:
	online_status_label.text = message
	online_status_label.add_theme_color_override("font_color", Color("#d97668") if is_error else Color("#8fbd83"))
	_set_status(message, is_error)

func _is_table_director() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer == null or peer is OfflineMultiplayerPeer or multiplayer.is_server()

func _update_director_permissions() -> void:
	var allowed := _is_table_director()
	for button in director_only_buttons:
		if is_instance_valid(button):
			if not button.has_meta("director_original_tooltip"):
				button.set_meta("director_original_tooltip", button.tooltip_text)
			button.disabled = not allowed
			button.tooltip_text = "Solo el anfitrión puede usar este control" if not allowed else str(button.get_meta("director_original_tooltip"))
	if table_board != null:
		table_board.set_director_mode(allowed)
		table_board.set_local_player_name(_online_player_name())
		table_board.set_local_player_id(online_player_id)
		table_board.set_online_players(online_players)
	if initiative_view != null:
		initiative_view.call("set_editable", allowed)
	_refresh_history_buttons()

# Mantiene una lista sencilla de jugadores para evitar errores al escribir propietarios.
# El servidor es el único que modifica y distribuye la lista completa.
@rpc("any_peer", "call_remote", "reliable")
func _register_online_player(player_name: String, player_id: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if peer_id <= 0:
		return
	var clean_name: String = player_name.strip_edges().substr(0, 32)
	if clean_name.is_empty():
		clean_name = "Jugador %d" % peer_id
	var clean_id: String = player_id.strip_edges().substr(0, 64)
	if clean_id.is_empty():
		clean_id = "peer-%d" % peer_id
	if online_banned_ids.has(clean_id):
		var active_peer := multiplayer.multiplayer_peer
		if active_peer is ENetMultiplayerPeer:
			active_peer.disconnect_peer(peer_id)
		return
	# Dos clientes activos nunca comparten identidad. Esto evita que una segunda
	# conexión herede por accidente las fichas del primer jugador.
	for existing_peer_key in online_players:
		if int(str(existing_peer_key)) == peer_id:
			continue
		var existing_data: Variant = online_players[existing_peer_key]
		if existing_data is Dictionary and str(existing_data.get("id", "")) == clean_id:
			clean_id = ("%s:%s:%s" % [clean_id, peer_id, Time.get_ticks_usec()]).sha256_text().substr(0, 24)
			break
	clean_name = _unique_online_player_name(clean_name, peer_id)
	online_players[str(peer_id)] = {"name": clean_name, "id": clean_id, "latency": -1}
	_refresh_online_players()
	_sync_online_players.rpc(online_players)
	_accept_online_identity.rpc_id(peer_id, clean_name, clean_id)

func _unique_online_player_name(requested: String, peer_id: int) -> String:
	var used: Dictionary = {}
	for existing_peer_key in online_players:
		if int(str(existing_peer_key)) == peer_id:
			continue
		var existing_data: Variant = online_players[existing_peer_key]
		var existing_name: String = str(existing_data.get("name", "") if existing_data is Dictionary else existing_data).strip_edges().to_lower()
		if not existing_name.is_empty():
			used[existing_name] = true
	if not used.has(requested.to_lower()):
		return requested
	var suffix: int = 2
	while used.has(("%s (%d)" % [requested, suffix]).to_lower()):
		suffix += 1
	return "%s (%d)" % [requested, suffix]

@rpc("authority", "call_remote", "reliable")
func _accept_online_identity(assigned_name: String, assigned_id: String) -> void:
	if multiplayer.is_server():
		return
	var clean_name: String = assigned_name.strip_edges().substr(0, 32)
	var clean_id: String = assigned_id.strip_edges().substr(0, 64)
	if clean_name.is_empty() or clean_id.is_empty():
		return
	if online_name_edit != null:
		online_name_edit.text = clean_name
	online_player_id = clean_id
	var file := FileAccess.open(ONLINE_ID_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(clean_id)
	_update_director_permissions()
	_set_online_status("Conectado como %s." % clean_name)

@rpc("authority", "call_remote", "reliable")
func _sync_online_players(players: Dictionary) -> void:
	online_players = players.duplicate(true)
	_refresh_online_players()
	_update_director_permissions()

func _refresh_online_players() -> void:
	var players: Array[Dictionary] = []
	for peer_key in online_players:
		var value: Variant = online_players[peer_key]
		var player_name: String = str(value.get("name", "") if value is Dictionary else value).strip_edges()
		var player_id: String = str(value.get("id", "") if value is Dictionary else "").strip_edges()
		var latency: int = int(value.get("latency", -1) if value is Dictionary else -1)
		if not player_name.is_empty():
			players.append({"name": player_name, "id": player_id, "peer_id": int(str(peer_key)), "latency": latency})
	players.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.name).naturalnocasecmp_to(str(b.name)) < 0)
	if online_players_list != null:
		online_players_list.clear()
		if players.is_empty():
			online_players_list.add_item("Sin jugadores conectados")
			online_players_list.set_item_disabled(0, true)
		else:
			for player in players:
				var suffix := " · Director" if int(player.peer_id) == 1 else (" · %d ms" % int(player.latency) if int(player.latency) >= 0 else " · midiendo…")
				online_players_list.add_item(str(player.name) + suffix)
				online_players_list.set_item_metadata(online_players_list.item_count - 1, int(player.peer_id))
	if token_owner_option != null:
		var current_owner: String = token_owner_edit.text.strip_edges() if token_owner_edit != null else ""
		token_owner_option.clear()
		token_owner_option.add_item("Sin propietario")
		token_owner_option.set_item_metadata(0, {"name": "", "id": ""})
		for player in players:
			token_owner_option.add_item(str(player.name))
			token_owner_option.set_item_metadata(token_owner_option.item_count - 1, player)
		_select_owner_option(current_owner, pending_token_owner_id)
	if table_board != null:
		table_board.set_online_players(online_players)
	if online_kick_button != null:
		online_kick_button.disabled = not multiplayer.is_server() or online_players.size() <= 1

func _select_token_owner_from_list(index: int) -> void:
	if token_owner_edit == null or token_owner_option == null:
		return
	var data: Variant = token_owner_option.get_item_metadata(index)
	token_owner_edit.text = str(data.get("name", "") if data is Dictionary else data)
	pending_token_owner_id = str(data.get("id", "") if data is Dictionary else "")

func _select_owner_option(owner: String, owner_id := "") -> void:
	if token_owner_option == null:
		return
	for index in range(token_owner_option.item_count):
		var data: Variant = token_owner_option.get_item_metadata(index)
		var item_name: String = str(data.get("name", "") if data is Dictionary else data)
		var item_id: String = str(data.get("id", "") if data is Dictionary else "")
		if (not owner_id.is_empty() and item_id == owner_id) or (owner_id.is_empty() and item_name == owner):
			token_owner_option.select(index)
			return
	token_owner_option.select(0)

func _kick_selected_online_player() -> void:
	if not multiplayer.is_server() or online_players_list == null:
		_set_online_status("Solo el anfitrión puede expulsar jugadores.", true)
		return
	var selected: PackedInt32Array = online_players_list.get_selected_items()
	if selected.is_empty():
		_set_online_status("Selecciona un jugador de la lista.", true)
		return
	var peer_id: int = int(online_players_list.get_item_metadata(selected[0]))
	if peer_id <= 1:
		_set_online_status("No puedes expulsar al anfitrión.", true)
		return
	var player_data: Variant = online_players.get(str(peer_id), {})
	var player_name: String = str(player_data.get("name", "Jugador") if player_data is Dictionary else player_data)
	var player_id: String = str(player_data.get("id", "") if player_data is Dictionary else "")
	if not player_id.is_empty():
		online_banned_ids[player_id] = true
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		peer.disconnect_peer(peer_id)
		_set_online_status("%s fue expulsado de la mesa." % player_name)

func _send_online_ping() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server():
		_online_ping_request.rpc_id(1, Time.get_ticks_msec())

@rpc("any_peer", "call_remote", "unreliable")
func _online_ping_request(sent_at: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id > 1:
		_online_ping_response.rpc_id(sender_id, sent_at)

@rpc("any_peer", "call_remote", "unreliable")
func _online_ping_response(sent_at: int) -> void:
	if multiplayer.is_server():
		return
	var latency: int = maxi(Time.get_ticks_msec() - sent_at, 0)
	_report_online_latency.rpc_id(1, latency)

@rpc("any_peer", "call_remote", "unreliable")
func _report_online_latency(latency: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var key := str(sender_id)
	if not online_players.has(key) or not online_players[key] is Dictionary:
		return
	var player_data: Dictionary = online_players[key].duplicate(true)
	player_data["latency"] = clampi(latency, 0, 9999)
	online_players[key] = player_data
	_refresh_online_players()
	_sync_online_players.rpc(online_players)

func _undo_table_change() -> void:
	if table_board != null and _is_table_director():
		table_board.undo()

func _redo_table_change() -> void:
	if table_board != null and _is_table_director():
		table_board.redo()

func _toggle_group_selection() -> void:
	group_selection_enabled = not group_selection_enabled
	if group_selection_button != null:
		group_selection_button.text = "GRUPO ✓" if group_selection_enabled else "GRUPO"
	if table_board != null:
		table_board.set_group_selection_mode(group_selection_enabled)
	_set_status("Toca las fichas que quieras agrupar." if group_selection_enabled else "Grupo listo: puedes moverlo o duplicarlo.")

func _duplicate_table_selection() -> void:
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona una ficha o un grupo para duplicar.", true)
		return
	if not _is_table_director():
		_set_status("Solo el anfitrión puede duplicar fichas online.", true)
		return
	table_board.duplicate_selected_tokens()
	_set_status("Ficha o grupo duplicado una casilla hacia abajo y a la derecha.")

func _assign_selected_token_owner() -> void:
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona una ficha antes de asignar propietario.", true)
		return
	if not _is_table_director():
		_set_status("Solo el anfitrión puede asignar fichas.", true)
		return
	var owner: String = token_owner_edit.text.strip_edges()
	var owner_id := ""
	if token_owner_option != null and token_owner_option.selected >= 0:
		var selected_data: Variant = token_owner_option.get_item_metadata(token_owner_option.selected)
		var selected_name: String = str(selected_data.get("name", "") if selected_data is Dictionary else selected_data)
		if selected_name == owner:
			owner_id = str(selected_data.get("id", "") if selected_data is Dictionary else "")
	pending_token_owner_id = owner_id
	table_board.set_selected_owner(owner, owner_id)
	_set_status("Ficha sin propietario: solo la mueve el director." if owner.is_empty() else "Ficha asignada a %s." % owner)

func _on_table_history_changed(can_undo: bool, can_redo: bool) -> void:
	history_can_undo = can_undo
	history_can_redo = can_redo
	_refresh_history_buttons()

func _refresh_history_buttons() -> void:
	var allowed := _is_table_director()
	if undo_button != null:
		undo_button.disabled = not allowed or not history_can_undo
	if redo_button != null:
		redo_button.disabled = not allowed or not history_can_redo

func _on_fog_changed() -> void:
	if loading_table_state:
		return
	pending_fog_sync = true
	_queue_table_live_sync()

func _on_drawings_changed() -> void:
	if loading_table_state:
		return
	pending_drawings_sync = true
	_queue_table_live_sync()

func _on_token_motion_changed() -> void:
	if loading_table_state:
		return
	pending_token_motion_sync = true
	if table_live_sync_timer != null and table_live_sync_timer.is_stopped():
		table_live_sync_timer.start()

func _queue_table_live_sync() -> void:
	if table_live_sync_timer != null and table_live_sync_timer.is_stopped():
		table_live_sync_timer.start()
	if table_save_debounce_timer != null:
		table_save_debounce_timer.start()

func _flush_table_live_sync() -> void:
	var send_fog: bool = pending_fog_sync
	var send_drawings: bool = pending_drawings_sync
	var send_token_motion: bool = pending_token_motion_sync
	pending_fog_sync = false
	pending_drawings_sync = false
	pending_token_motion_sync = false
	if table_board == null:
		return
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if send_fog and _is_table_director():
		table_board.sync_fog.rpc(table_board.export_fog())
	if send_drawings and _is_table_director():
		table_board.sync_drawings.rpc(table_board.export_drawings())
	if send_token_motion:
		table_board.sync_token_positions.rpc(table_board.export_token_positions())

func _toggle_token_lock() -> void:
	if table_board == null or not _is_table_director():
		return
	var state: Dictionary = table_board.export_locks()
	table_board.set_tokens_locked(not bool(state.get("tokens_locked", false)))

func _toggle_map_lock() -> void:
	if table_board == null or not _is_table_director():
		return
	var state: Dictionary = table_board.export_locks()
	table_board.set_map_locked(not bool(state.get("map_locked", false)))

func _on_table_locks_changed() -> void:
	if table_board == null:
		return
	var state: Dictionary = table_board.export_locks()
	if token_lock_button != null:
		token_lock_button.text = "Desbloquear fichas" if bool(state.get("tokens_locked", false)) else "Bloquear fichas"
	if map_lock_button != null:
		map_lock_button.text = "Desbloquear mapa" if bool(state.get("map_locked", false)) else "Bloquear mapa"
	_save_table_state()
	if not _is_table_director():
		return
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		table_board.sync_locks.rpc(state)

func _online_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server() and table_board != null:
		table_board.send_map_to_peer(peer_id)
		if table_media_playing and not current_table_media_path.is_empty():
			table_board.send_table_media_to_peer(peer_id, current_table_media_path)
		table_board.sync_tokens.rpc_id(peer_id, table_board.export_tokens())
		table_board.send_token_images_to_peer(peer_id)
		var sent_sheets: Dictionary = {}
		for token in table_board.export_tokens():
			if not token is Dictionary:
				continue
			var sheet_filename := str(token.get("sheet_file", "")).get_file()
			if sheet_filename.is_empty() or sent_sheets.has(sheet_filename):
				continue
			sent_sheets[sheet_filename] = true
			table_board.send_sheet_to_peer(peer_id, sheet_filename)
		table_board.sync_fog.rpc_id(peer_id, table_board.export_fog())
		table_board.sync_locks.rpc_id(peer_id, table_board.export_locks())
		table_board.sync_drawings.rpc_id(peer_id, table_board.export_drawings())
		_sync_chat_history.rpc_id(peer_id, chat_messages)
		if initiative_view != null:
			_sync_initiative_state.rpc_id(peer_id, initiative_view.call("export_state"))
		_sync_music_volume.rpc_id(peer_id, music_general_volume)
		if music_is_shared and not current_music_path.is_empty() and FileAccess.file_exists(current_music_path):
			table_board.send_music_to_peer(peer_id, current_music_path, music_player.stream_paused)
		_sync_online_players.rpc_id(peer_id, online_players)

func _on_shared_sheet_received(filename: String) -> void:
	_refresh_sheets_list()
	_set_status("Hoja recibida del director: %s." % filename.get_basename())

func _online_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	online_players.erase(str(peer_id))
	_refresh_online_players()
	_sync_online_players.rpc(online_players)

func _choose_token_image() -> void:
	if table_board.selected_token < 0:
		_set_status("Selecciona una ficha antes de importar su imagen.", true)
		return
	_show_external_file_dialog(token_image_dialog)

func _on_table_token_selected(index: int) -> void:
	if token_status_edit == null:
		return
	portrait_gallery_title.visible = index >= 0
	portrait_gallery_box.visible = index >= 0
	token_status_edit.clear()
	if token_status_preset != null:
		token_status_preset.select(0)
	if token_status_duration_spin != null:
		token_status_duration_spin.value = 0
	_refresh_token_status_list()
	if token_vision_spin != null and index >= 0:
		token_vision_spin.set_value_no_signal(table_board.get_selected_vision())
	if token_vision_spin != null:
		token_vision_spin.editable = index >= 0
	if token_owner_edit != null:
		token_owner_edit.text = table_board.get_selected_owner() if index >= 0 else ""
		pending_token_owner_id = table_board.get_selected_owner_id() if index >= 0 else ""
		_select_owner_option(token_owner_edit.text, pending_token_owner_id)
	_refresh_portrait_gallery()
	_refresh_chat()

func _apply_token_statuses() -> void:
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona una ficha para asignarle efectos de estado.", true)
		return
	var effects: Array[String] = table_board.get_selected_status_effects()
	var duration := int(token_status_duration_spin.value) if token_status_duration_spin != null else 0
	var added := 0
	for part in token_status_edit.text.split(","):
		var clean := part.strip_edges()
		if not clean.is_empty():
			var formatted := "%s (%d %s)" % [clean, duration, "turno" if duration == 1 else "turnos"] if duration > 0 else clean
			if not effects.has(formatted):
				effects.append(formatted)
				added += 1
	if added == 0:
		_set_status("Escribe un efecto nuevo antes de añadirlo.", true)
		return
	table_board.set_selected_status_effects(effects)
	_sync_selected_statuses_to_initiative(effects)
	token_status_edit.clear()
	if token_status_preset != null:
		token_status_preset.select(0)
	_refresh_token_status_list()
	_set_status("%d efecto(s) añadido(s)." % added)
	_refresh_chat()

func _remove_selected_token_status() -> void:
	if table_board == null or table_board.selected_token < 0 or token_status_list == null:
		_set_status("Selecciona una ficha y uno de sus efectos.", true)
		return
	var selected := token_status_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona el efecto que quieres quitar.", true)
		return
	var effects: Array[String] = table_board.get_selected_status_effects()
	var effect_index: int = selected[0]
	if effect_index < 0 or effect_index >= effects.size():
		return
	var removed := effects[effect_index]
	effects.remove_at(effect_index)
	table_board.set_selected_status_effects(effects)
	_sync_selected_statuses_to_initiative(effects)
	_refresh_token_status_list()
	_refresh_chat()
	_set_status("Efecto eliminado: %s." % removed)

func _refresh_token_status_list() -> void:
	if token_status_list == null:
		return
	token_status_list.clear()
	if table_board == null or table_board.selected_token < 0:
		return
	for effect in table_board.get_selected_status_effects():
		token_status_list.add_item(effect)

func _select_token_status_preset(index: int) -> void:
	if token_status_edit == null or token_status_preset == null or index <= 0:
		return
	token_status_edit.text = token_status_preset.get_item_text(index)
	token_status_edit.grab_focus()
	token_status_edit.caret_column = token_status_edit.text.length()

func _sync_selected_statuses_to_initiative(effects: Array[String]) -> void:
	if initiative_view == null or table_board == null or table_board.selected_token < 0:
		return
	initiative_view.call("set_combatant_statuses", table_board.selected_token, effects)

func _choose_table_media() -> void:
	_show_external_file_dialog(table_media_dialog)

func _setup_table_media_library() -> void:
	table_media_popup = Window.new()
	table_media_popup.title = "Biblioteca de animaciones"
	# Window nace visible. Se oculta antes de entrar al árbol para que la
	# biblioteca solo aparezca cuando el usuario pulse su botón, sin destellos.
	table_media_popup.visible = false
	add_child(table_media_popup)
	table_media_popup.hide()
	table_media_delete_dialog = ConfirmationDialog.new()
	table_media_delete_dialog.title = "Quitar animación"
	table_media_delete_dialog.ok_button_text = "Quitar de la biblioteca"
	table_media_delete_dialog.cancel_button_text = "Cancelar"
	table_media_delete_dialog.confirmed.connect(_confirm_remove_table_media)
	table_media_delete_dialog.visible = false
	add_child(table_media_delete_dialog)
	table_media_delete_dialog.hide()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.4), 1, 18))
	table_media_popup.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	var title := Label.new()
	title.text = "✦  ANIMACIONES DE LA MESA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	var help := Label.new()
	help.text = "Selecciona un efecto incluido o guarda hasta 30 GIF/vídeos para reproducirlos para todos."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_color", MUTED)
	body.add_child(help)
	table_media_count_label = Label.new()
	table_media_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_media_count_label.add_theme_color_override("font_color", GOLD)
	body.add_child(table_media_count_label)
	table_media_search = LineEdit.new()
	table_media_search.placeholder_text = "Buscar animación…"
	table_media_search.clear_button_enabled = true
	table_media_search.text_changed.connect(func(_text: String): _refresh_table_media_library())
	body.add_child(table_media_search)
	var content := BoxContainer.new()
	content.vertical = size.x < 700.0
	content.add_theme_constant_override("separation", 10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_media_preview_layout = content
	body.add_child(content)
	table_media_list = ItemList.new()
	table_media_list.name = "AnimationList"
	table_media_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_media_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_media_list.custom_minimum_size = Vector2(250, 260)
	table_media_list.allow_reselect = true
	table_media_list.item_activated.connect(func(_index: int): _play_selected_table_media())
	table_media_list.item_selected.connect(func(_index: int): _update_table_media_preview())
	content.add_child(table_media_list)
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(230, 260)
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.add_theme_stylebox_override("panel", _box(FIELD, 10, GOLD.darkened(0.55), 1, 10))
	content.add_child(preview_panel)
	var preview_body := VBoxContainer.new()
	preview_body.add_theme_constant_override("separation", 8)
	preview_panel.add_child(preview_body)
	table_media_preview = TextureRect.new()
	table_media_preview.custom_minimum_size = Vector2(200, 170)
	table_media_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_media_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table_media_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_body.add_child(table_media_preview)
	table_media_video_preview = VideoStreamPlayer.new()
	table_media_video_preview.custom_minimum_size = Vector2(200, 170)
	table_media_video_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_media_video_preview.expand = true
	table_media_video_preview.volume_db = -80.0
	table_media_video_preview.tooltip_text = "Vista previa silenciosa del vídeo"
	table_media_video_preview.finished.connect(_restart_table_media_video_preview)
	table_media_video_preview.hide()
	preview_body.add_child(table_media_video_preview)
	table_media_name_edit = LineEdit.new()
	table_media_name_edit.placeholder_text = "Nombre de la animación"
	preview_body.add_child(table_media_name_edit)
	var rename_button := Button.new()
	rename_button.text = "Cambiar nombre"
	rename_button.pressed.connect(_rename_selected_table_media)
	preview_body.add_child(rename_button)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	body.add_child(actions)
	for definition in [["＋ Añadir GIF/vídeo", _choose_table_media], ["▶ Reproducir", _play_selected_table_media], ["× Quitar", _remove_selected_table_media], ["■ Detener", _stop_uploaded_table_media]]:
		var button := Button.new()
		button.text = definition[0]
		button.custom_minimum_size = Vector2(125, 38)
		button.pressed.connect(definition[1])
		actions.add_child(button)
		director_only_buttons.append(button)
	_load_table_media_library()
	_refresh_table_media_library()

func _show_table_media_library() -> void:
	_refresh_table_media_library()
	_toggle_floating_window(table_media_popup, Vector2i(600, 620), "Biblioteca de animaciones")

func _load_table_media_library() -> void:
	table_media_library.clear()
	if not FileAccess.file_exists(TABLE_MEDIA_LIBRARY_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE_MEDIA_LIBRARY_PATH))
	if not parsed is Array:
		return
	for value in parsed:
		if value is Dictionary:
			var path := str(value.get("path", ""))
			if not path.is_empty() and FileAccess.file_exists(path):
				var fingerprint := str(value.get("hash", ""))
				if fingerprint.is_empty():
					fingerprint = FileAccess.get_md5(path)
				table_media_library.append({"name": str(value.get("name", path.get_file())), "path": path, "hash": fingerprint})
				if table_media_library.size() >= MAX_TABLE_MEDIA_ITEMS:
					break

func _save_table_media_library() -> void:
	var file := FileAccess.open(TABLE_MEDIA_LIBRARY_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(table_media_library, "  "))

func _refresh_table_media_library(preferred_path := "") -> void:
	if table_media_list == null:
		return
	if preferred_path.is_empty() and not table_media_list.get_selected_items().is_empty():
		var previous: Variant = table_media_list.get_item_metadata(table_media_list.get_selected_items()[0])
		if previous is Dictionary:
			preferred_path = str(previous.get("path", "builtin:" + str(previous.get("builtin", ""))))
	var query := table_media_search.text.strip_edges().to_lower() if table_media_search != null else ""
	table_media_list.clear()
	for effect_name in ["Fuego", "Hielo", "Magia", "Oscuridad", "Curación"]:
		if not query.is_empty() and not effect_name.to_lower().contains(query):
			continue
		var index := table_media_list.add_item("◆  %s  ·  incluido" % effect_name)
		table_media_list.set_item_metadata(index, {"builtin": effect_name})
	for entry in table_media_library:
		if not query.is_empty() and not str(entry.get("name", "")).to_lower().contains(query):
			continue
		var index := table_media_list.add_item("▶  %s" % str(entry.get("name", "Animación")))
		table_media_list.set_item_metadata(index, entry)
	if table_media_list.item_count > 0:
		var selection := 0
		for index in range(table_media_list.item_count):
			var data: Variant = table_media_list.get_item_metadata(index)
			if data is Dictionary:
				var identity := str(data.get("path", "builtin:" + str(data.get("builtin", ""))))
				if identity == preferred_path:
					selection = index
					break
		table_media_list.select(selection)
	table_media_list.tooltip_text = "%d/%d animaciones personalizadas guardadas" % [table_media_library.size(), MAX_TABLE_MEDIA_ITEMS]
	if table_media_count_label != null:
		var total_bytes: int = 0
		for entry in table_media_library:
			var media_file := FileAccess.open(str(entry.get("path", "")), FileAccess.READ)
			if media_file != null:
				total_bytes += media_file.get_length()
		table_media_count_label.text = "%d / %d ARCHIVOS  ·  %s" % [table_media_library.size(), MAX_TABLE_MEDIA_ITEMS, _format_file_size(total_bytes)]
	_update_table_media_preview()

func _format_file_size(byte_count: int) -> String:
	if byte_count < 1024:
		return "%d B" % byte_count
	if byte_count < 1024 * 1024:
		return "%.1f KB" % (float(byte_count) / 1024.0)
	return "%.1f MB" % (float(byte_count) / (1024.0 * 1024.0))

func _update_table_media_preview() -> void:
	_stop_table_media_preview()
	table_media_preview_texture = null
	table_media_preview_frame = 0
	table_media_preview_elapsed = 0.0
	if table_media_preview != null:
		table_media_preview.texture = null
		table_media_preview.show()
		table_media_preview.tooltip_text = "Selecciona una animación"
	if table_media_name_edit != null:
		table_media_name_edit.text = ""
		table_media_name_edit.editable = false
	if table_media_list == null or table_media_list.get_selected_items().is_empty():
		return
	var data: Variant = table_media_list.get_item_metadata(table_media_list.get_selected_items()[0])
	if not data is Dictionary:
		return
	if data.has("builtin"):
		if table_media_name_edit != null:
			table_media_name_edit.text = str(data.builtin) + " · efecto incluido"
		if table_media_preview != null:
			table_media_preview.tooltip_text = "Efecto de color incluido: %s" % str(data.builtin)
		return
	var path := str(data.get("path", ""))
	if table_media_name_edit != null:
		table_media_name_edit.text = str(data.get("name", path.get_file().get_basename()))
		table_media_name_edit.editable = true
	if table_media_preview != null:
		table_media_preview.tooltip_text = "Vista previa animada" if path.get_extension().to_lower() == "gif" else "Los vídeos OGV se previsualizan al reproducirlos en la mesa"
	if path.get_extension().to_lower() == "gif":
		table_media_preview_texture = GIF_PLAYBACK_SCRIPT.load_texture(path)
		if table_media_preview != null:
			table_media_preview.texture = table_media_preview_texture
	elif path.get_extension().to_lower() == "ogv" and FileAccess.file_exists(path) and table_media_video_preview != null:
		var stream := VideoStreamTheora.new()
		stream.file = path
		table_media_video_preview.stream = stream
		table_media_video_preview.show()
		if table_media_preview != null:
			table_media_preview.hide()
		table_media_video_preview.play()

func _stop_table_media_preview() -> void:
	if table_media_video_preview != null:
		table_media_video_preview.stop()
		table_media_video_preview.stream = null
		table_media_video_preview.hide()

func _restart_table_media_video_preview() -> void:
	if table_media_popup != null and table_media_popup.visible and table_media_video_preview != null and table_media_video_preview.stream != null:
		table_media_video_preview.play()

func _rename_selected_table_media() -> void:
	if table_media_list == null or table_media_name_edit == null or table_media_list.get_selected_items().is_empty():
		return
	var data: Variant = table_media_list.get_item_metadata(table_media_list.get_selected_items()[0])
	if not data is Dictionary or data.has("builtin"):
		_set_status("Los efectos incluidos conservan su nombre original.", true)
		return
	var new_name := table_media_name_edit.text.strip_edges().left(60)
	if new_name.is_empty():
		_set_status("Escribe un nombre para la animación.", true)
		return
	var path := str(data.get("path", ""))
	for index in range(table_media_library.size()):
		if str(table_media_library[index].get("path", "")) == path:
			table_media_library[index]["name"] = new_name
			break
	_save_table_media_library()
	_refresh_table_media_library(path)
	_set_status("Animación renombrada como %s." % new_name)

func _play_selected_table_media() -> void:
	if table_media_list == null or table_media_list.get_selected_items().is_empty():
		_set_status("Selecciona una animación de la biblioteca.", true)
		return
	var index := table_media_list.get_selected_items()[0]
	var data: Variant = table_media_list.get_item_metadata(index)
	if not data is Dictionary:
		return
	if data.has("builtin"):
		_play_table_effect(str(data.builtin))
		return
	current_table_media_path = str(data.get("path", ""))
	_play_uploaded_table_media()

func _remove_selected_table_media() -> void:
	if table_media_list == null or table_media_list.get_selected_items().is_empty():
		return
	var data: Variant = table_media_list.get_item_metadata(table_media_list.get_selected_items()[0])
	if not data is Dictionary or data.has("builtin"):
		_set_status("Los cinco efectos incluidos no se pueden eliminar.", true)
		return
	pending_table_media_delete_path = str(data.get("path", ""))
	var display_name := str(data.get("name", pending_table_media_delete_path.get_file().get_basename()))
	table_media_delete_dialog.dialog_text = "¿Quitar «%s» de la biblioteca?\n\nLa copia original no se borrará." % display_name
	_popup_centered_safe(table_media_delete_dialog, Vector2i(420, 190))

func _confirm_remove_table_media() -> void:
	var path := pending_table_media_delete_path
	pending_table_media_delete_path = ""
	if path.is_empty():
		return
	for index in range(table_media_library.size() - 1, -1, -1):
		if str(table_media_library[index].get("path", "")) == path:
			table_media_library.remove_at(index)
			break
	if current_table_media_path == path:
		_stop_uploaded_table_media()
		current_table_media_path = ""
	# Solo se borra la copia administrada dentro de user://; nunca el original
	# que el usuario eligió desde Descargas, Drive u otra aplicación Android.
	var absolute_path := ProjectSettings.globalize_path(path)
	var library_root := ProjectSettings.globalize_path(TABLE_MEDIA_LIBRARY_DIR)
	if absolute_path.begins_with(library_root + "/") or absolute_path.begins_with(library_root + "\\"):
		DirAccess.remove_absolute(absolute_path)
	_save_table_media_library()
	_refresh_table_media_library()
	_set_status("Animación quitada de la biblioteca. El archivo original no se modificó.")

func _on_table_transfer_progress(label: String, percent: float) -> void:
	if transfer_progress_bar == null or transfer_progress_label == null:
		return
	transfer_progress_label.text = label
	transfer_progress_bar.value = clampf(percent, 0.0, 100.0)
	transfer_progress_label.show()
	transfer_progress_bar.show()
	transfer_cancel_button.show()
	if percent >= 100.0:
		_set_status("Transferencia completada: %s" % label)
		transfer_cancel_button.hide()

func _cancel_table_transfers() -> void:
	if table_board != null:
		table_board.cancel_transfers()
	transfer_progress_label.hide()
	transfer_progress_bar.hide()
	transfer_cancel_button.hide()
	_set_status("Transferencia cancelada.")

func _on_table_transfer_failed(message: String) -> void:
	if transfer_progress_label != null:
		transfer_progress_label.hide()
		transfer_progress_bar.hide()
		transfer_cancel_button.hide()
	_set_status(message, true)

func _on_table_map_scale_changed(value: float) -> void:
	if map_scale_label != null:
		map_scale_label.text = "Escala del mapa: %d%%" % int(value * 100.0)
	if table_board == null or not _is_table_director():
		return
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		table_board.share_map_scale(value)

func _set_table_media(path: String) -> void:
	var extension := path.get_extension().to_lower()
	if extension not in ["gif", "ogv"]:
		_set_status("Formato no compatible. Usa GIF o vídeo Ogg Theora (.ogv).", true)
		return
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		_set_status("No se pudo leer la animación seleccionada.", true)
		return
	if bytes.size() > 50 * 1024 * 1024:
		_set_status("La animación supera 50 MB. Usa un archivo más pequeño.", true)
		return
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_MD5)
	hash_context.update(bytes)
	var fingerprint := hash_context.finish().hex_encode()
	for entry in table_media_library:
		if str(entry.get("hash", "")) == fingerprint:
			var existing_path := str(entry.get("path", ""))
			if table_media_search != null:
				table_media_search.text = ""
			_refresh_table_media_library(existing_path)
			_set_status("Ese archivo ya estaba guardado en la biblioteca.")
			return
	if table_media_library.size() >= MAX_TABLE_MEDIA_ITEMS:
		_set_status("La biblioteca ya tiene 30 animaciones. Quita una antes de añadir otra.", true)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TABLE_MEDIA_LIBRARY_DIR))
	var original_name := path.get_file()
	var stored_name := "%d_%s" % [Time.get_ticks_msec(), original_name.validate_filename()]
	var stored_path := TABLE_MEDIA_LIBRARY_DIR.path_join(stored_name)
	var stored_file := FileAccess.open(stored_path, FileAccess.WRITE)
	if stored_file == null:
		_set_status("No se pudo guardar la animación en la biblioteca.", true)
		return
	stored_file.store_buffer(bytes)
	stored_file.close()
	table_media_library.append({"name": original_name.get_basename(), "path": stored_path, "hash": fingerprint})
	current_table_media_path = stored_path
	_save_table_media_library()
	if table_media_search != null:
		table_media_search.text = ""
	_refresh_table_media_library(stored_path)
	_set_status("Animación guardada (%d/%d). Pulsa Reproducir para mostrarla." % [table_media_library.size(), MAX_TABLE_MEDIA_ITEMS])

func _play_uploaded_table_media() -> void:
	if not _is_table_director():
		_set_status("Solo el director puede reproducir escenas para toda la mesa.", true)
		return
	if current_table_media_path.is_empty() or not FileAccess.file_exists(current_table_media_path):
		_set_status("Primero selecciona un GIF o vídeo Ogg Theora (.ogv).", true)
		return
	if table_board.share_table_media(current_table_media_path):
		table_media_playing = true
		_set_status("Escena animada reproduciéndose y compartida con la mesa online.")
	else:
		_set_status("No se pudo reproducir el archivo. Usa GIF o vídeo Ogg Theora (.ogv).", true)

func _stop_uploaded_table_media() -> void:
	if not _is_table_director():
		_set_status("Solo el director puede detener escenas compartidas.", true)
		return
	table_media_playing = false
	if table_board != null:
		table_board.stop_and_share_table_media()
	_set_status("Escena animada detenida para toda la mesa.")

func _play_table_effect(effect_name: String) -> void:
	if not _is_table_director():
		_set_status("Solo el director puede activar efectos globales.", true)
		return
	# El efecto sustituye cualquier GIF/vídeo anterior. Así, un jugador que se
	# conecte durante el destello no recibirá por error el archivo anterior.
	table_media_playing = false
	table_board.play_builtin_effect(effect_name)
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		table_board.sync_builtin_effect.rpc(effect_name)
	_set_status("Efecto %s reproducido para la mesa." % effect_name)

func _choose_map_image() -> void:
	_show_external_file_dialog(map_image_dialog)

func _set_map_image(path: String) -> void:
	map_library_view.import_map(path)

func _map_library_panel() -> Control:
	map_library_view = MAP_LIBRARY_SCENE.instantiate()
	map_library_view.setup(table_board)
	map_library_view.add_map_requested.connect(_choose_map_image)
	map_library_view.status_requested.connect(_set_status)
	map_library_view.state_changed.connect(_on_map_library_state_changed)
	return map_library_view

func _show_map_library() -> void:
	if not _toggle_floating_window(map_library_popup, Vector2i(560, 540), "Biblioteca de mapas"):
		return
	map_library_view.refresh_library()

func _clear_current_map() -> void:
	map_library_view.clear_current_map()

func _on_map_library_state_changed() -> void:
	map_library_popup.hide()
	_save_table_state()
	if _is_table_director():
		var peer := multiplayer.multiplayer_peer
		if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			table_board.share_current_map()

func _set_token_image(path: String) -> void:
	var stored_path := _store_portrait(path)
	if not stored_path.is_empty() and table_board.set_selected_image(stored_path):
		_remember_portrait(stored_path)
		_set_status("Retrato asignado a la ficha.")
	else:
		_set_status("No se pudo cargar la imagen seleccionada.", true)

func _store_portrait(source_path: String) -> String:
	if source_path.begins_with("user://portrait_gallery/"):
		return source_path
	var bytes := FileAccess.get_file_as_bytes(source_path)
	if bytes.is_empty():
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://portrait_gallery"))
	var fingerprint := FileAccess.get_md5(source_path).left(12)
	var safe_name := source_path.get_file().validate_filename()
	var target := "user://portrait_gallery/%s_%s" % [fingerprint, safe_name]
	if not FileAccess.file_exists(target):
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			return ""
		file.store_buffer(bytes)
		file.close()
	return target

func _remember_portrait(path: String) -> void:
	portrait_gallery.erase(path)
	portrait_gallery.push_front(path)
	while portrait_gallery.size() > 5:
		portrait_gallery.pop_back()
	_refresh_portrait_gallery()
	_save_table_state()

func _refresh_portrait_gallery() -> void:
	if portrait_gallery_box == null:
		return
	for child in portrait_gallery_box.get_children():
		child.queue_free()
	var added := 0
	for path in portrait_gallery:
		if not FileAccess.file_exists(path):
			continue
		var button := TextureButton.new()
		button.custom_minimum_size = Vector2(24, 34)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.tooltip_text = "Usar " + path.get_file()
		button.texture_normal = _portrait_preview_texture(path)
		button.pressed.connect(_use_recent_portrait.bind(path))
		portrait_gallery_box.add_child(button)
		added += 1
	if added == 0:
		var empty := Label.new()
		empty.text = "Sube una imagen"
		empty.add_theme_font_size_override("font_size", 10)
		empty.add_theme_color_override("font_color", MUTED)
		portrait_gallery_box.add_child(empty)

func _portrait_preview_texture(path: String) -> Texture2D:
	if path.get_extension().to_lower() == "gif":
		if not ClassDB.class_exists(&"GIFTexture"):
			return null
		return ClassDB.class_call_static(&"GIFTexture", &"load_from_file", path) as Texture2D
	var image := Image.new()
	if image.load(path) != OK:
		return null
	image.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func _use_recent_portrait(path: String) -> void:
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona primero una ficha de la mesa.", true)
		return
	if table_board.set_selected_image(path):
		_remember_portrait(path)
		_set_status("Retrato reciente aplicado.")
	else:
		_set_status("La imagen reciente ya no está disponible.", true)

func _save_table_state(sync_tokens := true) -> void:
	if table_board == null or loading_table_state or (map_library_view != null and map_library_view.loading_map):
		return
	if map_library_view != null:
		map_library_view.save_current_state()
	var saved_map_id: String = str(map_library_view.current_map_id) if map_library_view != null else ""
	var initiative_state: Dictionary = initiative_view.call("export_state") if initiative_view != null else {}
	var serialized := JSON.stringify({"tokens": table_board.export_tokens(), "map_path": table_board.map_path, "map_scale": table_board.map_scale, "current_map_id": saved_map_id, "chat_messages": chat_messages, "portrait_gallery": portrait_gallery, "initiative": initiative_state, "fog": table_board.export_fog(), "locks": table_board.export_locks(), "drawings": table_board.export_drawings()}, "  ")
	var file := FileAccess.open(TABLE_TEMP_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(serialized)
		file.flush()
		file.close()
		_commit_table_save()
	var peer := multiplayer.multiplayer_peer
	if sync_tokens and peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		table_board.sync_tokens.rpc(table_board.export_tokens())

func _on_initiative_status_effects_changed(token_index: int, effects: Array[String]) -> void:
	if table_board == null or not _is_table_director():
		return
	table_board.set_token_status_effects(token_index, effects)
	if table_board.selected_token == token_index:
		_refresh_token_status_list()
	_refresh_chat_health()

func _on_initiative_hit_points_changed(token_index: int, current: float, maximum: float) -> void:
	if table_board == null or not _is_table_director():
		return
	table_board.set_token_hit_points(token_index, current, maximum)
	var tokens: Array = table_board.export_tokens()
	if token_index < 0 or token_index >= tokens.size():
		return
	var sheet_file := str(tokens[token_index].get("sheet_file", ""))
	if sheet_file.is_empty():
		_refresh_chat_health()
		return
	var path := SHEETS_DIR + "/" + sheet_file
	if not FileAccess.file_exists(path):
		_refresh_chat_health()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return
	var saved_fields: Dictionary = parsed.get("fields", {})
	var is_monster := str(parsed.get("metadata", {}).get("type", "Personaje")) == "Monstruo"
	var current_key := "monster_hp_current" if is_monster else "hp_current"
	var maximum_key := "monster_hp_max" if is_monster else "hp_max"
	saved_fields[current_key] = str(int(current))
	saved_fields[maximum_key] = str(int(maximum))
	parsed["fields"] = saved_fields
	if not _write_sheet_file(sheet_file, parsed):
		_set_status("No se pudo actualizar la vida de la hoja vinculada.", true)
		return
	if current_sheet_file == sheet_file and fields.has(current_key) and fields.has(maximum_key):
		fields[current_key].text = str(int(current))
		fields[maximum_key].text = str(int(maximum))
		_update_hp()
		_update_monster_hp()
	if multiplayer.is_server():
		table_board.share_sheet_to_all(sheet_file)
	_refresh_chat_health()

func _setup_table_backups_window() -> void:
	if table_backups_window != null:
		return
	table_backups_window = Window.new()
	table_backups_window.borderless = false
	add_child(table_backups_window)
	table_backups_window.hide()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, GOLD.darkened(0.4), 1, 18))
	table_backups_window.add_child(panel)
	var body := VBoxContainer.new()
	panel.add_child(body)
	var title := Label.new()
	title.text = "RESPALDOS DE LA MESA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	var hint := Label.new()
	hint.text = "Se conservan las 10 versiones más recientes. Restaurar no elimina las demás."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)
	table_backups_list = ItemList.new()
	table_backups_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_backups_list.custom_minimum_size.y = 280
	body.add_child(table_backups_list)
	var buttons := HBoxContainer.new()
	body.add_child(buttons)
	var create_button := Button.new()
	create_button.text = "CREAR AHORA"
	create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_button.pressed.connect(_create_manual_table_backup)
	buttons.add_child(create_button)
	var restore_button := Button.new()
	restore_button.text = "RESTAURAR"
	restore_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_button.pressed.connect(_restore_selected_table_backup)
	buttons.add_child(restore_button)

func _show_table_backups() -> void:
	if not _is_table_director():
		_set_status("Solo el director puede restaurar la mesa.", true)
		return
	if not _toggle_floating_window(table_backups_window, Vector2i(560, 470), "Respaldos de la mesa"):
		return
	_refresh_table_backups_list()

func _refresh_table_backups_list() -> void:
	if table_backups_list == null:
		return
	table_backups_list.clear()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(TABLE_BACKUP_DIR)):
		table_backups_list.add_item("Todavía no hay respaldos")
		table_backups_list.set_item_disabled(0, true)
		return
	var files: Array[String] = []
	for filename in DirAccess.get_files_at(TABLE_BACKUP_DIR):
		if filename.ends_with(".json"):
			files.append(filename)
	files.sort()
	files.reverse()
	if files.is_empty():
		table_backups_list.add_item("Todavía no hay respaldos")
		table_backups_list.set_item_disabled(0, true)
		return
	for filename in files:
		var path := TABLE_BACKUP_DIR + "/" + filename
		var modified := int(FileAccess.get_modified_time(path))
		var label := Time.get_datetime_string_from_unix_time(modified, true).replace("T", "  ")
		table_backups_list.add_item(label)
		table_backups_list.set_item_metadata(table_backups_list.item_count - 1, path)

func _create_manual_table_backup() -> void:
	_save_table_state()
	last_table_backup_time = 0
	_create_table_backup_if_due()
	_refresh_table_backups_list()
	_set_status("Respaldo manual creado.")

func _restore_selected_table_backup() -> void:
	var selected: PackedInt32Array = table_backups_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona primero un respaldo.", true)
		return
	var path: String = str(table_backups_list.get_item_metadata(selected[0]))
	var parser := JSON.new()
	if not FileAccess.file_exists(path) or parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		_set_status("El respaldo seleccionado no es válido.", true)
		return
	# Antes de restaurar se conserva una copia del estado actual para poder volver atrás.
	last_table_backup_time = 0
	_create_table_backup_if_due()
	var temp := FileAccess.open(TABLE_TEMP_PATH, FileAccess.WRITE)
	if temp == null:
		_set_status("No se pudo preparar la restauración.", true)
		return
	temp.store_string(JSON.stringify(parser.data, "  "))
	temp.close()
	_commit_table_save()
	_load_table_state()
	var peer := multiplayer.multiplayer_peer
	if peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		table_board.share_current_map()
		table_board.sync_tokens.rpc(table_board.export_tokens())
		table_board.sync_fog.rpc(table_board.export_fog())
		table_board.sync_locks.rpc(table_board.export_locks())
		table_board.sync_drawings.rpc(table_board.export_drawings())
		if initiative_view != null:
			_sync_initiative_state.rpc(initiative_view.call("export_state"))
	table_backups_window.hide()
	_set_status("Mesa restaurada desde el respaldo seleccionado.")

func _load_table_state() -> void:
	if table_board == null:
		return
	var recovered: Dictionary = _read_table_state_with_recovery()
	var data: Variant = recovered.get("data", {})
	if data is Dictionary and data.get("tokens", []) is Array:
		if bool(recovered.get("backup", false)):
			_set_status("La sesión principal estaba dañada; se recuperó el respaldo más reciente.", true)
		loading_table_state = true
		if map_library_view != null:
			map_library_view.restore_current_map_id(str(data.get("current_map_id", "")))
		table_board.import_tokens(data.get("tokens", []))
		if data.get("fog", {}) is Dictionary:
			table_board.import_fog(data.get("fog", {}))
		if data.get("drawings", []) is Array:
			table_board.import_drawings(data.get("drawings", []))
		portrait_gallery.clear()
		for saved_portrait in data.get("portrait_gallery", []):
			var portrait_path := str(saved_portrait)
			if not portrait_path.is_empty() and FileAccess.file_exists(portrait_path):
				portrait_gallery.append(portrait_path)
		_refresh_portrait_gallery()
		if data.get("chat_messages", []) is Array:
			chat_messages.assign(data.get("chat_messages", []))
			_refresh_chat()
		if initiative_view != null and data.get("initiative", {}) is Dictionary:
			loading_initiative_state = true
			initiative_view.call("import_state", data.get("initiative", {}))
			loading_initiative_state = false
		var saved_map_path := str(data.get("map_path", ""))
		if not saved_map_path.is_empty() and table_board.load_map(saved_map_path):
			table_board.set_map_scale(float(data.get("map_scale", 1.0)))
		if data.get("locks", {}) is Dictionary:
			table_board.import_locks(data.get("locks", {}))
		loading_table_state = false
		table_board.clear_history()

func _commit_table_save() -> void:
	var temporary_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE_TEMP_PATH))
	if not temporary_data is Dictionary:
		return
	_create_table_backup_if_due()
	var save_absolute := ProjectSettings.globalize_path(TABLE_SAVE_PATH)
	var temp_absolute := ProjectSettings.globalize_path(TABLE_TEMP_PATH)
	var previous_absolute := ProjectSettings.globalize_path(TABLE_PREVIOUS_PATH)
	if FileAccess.file_exists(TABLE_PREVIOUS_PATH):
		DirAccess.remove_absolute(previous_absolute)
	var had_previous := FileAccess.file_exists(TABLE_SAVE_PATH)
	if had_previous and DirAccess.rename_absolute(save_absolute, previous_absolute) != OK:
		return
	var commit_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if commit_error != OK:
		if had_previous and FileAccess.file_exists(TABLE_PREVIOUS_PATH):
			DirAccess.rename_absolute(previous_absolute, save_absolute)
		return
	if FileAccess.file_exists(TABLE_PREVIOUS_PATH):
		DirAccess.remove_absolute(previous_absolute)

func _create_table_backup_if_due() -> void:
	if not FileAccess.file_exists(TABLE_SAVE_PATH):
		return
	var now := int(Time.get_unix_time_from_system())
	if last_table_backup_time > 0 and now - last_table_backup_time < TABLE_BACKUP_INTERVAL_SECONDS:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TABLE_BACKUP_DIR))
	var backup_path := TABLE_BACKUP_DIR + "/table_%d_%d.json" % [now, Time.get_ticks_msec() % 100000]
	if DirAccess.copy_absolute(ProjectSettings.globalize_path(TABLE_SAVE_PATH), ProjectSettings.globalize_path(backup_path)) == OK:
		last_table_backup_time = now
	_prune_table_backups()

func _prune_table_backups() -> void:
	var files: Array[String] = []
	for filename in DirAccess.get_files_at(TABLE_BACKUP_DIR):
		if filename.ends_with(".json"):
			files.append(filename)
	files.sort()
	while files.size() > MAX_TABLE_BACKUPS:
		var oldest: String = files.pop_front()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TABLE_BACKUP_DIR + "/" + oldest))

func _read_table_state_with_recovery() -> Dictionary:
	var candidates: Array[String] = [TABLE_SAVE_PATH, TABLE_PREVIOUS_PATH]
	var backups: Array[String] = []
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(TABLE_BACKUP_DIR)):
		for filename in DirAccess.get_files_at(TABLE_BACKUP_DIR):
			if filename.ends_with(".json"):
				backups.append(filename)
	backups.sort()
	backups.reverse()
	for filename in backups:
		candidates.append(TABLE_BACKUP_DIR + "/" + filename)
	for index in range(candidates.size()):
		var path: String = candidates[index]
		if not FileAccess.file_exists(path):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK:
			continue
		var parsed: Variant = parser.data
		if parsed is Dictionary and parsed.get("tokens", []) is Array:
			return {"data": parsed, "backup": index > 0}
	return {}

func _open_token_sheet(_token_index: int) -> void:
	if token_sheet_popup.visible:
		token_sheet_popup.hide()
		return
	var filename: String = table_board.get_selected_sheet()
	if filename.is_empty():
		_set_status("Esta ficha no tiene hoja. Selecciona una en la biblioteca y pulsa ‘Asignar a ficha’.", true)
		_show_sheets_manager()
		return
	current_sheet_file = filename
	load_sheet()
	_build_token_sheet_window()
	_toggle_floating_window(token_sheet_popup, Vector2i(800, 720), "Hoja de personaje")

func _build_token_sheet_window() -> void:
	for child in token_sheet_popup.get_children():
		child.queue_free()
	var panel: PanelContainer = TOKEN_SHEET_WINDOW_SCENE.instantiate()
	panel.add_theme_stylebox_override("panel", _box(palette.panel, 12, palette.accent, 1, 22))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var is_monster: bool = _selected_sheet_type() == "Monstruo"
	var title := Label.new()
	var title_field: LineEdit = fields.monster_name if is_monster else fields.name
	title.text = ("☠  " if is_monster else "◆  ") + (title_field.text if not title_field.text.is_empty() else ("MONSTRUO" if is_monster else "HOJA DE PERSONAJE"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", palette.accent)
	body.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	body.add_child(grid)
	var popup_fields := [
		["Nombre", "monster_name"], ["Descripción", "monster_description"], ["Clase de armadura", "monster_ac"],
		["Velocidad", "monster_speed"], ["PV actuales", "monster_hp_current"], ["PV máximos", "monster_hp_max"]
	] if is_monster else [
		["Nombre", "name"], ["Linaje", "ancestry"], ["Clase / Oficio", "class"], ["Trasfondo", "background"],
		["Nivel", "level"], ["EXP", "experience"], ["PV actuales", "hp_current"], ["PV máximos", "hp_max"]
	]
	for d in popup_fields:
		var holder := VBoxContainer.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = d[0].to_upper()
		holder.add_child(label)
		var edit := LineEdit.new()
		edit.text = fields[d[1]].text
		edit.editable = d[1] != "level"
		edit.text_changed.connect(_update_popup_line_field.bind(str(d[1])))
		holder.add_child(edit)
		grid.add_child(holder)
	if is_monster:
		var extra_grid := GridContainer.new()
		extra_grid.columns = 2
		body.add_child(extra_grid)
		for definition in [["Dados de golpe", "monster_hit_dice"], ["Iniciativa", "monster_initiative"], ["Salvaciones", "monster_saves"], ["Habilidades", "monster_skills"], ["Vulnerabilidades", "monster_vulnerabilities"], ["Resistencias", "monster_resistances"], ["Inmunidades al daño", "monster_immunities"], ["Inmunidades a estados", "monster_condition_immunities"], ["Sentidos", "monster_senses"], ["Idiomas", "monster_languages"], ["Desafío", "monster_challenge"], ["Competencia", "monster_proficiency"]]:
			var holder := VBoxContainer.new()
			holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var label := Label.new()
			label.text = str(definition[0]).to_upper()
			holder.add_child(label)
			var edit := LineEdit.new()
			edit.text = fields[definition[1]].text
			edit.text_changed.connect(_update_popup_line_field.bind(str(definition[1])))
			holder.add_child(edit)
			extra_grid.add_child(holder)
		var stats_title := Label.new()
		stats_title.text = "ATRIBUTOS"
		stats_title.add_theme_color_override("font_color", palette.accent)
		body.add_child(stats_title)
		var stats_grid := GridContainer.new()
		stats_grid.columns = 3
		body.add_child(stats_grid)
		for definition in [["FUE", "monster_str"], ["DES", "monster_dex"], ["CON", "monster_con"], ["INT", "monster_int"], ["SAB", "monster_wis"], ["CAR", "monster_cha"]]:
			var holder := VBoxContainer.new()
			var label := Label.new()
			label.text = definition[0]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			holder.add_child(label)
			var spin := SpinBox.new()
			spin.min_value = 1
			spin.max_value = 1_000_000_000
			spin.allow_greater = true
			spin.value = fields[definition[1]].value
			spin.value_changed.connect(_update_popup_spin_field.bind(str(definition[1])))
			holder.add_child(spin)
			stats_grid.add_child(holder)
		for definition in [["RASGOS", "monster_traits", 120], ["ACCIONES", "monster_actions", 170], ["REACCIONES", "monster_reactions", 110], ["ACCIONES LEGENDARIAS", "monster_legendary_actions", 110], ["LORE", "monster_lore", 180]]:
			var label := Label.new()
			label.text = definition[0]
			label.add_theme_color_override("font_color", palette.accent)
			body.add_child(label)
			var edit := TextEdit.new()
			edit.text = fields[definition[1]].text
			edit.custom_minimum_size.y = int(definition[2])
			edit.text_changed.connect(_update_popup_text_field.bind(edit, str(definition[1])))
			body.add_child(edit)
	var mechanics_title := Label.new()
	mechanics_title.text = "MECÁNICAS Y PUNTOS"
	mechanics_title.add_theme_font_size_override("font_size", 17)
	mechanics_title.add_theme_color_override("font_color", palette.accent)
	body.add_child(mechanics_title)
	var popup_mechanics := VBoxContainer.new()
	popup_mechanics.add_theme_constant_override("separation", 8)
	body.add_child(popup_mechanics)
	if mechanic_count == 0:
		var empty_label := Label.new()
		empty_label.text = "Esta hoja todavía no tiene contadores personalizados."
		empty_label.add_theme_color_override("font_color", MUTED)
		popup_mechanics.add_child(empty_label)
	else:
		for index in range(mechanic_count):
			popup_mechanics.add_child(_popup_mechanic_row(index))
	if not is_monster:
		var notes := TextEdit.new()
		notes.placeholder_text = "Notas rápidas de la ficha…"
		notes.text = fields.notas.text
		notes.custom_minimum_size.y = 130
		notes.text_changed.connect(_update_popup_text_field.bind(notes, "notas"))
		body.add_child(notes)
	var buttons := HBoxContainer.new()
	body.add_child(buttons)
	var full_button := Button.new()
	full_button.text = "Abrir hoja completa"
	full_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_button.pressed.connect(func(): token_sheet_popup.hide(); _show_page(0))
	buttons.add_child(full_button)
	var save_button := Button.new()
	save_button.text = "Guardar cambios"
	save_button.pressed.connect(save_sheet)
	buttons.add_child(save_button)
	token_sheet_popup.add_child(panel)

func _update_popup_line_field(value: String, key: String) -> void:
	if fields.has(key) and fields[key] is LineEdit:
		fields[key].text = value

func _update_popup_spin_field(value: float, key: String) -> void:
	if fields.has(key) and fields[key] is SpinBox:
		fields[key].value = value

func _update_popup_text_field(edit: TextEdit, key: String) -> void:
	if fields.has(key) and fields[key] is TextEdit:
		fields[key].text = edit.text

func _popup_mechanic_row(index: int) -> Control:
	var row := HBoxContainer.new()
	var name_key := "mechanic_%d_name" % index
	var value_key := "mechanic_%d_value" % index
	var max_key := "mechanic_%d_max" % index
	var positive_key := "mechanic_%d_positive" % index
	var negative_key := "mechanic_%d_negative" % index
	var name := LineEdit.new()
	name.text = fields[name_key].text
	name.placeholder_text = "Nombre de la mecánica"
	name.custom_minimum_size.x = 150
	name.text_changed.connect(func(text: String): fields[name_key].text = text)
	row.add_child(name)
	var value := SpinBox.new()
	value.min_value = -999
	value.max_value = 999
	value.value = fields[value_key].value
	value.custom_minimum_size.x = 82
	row.add_child(value)
	var maximum := SpinBox.new()
	maximum.min_value = 1
	maximum.max_value = 100
	maximum.value = fields[max_key].value
	maximum.custom_minimum_size.x = 72
	row.add_child(maximum)
	var positive := ColorPickerButton.new()
	positive.color = fields[positive_key].color
	positive.tooltip_text = "Color positivo"
	row.add_child(positive)
	var negative := ColorPickerButton.new()
	negative.color = fields[negative_key].color
	negative.tooltip_text = "Color negativo"
	row.add_child(negative)
	var track_script: Script = load("res://PointTrack.gd")
	var track: Control = track_script.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(track)
	value.value_changed.connect(func(_number: float): _sync_popup_mechanic(index, track, value, maximum, positive, negative))
	maximum.value_changed.connect(func(_number: float): _sync_popup_mechanic(index, track, value, maximum, positive, negative))
	positive.color_changed.connect(func(_color: Color): _sync_popup_mechanic(index, track, value, maximum, positive, negative))
	negative.color_changed.connect(func(_color: Color): _sync_popup_mechanic(index, track, value, maximum, positive, negative))
	_sync_popup_mechanic(index, track, value, maximum, positive, negative)
	return row

func _sync_popup_mechanic(index: int, track: Control, value: SpinBox, maximum: SpinBox, positive: ColorPickerButton, negative: ColorPickerButton) -> void:
	fields["mechanic_%d_value" % index].value = value.value
	fields["mechanic_%d_max" % index].value = maximum.value
	fields["mechanic_%d_positive" % index].color = positive.color
	fields["mechanic_%d_negative" % index].color = negative.color
	track.configure(int(value.value), int(maximum.value), positive.color, negative.color)

func _show_appearance() -> void:
	_toggle_floating_window(appearance_popup, Vector2i(760, 390), "Skins y colores")

func _appearance() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var skin_title := Label.new()
	skin_title.text = "SKINS PREDEFINIDOS"
	skin_title.add_theme_font_size_override("font_size", 12)
	body.add_child(skin_title)
	var skin_row := HFlowContainer.new()
	skin_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for skin_name in SKIN_PRESETS:
		var skin_button := Button.new()
		skin_button.text = str(skin_name).to_upper()
		skin_button.tooltip_text = "Aplicar el skin %s" % skin_name
		skin_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skin_button.custom_minimum_size = Vector2(180, 48)
		skin_button.pressed.connect(_apply_skin.bind(str(skin_name)))
		skin_row.add_child(skin_button)
	body.add_child(skin_row)
	var hint := Label.new()
	hint.text = "Puedes aplicar un skin y después ajustar cualquier color manualmente."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	body.add_child(hint)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	for d in [["Fondo", "background"], ["Paneles", "panel"], ["Campos", "field"], ["Acento", "accent"], ["Fuente", "text"]]:
		var holder := VBoxContainer.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.custom_minimum_size.x = 112
		var label := Label.new()
		label.text = d[0].to_upper()
		label.add_theme_font_size_override("font_size", 11)
		holder.add_child(label)
		var picker := ColorPickerButton.new()
		picker.color = palette[d[1]]
		picker.custom_minimum_size.y = 48
		picker.color_changed.connect(func(color: Color): _set_palette_color(d[1], color))
		holder.add_child(picker)
		option_fields["color_" + d[1]] = picker
		row.add_child(holder)
	body.add_child(row)
	var reset_windows := Button.new()
	reset_windows.text = "RESTABLECER VENTANAS"
	reset_windows.tooltip_text = "Olvidar posiciones y tamaños personalizados"
	reset_windows.custom_minimum_size.y = 48
	reset_windows.pressed.connect(_reset_floating_windows)
	body.add_child(reset_windows)
	var section := _section("APARIENCIA", body)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(section)
	return scroll

func _apply_skin(skin_name: String) -> void:
	if not SKIN_PRESETS.has(skin_name):
		return
	var preset: Dictionary = SKIN_PRESETS[skin_name]
	active_skin = skin_name
	applying_skin = true
	for key in palette:
		if preset.has(key):
			palette[key] = Color.from_string(str(preset[key]), palette[key])
		var picker_key := "color_" + str(key)
		if option_fields.has(picker_key) and option_fields[picker_key] is ColorPickerButton:
			option_fields[picker_key].color = palette[key]
	applying_skin = false
	if palette_apply_timer != null:
		palette_apply_timer.stop()
	pending_palette_keys.clear()
	_apply_palette()
	_save_appearance(skin_name)
	_set_status("Skin aplicado: %s." % skin_name)

func _reset_floating_windows() -> void:
	floating_window_layout.clear()
	if FileAccess.file_exists(WINDOW_LAYOUT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(WINDOW_LAYOUT_PATH))
	for window in [appearance_popup, sheets_popup, token_sheet_popup, deck_popup, chat_popup, initiative_popup, encounter_popup, campaign_popup, music_popup, online_popup, map_library_popup, table_backups_window, pdf_viewer_popup]:
		if window != null:
			window.remove_meta("opened_once")
	_set_status("Posiciones de ventanas restablecidas.")

func _sheets_manager() -> Control:
	var panel: PanelContainer = SHEETS_MANAGER_SCENE.instantiate()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 14, GOLD.darkened(0.4), 1, 22))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var heading := HBoxContainer.new()
	body.add_child(heading)
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	var title := Label.new()
	title.text = "▤  BIBLIOTECA DE HOJAS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GOLD)
	heading_text.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Crea, organiza y comparte personajes, monstruos y PNJ. Doble clic para abrir."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", MUTED)
	heading_text.add_child(subtitle)
	sheets_count_label = Label.new()
	sheets_count_label.text = "0 hojas"
	sheets_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sheets_count_label.add_theme_color_override("font_color", GOLD)
	heading.add_child(sheets_count_label)
	var editor_panel := PanelContainer.new()
	editor_panel.add_theme_stylebox_override("panel", _box(FIELD, 10, GOLD.darkened(0.58), 1, 12))
	body.add_child(editor_panel)
	var form := HFlowContainer.new()
	form.add_theme_constant_override("h_separation", 12)
	form.add_theme_constant_override("v_separation", 8)
	editor_panel.add_child(form)
	var name_holder := VBoxContainer.new()
	name_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(name_holder)
	var name_label := Label.new()
	name_label.text = "NOMBRE DE LA HOJA"
	name_holder.add_child(name_label)
	sheet_name_edit = LineEdit.new()
	sheet_name_edit.placeholder_text = "Ej.: Aria, Dragón rojo, Mercader…"
	name_holder.add_child(sheet_name_edit)
	var type_holder := VBoxContainer.new()
	form.add_child(type_holder)
	var type_label := Label.new()
	type_label.text = "TIPO"
	type_holder.add_child(type_label)
	sheet_type_option = OptionButton.new()
	for type_name in SHEET_TYPES:
		sheet_type_option.add_item(type_name)
	sheet_type_option.item_selected.connect(_on_sheet_type_selected)
	sheet_type_option.custom_minimum_size.x = 160
	type_holder.add_child(sheet_type_option)
	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 10)
	body.add_child(search_row)
	sheets_search = LineEdit.new()
	sheets_search.placeholder_text = "⌕  Buscar por nombre o tipo de hoja…"
	sheets_search.clear_button_enabled = true
	sheets_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheets_search.text_changed.connect(func(_text: String): _refresh_sheets_list())
	search_row.add_child(sheets_search)
	sheets_list = ItemList.new()
	sheets_list.custom_minimum_size.y = 300
	sheets_list.add_theme_constant_override("line_separation", 8)
	sheets_list.item_selected.connect(_select_sheet_from_list)
	sheets_list.item_activated.connect(func(_index: int): _load_selected_sheet())
	var list_panel := PanelContainer.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", _box(Color("#171619"), 10, GOLD.darkened(0.62), 1, 8))
	list_panel.add_child(sheets_list)
	body.add_child(list_panel)
	var primary_label := Label.new()
	primary_label.text = "ACCIONES DE LA HOJA"
	primary_label.add_theme_font_size_override("font_size", 10)
	primary_label.add_theme_color_override("font_color", MUTED)
	body.add_child(primary_label)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)
	body.add_child(buttons)
	for d in [["＋ Nueva", _create_new_sheet], ["✓ Guardar actual", _save_from_manager], ["↗ Abrir", _load_selected_sheet], ["× Eliminar", _delete_selected_sheet]]:
		var button := Button.new()
		button.text = d[0]
		button.custom_minimum_size.y = 40
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(d[1])
		buttons.add_child(button)
	var transfer_label := Label.new()
	transfer_label.text = "COMPARTIR Y VINCULAR"
	transfer_label.add_theme_font_size_override("font_size", 10)
	transfer_label.add_theme_color_override("font_color", MUTED)
	body.add_child(transfer_label)
	var transfer_buttons := HFlowContainer.new()
	transfer_buttons.add_theme_constant_override("h_separation", 8)
	body.add_child(transfer_buttons)
	var export_button := Button.new()
	export_button.text = "⇧ Exportar hoja"
	export_button.tooltip_text = "Guardar la hoja seleccionada en un archivo para compartir"
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.pressed.connect(_choose_sheet_export_path)
	transfer_buttons.add_child(export_button)
	var import_button := Button.new()
	import_button.text = "⇩ Importar hoja"
	import_button.tooltip_text = "Añadir a la biblioteca una hoja recibida de otro jugador"
	import_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_button.pressed.connect(_choose_sheet_import_file)
	transfer_buttons.add_child(import_button)
	var assign_button := Button.new()
	assign_button.text = "◆ Asignar a ficha seleccionada"
	assign_button.custom_minimum_size.y = 42
	assign_button.tooltip_text = "Vincular la hoja seleccionada con la ficha activa de la Mesa"
	assign_button.pressed.connect(_assign_selected_sheet_to_token)
	body.add_child(assign_button)
	return panel

func _show_sheets_manager() -> void:
	if not _toggle_floating_window(sheets_popup, Vector2i(720, 570), "Hojas guardadas"):
		return
	_refresh_sheets_list()

func _refresh_sheets_list() -> void:
	sheets_list.clear()
	var query := sheets_search.text.strip_edges().to_lower() if sheets_search != null else ""
	var visible_count := 0
	var total_count := 0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEETS_DIR))
	var migrated_path := SHEETS_DIR + "/hoja_anterior.json"
	if FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(migrated_path):
		var legacy_data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if legacy_data is Dictionary:
			legacy_data.metadata = {"name": "Hoja anterior", "type": "Personaje", "updated_at": Time.get_datetime_string_from_system()}
			var migrated_file := FileAccess.open(migrated_path, FileAccess.WRITE)
			if migrated_file != null:
				migrated_file.store_string(JSON.stringify(legacy_data, "  "))
	var directory := DirAccess.open(SHEETS_DIR)
	if directory == null:
		return
	var filenames := directory.get_files()
	filenames.sort()
	for filename in filenames:
		if not filename.ends_with(".json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_DIR + "/" + filename))
		if not data is Dictionary:
			continue
		var metadata: Dictionary = data.get("metadata", {})
		var display_name := str(metadata.get("name", filename.get_basename()))
		var type_name := str(metadata.get("type", "Personaje"))
		total_count += 1
		if not query.is_empty() and query not in (display_name + " " + type_name).to_lower():
			continue
		var type_icon := str({"Personaje": "♟", "PNJ": "●", "Monstruo": "☠", "Compañero": "◆", "Personalizada": "◇"}.get(type_name, "◇"))
		var updated := str(metadata.get("updated_at", "Sin fecha")).replace("T", " ")
		# ItemList no distribuye bien los saltos de línea en todas las plataformas.
		# Una fila compacta evita que nombre y tipo aparezcan pegados al exportar.
		var clean_name := display_name.replace("\n", " ").replace("\r", " ").strip_edges()
		var clean_type := type_name.replace("\n", " ").replace("\r", " ").strip_edges()
		var index := sheets_list.add_item("%s  %s   ·   %s" % [type_icon, clean_name, clean_type])
		sheets_list.set_item_metadata(index, filename)
		sheets_list.set_item_tooltip(index, "%s\nTipo: %s\nActualizada: %s" % [clean_name, clean_type, updated])
		visible_count += 1
	if sheets_count_label != null:
		sheets_count_label.text = "%d de %d hojas" % [visible_count, total_count]

func _select_sheet_from_list(index: int) -> void:
	var filename := str(sheets_list.get_item_metadata(index))
	var data = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_DIR + "/" + filename))
	if not data is Dictionary:
		return
	var metadata: Dictionary = data.get("metadata", {})
	sheet_name_edit.text = str(metadata.get("name", filename.get_basename()))
	var type_name := str(metadata.get("type", "Personaje"))
	for option_index in range(sheet_type_option.item_count):
		if sheet_type_option.get_item_text(option_index) == type_name:
			sheet_type_option.select(option_index)
			break
	_update_sheet_type_view()

func _create_new_sheet() -> void:
	if sheet_name_edit.text.strip_edges().is_empty():
		_set_status("Escribe un nombre para crear la hoja.", true)
		return
	current_sheet_file = "%d_%d.json" % [int(Time.get_unix_time_from_system()), randi_range(1000, 9999)]
	clear_sheet()
	_update_sheet_type_view()
	save_sheet()
	_refresh_sheets_list()
	_set_status("Nueva hoja creada: " + sheet_name_edit.text.strip_edges())

func _save_from_manager() -> void:
	if sheet_name_edit.text.strip_edges().is_empty():
		_set_status("La hoja necesita un nombre.", true)
		return
	if current_sheet_file.is_empty():
		current_sheet_file = "%d_%d.json" % [int(Time.get_unix_time_from_system()), randi_range(1000, 9999)]
	save_sheet()
	_refresh_sheets_list()

func _load_selected_sheet() -> void:
	var selected := sheets_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona una hoja de la biblioteca.", true)
		return
	current_sheet_file = str(sheets_list.get_item_metadata(selected[0]))
	load_sheet()
	sheets_popup.hide()
	_show_page(0)

func _choose_sheet_export_path() -> void:
	var selected := sheets_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona una hoja para exportarla.", true)
		return
	pending_export_sheet = str(sheets_list.get_item_metadata(selected[0]))
	var source := SHEETS_DIR + "/" + pending_export_sheet
	var portable_name := ""
	if FileAccess.file_exists(source):
		var selected_data = JSON.parse_string(FileAccess.get_file_as_string(source))
		if selected_data is Dictionary:
			var selected_metadata: Dictionary = selected_data.get("metadata", {})
			portable_name = str(selected_metadata.get("name", "")).strip_edges().validate_filename()
	if portable_name.is_empty():
		portable_name = pending_export_sheet.get_basename().validate_filename()
	if portable_name.is_empty():
		portable_name = "hoja_personaje"
	sheet_export_dialog.current_file = portable_name + ".dndsheet"
	_show_external_file_dialog(sheet_export_dialog)

func _export_sheet_to_path(destination: String) -> void:
	if pending_export_sheet.is_empty():
		_set_status("No hay una hoja preparada para exportar.", true)
		return
	var source := SHEETS_DIR + "/" + pending_export_sheet
	if not FileAccess.file_exists(source):
		pending_export_sheet = ""
		_set_status("La hoja seleccionada ya no existe.", true)
		return
	var content := FileAccess.get_file_as_string(source)
	var sheet_data = JSON.parse_string(content)
	if not (sheet_data is Dictionary) or not (sheet_data.get("fields", {}) is Dictionary):
		pending_export_sheet = ""
		_set_status("La hoja seleccionada está dañada y no se puede exportar.", true)
		return
	var final_path := destination.strip_edges()
	if final_path.is_empty():
		pending_export_sheet = ""
		_set_status("No se eligió un destino para la exportación.", true)
		return
	# No se modifica un URI del selector de Android: añadir texto al final puede
	# invalidar el permiso temporal concedido por el sistema.
	if not final_path.contains("://") and final_path.get_extension().to_lower() != "dndsheet":
		final_path += ".dndsheet"
	var export_bytes := content.to_utf8_buffer()
	# Las URI content:// de Android usan Storage Access Framework. Abrirlas en
	# WRITE_READ mantiene el descriptor concedido por el selector disponible
	# para comprobar la escritura antes de cerrarlo.
	var output_mode := FileAccess.WRITE_READ if final_path.contains("://") else FileAccess.WRITE
	var output := FileAccess.open(final_path, output_mode)
	if output == null:
		pending_export_sheet = ""
		_set_status("Android creó el destino, pero no permitió escribir la hoja. Elige otra carpeta.", true)
		return
	var write_ok := output.store_buffer(export_bytes)
	output.flush()
	var written_size := output.get_length()
	var verified := write_ok and written_size == export_bytes.size()
	if verified and final_path.contains("://"):
		output.seek(0)
		verified = output.get_buffer(export_bytes.size()) == export_bytes
	output.close()
	if not verified:
		pending_export_sheet = ""
		_set_status("La exportación quedó incompleta. Prueba otra carpeta del teléfono.", true)
		return
	pending_export_sheet = ""
	_set_status("Hoja exportada. Ya puedes enviarla a otro jugador.")

func _choose_sheet_import_file() -> void:
	if sheet_import_busy:
		return
	_show_external_file_dialog(sheet_import_dialog)

func _import_sheet_from_path(source: String) -> void:
	if sheet_import_busy:
		return
	sheet_import_busy = true
	_set_status("Importando hoja…")
	if sheet_import_loading_popup != null:
		sheet_import_loading_popup.popup_centered()
	# El selector nativo de Android necesita devolver el control a la interfaz.
	# Esperar dos fotogramas permite que el indicador aparezca antes de leer JSON.
	await get_tree().process_frame
	await get_tree().process_frame
	var source_file := FileAccess.open(source, FileAccess.READ)
	if source_file == null:
		_finish_sheet_import("No se pudo abrir la hoja recibida.", true)
		return
	if source_file.get_length() > 5 * 1024 * 1024:
		source_file.close()
		_finish_sheet_import("La hoja supera el límite permitido de 5 MB.", true)
		return
	var content := source_file.get_as_text()
	source_file.close()
	var imported = JSON.parse_string(content)
	if not (imported is Dictionary) or not (imported.get("fields", {}) is Dictionary):
		_finish_sheet_import("El archivo no contiene una hoja de personaje válida.", true)
		return
	var metadata: Dictionary = imported.get("metadata", {})
	if str(metadata.get("name", "")).strip_edges().is_empty():
		metadata.name = source.get_file().get_basename()
	metadata.imported_at = Time.get_datetime_string_from_system()
	imported.metadata = metadata
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEETS_DIR))
	var destination := SHEETS_DIR + "/importada_%d_%d.json" % [int(Time.get_unix_time_from_system()), randi_range(1000, 9999)]
	var output := FileAccess.open(destination, FileAccess.WRITE)
	if output == null:
		_finish_sheet_import("No se pudo copiar la hoja a la biblioteca.", true)
		return
	output.store_string(JSON.stringify(imported, "  "))
	output.close()
	_refresh_sheets_list()
	_finish_sheet_import("Hoja importada: " + str(metadata.name))

func _setup_sheet_import_loading_popup() -> void:
	sheet_import_loading_popup = Window.new()
	sheet_import_loading_popup.title = "Importando"
	sheet_import_loading_popup.size = Vector2i(360, 125)
	sheet_import_loading_popup.unresizable = true
	sheet_import_loading_popup.transient = true
	sheet_import_loading_popup.exclusive = true
	add_child(sheet_import_loading_popup)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _box(PANEL, 10, Color("#745a38"), 1, 18))
	sheet_import_loading_popup.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(content)
	var message := Label.new()
	message.text = "IMPORTANDO HOJA…"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", GOLD)
	content.add_child(message)
	var progress := ProgressBar.new()
	progress.indeterminate = true
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(300, 18)
	content.add_child(progress)
	sheet_import_loading_popup.close_requested.connect(func(): pass)
	sheet_import_loading_popup.hide()

func _finish_sheet_import(message: String, is_error := false) -> void:
	if sheet_import_loading_popup != null:
		sheet_import_loading_popup.hide()
	sheet_import_busy = false
	_set_status(message, is_error)

func _delete_selected_sheet() -> void:
	var selected := sheets_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona una hoja para eliminar.", true)
		return
	var filename := str(sheets_list.get_item_metadata(selected[0]))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SHEETS_DIR + "/" + filename))
	if current_sheet_file == filename:
		current_sheet_file = ""
	_refresh_sheets_list()
	_set_status("Hoja eliminada de la biblioteca.")

func _assign_selected_sheet_to_token() -> void:
	if table_board == null or table_board.selected_token < 0:
		_set_status("Selecciona primero una ficha en la Mesa.", true)
		return
	var selected := sheets_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecciona una hoja de la biblioteca.", true)
		return
	var filename := str(sheets_list.get_item_metadata(selected[0]))
	table_board.set_selected_sheet(filename)
	var snapshot := _read_sheet_snapshot(filename)
	table_board.set_selected_sheet_snapshot(str(snapshot.name), float(snapshot.current), float(snapshot.maximum))
	sheets_popup.hide()
	_set_status("Hoja vinculada. Haz doble clic sobre la ficha para abrirla.")

func _create_character_sheet_view() -> Control:
	character_sheet_view = CHARACTER_SHEET_VIEW_SCENE.instantiate()
	# Se construyen los bloques existentes dentro de la escena nueva. Así no cambia
	# ninguna clave del formato JSON y las hojas antiguas siguen siendo válidas.
	character_sheet_view.call("configure", _identity(), _stats(), _skills(), _proficiencies(), _combat(), _notes())
	character_sheet_view.call("set_palette", palette)
	columns = character_sheet_view.get("columns") as BoxContainer
	return character_sheet_view

func _create_monster_sheet_view() -> Control:
	monster_sheet_view = MONSTER_SHEET_SCENE.instantiate()
	monster_sheet_view.call("build")
	monster_sheet_view.connect("save_to_library_requested", _save_current_monster_to_library)
	monster_sheet_view.connect("share_to_table_requested", _share_current_monster_online)
	monster_sheet_view.connect("open_bestiary_requested", _open_monster_bestiary)
	monster_sheet_view.connect("send_to_chat_requested", _send_monster_block_to_chat)
	var monster_fields: Dictionary = monster_sheet_view.get("fields")
	for key in monster_fields:
		fields[key] = monster_fields[key]
	monster_sheet_view.call("set_palette", palette)
	return monster_sheet_view

func _selected_sheet_type() -> String:
	if sheet_type_option == null or sheet_type_option.item_count == 0:
		return "Personaje"
	return sheet_type_option.get_item_text(sheet_type_option.selected)

func _on_sheet_type_selected(index: int) -> void:
	if sheet_type_option != null and sheet_type_option.selected != index:
		sheet_type_option.select(index)
	if header_sheet_type_option != null and header_sheet_type_option.selected != index:
		header_sheet_type_option.select(index)
	_update_sheet_type_view()
	_set_status("Tipo de hoja: %s." % _selected_sheet_type())

func _update_sheet_type_view() -> void:
	if header_sheet_type_option != null and sheet_type_option != null and header_sheet_type_option.selected != sheet_type_option.selected:
		header_sheet_type_option.select(sheet_type_option.selected)
	var is_monster: bool = _selected_sheet_type() == "Monstruo"
	if character_sheet_content != null:
		character_sheet_content.visible = not is_monster
	if monster_sheet_content != null:
		monster_sheet_content.visible = is_monster

func _update_monster_hp() -> void:
	if monster_sheet_view != null:
		monster_sheet_view.call("refresh_health")

func _active_sheet_health() -> Vector2:
	if _selected_sheet_type() == "Monstruo":
		var current: float = float(fields.monster_hp_current.text) if fields.monster_hp_current.text.is_valid_float() else 0.0
		var maximum: float = float(fields.monster_hp_max.text) if fields.monster_hp_max.text.is_valid_float() else 1.0
		return Vector2(current, maxf(maximum, 1.0))
	var current: float = float(fields.hp_current.text) if fields.hp_current.text.is_valid_float() else 0.0
	var maximum: float = float(fields.hp_max.text) if fields.hp_max.text.is_valid_float() else 1.0
	return Vector2(current, maxf(maximum, 1.0))

func _identity() -> Control:
	var body := BoxContainer.new()
	body.vertical = false
	identity_layout = body
	body.add_theme_constant_override("separation", 20)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.9
	var name_label := Label.new()
	name_label.text = "NOMBRE"
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", MUTED)
	left.add_child(name_label)
	var character_name := LineEdit.new()
	character_name.placeholder_text = "NOMBRE DEL PERSONAJE"
	character_name.add_theme_font_size_override("font_size", 22)
	character_name.custom_minimum_size.y = 46
	fields.name = character_name
	left.add_child(character_name)
	_add_field(left, "EXP total", "experience", "0")
	fields.experience.text = "0"
	fields.experience.text_changed.connect(func(_text: String): _update_experience())
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size.y = 25
	xp_bar.show_percentage = false
	left.add_child(xp_bar)
	xp_progress_label = Label.new()
	xp_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	xp_progress_label.add_theme_font_size_override("font_size", 12)
	xp_progress_label.add_theme_color_override("font_color", MUTED)
	left.add_child(xp_progress_label)
	body.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.1
	body.add_child(right)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	for d in [["Linaje", "ancestry", "Humano, elfo…"], ["Clase / Oficio", "class", "Explorador"], ["Trasfondo", "background", "Forastero"], ["Nivel", "level", "1"]]:
		_add_field(grid, d[0], d[1], d[2])
		fields[d[1]].add_theme_font_size_override("font_size", 14)
	fields.level.text = "1"
	fields.level.editable = false
	right.add_child(grid)
	_update_experience()
	return _section("IDENTIDAD", body)

func _update_experience() -> void:
	if xp_bar == null:
		return
	var text: String = fields.experience.text.replace(",", "").strip_edges()
	var xp: int = maxi(int(text) if text.is_valid_int() else 0, 0)
	var level := 1
	while xp >= _xp_for_level(level + 1) and level < 10000:
		level += 1
	fields.level.text = str(level)
	var floor_xp := _xp_for_level(level)
	var next_xp := _xp_for_level(level + 1)
	xp_bar.value = float(xp - floor_xp) / float(next_xp - floor_xp) * 100.0
	xp_progress_label.text = "%s / %s EXP  •  Faltan %s para nivel %d" % [_format_number(xp), _format_number(next_xp), _format_number(next_xp - xp), level + 1]
	_update_skills()

func _xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	if level <= XP_THRESHOLDS.size():
		return XP_THRESHOLDS[level - 1]
	var levels_after_twenty := level - 20
	# Tras nivel 20, cada nivel requiere 5.000 EXP más que el anterior.
	return XP_THRESHOLDS[19] + levels_after_twenty * 50000 + (levels_after_twenty - 1) * levels_after_twenty * 2500

func _format_number(value: int) -> String:
	var raw := str(value)
	var result := ""
	while raw.length() > 3:
		result = "." + raw.right(3) + result
		raw = raw.left(-3)
	return raw + result

func _stats() -> Control:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var roll_toolbar := HFlowContainer.new()
	roll_toolbar.add_theme_constant_override("h_separation", 8)
	body.add_child(roll_toolbar)
	var roll_hint := Label.new()
	roll_hint.text = "MODO DE TIRADA"
	roll_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	roll_hint.add_theme_color_override("font_color", MUTED)
	roll_toolbar.add_child(roll_hint)
	sheet_roll_mode_option = OptionButton.new()
	sheet_roll_mode_option.add_item("Normal")
	sheet_roll_mode_option.add_item("Ventaja")
	sheet_roll_mode_option.add_item("Desventaja")
	sheet_roll_mode_option.tooltip_text = "Se aplica a características, habilidades y ataques"
	sheet_roll_mode_option.custom_minimum_size.x = 150
	roll_toolbar.add_child(sheet_roll_mode_option)
	var grid := GridContainer.new()
	attributes_grid = grid
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for stat in ["Fuerza", "Destreza", "Constitución", "Inteligencia", "Sabiduría", "Carisma"]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(145, 170)
		card.add_theme_stylebox_override("panel", _box(palette.field.lightened(0.025), 10, palette.accent.darkened(0.35), 1, 12))
		attribute_cards.append(card)
		grid.add_child(card)
		var card_body := VBoxContainer.new()
		card_body.alignment = BoxContainer.ALIGNMENT_CENTER
		card_body.add_theme_constant_override("separation", 5)
		card.add_child(card_body)
		var label := Label.new()
		label.text = stat.to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_body.add_child(label)
		var spin := SpinBox.new()
		spin.min_value = 1
		# Godot necesita un máximo de referencia para dibujar el SpinBox, pero
		# allow_greater permite escribir valores todavía mayores. En la práctica
		# la puntuación queda limitada únicamente por el entero de 64 bits.
		spin.max_value = 1_000_000_000
		spin.allow_greater = true
		spin.value = 10
		spin.tooltip_text = "Sin límite de 30: puedes escribir cualquier puntuación positiva"
		spin.custom_minimum_size = Vector2(90, 34)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_body.add_child(spin)
		var mod := Label.new()
		mod.text = "+0"
		mod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mod.custom_minimum_size.y = 32
		mod.add_theme_font_size_override("font_size", 26)
		mod.add_theme_color_override("font_color", GOLD)
		card_body.add_child(mod)
		var key: String = stat.to_lower().replace("ó", "o").replace("í", "i")
		stat_spins[key] = spin
		stat_mods[key] = mod
		spin.value_changed.connect(func(value: float): _on_stat_changed(key, int(value)))
		var roll_button := Button.new()
		roll_button.text = "Tirar d20"
		roll_button.tooltip_text = "Lanzar una prueba de %s y enviarla al chat" % stat
		roll_button.pressed.connect(_roll_stat.bind(key, stat))
		card_body.add_child(roll_button)
	return _section("ATRIBUTOS", body)

func _new_responsive_sheet_row() -> BoxContainer:
	var row := BoxContainer.new()
	row.vertical = size.x < 900.0
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	responsive_sheet_rows.append(row)
	return row

func _vitals() -> Control:
	var body := VBoxContainer.new()
	var row := _new_responsive_sheet_row()
	body.add_child(row)
	_add_field(row, "PV actuales", "hp_current", "10")
	_add_field(row, "PV máximos", "hp_max", "10")
	fields.hp_current.text = "10"
	fields.hp_max.text = "10"
	fields.hp_current.text_changed.connect(func(_text: String): _update_hp())
	fields.hp_max.text_changed.connect(func(_text: String): _update_hp())
	hp_bar = ProgressBar.new()
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size.y = 28
	body.add_child(hp_bar)
	return body

func _combat_mechanics() -> Control:
	var body := VBoxContainer.new()
	var toolbar := HFlowContainer.new()
	var title := Label.new()
	title.text = "CONTADORES Y PUNTOS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GOLD)
	toolbar.add_child(title)
	var remove_button := Button.new()
	remove_button.text = "− Quitar"
	remove_button.pressed.connect(_remove_mechanic_row)
	toolbar.add_child(remove_button)
	var add_button := Button.new()
	add_button.text = "+ Añadir mecánica"
	add_button.pressed.connect(_add_mechanic_row)
	toolbar.add_child(add_button)
	body.add_child(toolbar)
	var rest_toolbar := HFlowContainer.new()
	rest_toolbar.add_theme_constant_override("h_separation", 8)
	rest_toolbar.add_theme_constant_override("v_separation", 8)
	body.add_child(rest_toolbar)
	var short_rest := Button.new()
	short_rest.text = "☕ Descanso corto"
	short_rest.tooltip_text = "Restaura los contadores configurados para descanso corto"
	short_rest.pressed.connect(_take_short_rest)
	rest_toolbar.add_child(short_rest)
	var long_rest := Button.new()
	long_rest.text = "☾ Descanso largo"
	long_rest.tooltip_text = "Restaura vida, magia y contadores de descanso"
	long_rest.pressed.connect(_take_long_rest)
	rest_toolbar.add_child(long_rest)
	mechanic_rows_container = VBoxContainer.new()
	mechanic_rows_container.add_theme_constant_override("separation", 8)
	body.add_child(mechanic_rows_container)
	for _index in range(2):
		_add_mechanic_row()
	return body

func _add_mechanic_row() -> void:
	var index := mechanic_count
	mechanic_count += 1
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.set_meta("mechanic_index", index)
	mechanic_rows.append(row)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("h_separation", 7)
	controls.add_theme_constant_override("v_separation", 7)
	row.add_child(controls)
	var name := LineEdit.new()
	name.placeholder_text = "Nombre de la mecánica"
	name.custom_minimum_size.x = 150
	fields["mechanic_%d_name" % index] = name
	controls.add_child(name)
	name.text_changed.connect(func(_text: String): _refresh_spell_mechanic_options())
	var value := SpinBox.new()
	value.min_value = -999
	value.max_value = 999
	value.value = 0
	value.custom_minimum_size.x = 82
	fields["mechanic_%d_value" % index] = value
	controls.add_child(value)
	var maximum := SpinBox.new()
	maximum.min_value = 1
	maximum.max_value = 100
	maximum.value = 5
	maximum.custom_minimum_size.x = 72
	maximum.tooltip_text = "Cantidad máxima de círculos"
	fields["mechanic_%d_max" % index] = maximum
	controls.add_child(maximum)
	var recovery := OptionButton.new()
	recovery.add_item("Recuperación manual")
	recovery.add_item("Descanso corto")
	recovery.add_item("Descanso largo")
	recovery.tooltip_text = "Indica cuándo se rellenan automáticamente estos puntos"
	recovery.custom_minimum_size.x = 150
	option_fields["mechanic_%d_recovery" % index] = recovery
	controls.add_child(recovery)
	var positive := ColorPickerButton.new()
	positive.color = Color("#59b86b")
	positive.tooltip_text = "Color para puntos positivos"
	positive.custom_minimum_size.x = 36
	fields["mechanic_%d_positive" % index] = positive
	controls.add_child(positive)
	var negative := ColorPickerButton.new()
	negative.color = Color("#d45d52")
	negative.tooltip_text = "Color para puntos negativos"
	negative.custom_minimum_size.x = 36
	fields["mechanic_%d_negative" % index] = negative
	controls.add_child(negative)
	var track_script: Script = load("res://PointTrack.gd")
	var track: Control = track_script.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mechanic_tracks[index] = track
	row.add_child(track)
	value.value_changed.connect(func(_number: float): _update_mechanic(index))
	maximum.value_changed.connect(func(_number: float): _update_mechanic(index))
	positive.color_changed.connect(func(_color: Color): _update_mechanic(index))
	negative.color_changed.connect(func(_color: Color): _update_mechanic(index))
	mechanic_rows_container.add_child(row)
	_update_mechanic(index)
	_refresh_spell_mechanic_options()

func _update_mechanic(index: int) -> void:
	if not mechanic_tracks.has(index):
		return
	mechanic_tracks[index].configure(
		int(fields["mechanic_%d_value" % index].value),
		int(fields["mechanic_%d_max" % index].value),
		fields["mechanic_%d_positive" % index].color,
		fields["mechanic_%d_negative" % index].color
	)
	for spell_index in spell_mechanic_options:
		if _spell_linked_mechanic_index(int(spell_index)) == index:
			_update_spell_mechanic(int(spell_index))

func _remove_mechanic_row() -> void:
	if mechanic_rows.is_empty():
		_set_status("No quedan contadores para quitar.", true)
		return
	var row: BoxContainer = mechanic_rows.pop_back()
	var index: int = row.get_meta("mechanic_index")
	for suffix in ["name", "value", "max", "positive", "negative"]:
		fields.erase("mechanic_%d_%s" % [index, suffix])
	option_fields.erase("mechanic_%d_recovery" % index)
	mechanic_tracks.erase(index)
	row.queue_free()
	mechanic_count = maxi(mechanic_count - 1, 0)
	_refresh_spell_mechanic_options()
	_set_status("Contador eliminado.")

func _restore_mechanics_for_rest(include_long_rest: bool) -> Array[String]:
	var restored: Array[String] = []
	for index in range(mechanic_count):
		var recovery_key := "mechanic_%d_recovery" % index
		var value_key := "mechanic_%d_value" % index
		var max_key := "mechanic_%d_max" % index
		if not option_fields.has(recovery_key) or not fields.has(value_key) or not fields.has(max_key):
			continue
		var recovery_type: int = option_fields[recovery_key].selected
		if recovery_type == 1 or (include_long_rest and recovery_type == 2):
			fields[value_key].value = fields[max_key].value
			var mechanic_name: String = fields["mechanic_%d_name" % index].text.strip_edges()
			restored.append(mechanic_name if not mechanic_name.is_empty() else "Mecánica %d" % (index + 1))
	return restored

func _take_short_rest() -> void:
	var restored := _restore_mechanics_for_rest(false)
	var detail := ", ".join(restored) if not restored.is_empty() else "ningún contador automático"
	_post_chat(fields.name.text if not fields.name.text.is_empty() else "Personaje", "Realizó un descanso corto. Recuperó: %s." % detail)
	_save_after_rest("Descanso corto completado.")

func _take_long_rest() -> void:
	var restored := _restore_mechanics_for_rest(true)
	if fields.has("hp_current") and fields.has("hp_max"):
		fields.hp_current.text = fields.hp_max.text
	if fields.has("magic_current") and fields.has("magic_max"):
		fields.magic_current.text = fields.magic_max.text
	_update_hp()
	var detail := ", ".join(restored) if not restored.is_empty() else "sin contadores automáticos"
	_post_chat(fields.name.text if not fields.name.text.is_empty() else "Personaje", "Realizó un descanso largo. Recuperó sus PV, su magia y %s." % detail)
	_save_after_rest("Descanso largo completado: vida y magia restauradas.")

func _save_after_rest(message: String) -> void:
	if current_sheet_file.is_empty():
		_set_status(message + " Guarda la hoja para conservar los cambios.")
		return
	save_sheet()
	_set_status(message)

func _skills() -> Control:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	skill_proficiency_label = Label.new()
	skill_proficiency_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_proficiency_label.add_theme_color_override("font_color", MUTED)
	body.add_child(skill_proficiency_label)
	var skill_list := VBoxContainer.new()
	skill_list.add_theme_constant_override("separation", 6)
	body.add_child(skill_list)
	var definitions := [
		["Acrobacias", "destreza", "DES"],
		["Arcano", "inteligencia", "INT"],
		["Atletismo", "fuerza", "FUE"],
		["Engaño", "carisma", "CAR"],
		["Historia", "inteligencia", "INT"],
		["Intimidación", "carisma", "CAR"],
		["Interpretación", "carisma", "CAR"],
		["Investigación", "inteligencia", "INT"],
		["Juego de manos", "destreza", "DES"],
		["Medicina", "sabiduria", "SAB"],
		["Naturaleza", "inteligencia", "INT"],
		["Percepción", "sabiduria", "SAB"],
		["Perspicacia", "sabiduria", "SAB"],
		["Persuasión", "carisma", "CAR"],
		["Religión", "inteligencia", "INT"],
		["Sigilo", "destreza", "DES"],
		["Supervivencia", "sabiduria", "SAB"],
		["Trato con animales", "sabiduria", "SAB"]
	]
	for definition in definitions:
		var skill: String = definition[0]
		var ability: String = definition[1]
		var abbreviation: String = definition[2]
		var row := BoxContainer.new()
		row.vertical = size.x < 520.0
		row.add_theme_constant_override("separation", 6)
		skill_rows.append(row)
		skill_list.add_child(row)
		var check := CheckBox.new()
		check.text = skill
		check.tooltip_text = "Marca la casilla si tienes competencia. La característica puede cambiarse a la derecha."
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(check)
		var value_row := HBoxContainer.new()
		value_row.add_theme_constant_override("separation", 6)
		row.add_child(value_row)
		var ability_option := OptionButton.new()
		ability_option.fit_to_longest_item = false
		ability_option.custom_minimum_size.x = 78
		var ability_definitions := [["FUE", "fuerza"], ["DES", "destreza"], ["CON", "constitucion"], ["INT", "inteligencia"], ["SAB", "sabiduria"], ["CAR", "carisma"]]
		for ability_definition in ability_definitions:
			ability_option.add_item(ability_definition[0])
			ability_option.set_item_metadata(ability_option.item_count - 1, ability_definition[1])
			if ability_definition[1] == ability:
				ability_option.select(ability_option.item_count - 1)
		ability_option.tooltip_text = "Característica que aumenta %s (predeterminada: %s)" % [skill, abbreviation]
		value_row.add_child(ability_option)
		var edit := LineEdit.new()
		edit.placeholder_text = "+0"
		edit.editable = true
		edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		edit.tooltip_text = "Total calculado. Puedes escribir otro valor para añadir un ajuste manual."
		edit.custom_minimum_size.x = 65
		value_row.add_child(edit)
		var key := "skill_" + skill.to_lower().replace("ó", "o").replace(" ", "_")
		var skill_data := {"check": check, "value": edit, "ability_option": ability_option, "default_ability": ability, "name": skill, "manual_adjustment": 0}
		fields[key] = skill_data
		skill_fields[key] = skill_data
		var roll_button := Button.new()
		roll_button.text = "d20"
		roll_button.tooltip_text = "Tirar %s con el bonificador mostrado" % skill
		roll_button.custom_minimum_size.x = 58
		roll_button.pressed.connect(_roll_skill.bind(key))
		value_row.add_child(roll_button)
		check.toggled.connect(func(_enabled: bool): _update_skills())
		ability_option.item_selected.connect(func(_index: int): _update_skills())
		edit.text_submitted.connect(func(_text: String): _commit_skill_value(key))
		edit.focus_exited.connect(func(): _commit_skill_value(key))
	_update_skills.call_deferred()
	return _section("HABILIDADES", body)

func _character_proficiency_bonus() -> int:
	var level := maxi(int(fields.level.text) if fields.has("level") else 1, 1)
	# La progresión continúa después de nivel 20 porque esta hoja admite nivel
	# 100 o superior: +2 en nivel 1 y +1 adicional cada cuatro niveles.
	return 2 + floori(float(level - 1) / 4.0)

func _update_skills() -> void:
	if skill_fields.is_empty():
		return
	var proficiency := _character_proficiency_bonus()
	if skill_proficiency_label != null:
		skill_proficiency_label.text = "La abreviatura indica la característica. ☑ Competencia suma +%d según tu nivel." % proficiency
	for key in skill_fields:
		var data: Dictionary = skill_fields[key]
		var calculation := _skill_base_calculation(data, proficiency)
		if calculation.is_empty():
			continue
		var ability := str(calculation.ability)
		var ability_modifier := int(calculation.modifier)
		var trained: bool = bool(calculation.trained)
		var adjustment := int(data.get("manual_adjustment", 0))
		var total := int(calculation.total) + adjustment
		data.value.text = ("+" if total >= 0 else "") + str(total)
		var competence_text := "  +  competencia %s%d" % ["+" if proficiency >= 0 else "", proficiency] if trained else ""
		var adjustment_text := "  +  ajuste %s%d" % ["+" if adjustment >= 0 else "", adjustment] if adjustment != 0 else ""
		data.value.tooltip_text = "%s: %s%d%s%s" % [ability.capitalize(), "+" if ability_modifier >= 0 else "", ability_modifier, competence_text, adjustment_text]
		data.value.add_theme_color_override("font_color", palette.accent if adjustment != 0 else palette.text)

func _skill_base_calculation(data: Dictionary, proficiency: int) -> Dictionary:
	var ability_option: OptionButton = data.get("ability_option")
	var ability := str(ability_option.get_selected_metadata()) if ability_option != null and ability_option.selected >= 0 else str(data.get("default_ability", ""))
	if not stat_spins.has(ability):
		return {}
	var score := int(stat_spins[ability].value)
	var ability_modifier := floori((score - 10) / 2.0)
	var trained: bool = data.check.button_pressed
	return {"ability": ability, "modifier": ability_modifier, "trained": trained, "total": ability_modifier + (proficiency if trained else 0)}

func _commit_skill_value(key: String) -> void:
	if not skill_fields.has(key):
		return
	var data: Dictionary = skill_fields[key]
	var clean := str(data.value.text).strip_edges().replace("+", "")
	if clean.is_empty():
		data["manual_adjustment"] = 0
		_update_skills()
		return
	if not clean.is_valid_int():
		_set_status("El bonificador de habilidad debe ser un número entero, por ejemplo +5 o -2.", true)
		_update_skills()
		return
	var calculation := _skill_base_calculation(data, _character_proficiency_bonus())
	if calculation.is_empty():
		return
	data["manual_adjustment"] = int(clean) - int(calculation.total)
	_update_skills()
	_set_status("Bonificador manual de %s actualizado." % str(data.get("name", "habilidad")))

func _combat() -> Control:
	var body := VBoxContainer.new()
	var health_label := Label.new()
	health_label.text = "PUNTOS DE VIDA"
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", MUTED)
	body.add_child(health_label)
	body.add_child(_vitals())
	body.add_child(_combat_mechanics())
	var row := _new_responsive_sheet_row()
	body.add_child(row)
	for d in [["Clase de armadura", "armor_class", "10"], ["Iniciativa", "initiative", "+0"], ["Dado de golpe", "hit_dice", "1d8"]]:
		_add_field(row, d[0], d[1], d[2])
	var movement_label := Label.new()
	movement_label.text = "VELOCIDAD DE MOVIMIENTO"
	movement_label.add_theme_font_size_override("font_size", 12)
	movement_label.add_theme_color_override("font_color", MUTED)
	body.add_child(movement_label)
	var movement := _new_responsive_sheet_row()
	body.add_child(movement)
	for d in [["Caminar", "walk_speed", "9 m"], ["Nadar", "swim_speed", "—"], ["Volar", "fly_speed", "—"]]:
		_add_field(movement, d[0], d[1], d[2])
	var attacks := TextEdit.new()
	attacks.placeholder_text = "Ataques, conjuros y maniobras…\nEj.: Espada larga  +5  •  1d8+3"
	attacks.custom_minimum_size.y = 120
	fields.attacks = attacks
	body.add_child(attacks)
	var attack_tools := HFlowContainer.new()
	attack_tools.add_theme_constant_override("h_separation", 8)
	body.add_child(attack_tools)
	var attack_roll := Button.new()
	attack_roll.text = "⚔ Tirar ataque de la línea activa"
	attack_roll.tooltip_text = "Busca el primer bonificador como +5 o -1 en la línea donde está el cursor"
	attack_roll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_roll.pressed.connect(_roll_active_attack)
	attack_tools.add_child(attack_roll)
	var initiative_roll := Button.new()
	initiative_roll.text = "Tirar iniciativa"
	initiative_roll.pressed.connect(_roll_initiative_from_sheet)
	attack_tools.add_child(initiative_roll)
	var actions_label := Label.new()
	actions_label.text = "ACCIONES"
	actions_label.add_theme_font_size_override("font_size", 12)
	actions_label.add_theme_color_override("font_color", MUTED)
	body.add_child(actions_label)
	var actions := TextEdit.new()
	actions.text = "Ataque • Usar Magia • Correr • Liberarse • Esquivar • Ayudar • Esconderse • Prepararse • Buscar • Usar un Objeto • Agarrar • Empujar • Improvisar • Interactuar con un objeto"
	actions.custom_minimum_size.y = 110
	actions.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	fields.actions = actions
	body.add_child(actions)
	return _section("COMBATE", body)

func _proficiencies() -> Control:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	proficiency_lists.clear()
	proficiency_list_containers.clear()
	for definition in [["Resistencias", "resistances", "Ej.: Fuego"], ["Idiomas", "languages", "Ej.: Común"], ["Armas / Armaduras", "weapon_proficiencies", "Ej.: Espadas largas"], ["Herramientas", "tool_proficiencies", "Ej.: Herramientas de ladrón"]]:
		_add_proficiency_list(body, str(definition[0]), str(definition[1]), str(definition[2]))
	return _section("RESISTENCIAS Y COMPETENCIAS", body)

func _add_proficiency_list(parent: VBoxContainer, title_text: String, key: String, placeholder: String) -> void:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 7)
	parent.add_child(group)
	var toolbar := HBoxContainer.new()
	group.add_child(toolbar)
	var label := Label.new()
	label.text = title_text.to_upper()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", MUTED)
	toolbar.add_child(label)
	var add_button := Button.new()
	add_button.text = "+ Añadir"
	add_button.tooltip_text = "Añadir elemento a %s" % title_text.to_lower()
	add_button.pressed.connect(_add_proficiency_item.bind(key, placeholder, ""))
	toolbar.add_child(add_button)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	group.add_child(rows)
	proficiency_lists[key] = []
	proficiency_list_containers[key] = rows
	_add_proficiency_item(key, placeholder, "")

func _add_proficiency_item(key: String, placeholder: String, initial_text: String = "") -> void:
	if not proficiency_lists.has(key) or not proficiency_list_containers.has(key):
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.text = initial_text
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	var remove_button := Button.new()
	remove_button.text = "×"
	remove_button.tooltip_text = "Quitar este elemento"
	remove_button.custom_minimum_size.x = 42
	remove_button.pressed.connect(_remove_proficiency_item.bind(key, row, edit))
	row.add_child(remove_button)
	var list: Array = proficiency_lists[key]
	list.append(edit)
	proficiency_lists[key] = list
	var container: VBoxContainer = proficiency_list_containers[key]
	container.add_child(row)

func _remove_proficiency_item(key: String, row: Control, edit: LineEdit) -> void:
	if not proficiency_lists.has(key):
		return
	var list: Array = proficiency_lists[key]
	list.erase(edit)
	proficiency_lists[key] = list
	row.queue_free()

func _replace_proficiency_items(key: String, values: Array[String]) -> void:
	if not proficiency_lists.has(key):
		return
	var existing: Array = proficiency_lists[key].duplicate()
	for edit in existing:
		if is_instance_valid(edit):
			var row: Node = edit.get_parent()
			if is_instance_valid(row):
				row.queue_free()
	proficiency_lists[key] = []
	var placeholders := {"resistances": "Ej.: Fuego", "languages": "Ej.: Común", "weapon_proficiencies": "Ej.: Espadas largas", "tool_proficiencies": "Ej.: Herramientas de ladrón"}
	for value in values:
		_add_proficiency_item(key, str(placeholders.get(key, "Nuevo elemento")), value)
	if values.is_empty():
		_add_proficiency_item(key, str(placeholders.get(key, "Nuevo elemento")), "")

func _legacy_proficiency_values(value: Variant) -> Array[String]:
	var result: Array[String] = []
	var normalized := str(value).replace("•", "\n").replace(",", "\n").replace(";", "\n")
	for part in normalized.split("\n", false):
		var clean := part.strip_edges()
		if not clean.is_empty():
			result.append(clean)
	return result

func _inventory() -> Control:
	var body := VBoxContainer.new()
	var currency := _new_responsive_sheet_row()
	body.add_child(currency)
	for d in [["Oro", "gold"], ["Plata", "silver"], ["Cobre", "copper"]]:
		_add_field(currency, d[0], d[1], "0")
	var weight := _new_responsive_sheet_row()
	body.add_child(weight)
	_add_field(weight, "Peso actual", "current_weight", "0 kg")
	fields.current_weight.text = "0 kg"
	fields.current_weight.editable = false
	_add_field(weight, "Capacidad de carga", "carry_capacity", "75 kg")
	var toolbar := HFlowContainer.new()
	var title := Label.new()
	title.text = "OBJETOS Y EQUIPO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GOLD)
	toolbar.add_child(title)
	var remove_button := Button.new()
	remove_button.text = "− Quitar objeto"
	remove_button.pressed.connect(_remove_inventory_row)
	toolbar.add_child(remove_button)
	var add_button := Button.new()
	add_button.text = "+ Añadir objeto"
	add_button.pressed.connect(_add_inventory_row)
	toolbar.add_child(add_button)
	body.add_child(toolbar)
	inventory_rows_container = VBoxContainer.new()
	inventory_rows_container.add_theme_constant_override("separation", 8)
	body.add_child(inventory_rows_container)
	for _index in range(5):
		_add_inventory_row()
	return _section("INVENTARIO", body)

func _add_inventory_row() -> void:
	var index := inventory_count
	inventory_count += 1
	var row := _new_responsive_sheet_row()
	row.set_meta("inventory_index", index)
	inventory_rows.append(row)
	_add_field(row, "Objeto", "item_%d_name" % index, "Nombre o cantidad…")
	_add_field(row, "Descripción", "item_%d_description" % index, "Qué hace, rareza, origen o notas…")
	_add_field(row, "Peso", "item_%d_weight" % index, "0 kg")
	fields["item_%d_name" % index].custom_minimum_size.x = 180
	fields["item_%d_description" % index].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields["item_%d_weight" % index].custom_minimum_size.x = 150
	fields["item_%d_weight" % index].text_changed.connect(func(_text: String): _update_inventory_weight())
	inventory_rows_container.add_child(row)

func _remove_inventory_row() -> void:
	if inventory_rows.is_empty():
		_set_status("No quedan objetos para quitar.", true)
		return
	var row: BoxContainer = inventory_rows.pop_back()
	var index: int = row.get_meta("inventory_index")
	fields.erase("item_%d_name" % index)
	fields.erase("item_%d_description" % index)
	fields.erase("item_%d_weight" % index)
	row.queue_free()
	inventory_count = maxi(inventory_count - 1, 0)
	_update_inventory_weight()
	_set_status("Objeto eliminado del inventario.")

func _update_inventory_weight() -> void:
	if not fields.has("current_weight"):
		return
	var total := 0.0
	for index in range(inventory_count):
		var key := "item_%d_weight" % index
		if fields.has(key):
			var clean: String = fields[key].text.to_lower().replace("kg", "").replace(",", ".").strip_edges()
			if clean.is_valid_float():
				total += float(clean)
	fields.current_weight.text = ("%.2f" % total).trim_suffix("0").trim_suffix(".") + " kg"

func _notes() -> Control:
	var tabs := TabContainer.new()
	tabs.custom_minimum_size.y = 650
	for tab_name in ["Rasgos", "Historia"]:
		var edit := TextEdit.new()
		edit.name = tab_name
		edit.placeholder_text = "Escribe aquí " + tab_name.to_lower() + " del personaje…"
		fields[tab_name.to_lower()] = edit
		tabs.add_child(edit)
	var crafting := _crafting_tab()
	crafting.name = "Crafteo"
	tabs.add_child(crafting)
	var notes := TextEdit.new()
	notes.name = "Notas"
	notes.placeholder_text = "Escribe aquí las notas del personaje…"
	fields.notas = notes
	tabs.add_child(notes)
	return _section("PERSONAJE", tabs)

func _crafting_tab() -> Control:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	var materials := TextEdit.new()
	materials.placeholder_text = "Materiales disponibles, componentes y cantidades…"
	materials.custom_minimum_size.y = 150
	fields.crafting_materials = materials
	body.add_child(materials)
	var recipes := TextEdit.new()
	recipes.placeholder_text = "Recetas conocidas, requisitos, dificultad y resultado…"
	recipes.custom_minimum_size.y = 190
	fields.crafting_recipes = recipes
	body.add_child(recipes)
	var projects := TextEdit.new()
	projects.placeholder_text = "Proyectos en curso, progreso y tiempo restante…"
	projects.custom_minimum_size.y = 150
	fields.crafting_projects = projects
	body.add_child(projects)
	return body

func _spells_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	var magic_header := PanelContainer.new()
	magic_header.add_theme_stylebox_override("panel", _box(Color("#29352e"), 10, Color("#78b77a"), 1, 14))
	var header_row := _new_responsive_sheet_row()
	magic_header.add_child(header_row)
	var ability_holder := VBoxContainer.new()
	ability_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(ability_holder)
	var ability_label := Label.new()
	ability_label.text = "CARACTERÍSTICA MÁGICA"
	ability_label.add_theme_font_size_override("font_size", 12)
	ability_label.add_theme_color_override("font_color", Color("#9fd69c"))
	ability_holder.add_child(ability_label)
	var ability := OptionButton.new()
	for stat in ["Inteligencia", "Sabiduría", "Carisma"]:
		ability.add_item(stat)
	ability.item_selected.connect(func(_index: int): _update_magic_bonus())
	option_fields.magic_ability = ability
	ability_holder.add_child(ability)
	_add_field(header_row, "Magia actual", "magic_current", "0")
	_add_field(header_row, "Magia máxima", "magic_max", "0")
	_add_field(header_row, "Competencia", "magic_proficiency", "+2")
	fields.magic_proficiency.text = "+2"
	fields.magic_proficiency.text_changed.connect(func(_text: String): _update_magic_bonus())
	var bonus_holder := VBoxContainer.new()
	header_row.add_child(bonus_holder)
	var bonus_title := Label.new()
	bonus_title.text = "BONIF. MÁGICA"
	bonus_title.add_theme_font_size_override("font_size", 12)
	bonus_title.add_theme_color_override("font_color", Color("#9fd69c"))
	bonus_holder.add_child(bonus_title)
	magic_bonus_label = Label.new()
	magic_bonus_label.text = "+2"
	magic_bonus_label.custom_minimum_size = Vector2(70, 42)
	magic_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	magic_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	magic_bonus_label.add_theme_font_size_override("font_size", 24)
	magic_bonus_label.add_theme_color_override("font_color", Color("#b9f0a9"))
	bonus_holder.add_child(magic_bonus_label)
	body.add_child(magic_header)
	body.add_child(_spell_library_panel())
	var card_toolbar := HFlowContainer.new()
	var card_title := Label.new()
	card_title.text = "CARTAS DE CONJURO"
	card_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_title.add_theme_color_override("font_color", GOLD)
	card_toolbar.add_child(card_title)
	var remove_button := Button.new()
	remove_button.text = "− Quitar última"
	remove_button.pressed.connect(_remove_spell_card)
	card_toolbar.add_child(remove_button)
	var add_button := Button.new()
	add_button.text = "+ Añadir carta"
	add_button.pressed.connect(_add_spell_card)
	card_toolbar.add_child(add_button)
	body.add_child(card_toolbar)
	spell_cards_container = GridContainer.new()
	spell_cards_container.columns = _responsive_spell_columns()
	spell_cards_container.add_theme_constant_override("separation", 14)
	body.add_child(spell_cards_container)
	for _index in range(3):
		_add_spell_card()
	_update_magic_bonus()
	return scroll

func _spell_library_panel() -> Control:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var hint := Label.new()
	hint.text = "HECHIZOS REUTILIZABLES Y COMPARTIBLES"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", MUTED)
	heading.add_child(hint)
	spell_library_count_label = Label.new()
	spell_library_count_label.text = "0 hechizos"
	spell_library_count_label.add_theme_color_override("font_color", palette.accent)
	heading.add_child(spell_library_count_label)
	spell_library_search = LineEdit.new()
	spell_library_search.placeholder_text = "⌕ Buscar hechizo guardado…"
	spell_library_search.text_changed.connect(func(_text: String): _refresh_spell_library())
	content.add_child(spell_library_search)
	spell_library_list = ItemList.new()
	spell_library_list.custom_minimum_size.y = 155
	spell_library_list.item_selected.connect(_select_spell_library_entry)
	spell_library_list.item_activated.connect(func(_item: int): _add_selected_spell_library_to_deck())
	content.add_child(spell_library_list)
	var tools := HFlowContainer.new()
	tools.add_theme_constant_override("h_separation", 8)
	tools.add_theme_constant_override("v_separation", 8)
	content.add_child(tools)
	for definition in [["＋ Añadir al mazo", _add_selected_spell_library_to_deck], ["⇩ Importar", _choose_library_catalog_import], ["⇧ Exportar", _choose_library_catalog_export], ["◎ Compartir online", _share_selected_spell_online]]:
		var button := Button.new()
		button.text = definition[0]
		button.pressed.connect(definition[1])
		tools.add_child(button)
	_refresh_spell_library()
	return _section("BIBLIOTECA DE HECHIZOS", content)

func _refresh_spell_library() -> void:
	if spell_library_list == null:
		return
	spell_library_list.clear()
	var query := spell_library_search.text.strip_edges().to_lower() if spell_library_search != null else ""
	var visible_count := 0
	for index in range(library_catalog_entries.size()):
		var entry: Dictionary = library_catalog_entries[index]
		if str(entry.get("category", "")) != "Conjuro":
			continue
		var searchable := "%s %s %s" % [entry.get("name", ""), entry.get("source", ""), entry.get("notes", "")]
		if not query.is_empty() and query not in searchable.to_lower():
			continue
		var item := spell_library_list.add_item("✦  %s\n%s" % [entry.get("name", "Sin nombre"), entry.get("source", "Sin fuente")])
		spell_library_list.set_item_metadata(item, index)
		visible_count += 1
	if spell_library_count_label != null:
		spell_library_count_label.text = "%d hechizo(s)" % visible_count

func _select_spell_library_entry(item_index: int) -> void:
	if spell_library_list == null or item_index < 0 or item_index >= spell_library_list.item_count:
		return
	library_catalog_selected = int(spell_library_list.get_item_metadata(item_index))

func _add_selected_spell_library_to_deck() -> void:
	if library_catalog_selected < 0 or library_catalog_selected >= library_catalog_entries.size() or str(library_catalog_entries[library_catalog_selected].get("category", "")) != "Conjuro":
		_set_status("Selecciona un hechizo de la biblioteca.", true)
		return
	_send_catalog_spell_to_deck()

func _share_selected_spell_online() -> void:
	_share_selected_library_entry_online("Conjuro")

func _share_selected_library_entry_online(expected_category := "") -> void:
	if library_catalog_selected < 0 or library_catalog_selected >= library_catalog_entries.size():
		_set_status("Selecciona una entrada de la biblioteca.", true)
		return
	var entry: Dictionary = library_catalog_entries[library_catalog_selected]
	var category := str(entry.get("category", ""))
	if not expected_category.is_empty() and category != expected_category:
		_set_status("La entrada seleccionada no es de tipo %s." % expected_category, true)
		return
	var peer := multiplayer.multiplayer_peer
	if table_board == null or peer == null or peer is OfflineMultiplayerPeer or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_set_status("Conéctate a una mesa online antes de compartir contenido.", true)
		return
	var portable := {"format": "dnd-library-entry", "version": 1, "exported_at": Time.get_datetime_string_from_system(), "entries": [entry]}
	var bytes := JSON.stringify(portable).to_utf8_buffer()
	var filename := str(entry.get("name", "hechizo")).validate_filename()
	if filename.is_empty():
		filename = "hechizo"
	if not table_board.share_library_entry(filename + "." + LIBRARY_ENTRY_EXTENSION, bytes):
		_set_status("No hay jugadores conectados o no se pudo iniciar el envío.", true)
		return
	_set_status("%s compartido con la mesa: %s." % [category, str(entry.get("name", "Entrada"))])

func _on_shared_library_entry_received(bytes: PackedByteArray, sender_peer_id: int) -> void:
	if bytes.is_empty() or bytes.size() > 8 * 1024 * 1024:
		return
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		_set_status("Se rechazó contenido online no válido.", true)
		return
	var portable: Dictionary = parser.data
	if str(portable.get("format", "")) != "dnd-library-entry" or not portable.get("entries", []) is Array or portable.entries.size() != 1 or not portable.entries[0] is Dictionary:
		_set_status("El contenido compartido no es válido.", true)
		return
	var entry := _sanitize_library_catalog_entry(portable.entries[0])
	if entry.is_empty() or str(entry.get("category", "")) not in ["Conjuro", "Enemigo"]:
		_set_status("El contenido compartido no es un hechizo ni un monstruo válido.", true)
		return
	var identity := _library_catalog_identity(entry)
	var target_index := -1
	for index in range(library_catalog_entries.size()):
		if _library_catalog_identity(library_catalog_entries[index]) == identity:
			target_index = index
			break
	if target_index >= 0:
		library_catalog_entries[target_index] = entry
	else:
		if library_catalog_entries.size() >= MAX_LIBRARY_CATALOG_ENTRIES:
			_set_status("La biblioteca está llena; no se pudo recibir el hechizo.", true)
			return
		library_catalog_entries.append(entry)
		target_index = library_catalog_entries.size() - 1
	library_catalog_selected = target_index
	_write_library_catalog()
	_refresh_library_catalog()
	if multiplayer.is_server() and sender_peer_id > 1:
		# El servidor vuelve a serializar solo los datos ya saneados antes de
		# distribuirlos; nunca reenvía directamente el archivo del jugador.
		var safe_portable := {"format": "dnd-library-entry", "version": 1, "exported_at": Time.get_datetime_string_from_system(), "entries": [entry]}
		var safe_bytes := JSON.stringify(safe_portable).to_utf8_buffer()
		var safe_filename := str(entry.get("name", "hechizo")).validate_filename()
		if safe_filename.is_empty():
			safe_filename = "hechizo"
		table_board.share_library_entry_to_all(safe_filename + "." + LIBRARY_ENTRY_EXTENSION, safe_bytes)
	_set_status("%s recibido online: %s." % [str(entry.get("category", "Contenido")), str(entry.get("name", "Entrada"))])

func _responsive_spell_columns() -> int:
	if _is_phone_layout() or size.x < 720.0:
		return 1
	if size.x < 1180.0:
		return 2
	# Las cartas ahora son más amplias. Cuatro columnas solo caben cómodamente
	# en monitores grandes; en una ventana normal tres evitan campos comprimidos.
	if size.x < 1540.0:
		return 3
	return 4

func _refresh_spell_layout() -> void:
	var column_count: int = _responsive_spell_columns()
	if spell_cards_container != null:
		spell_cards_container.columns = column_count
	if deck_cards_grid != null:
		deck_cards_grid.columns = column_count
		for index in range(deck_card_nodes.size()):
			var card: Control = deck_card_nodes[index]
			if not is_instance_valid(card):
				continue
			var resting_angle: float = [-4.0, -1.5, 1.5, 4.0][index % 4] if column_count >= 4 else 0.0
			card.set_meta("deck_resting_angle", resting_angle)
			card.rotation_degrees = resting_angle
			card.scale = Vector2.ONE

func _add_spell_card() -> void:
	var index := spell_count
	spell_count += 1
	var card := PanelContainer.new()
	# Una carta amplia mantiene legibles los datos y los controles táctiles.
	card.custom_minimum_size = Vector2(340, 0)
	card.add_theme_stylebox_override("panel", _box(palette.panel.lightened(0.08), 10, palette.accent, 3, 16))
	card.set_meta("spell_index", index)
	spell_cards.append(card)
	var body := VBoxContainer.new()
	card.add_child(body)
	var title := LineEdit.new()
	title.placeholder_text = "NOMBRE DEL CONJURO"
	title.alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.custom_minimum_size.y = 48
	# Las cartas deben seguir la skin activa. Antes usaban rojo y verde fijos,
	# por eso podían verse distintas al resto de la hoja.
	title.add_theme_color_override("font_color", palette.accent)
	fields["spell_%d_name" % index] = title
	body.add_child(title)
	var details := GridContainer.new()
	details.columns = 2
	details.add_theme_constant_override("h_separation", 12)
	details.add_theme_constant_override("v_separation", 10)
	body.add_child(details)
	for d in [["Nivel", "level", "1"], ["Bonif. por nivel", "level_bonus", "+1d4"], ["Tiempo de lanzamiento", "casting_time", "1 acción"], ["Magia utilizada", "magic_cost", "1"], ["Escuela", "school", "Evocación"], ["Alcance", "range", "18 m"], ["Objetivo", "target", "Una criatura o punto"], ["Duración", "duration", "Instantánea"], ["Daño / efecto", "effect", "1d4+1"], ["Componentes", "components", "V, S"]]:
		_add_spell_field(details, index, d[0], d[1], d[2])
	# El bono suele contener varios dados o escalados, por eso recibe más altura
	# y tamaño de letra que los campos cortos.
	fields["spell_%d_level_bonus" % index].custom_minimum_size.y = 48
	fields["spell_%d_level_bonus" % index].add_theme_font_size_override("font_size", 18)
	_add_spell_mechanic(body, index)
	var description := TextEdit.new()
	description.placeholder_text = "Describe el efecto del conjuro, sus requisitos y mejoras a niveles superiores…"
	description.custom_minimum_size.y = 185
	description.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	description.add_theme_color_override("font_color", palette.text)
	fields["spell_%d_description" % index] = description
	body.add_child(description)
	var use_button := Button.new()
	use_button.text = "✦ Usar conjuro"
	use_button.tooltip_text = "Consume la magia y los puntos de la mecánica vinculada"
	use_button.pressed.connect(_use_spell.bind(index))
	body.add_child(use_button)
	var library_button := Button.new()
	library_button.text = "▣ Guardar en biblioteca"
	library_button.tooltip_text = "Guarda una copia portátil de esta carta"
	library_button.pressed.connect(_save_spell_card_to_library.bind(index))
	body.add_child(library_button)
	var chat_button := Button.new()
	chat_button.text = "Enviar al chat"
	chat_button.pressed.connect(func(): _send_spell_to_chat(index))
	body.add_child(chat_button)
	spell_cards_container.add_child(card)

func _remove_spell_card() -> void:
	if spell_cards.is_empty():
		_set_status("No quedan cartas de conjuro para quitar.", true)
		return
	var card: PanelContainer = spell_cards.pop_back()
	var index: int = card.get_meta("spell_index")
	for key in fields.keys():
		if str(key).begins_with("spell_%d_" % index):
			fields.erase(key)
	spell_mechanic_tracks.erase(index)
	spell_mechanic_options.erase(index)
	card.queue_free()
	spell_count = maxi(spell_count - 1, 0)
	_set_status("Carta de conjuro eliminada.")

func _add_spell_field(parent: Container, index: int, label_text: String, suffix: String, placeholder: String) -> void:
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", palette.accent)
	holder.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.custom_minimum_size.y = 40
	edit.add_theme_color_override("font_color", palette.text)
	holder.add_child(edit)
	fields["spell_%d_%s" % [index, suffix]] = edit
	parent.add_child(holder)

func _add_spell_mechanic(parent: VBoxContainer, index: int) -> void:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 4)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.tooltip_text = "Vincula esta carta con un contador de la sección Combate"
	spell_mechanic_options[index] = option
	row.add_child(option)
	var name := LineEdit.new()
	name.visible = false
	fields["spell_%d_mechanic_name" % index] = name
	panel.add_child(name)
	var link := SpinBox.new()
	link.min_value = -1
	link.max_value = 999
	link.value = -1
	link.visible = false
	fields["spell_%d_mechanic_link" % index] = link
	panel.add_child(link)
	var cost := SpinBox.new()
	cost.min_value = 0
	cost.max_value = 100
	cost.value = 1
	cost.custom_minimum_size.x = 64
	cost.tooltip_text = "Puntos que consume el conjuro"
	fields["spell_%d_mechanic_cost" % index] = cost
	row.add_child(cost)
	var maximum := SpinBox.new()
	maximum.min_value = 1
	maximum.max_value = 100
	maximum.value = 5
	maximum.custom_minimum_size.x = 64
	maximum.tooltip_text = "Cantidad máxima de puntos"
	fields["spell_%d_mechanic_max" % index] = maximum
	maximum.visible = false
	panel.add_child(maximum)
	var value := SpinBox.new()
	value.min_value = 0
	value.max_value = 100
	value.value = 0
	value.visible = false
	fields["spell_%d_mechanic_value" % index] = value
	panel.add_child(value)
	var track_script: Script = load("res://PointTrack.gd")
	var track: Control = track_script.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.set_interactive(true)
	track.tooltip_text = "Toca un círculo para marcar o desmarcar puntos"
	spell_mechanic_tracks[index] = track
	panel.add_child(track)
	maximum.value_changed.connect(func(_number: float):
		value.max_value = maximum.value
		value.value = minf(value.value, maximum.value)
		_update_spell_mechanic(index)
	)
	value.value_changed.connect(func(_number: float): _update_spell_mechanic(index))
	track.value_changed.connect(_on_spell_track_value_changed.bind(index))
	option.item_selected.connect(_on_spell_mechanic_selected.bind(index))
	_refresh_spell_mechanic_option(index)
	_update_spell_mechanic(index)

func _update_spell_mechanic(index: int) -> void:
	if not spell_mechanic_tracks.has(index):
		return
	var linked_index := _spell_linked_mechanic_index(index)
	if linked_index >= 0:
		spell_mechanic_tracks[index].configure(
			int(fields["mechanic_%d_value" % linked_index].value),
			int(fields["mechanic_%d_max" % linked_index].value),
			fields["mechanic_%d_positive" % linked_index].color,
			fields["mechanic_%d_negative" % linked_index].color
		)
		return
	spell_mechanic_tracks[index].configure(
		int(fields["spell_%d_mechanic_value" % index].value),
		int(fields["spell_%d_mechanic_max" % index].value),
		Color("#59b86b"), Color("#d45d52")
	)

func _spell_mechanic_summary(index: int) -> String:
	var linked_index := _spell_linked_mechanic_index(index)
	if linked_index < 0:
		return "Ninguna"
	var mechanic_name: String = fields["mechanic_%d_name" % linked_index].text.strip_edges()
	if mechanic_name.is_empty():
		mechanic_name = "Mecánica %d" % (linked_index + 1)
	return "%s %d/%d; coste %d" % [mechanic_name, int(fields["mechanic_%d_value" % linked_index].value), int(fields["mechanic_%d_max" % linked_index].value), int(fields["spell_%d_mechanic_cost" % index].value)]

func _refresh_spell_mechanic_options() -> void:
	for index in spell_mechanic_options:
		_refresh_spell_mechanic_option(int(index))

func _refresh_spell_mechanic_option(index: int) -> void:
	if not spell_mechanic_options.has(index):
		return
	var option: OptionButton = spell_mechanic_options[index]
	var saved_name: String = fields["spell_%d_mechanic_name" % index].text.strip_edges()
	var previous_link := _spell_linked_mechanic_index(index)
	var saved_link := int(fields["spell_%d_mechanic_link" % index].value)
	if previous_link < 0 and saved_link >= 0:
		previous_link = saved_link
	option.clear()
	option.add_item("Sin mecánica")
	option.set_item_metadata(0, -1)
	var selected := 0
	for mechanic_index in range(mechanic_count):
		var key := "mechanic_%d_name" % mechanic_index
		if not fields.has(key):
			continue
		var mechanic_name: String = fields[key].text.strip_edges()
		if mechanic_name.is_empty():
			mechanic_name = "Mecánica %d" % (mechanic_index + 1)
		option.add_item(mechanic_name)
		option.set_item_metadata(option.item_count - 1, mechanic_index)
		if mechanic_index == previous_link or (saved_name == fields[key].text.strip_edges() and not saved_name.is_empty()):
			selected = option.item_count - 1
	option.select(selected)
	if selected > 0:
		var linked_index := int(option.get_item_metadata(selected))
		fields["spell_%d_mechanic_link" % index].value = linked_index
		fields["spell_%d_mechanic_name" % index].text = fields["mechanic_%d_name" % linked_index].text.strip_edges()
	else:
		fields["spell_%d_mechanic_link" % index].value = -1
	_update_spell_mechanic(index)

func _on_spell_mechanic_selected(_option_index: int, spell_index: int) -> void:
	var linked_index := _spell_linked_mechanic_index(spell_index)
	fields["spell_%d_mechanic_link" % spell_index].value = linked_index
	fields["spell_%d_mechanic_name" % spell_index].text = "" if linked_index < 0 else fields["mechanic_%d_name" % linked_index].text.strip_edges()
	_update_spell_mechanic(spell_index)

func _spell_linked_mechanic_index(index: int) -> int:
	if not spell_mechanic_options.has(index):
		return -1
	var option: OptionButton = spell_mechanic_options[index]
	if option.selected < 0:
		return -1
	return int(option.get_item_metadata(option.selected))

func _on_spell_track_value_changed(new_value: int, spell_index: int) -> void:
	var linked_index := _spell_linked_mechanic_index(spell_index)
	if linked_index >= 0:
		fields["mechanic_%d_value" % linked_index].value = new_value
	else:
		fields["spell_%d_mechanic_value" % spell_index].value = new_value

func _spell_number(index: int, suffix: String) -> int:
	var key := "spell_%d_%s" % [index, suffix]
	if not fields.has(key):
		return 0
	var text: String = fields[key].text.strip_edges()
	return maxi(int(text), 0) if text.is_valid_int() else 0

func _save_spell_card_to_library(index: int) -> void:
	var name_key := "spell_%d_name" % index
	if not fields.has(name_key):
		return
	var spell_name: String = fields[name_key].text.strip_edges().substr(0, 120)
	if spell_name.is_empty():
		_set_status("Escribe un nombre para el hechizo antes de guardarlo.", true)
		return
	var spell_data: Dictionary = {}
	for suffix in ["name", "level", "level_bonus", "casting_time", "magic_cost", "school", "range", "target", "duration", "effect", "components", "description", "mechanic_name", "mechanic_cost", "mechanic_max", "mechanic_value"]:
		var key := "spell_%d_%s" % [index, suffix]
		if not fields.has(key):
			continue
		var control = fields[key]
		if control is LineEdit or control is TextEdit:
			spell_data[suffix] = control.text
		elif control is SpinBox:
			spell_data[suffix] = control.value
	var entry := {
		"category": "Conjuro", "name": spell_name,
		"source": "Mazo de %s" % (fields.name.text if not fields.name.text.is_empty() else "personaje"),
		"notes": str(spell_data.get("description", "")).substr(0, 20000),
		"image_data": "", "image_format": "", "spell_data": spell_data,
		"updated_at": Time.get_datetime_string_from_system()
	}
	var existing_index := -1
	for library_index in range(library_catalog_entries.size()):
		if str(library_catalog_entries[library_index].get("category", "")) == "Conjuro" and str(library_catalog_entries[library_index].get("name", "")).nocasecmp_to(spell_name) == 0:
			existing_index = library_index
			break
	if existing_index >= 0:
		library_catalog_entries[existing_index] = entry
		library_catalog_selected = existing_index
	else:
		if library_catalog_entries.size() >= MAX_LIBRARY_CATALOG_ENTRIES:
			_set_status("La biblioteca alcanzó su límite de entradas.", true)
			return
		library_catalog_entries.append(entry)
		library_catalog_selected = library_catalog_entries.size() - 1
	_write_library_catalog()
	_refresh_library_catalog()
	_set_status("Hechizo guardado en la biblioteca: %s." % spell_name)

func _use_spell(index: int) -> void:
	var magic_cost := _spell_number(index, "magic_cost")
	var magic_current := maxi(int(fields.magic_current.text), 0) if fields.magic_current.text.is_valid_int() else 0
	if magic_current < magic_cost:
		_set_status("No tienes magia suficiente para usar este conjuro.", true)
		return
	var linked_index := _spell_linked_mechanic_index(index)
	var mechanic_cost := int(fields["spell_%d_mechanic_cost" % index].value)
	if linked_index >= 0 and int(fields["mechanic_%d_value" % linked_index].value) < mechanic_cost:
		_set_status("No tienes puntos suficientes de %s." % _spell_mechanic_summary(index), true)
		return
	fields.magic_current.text = str(magic_current - magic_cost)
	if linked_index >= 0:
		fields["mechanic_%d_value" % linked_index].value -= mechanic_cost
	_send_spell_to_chat(index)
	save_sheet()
	if deck_popup != null and deck_popup.visible:
		_build_deck_window.call_deferred()

func _footer() -> Control:
	var row := HBoxContainer.new()
	status_label = Label.new()
	status_label.text = "Los cambios aún no se han guardado."
	status_label.add_theme_color_override("font_color", MUTED)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status_label)
	var button := Button.new()
	button.text = "Nueva hoja"
	button.pressed.connect(clear_sheet)
	row.add_child(button)
	return row

func _section(title_text: String, content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(palette.panel, 14, palette.accent.darkened(0.35), 1, 18))
	regular_panels.append(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	body.add_child(title_row)
	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(4, 24)
	accent.color = palette.accent
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section_accents.append(accent)
	title_row.add_child(accent)
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", GOLD)
	section_titles.append(title)
	title_row.add_child(title)
	var line := HSeparator.new()
	line.modulate = palette.accent.darkened(0.35)
	body.add_child(line)
	body.add_child(content)
	return panel

func _set_palette_color(key: String, color: Color) -> void:
	palette[key] = color
	if applying_skin:
		return
	pending_palette_keys[key] = true
	# ColorPicker emite muchos cambios por segundo mientras se arrastra. Agruparlos
	# evita reconstruir cientos de StyleBox y escribir el JSON en cada píxel.
	if palette_apply_timer != null:
		palette_apply_timer.start()
	else:
		_flush_palette_changes()

func _flush_palette_changes() -> void:
	var changed_keys: Array = pending_palette_keys.keys()
	pending_palette_keys.clear()
	if changed_keys.size() == 1 and str(changed_keys[0]) == "background":
		if background_rect != null:
			background_rect.color = palette.background
	elif changed_keys.size() == 1 and str(changed_keys[0]) == "text":
		_apply_text_palette()
	else:
		_apply_palette()
	# Escribir en disco es bastante más lento en Android que cambiar un color.
	# Se guarda cuando el usuario deja de editar durante un momento.
	if appearance_save_timer != null:
		appearance_save_timer.start()
	else:
		_save_appearance(active_skin)

func _load_appearance() -> void:
	if not FileAccess.file_exists(APPEARANCE_PATH):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(APPEARANCE_PATH))
	if not saved is Dictionary:
		return
	var saved_skin := str(saved.get("skin", "Medieval antiguo"))
	if SKIN_PRESETS.has(saved_skin):
		active_skin = saved_skin
	var saved_palette: Dictionary = saved.get("palette", {})
	for key in palette:
		if saved_palette.has(key):
			palette[key] = Color.from_string(str(saved_palette[key]), palette[key])

func _save_appearance(skin_name: String) -> void:
	var saved_palette: Dictionary = {}
	for key in palette:
		saved_palette[key] = palette[key].to_html(true)
	var file := FileAccess.open(APPEARANCE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"skin": skin_name, "palette": saved_palette}, "  "))
		file.flush()
		file.close()

func _persist_appearance_now() -> void:
	# En Android, ir a Inicio puede suspender el proceso sin emitir un cierre.
	# Se aplica cualquier color pendiente y se fuerza la escritura inmediatamente.
	if palette_apply_timer != null and not palette_apply_timer.is_stopped():
		palette_apply_timer.stop()
		var changed_keys: Array = pending_palette_keys.keys()
		pending_palette_keys.clear()
		if changed_keys.size() == 1 and str(changed_keys[0]) == "background":
			if background_rect != null:
				background_rect.color = palette.background
		elif changed_keys.size() == 1 and str(changed_keys[0]) == "text":
			_apply_text_palette()
		elif not changed_keys.is_empty():
			_apply_palette()
	if appearance_save_timer != null:
		appearance_save_timer.stop()
	_save_appearance(active_skin)

func _apply_palette() -> void:
	# Los StyleBox dependen de la paleta actual; se descartan una sola vez por
	# lote y luego se comparten entre todos los controles equivalentes.
	skin_style_cache.clear()
	var skin: Dictionary = SKIN_PRESETS.get(active_skin, SKIN_PRESETS["Medieval antiguo"])
	var radius := int(skin.get("radius", 8))
	var border_width := int(skin.get("border", 1))
	var padding := int(skin.get("padding", 12))
	var spacing := int(skin.get("spacing", 10))
	var button_height := int(skin.get("button_height", 40))
	var title_size := int(skin.get("title_size", 17))
	var accent_width := int(skin.get("accent_width", 4))
	var shadow_size := int(skin.get("shadow", 0))
	if background_rect != null:
		background_rect.color = palette.background
	for type_name in ["Label", "Button", "LineEdit", "TextEdit", "SpinBox", "OptionButton", "CheckBox"]:
		ui_theme.set_color("font_color", type_name, palette.text)
	ui_theme.set_color("font_placeholder_color", "LineEdit", palette.text.darkened(0.35))
	ui_theme.set_color("font_placeholder_color", "TextEdit", palette.text.darkened(0.35))
	for type_name in ["LineEdit", "TextEdit", "SpinBox", "OptionButton"]:
		ui_theme.set_stylebox("normal", type_name, _cached_skin_box(palette.field, radius, palette.accent.darkened(0.5), border_width, padding, shadow_size))
		ui_theme.set_stylebox("focus", type_name, _cached_skin_box(palette.field, radius, palette.accent, maxi(border_width, 2), padding, shadow_size))
	ui_theme.set_stylebox("normal", "Button", _cached_skin_box(palette.panel.lightened(0.08), radius, palette.accent.darkened(0.35), border_width, padding, shadow_size))
	ui_theme.set_stylebox("hover", "Button", _cached_skin_box(palette.panel.lightened(0.16), radius, palette.accent, maxi(border_width, 1), padding, shadow_size))
	ui_theme.set_stylebox("pressed", "Button", _cached_skin_box(palette.field, radius, palette.accent, maxi(border_width, 1), padding, shadow_size))
	ui_theme.set_constant("separation", "VBoxContainer", spacing)
	ui_theme.set_constant("separation", "HBoxContainer", spacing)
	_apply_skin_to_cached_panels(radius, border_width, padding, shadow_size)
	for panel in regular_panels:
		if is_instance_valid(panel):
			panel.add_theme_stylebox_override("panel", _cached_skin_box(palette.panel, radius, palette.accent.darkened(0.35), border_width, padding, shadow_size))
	for card in attribute_cards:
		if is_instance_valid(card):
			card.add_theme_stylebox_override("panel", _cached_skin_box(palette.field.lightened(0.025), radius, palette.accent.darkened(0.35), border_width, padding, shadow_size))
	for accent in section_accents:
		if is_instance_valid(accent):
			accent.color = palette.accent
			accent.custom_minimum_size.x = accent_width
	for title in section_titles:
		if is_instance_valid(title):
			title.add_theme_color_override("font_color", palette.accent)
			title.add_theme_font_size_override("font_size", title_size)
	for card in spell_cards:
		if is_instance_valid(card):
			card.add_theme_stylebox_override("panel", _cached_skin_box(palette.panel.lightened(0.08), radius, palette.accent, maxi(border_width, 1), padding, shadow_size))
	# La navegación también cambia de densidad y forma; esto hace que un skin sea
	# una interfaz completa y no solamente una combinación de colores.
	if header_navigation != null:
		for control in header_navigation.get_children():
			if control is Button:
				control.custom_minimum_size.y = button_height
	if monster_sheet_view != null:
		monster_sheet_view.call("set_palette", palette)
	if character_sheet_view != null:
		character_sheet_view.call("set_palette", palette)
	_apply_text_palette()

func _apply_text_palette() -> void:
	for type_name in ["Label", "Button", "LineEdit", "TextEdit", "SpinBox", "OptionButton", "CheckBox"]:
		ui_theme.set_color("font_color", type_name, palette.text)
	ui_theme.set_color("font_placeholder_color", "LineEdit", palette.text.darkened(0.35))
	ui_theme.set_color("font_placeholder_color", "TextEdit", palette.text.darkened(0.35))
	if palette_font_controls.is_empty():
		_cache_palette_tree(self)
	for index in range(palette_font_controls.size() - 1, -1, -1):
		var node: Control = palette_font_controls[index]
		if not is_instance_valid(node):
			palette_font_controls.remove_at(index)
			continue
		var font_color: Color = palette.text
		if node is Label and section_titles.has(node):
			font_color = palette.accent
		node.add_theme_color_override("font_color", font_color)
		if node is LineEdit or node is TextEdit:
			node.add_theme_color_override("font_placeholder_color", palette.text.darkened(0.35))

func _cache_palette_tree(node: Node) -> void:
	_cache_palette_control(node)
	for child in node.get_children():
		_cache_palette_tree(child)

func _cache_palette_control(node: Node) -> void:
	if node is PanelContainer and not _is_map_canvas_panel(node):
		var panel := node as PanelContainer
		if panel not in skin_managed_panels:
			skin_managed_panels.append(panel)
	if node is Label or node is Button or node is LineEdit or node is TextEdit or node is SpinBox or node is OptionButton or node is CheckBox:
		if node not in palette_font_controls:
			palette_font_controls.append(node)

func _on_palette_node_added(node: Node) -> void:
	if node != self and is_ancestor_of(node):
		_cache_palette_control(node)

func _is_map_canvas_panel(panel: PanelContainer) -> bool:
	# El panel que contiene el SubViewport del mapa conserva su marco neutro para
	# no teñir ni cubrir el tablero durante un cambio de skin.
	return table_board != null and panel.is_ancestor_of(table_board)

func _apply_skin_to_cached_panels(radius: int, border_width: int, padding: int, shadow_size: int) -> void:
	if skin_managed_panels.is_empty():
		_cache_palette_tree(self)
	var style := _cached_skin_box(palette.panel, radius, palette.accent.darkened(0.35), border_width, padding, shadow_size)
	for index in range(skin_managed_panels.size() - 1, -1, -1):
		var panel: PanelContainer = skin_managed_panels[index]
		if not is_instance_valid(panel):
			skin_managed_panels.remove_at(index)
			continue
		if not _is_map_canvas_panel(panel):
			panel.add_theme_stylebox_override("panel", style)

func _add_field(parent: Container, label_text: String, key: String, placeholder: String, wide := false) -> void:
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wide:
		holder.custom_minimum_size.x = 220
	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", MUTED)
	holder.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(edit)
	fields[key] = edit
	parent.add_child(holder)

func _update_modifier(key: String, value: int) -> void:
	var modifier := floori((value - 10) / 2.0)
	stat_mods[key].text = ("+" if modifier >= 0 else "") + str(modifier)

func _on_stat_changed(key: String, value: int) -> void:
	_update_modifier(key, value)
	_update_skills()
	_update_magic_bonus()

func _update_magic_bonus() -> void:
	if magic_bonus_label == null or not option_fields.has("magic_ability"):
		return
	var ability: OptionButton = option_fields.magic_ability
	var keys := ["inteligencia", "sabiduria", "carisma"]
	var stat_value := int(stat_spins[keys[ability.selected]].value)
	var stat_bonus := floori((stat_value - 10) / 2.0)
	var proficiency_text: String = fields.magic_proficiency.text.replace("+", "").strip_edges()
	var proficiency: int = int(proficiency_text) if proficiency_text.is_valid_int() else 0
	var total := stat_bonus + proficiency
	magic_bonus_label.text = ("+" if total >= 0 else "") + str(total)

func _update_hp() -> void:
	var current: float = float(fields.hp_current.text) if fields.hp_current.text.is_valid_float() else 0.0
	var maximum: float = float(fields.hp_max.text) if fields.hp_max.text.is_valid_float() else 1.0
	hp_bar.value = clampf(current / maxf(maximum, 1.0) * 100.0, 0.0, 100.0)
	hp_bar.tooltip_text = "%d / %d puntos de vida" % [int(current), int(maximum)]

func _setup_sheet_protection() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEET_BACKUP_DIR))
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_SECONDS
	autosave_timer.one_shot = false
	autosave_timer.timeout.connect(_autosave_sheet_if_needed)
	add_child(autosave_timer)
	autosave_timer.start()
	recovery_dialog = ConfirmationDialog.new()
	recovery_dialog.title = "Recuperar hoja"
	recovery_dialog.ok_button_text = "Recuperar cambios"
	recovery_dialog.cancel_button_text = "Descartar"
	recovery_dialog.confirmed.connect(_restore_recovered_sheet)
	recovery_dialog.canceled.connect(_discard_sheet_recovery)
	add_child(recovery_dialog)

func _sheet_fingerprint(data: Dictionary) -> String:
	# No se incluye updated_at para que la fecha no provoque guardados infinitos.
	var comparable := data.duplicate(true)
	comparable.erase("metadata")
	return JSON.stringify(comparable)

func _current_sheet_data() -> Dictionary:
	var data := _collect_data()
	data.metadata = {
		"name": sheet_name_edit.text.strip_edges() if not sheet_name_edit.text.strip_edges().is_empty() else "Hoja sin nombre",
		"type": sheet_type_option.get_item_text(sheet_type_option.selected),
		"updated_at": Time.get_datetime_string_from_system()
	}
	return data

func _autosave_sheet_if_needed() -> void:
	if current_sheet_file.is_empty() or sheet_name_edit == null or fields.is_empty():
		return
	var data := _current_sheet_data()
	var fingerprint := _sheet_fingerprint(data)
	if fingerprint == last_sheet_fingerprint:
		return
	# El borrador se escribe primero: si el proceso termina durante el guardado
	# principal, el siguiente inicio todavía puede recuperar estos datos.
	_write_recovery_file(current_sheet_file, data)
	_backup_sheet_file(current_sheet_file)
	if _write_sheet_file(current_sheet_file, data):
		last_sheet_fingerprint = fingerprint
		_discard_sheet_recovery()
		_set_status("Guardado automático completado.")

func _write_sheet_file(filename: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEETS_DIR))
	var file := FileAccess.open(SHEETS_DIR + "/" + filename, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return true

func _write_recovery_file(filename: String, data: Dictionary) -> void:
	var file := FileAccess.open(SHEET_RECOVERY_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"sheet_file": filename, "saved_at": Time.get_datetime_string_from_system(), "data": data}, "  "))
	file.close()

func _backup_sheet_file(filename: String) -> void:
	var source_path := SHEETS_DIR + "/" + filename
	if not FileAccess.file_exists(source_path):
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEET_BACKUP_DIR))
	var backup_name := "%s__backup__%d_%d.json" % [filename.get_basename(), int(Time.get_unix_time_from_system()), randi_range(1000, 9999)]
	var backup := FileAccess.open(SHEET_BACKUP_DIR + "/" + backup_name, FileAccess.WRITE)
	if backup == null:
		return
	backup.store_buffer(FileAccess.get_file_as_bytes(source_path))
	backup.close()
	_prune_sheet_backups(filename.get_basename())

func _prune_sheet_backups(sheet_basename: String) -> void:
	var directory := DirAccess.open(SHEET_BACKUP_DIR)
	if directory == null:
		return
	var matching: Array[String] = []
	for filename in directory.get_files():
		if filename.begins_with(sheet_basename + "__backup__") and filename.ends_with(".json"):
			matching.append(filename)
	matching.sort()
	while matching.size() > MAX_SHEET_BACKUPS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SHEET_BACKUP_DIR + "/" + matching.pop_front()))

func _check_sheet_recovery() -> void:
	if not FileAccess.file_exists(SHEET_RECOVERY_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SHEET_RECOVERY_PATH))
	if not parsed is Dictionary or not parsed.get("data", {}) is Dictionary:
		_discard_sheet_recovery()
		return
	var recovered: Dictionary = parsed.get("data", {})
	var filename := str(parsed.get("sheet_file", ""))
	if filename.is_empty():
		_discard_sheet_recovery()
		return
	var current_path := SHEETS_DIR + "/" + filename
	if FileAccess.file_exists(current_path):
		var current = JSON.parse_string(FileAccess.get_file_as_string(current_path))
		if current is Dictionary and _sheet_fingerprint(current) == _sheet_fingerprint(recovered):
			_discard_sheet_recovery()
			return
	pending_recovery_data = parsed
	var metadata: Dictionary = recovered.get("metadata", {})
	recovery_dialog.dialog_text = "Se encontraron cambios recuperables de ‘%s’ (%s)." % [str(metadata.get("name", "Hoja")), str(parsed.get("saved_at", "fecha desconocida"))]
	_popup_centered_safe(recovery_dialog, Vector2i(520, 190))

func _restore_recovered_sheet() -> void:
	if pending_recovery_data.is_empty():
		return
	var recovered: Dictionary = pending_recovery_data.get("data", {})
	current_sheet_file = str(pending_recovery_data.get("sheet_file", ""))
	_apply_data(recovered)
	var metadata: Dictionary = recovered.get("metadata", {})
	sheet_name_edit.text = str(metadata.get("name", "Hoja recuperada"))
	var type_name := str(metadata.get("type", "Personaje"))
	for index in range(sheet_type_option.item_count):
		if sheet_type_option.get_item_text(index) == type_name:
			sheet_type_option.select(index)
			break
	_update_sheet_type_view()
	last_sheet_fingerprint = ""
	save_sheet()
	_discard_sheet_recovery()
	_show_page(0)
	_set_status("Hoja recuperada y guardada correctamente.")

func _discard_sheet_recovery() -> void:
	pending_recovery_data.clear()
	if FileAccess.file_exists(SHEET_RECOVERY_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SHEET_RECOVERY_PATH))

func save_sheet() -> void:
	if current_sheet_file.is_empty():
		_show_sheets_manager()
		_set_status("Crea o selecciona una hoja antes de guardar.", true)
		return
	var data := _current_sheet_data()
	_backup_sheet_file(current_sheet_file)
	if not _write_sheet_file(current_sheet_file, data):
		_set_status("No se pudo guardar la hoja.", true)
		return
	last_sheet_fingerprint = _sheet_fingerprint(data)
	_discard_sheet_recovery()
	if table_board != null and table_board.selected_token >= 0 and table_board.get_selected_sheet() == current_sheet_file:
		var health := _active_sheet_health()
		table_board.set_selected_sheet_snapshot(str(data.metadata.name), health.x, health.y)
		_refresh_chat()
	var peer := multiplayer.multiplayer_peer
	if table_board != null and multiplayer.is_server() and peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		table_board.share_sheet_to_all(current_sheet_file)
	_set_status("Hoja guardada: " + str(data.metadata.name))

func load_sheet() -> void:
	if current_sheet_file.is_empty():
		_show_sheets_manager()
		_set_status("Selecciona una hoja para cargar.")
		return
	var path := SHEETS_DIR + "/" + current_sheet_file
	if not FileAccess.file_exists(path):
		_set_status("No se encontró la hoja seleccionada.", true)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_set_status("El archivo guardado no es válido.", true)
		return
	_apply_data(parsed)
	var metadata: Dictionary = parsed.get("metadata", {})
	sheet_name_edit.text = str(metadata.get("name", "Hoja sin nombre"))
	var type_name := str(metadata.get("type", "Personaje"))
	for index in range(sheet_type_option.item_count):
		if sheet_type_option.get_item_text(index) == type_name:
			sheet_type_option.select(index)
			break
	_update_sheet_type_view()
	_update_monster_hp()
	last_sheet_fingerprint = _sheet_fingerprint(parsed)
	_set_status("Hoja cargada: " + sheet_name_edit.text)

func _collect_data() -> Dictionary:
	var data := {"fields": {}, "stats": {}, "options": {}, "colors": {}, "proficiency_lists": {}, "spell_count": spell_count, "inventory_count": inventory_count, "mechanic_count": mechanic_count}
	for key in fields:
		var control = fields[key]
		if control is LineEdit or control is TextEdit:
			data.fields[key] = control.text
		elif control is SpinBox:
			data.fields[key] = control.value
		elif control is ColorPickerButton:
			data.fields[key] = control.color.to_html(true)
		elif control is Dictionary:
			var dictionary_data := {"trained": control.check.button_pressed, "value": control.value.text}
			if control.has("ability_option") and control.ability_option is OptionButton:
				dictionary_data["ability"] = control.ability_option.selected
			dictionary_data["adjustment"] = int(control.get("manual_adjustment", 0))
			data.fields[key] = dictionary_data
	for key in stat_spins:
		data.stats[key] = stat_spins[key].value
	for key in option_fields:
		if option_fields[key] is OptionButton:
			data.options[key] = option_fields[key].selected
	for key in palette:
		data.colors[key] = palette[key].to_html(true)
	for key in proficiency_lists:
		var values: Array[String] = []
		for edit in proficiency_lists[key]:
			if is_instance_valid(edit) and not edit.text.strip_edges().is_empty():
				values.append(edit.text.strip_edges())
		data.proficiency_lists[key] = values
	return data

func _apply_data(data: Dictionary) -> void:
	var target_spell_count := maxi(int(data.get("spell_count", 3)), 0)
	while spell_count < target_spell_count:
		_add_spell_card()
	while spell_count > target_spell_count:
		_remove_spell_card()
	var target_inventory_count := maxi(int(data.get("inventory_count", 5)), 0)
	while inventory_count < target_inventory_count:
		_add_inventory_row()
	while inventory_count > target_inventory_count:
		_remove_inventory_row()
	var target_mechanic_count := maxi(int(data.get("mechanic_count", 2)), 0)
	while mechanic_count < target_mechanic_count:
		_add_mechanic_row()
	while mechanic_count > target_mechanic_count:
		_remove_mechanic_row()
	# Evita que hojas antiguas hereden campos añadidos posteriormente desde el
	# monstruo que estaba abierto antes.
	for key in fields:
		if not str(key).begins_with("monster_"):
			continue
		var monster_control = fields[key]
		if monster_control is LineEdit or monster_control is TextEdit:
			monster_control.text = ""
		elif monster_control is SpinBox:
			monster_control.value = 10
	var saved_fields: Dictionary = data.get("fields", {})
	for key in saved_fields:
		if not fields.has(key):
			continue
		var control = fields[key]
		if control is LineEdit or control is TextEdit:
			control.text = str(saved_fields[key])
		elif control is SpinBox:
			control.value = float(saved_fields[key])
		elif control is ColorPickerButton:
			control.color = Color.from_string(str(saved_fields[key]), control.color)
		elif control is Dictionary and saved_fields[key] is Dictionary:
			control.check.button_pressed = saved_fields[key].get("trained", false)
			control.value.text = str(saved_fields[key].get("value", ""))
			control["manual_adjustment"] = int(saved_fields[key].get("adjustment", 0))
			if control.has("ability_option") and control.ability_option is OptionButton and saved_fields[key].has("ability"):
				control.ability_option.select(clampi(int(saved_fields[key].get("ability", 0)), 0, control.ability_option.item_count - 1))
	var saved_proficiencies: Dictionary = data.get("proficiency_lists", {})
	for key in proficiency_lists:
		var values: Array[String] = []
		if saved_proficiencies.has(key) and saved_proficiencies[key] is Array:
			for value in saved_proficiencies[key]:
				if not str(value).strip_edges().is_empty():
					values.append(str(value).strip_edges())
		elif saved_fields.has(key):
			# Convierte automáticamente los cuadros usados por hojas antiguas.
			values = _legacy_proficiency_values(saved_fields[key])
		_replace_proficiency_items(str(key), values)
	# Compatibilidad con las dos cajas de texto usadas brevemente por las
	# versiones anteriores de las cartas.
	for index in range(spell_count):
		var old_name_key := "spell_%d_mechanic" % index
		var new_name_key := "spell_%d_mechanic_name" % index
		if saved_fields.has(old_name_key) and fields.has(new_name_key) and fields[new_name_key].text.is_empty():
			fields[new_name_key].text = str(saved_fields[old_name_key])
		var old_cost_key := "spell_%d_mechanic_cost" % index
		var new_value_key := "spell_%d_mechanic_value" % index
		if saved_fields.has(old_cost_key) and fields.has(new_value_key):
			fields[new_value_key].value = absf(float(saved_fields[old_cost_key]))
	var saved_stats: Dictionary = data.get("stats", {})
	for key in saved_stats:
		if stat_spins.has(key):
			stat_spins[key].value = saved_stats[key]
	var saved_options: Dictionary = data.get("options", {})
	for key in saved_options:
		if option_fields.has(key) and option_fields[key] is OptionButton:
			option_fields[key].select(int(saved_options[key]))
	# La apariencia es una preferencia del dispositivo, no de la hoja. Las
	# versiones antiguas guardaban "colors" dentro de cada archivo y eso hacía
	# que abrir una hoja cambiara el skin activo. Conservamos esos datos para no
	# romper exportaciones viejas, pero ya no se aplican ni se guardan aquí.
	# Si algún día quieres estilos por hoja, crea una opción explícita para ello.
	_update_hp()
	_update_monster_hp()
	_update_experience()
	_update_inventory_weight()
	for index in mechanic_tracks:
		_update_mechanic(index)
	_refresh_spell_mechanic_options()
	for index in spell_mechanic_tracks:
		_update_spell_mechanic(index)
	_update_magic_bonus()
	_update_skills()

func clear_sheet() -> void:
	for control in fields.values():
		if control is LineEdit or control is TextEdit:
			control.text = ""
		elif control is SpinBox:
			control.value = 0
		elif control is Dictionary:
			control.check.button_pressed = false
			control.value.text = ""
			control["manual_adjustment"] = 0
			if control.has("ability_option") and control.ability_option is OptionButton:
				var default_ability := str(control.get("default_ability", ""))
				for index in range(control.ability_option.item_count):
					if str(control.ability_option.get_item_metadata(index)) == default_ability:
						control.ability_option.select(index)
						break
	for key in proficiency_lists:
		_replace_proficiency_items(str(key), [])
	for spin in stat_spins.values():
		spin.value = 10
	for option in option_fields.values():
		if option is OptionButton:
			option.select(0)
	fields.hp_current.text = "10"
	fields.hp_max.text = "10"
	fields.level.text = "1"
	fields.experience.text = "0"
	fields.magic_proficiency.text = "+2"
	fields.monster_hp_current.text = "45"
	fields.monster_hp_max.text = "45"
	fields.monster_ac.text = "15"
	_update_hp()
	_update_monster_hp()
	_update_experience()
	_update_inventory_weight()
	_update_magic_bonus()
	_update_skills()
	_set_status("Nueva hoja lista para editar.")

func _set_status(message: String, is_error := false) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("#d97668") if is_error else Color("#8fbd83"))

func _resize() -> void:
	var phone_layout := _is_phone_layout()
	var compact := size.x < 900.0 or phone_layout
	if root_margin != null:
		var horizontal_margin := 10 if phone_layout else (18 if compact else 28)
		root_margin.add_theme_constant_override("margin_left", horizontal_margin)
		root_margin.add_theme_constant_override("margin_right", horizontal_margin)
		root_margin.add_theme_constant_override("margin_top", 12 if phone_layout else 24)
		root_margin.add_theme_constant_override("margin_bottom", 20 if phone_layout else 40)
	if header_layout != null:
		header_layout.vertical = phone_layout
	if header_left_slot != null:
		header_left_slot.hide()
	if header_type_slot != null:
		header_type_slot.custom_minimum_size.x = 0 if phone_layout else 150
		header_type_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL if phone_layout else Control.SIZE_SHRINK_END
	if header_sheet_type_option != null:
		header_sheet_type_option.custom_minimum_size = Vector2(0 if phone_layout else 150, 42 if phone_layout else 34)
	if library_catalog_layout != null:
		library_catalog_layout.vertical = compact
	if identity_layout != null:
		identity_layout.vertical = compact
	if attributes_grid != null:
		attributes_grid.columns = 2 if compact else 3
	for row in responsive_sheet_rows:
		if is_instance_valid(row):
			row.vertical = compact
	for skill_row in skill_rows:
		if is_instance_valid(skill_row):
			skill_row.vertical = phone_layout or size.x < 520.0
	if monster_sheet_view != null:
		monster_sheet_view.call("set_compact", compact)
	_refresh_spell_layout()
	if character_sheet_view != null:
		character_sheet_view.call("set_compact", compact)
	if library_layout != null:
		library_layout.vertical = compact
	if library_sidebar_panel != null:
		library_sidebar_panel.custom_minimum_size = Vector2(0, 300) if compact else Vector2(285, 0)
	if table_media_preview_layout != null:
		table_media_preview_layout.vertical = phone_layout or size.x < 700.0
	var table_mobile := phone_layout
	if table_layout != null:
		table_layout.vertical = table_mobile
	if table_left_panel != null:
		table_left_panel.custom_minimum_size = Vector2(0, 58) if table_mobile else Vector2(72, 0)
	if table_right_panel != null:
		if table_mobile:
			table_right_panel.custom_minimum_size = Vector2(0, 0)
			table_right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			table_right_panel.custom_minimum_size = Vector2(190 if size.x < 1100.0 else 210, 0)
	if table_left_rail != null:
		table_left_rail.vertical = not table_mobile
	if table_left_scroll != null:
		table_left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if table_mobile else ScrollContainer.SCROLL_MODE_DISABLED
		table_left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if table_mobile else ScrollContainer.SCROLL_MODE_AUTO
	var compact_tools: bool = phone_layout or size.x < 1100.0
	if table_right_rail != null:
		table_right_rail.add_theme_constant_override("separation", 6 if compact_tools else 8)
	for header in table_section_headers:
		if is_instance_valid(header):
			header.custom_minimum_size.y = 30 if compact_tools else 32
			header.add_theme_font_size_override("font_size", 11 if compact_tools else 12)
	if table_right_rail != null:
		for node in table_right_rail.find_children("*", "Button", true, false):
			if node is Button and node not in table_section_headers:
				node.custom_minimum_size.y = 34 if compact_tools else 38
				node.add_theme_font_size_override("font_size", 12 if compact_tools else 13)
	# Al entrar por primera vez al formato móvil dejamos abiertas las herramientas
	# básicas y plegamos las secciones avanzadas para evitar una página enorme.
	if table_mobile and not table_mobile_layout_active:
		for header in table_section_headers:
			if not is_instance_valid(header):
				continue
			var title: String = str(header.get_meta("section_title", ""))
			_set_table_section_expanded(header, "MAPA" in title or "PLANTILLAS" in title)
	table_mobile_layout_active = table_mobile
	# Se difiere un frame para que Godot termine de actualizar el tamaño del
	# viewport tras una rotación antes de recolocar las ventanas emergentes.
	_fit_floating_windows_to_viewport.call_deferred()
