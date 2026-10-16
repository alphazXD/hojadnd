extends VBoxContainer

# Estructura visual independiente de la hoja de personaje.
# Los controles y cálculos siguen siendo compartidos con CharacterSheet.gd para
# conservar compatibilidad con todas las hojas guardadas anteriormente.

var columns: BoxContainer
var left_column: VBoxContainer
var right_column: VBoxContainer
var column_headings: Array[Label] = []
var accent := Color("#c99a52")
var _configured := false

func configure(identity: Control, stats: Control, skills: Control, proficiencies: Control, combat: Control, notes: Control) -> void:
	if _configured:
		return
	_configured = true
	add_theme_constant_override("separation", 16)
	add_child(identity)
	var divider := HSeparator.new()
	divider.modulate = accent.darkened(0.45)
	divider.name = "IdentityDivider"
	add_child(divider)
	columns = BoxContainer.new()
	columns.vertical = false
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	add_child(columns)
	left_column = VBoxContainer.new()
	right_column = VBoxContainer.new()
	for column in [left_column, right_column]:
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.custom_minimum_size.x = 340
		column.add_theme_constant_override("separation", 14)
		columns.add_child(column)
	left_column.add_child(_column_heading("PERFIL Y APTITUDES", "◆"))
	left_column.add_child(stats)
	left_column.add_child(skills)
	left_column.add_child(proficiencies)
	right_column.add_child(_column_heading("COMBATE Y RELATO", "✦"))
	right_column.add_child(combat)
	right_column.add_child(notes)

func _column_heading(text: String, symbol: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := Label.new()
	icon.text = symbol
	icon.add_theme_color_override("font_color", accent)
	icon.add_theme_font_size_override("font_size", 16)
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", accent)
	label.add_theme_font_size_override("font_size", 13)
	column_headings.append(icon)
	column_headings.append(label)
	row.add_child(label)
	return row

func set_palette(colors: Dictionary) -> void:
	accent = colors.get("accent", accent)
	for label in column_headings:
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", accent)
	var divider := get_node_or_null("IdentityDivider") as HSeparator
	if divider != null:
		divider.modulate = accent.darkened(0.45)

func set_compact(enabled: bool) -> void:
	if columns != null:
		columns.vertical = enabled
		columns.add_theme_constant_override("separation", 14 if enabled else 18)
	if left_column != null:
		left_column.custom_minimum_size.x = 0 if enabled else 340
	if right_column != null:
		right_column.custom_minimum_size.x = 0 if enabled else 340
