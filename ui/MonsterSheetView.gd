extends VBoxContainer

# Hoja compacta e independiente para monstruos.
# PERSONALIZACIÓN: agrega campos en _build_interface(); CharacterSheet.gd los
# guardará automáticamente mientras estén registrados en `fields`.

signal health_changed(current: float, maximum: float)
signal save_to_library_requested
signal share_to_table_requested
signal open_bestiary_requested
signal send_to_chat_requested

var fields: Dictionary = {}
var hp_bar: ProgressBar
var panels: Array[PanelContainer] = []
var stat_cards: Array[PanelContainer] = []
var section_titles: Array[Label] = []
var section_accents: Array[ColorRect] = []
var field_labels: Array[Label] = []
var stat_accent_labels: Array[Label] = []
var accent := Color("#c99a52")
var panel_color := Color("#211f22")
var text_color := Color("#eadfc4")
var _built := false
var vitals_grid: GridContainer
var stats_grid: GridContainer
var details_grid: GridContainer
var hp_status_label: Label

func build() -> void:
	if _built:
		return
	_built = true
	add_theme_constant_override("separation", 14)
	_build_interface()

func _ready() -> void:
	build()

func _build_interface() -> void:
	var identity := VBoxContainer.new()
	var identity_hint := Label.new()
	identity_hint.text = "BLOQUE DE CRIATURA"
	identity_hint.add_theme_font_size_override("font_size", 11)
	identity_hint.add_theme_color_override("font_color", accent)
	stat_accent_labels.append(identity_hint)
	identity.add_child(identity_hint)
	_add_line_field(identity, "Nombre", "monster_name", "NOMBRE DEL MONSTRUO", 24)
	_add_line_field(identity, "Descripción", "monster_description", "Grande aberración, caótico maligno…")
	add_child(_section("MONSTRUO", identity))

	var vitals := GridContainer.new()
	vitals_grid = vitals
	vitals.columns = 3
	vitals.add_theme_constant_override("h_separation", 10)
	vitals.add_theme_constant_override("v_separation", 10)
	for definition in [
		["Clase de armadura", "monster_ac", "15"], ["PV actuales", "monster_hp_current", "45"],
		["PV máximos", "monster_hp_max", "45"], ["Dados de golpe", "monster_hit_dice", "6d10 + 12"],
		["Velocidad", "monster_speed", "30 pies"], ["Iniciativa", "monster_initiative", "+2"]
	]:
		_add_field(vitals, definition[0], definition[1], definition[2])
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size.y = 22
	hp_status_label = Label.new()
	hp_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_status_label.add_theme_font_size_override("font_size", 12)
	hp_status_label.add_theme_color_override("font_color", accent)
	fields.monster_hp_current.text_changed.connect(func(_text: String): _update_health())
	fields.monster_hp_max.text_changed.connect(func(_text: String): _update_health())
	var vital_box := VBoxContainer.new()
	vital_box.add_child(vitals)
	vital_box.add_child(hp_bar)
	vital_box.add_child(hp_status_label)
	add_child(_section("COMBATE", vital_box))

	var stats := GridContainer.new()
	stats_grid = stats
	stats.columns = 6
	stats.add_theme_constant_override("h_separation", 8)
	stats.add_theme_constant_override("v_separation", 8)
	for definition in [["FUE", "str"], ["DES", "dex"], ["CON", "con"], ["INT", "int"], ["SAB", "wis"], ["CAR", "cha"]]:
		stats.add_child(_stat(definition[0], definition[1]))
	add_child(_section("ATRIBUTOS", stats))

	var details := GridContainer.new()
	details_grid = details
	details.columns = 2
	details.add_theme_constant_override("h_separation", 12)
	details.add_theme_constant_override("v_separation", 10)
	for definition in [
		["Salvaciones", "monster_saves", "DES +5, SAB +3"], ["Habilidades", "monster_skills", "Percepción +5, Sigilo +4"],
		["Vulnerabilidades", "monster_vulnerabilities", "—"], ["Resistencias", "monster_resistances", "fuego; daño no mágico"],
		["Inmunidades al daño", "monster_immunities", "veneno"], ["Inmunidades a estados", "monster_condition_immunities", "asustado, envenenado"],
		["Sentidos", "monster_senses", "visión en la oscuridad 60 pies"], ["Idiomas", "monster_languages", "común, dracónico"],
		["Desafío", "monster_challenge", "4 (1.100 PX)"], ["Competencia", "monster_proficiency", "+2"]
	]:
		_add_field(details, definition[0], definition[1], definition[2])
	add_child(_section("INFORMACIÓN", details))

	for definition in [
		["RASGOS", "monster_traits", "Escribe aquí rasgos pasivos o especiales…"],
		["ACCIONES", "monster_actions", "Mordisco. Ataque cuerpo a cuerpo…"],
		["REACCIONES", "monster_reactions", "Añade reacciones si las tiene…"],
		["ACCIONES LEGENDARIAS", "monster_legendary_actions", "Opcional: añade acciones legendarias…"]
	]:
		var edit := TextEdit.new()
		edit.placeholder_text = definition[2]
		edit.custom_minimum_size.y = 150 if definition[1] == "monster_actions" else 105
		fields[definition[1]] = edit
		add_child(_section(definition[0], edit))
	# PERSONALIZACIÓN: esta sección queda al final para que pueda crecer sin
	# comprimir el bloque de estadísticas y combate del monstruo.
	var lore := TextEdit.new()
	lore.placeholder_text = "Historia, origen, comportamiento, territorio, rumores, relaciones y secretos del monstruo…"
	lore.custom_minimum_size.y = 230
	lore.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	fields.monster_lore = lore
	add_child(_section("LORE", lore))
	var template_buttons := HFlowContainer.new()
	template_buttons.add_theme_constant_override("h_separation", 8)
	template_buttons.add_theme_constant_override("v_separation", 8)
	add_child(template_buttons)
	var save_template := Button.new()
	save_template.text = "▣ Guardar monstruo en biblioteca"
	save_template.tooltip_text = "Conserva todos los datos como una plantilla reutilizable y compartible"
	save_template.custom_minimum_size.y = 46
	save_template.custom_minimum_size.x = 210
	save_template.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_template.pressed.connect(func(): save_to_library_requested.emit())
	template_buttons.add_child(save_template)
	var share_template := Button.new()
	share_template.text = "◎ Compartir online"
	share_template.tooltip_text = "Guarda y envía esta plantilla a los jugadores conectados"
	share_template.custom_minimum_size.y = 46
	share_template.custom_minimum_size.x = 180
	share_template.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	share_template.pressed.connect(func(): share_to_table_requested.emit())
	template_buttons.add_child(share_template)
	var open_bestiary := Button.new()
	open_bestiary.text = "☠ Abrir bestiario"
	open_bestiary.tooltip_text = "Abre la biblioteca mostrando solamente enemigos"
	open_bestiary.custom_minimum_size = Vector2(180, 46)
	open_bestiary.pressed.connect(func(): open_bestiary_requested.emit())
	template_buttons.add_child(open_bestiary)
	var send_chat := Button.new()
	send_chat.text = "☷ Enviar al chat"
	send_chat.tooltip_text = "Publica el bloque de combate para consultarlo durante la partida"
	send_chat.custom_minimum_size = Vector2(180, 46)
	send_chat.pressed.connect(func(): send_to_chat_requested.emit())
	template_buttons.add_child(send_chat)
	_update_health()

func _add_line_field(parent: Container, label_text: String, key: String, placeholder: String, font_size := 16) -> void:
	_add_field(parent, label_text, key, placeholder)
	var edit: LineEdit = fields[key]
	edit.add_theme_font_size_override("font_size", font_size)

func _add_field(parent: Container, label_text: String, key: String, placeholder: String) -> void:
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", text_color.darkened(0.28))
	field_labels.append(label)
	holder.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(edit)
	fields[key] = edit
	parent.add_child(holder)

func _stat(label_text: String, key: String) -> Control:
	var card := PanelContainer.new()
	stat_cards.append(card)
	var holder := VBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.add_theme_constant_override("separation", 4)
	card.add_child(holder)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", accent)
	stat_accent_labels.append(label)
	holder.add_child(label)
	var score := SpinBox.new()
	score.min_value = 1
	# Igual que en la hoja de personaje, las criaturas personalizadas pueden
	# superar los límites habituales de D&D sin que la interfaz las recorte.
	score.max_value = 1_000_000_000
	score.allow_greater = true
	score.value = 10
	score.custom_minimum_size.x = 90
	fields["monster_%s" % key] = score
	holder.add_child(score)
	var modifier := Label.new()
	modifier.text = "+0"
	modifier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modifier.add_theme_font_size_override("font_size", 20)
	modifier.add_theme_color_override("font_color", accent)
	stat_accent_labels.append(modifier)
	holder.add_child(modifier)
	score.value_changed.connect(func(value: float):
		var bonus: int = floori((value - 10.0) / 2.0)
		modifier.text = ("+" if bonus >= 0 else "") + str(bonus)
	)
	_style_stat_card(card)
	return card

func _section(title_text: String, content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panels.append(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 9)
	body.add_child(title_row)
	var marker := ColorRect.new()
	marker.custom_minimum_size = Vector2(4, 23)
	marker.color = accent
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section_accents.append(marker)
	title_row.add_child(marker)
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", accent)
	section_titles.append(title)
	title_row.add_child(title)
	var separator := HSeparator.new()
	separator.modulate = accent.darkened(0.42)
	body.add_child(separator)
	body.add_child(content)
	_style_panel(panel)
	return panel

func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = accent.darkened(0.45)
	style.set_border_width_all(1)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)

func _style_stat_card(card: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color.lightened(0.045)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.border_color = accent.darkened(0.35)
	style.set_border_width_all(1)
	style.set_content_margin_all(9)
	card.add_theme_stylebox_override("panel", style)

func _style_health_bar(health_ratio: float) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = panel_color.darkened(0.2)
	background.corner_radius_top_left = 7
	background.corner_radius_top_right = 7
	background.corner_radius_bottom_left = 7
	background.corner_radius_bottom_right = 7
	background.border_color = accent.darkened(0.55)
	background.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#b84d45") if health_ratio <= 0.25 else (Color("#c98245") if health_ratio <= 0.5 else Color("#6f9b62"))
	fill.corner_radius_top_left = 7
	fill.corner_radius_top_right = 7
	fill.corner_radius_bottom_left = 7
	fill.corner_radius_bottom_right = 7
	hp_bar.add_theme_stylebox_override("background", background)
	hp_bar.add_theme_stylebox_override("fill", fill)

func set_palette(colors: Dictionary) -> void:
	panel_color = colors.get("panel", panel_color)
	accent = colors.get("accent", accent)
	text_color = colors.get("text", text_color)
	for panel in panels:
		if is_instance_valid(panel):
			_style_panel(panel)
	_recolor(self)
	for card in stat_cards:
		if is_instance_valid(card):
			_style_stat_card(card)
	for marker in section_accents:
		if is_instance_valid(marker):
			marker.color = accent
	for title in section_titles:
		if is_instance_valid(title):
			title.add_theme_color_override("font_color", accent)
	for label in field_labels:
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", text_color.darkened(0.28))
	for label in stat_accent_labels:
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", accent)
	if hp_status_label != null:
		hp_status_label.add_theme_color_override("font_color", accent)
	_update_health()

func _recolor(node: Node) -> void:
	if node is Label or node is Button or node is LineEdit or node is TextEdit or node is SpinBox:
		node.add_theme_color_override("font_color", text_color)
	for child in node.get_children():
		_recolor(child)

func _update_health() -> void:
	var current: float = float(fields.monster_hp_current.text) if fields.monster_hp_current.text.is_valid_float() else 0.0
	var maximum: float = float(fields.monster_hp_max.text) if fields.monster_hp_max.text.is_valid_float() else 1.0
	var ratio := clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	hp_bar.value = ratio * 100.0
	hp_bar.tooltip_text = "%d / %d puntos de vida" % [int(current), int(maximum)]
	if hp_status_label != null:
		hp_status_label.text = "%d / %d PV  ·  %d%%" % [int(current), int(maximum), roundi(ratio * 100.0)]
	_style_health_bar(ratio)
	health_changed.emit(current, maximum)

func refresh_health() -> void:
	_update_health()

func set_compact(enabled: bool) -> void:
	# PERSONALIZACIÓN: estos valores controlan cuántos campos aparecen por fila.
	# En celular se priorizan controles grandes y legibles sobre una fila extensa.
	if vitals_grid != null:
		vitals_grid.columns = 2 if enabled else 3
	if stats_grid != null:
		stats_grid.columns = 2 if enabled else 6
	if details_grid != null:
		details_grid.columns = 1 if enabled else 2
