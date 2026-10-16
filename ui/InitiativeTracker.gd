extends PanelContainer

# Rastreador de iniciativa independiente. El controlador principal solo le
# entrega fichas y recibe avisos de turno/estado para guardar y sincronizar.
signal state_changed
signal turn_announced(message: String)
signal add_selected_requested
signal status_effects_changed(token_index: int, effects: Array[String])
signal hit_points_changed(token_index: int, current: float, maximum: float)

var combatants: Array[Dictionary] = []
var current_turn := -1
var round_number := 1
var list: ItemList
var round_label: Label
var initiative_spin: SpinBox
var status_edit: LineEdit
var hp_current_spin: SpinBox
var hp_max_spin: SpinBox
var hp_change_spin: SpinBox
var _applying := false
var editable := true
var editable_controls: Array[Control] = []
var mode_label: Label

func _ready() -> void:
	_build_interface()
	_refresh()

func _build_interface() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "⚔  ORDEN DE INICIATIVA"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	round_label = Label.new()
	header.add_child(round_label)
	mode_label = Label.new()
	mode_label.add_theme_color_override("font_color", Color("#c99a52"))
	header.add_child(mode_label)
	body.add_child(header)
	var add_button := Button.new()
	add_button.text = "＋ Añadir ficha y tirar d20"
	add_button.tooltip_text = "Añade la ficha seleccionada de la mesa y tira 1d20"
	add_button.pressed.connect(func(): add_selected_requested.emit())
	body.add_child(add_button)
	editable_controls.append(add_button)

	list = ItemList.new()
	list.custom_minimum_size = Vector2(280, 260)
	list.item_selected.connect(_on_selected)
	body.add_child(list)

	var editor := GridContainer.new()
	editor.columns = 2
	var initiative_label := Label.new()
	initiative_label.text = "INICIATIVA"
	editor.add_child(initiative_label)
	initiative_spin = SpinBox.new()
	initiative_spin.min_value = -99
	initiative_spin.max_value = 999
	initiative_spin.value_changed.connect(_edit_initiative)
	editor.add_child(initiative_spin)
	editable_controls.append(initiative_spin)
	var hp_current_label := Label.new()
	hp_current_label.text = "PV ACTUALES"
	editor.add_child(hp_current_label)
	hp_current_spin = SpinBox.new()
	hp_current_spin.min_value = -999999
	hp_current_spin.max_value = 999999
	hp_current_spin.value_changed.connect(_edit_hit_points)
	editor.add_child(hp_current_spin)
	editable_controls.append(hp_current_spin)
	var hp_max_label := Label.new()
	hp_max_label.text = "PV MÁXIMOS"
	editor.add_child(hp_max_label)
	hp_max_spin = SpinBox.new()
	hp_max_spin.min_value = 1
	hp_max_spin.max_value = 999999
	hp_max_spin.value = 1
	hp_max_spin.value_changed.connect(_edit_hit_points)
	editor.add_child(hp_max_spin)
	editable_controls.append(hp_max_spin)
	var status_label := Label.new()
	status_label.text = "ESTADOS / DURACIÓN"
	editor.add_child(status_label)
	status_edit = LineEdit.new()
	status_edit.placeholder_text = "Envenenado (2 turnos)…"
	status_edit.text_changed.connect(_edit_status)
	editor.add_child(status_edit)
	editable_controls.append(status_edit)
	body.add_child(editor)
	var health_tools := HBoxContainer.new()
	body.add_child(health_tools)
	hp_change_spin = SpinBox.new()
	hp_change_spin.min_value = 1
	hp_change_spin.max_value = 999999
	hp_change_spin.value = 1
	hp_change_spin.prefix = "Cantidad "
	hp_change_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_tools.add_child(hp_change_spin)
	editable_controls.append(hp_change_spin)
	var damage_button := Button.new()
	damage_button.text = "− Daño"
	damage_button.pressed.connect(_change_hit_points.bind(-1))
	health_tools.add_child(damage_button)
	editable_controls.append(damage_button)
	var heal_button := Button.new()
	heal_button.text = "+ Curar"
	heal_button.pressed.connect(_change_hit_points.bind(1))
	health_tools.add_child(heal_button)
	editable_controls.append(heal_button)

	var turns := HFlowContainer.new()
	for definition in [["← Anterior", _previous_turn], ["Siguiente →", _next_turn]]:
		var button := Button.new()
		button.text = definition[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(definition[1])
		turns.add_child(button)
		editable_controls.append(button)
	body.add_child(turns)
	var actions := HFlowContainer.new()
	for definition in [["↕ Reordenar", _sort_combatants], ["× Quitar", _remove_selected], ["■ Terminar combate", clear]]:
		var button := Button.new()
		button.text = definition[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(definition[1])
		actions.add_child(button)
		editable_controls.append(button)
	body.add_child(actions)
	set_editable(editable)

func set_editable(value: bool) -> void:
	editable = value
	if mode_label != null:
		mode_label.text = "" if editable else "SOLO LECTURA"
	for control in editable_controls:
		if control is Button:
			control.disabled = not editable
		elif control is SpinBox:
			control.editable = editable
		elif control is LineEdit:
			control.editable = editable

func add_combatant(token_index: int, token_data: Dictionary, modifier: int) -> void:
	if not editable:
		return
	var stable_id := str(token_index)
	for index in range(combatants.size()):
		if str(combatants[index].get("id", "")) == stable_id:
			combatants[index].initiative = randi_range(1, 20) + modifier
			combatants[index].modifier = modifier
			_sort_combatants()
			return
	var display_name := str(token_data.get("character_name", "")).strip_edges()
	if display_name.is_empty():
		display_name = "Ficha %s" % str(token_data.get("label", token_index + 1))
	var status_names := PackedStringArray()
	for status in token_data.get("status_effects", []):
		status_names.append(str(status))
	combatants.append({
		"id": stable_id, "name": display_name, "initiative": randi_range(1, 20) + modifier,
		"modifier": modifier, "hp_current": float(token_data.get("hp_current", 0.0)),
		"hp_max": maxf(float(token_data.get("hp_max", 1.0)), 1.0),
		"statuses": ", ".join(status_names)
	})
	_sort_combatants()

func set_combatant_statuses(token_index: int, effects: Array[String]) -> void:
	var stable_id := str(token_index)
	for index in range(combatants.size()):
		if str(combatants[index].get("id", "")) != stable_id:
			continue
		combatants[index].statuses = ", ".join(effects)
		_refresh(index)
		_changed()
		return

func _sort_combatants() -> void:
	if not editable:
		return
	combatants.sort_custom(func(a: Dictionary, b: Dictionary):
		if int(a.initiative) == int(b.initiative):
			return int(a.modifier) > int(b.modifier)
		return int(a.initiative) > int(b.initiative)
	)
	current_turn = 0 if not combatants.is_empty() else -1
	_refresh()
	_changed()

func _next_turn() -> void:
	if not editable:
		return
	if combatants.is_empty():
		return
	_tick_current_statuses()
	current_turn += 1
	if current_turn >= combatants.size():
		current_turn = 0
		round_number += 1
	_refresh()
	_announce_turn()
	_changed()

func _tick_current_statuses() -> void:
	if current_turn < 0 or current_turn >= combatants.size():
		return
	var entry: Dictionary = combatants[current_turn]
	var kept: Array[String] = []
	var expired: Array[String] = []
	var duration_pattern := RegEx.new()
	duration_pattern.compile("^(.+?)\\s*\\((\\d+)\\s*turnos?\\)\\s*$")
	for raw_status in str(entry.get("statuses", "")).split(",", false):
		var status := raw_status.strip_edges()
		if status.is_empty():
			continue
		var match := duration_pattern.search(status)
		if match == null:
			kept.append(status)
			continue
		var remaining := int(match.get_string(2)) - 1
		var status_name := match.get_string(1).strip_edges()
		if remaining <= 0:
			expired.append(status_name)
		else:
			kept.append("%s (%d %s)" % [status_name, remaining, "turno" if remaining == 1 else "turnos"])
	entry.statuses = ", ".join(kept)
	combatants[current_turn] = entry
	var token_index_text := str(entry.get("id", "-1"))
	if token_index_text.is_valid_int():
		status_effects_changed.emit(int(token_index_text), kept)
	if not expired.is_empty():
		turn_announced.emit("Finalizaron los efectos de %s: %s" % [str(entry.get("name", "Ficha")), ", ".join(expired)])

func _previous_turn() -> void:
	if not editable:
		return
	if combatants.is_empty():
		return
	current_turn -= 1
	if current_turn < 0:
		current_turn = combatants.size() - 1
		round_number = maxi(round_number - 1, 1)
	_refresh()
	_announce_turn()
	_changed()

func _announce_turn() -> void:
	if current_turn < 0 or current_turn >= combatants.size():
		return
	turn_announced.emit("Ronda %d • Turno de %s" % [round_number, combatants[current_turn].name])

func _remove_selected() -> void:
	if not editable:
		return
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	combatants.remove_at(selected[0])
	current_turn = mini(current_turn, combatants.size() - 1)
	_refresh()
	_changed()

func clear() -> void:
	if not editable:
		return
	combatants.clear()
	current_turn = -1
	round_number = 1
	_refresh()
	_changed()

func _on_selected(index: int) -> void:
	if index < 0 or index >= combatants.size():
		return
	_applying = true
	initiative_spin.value = float(combatants[index].initiative)
	hp_current_spin.value = float(combatants[index].hp_current)
	hp_max_spin.value = float(combatants[index].hp_max)
	status_edit.text = str(combatants[index].statuses)
	_applying = false

func _edit_initiative(value: float) -> void:
	if _applying or not editable:
		return
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	combatants[selected[0]].initiative = int(value)
	_refresh(selected[0])
	_changed()

func _edit_status(value: String) -> void:
	if _applying or not editable:
		return
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	combatants[selected[0]].statuses = value
	_refresh(selected[0])
	_changed()

func _edit_hit_points(_value: float) -> void:
	if _applying or not editable:
		return
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	var index: int = selected[0]
	combatants[index].hp_max = maxf(hp_max_spin.value, 1.0)
	combatants[index].hp_current = minf(hp_current_spin.value, combatants[index].hp_max)
	_applying = true
	hp_current_spin.value = combatants[index].hp_current
	_applying = false
	_refresh(index)
	_emit_hit_points(index)
	_changed()

func _change_hit_points(direction: int) -> void:
	if not editable:
		return
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	var index: int = selected[0]
	var maximum := maxf(float(combatants[index].hp_max), 1.0)
	combatants[index].hp_current = clampf(float(combatants[index].hp_current) + hp_change_spin.value * direction, -999999.0, maximum)
	_applying = true
	hp_current_spin.value = combatants[index].hp_current
	_applying = false
	_refresh(index)
	_emit_hit_points(index)
	_changed()

func _emit_hit_points(combatant_index: int) -> void:
	var token_id := str(combatants[combatant_index].get("id", "-1"))
	if token_id.is_valid_int():
		hit_points_changed.emit(int(token_id), float(combatants[combatant_index].hp_current), float(combatants[combatant_index].hp_max))

func _refresh(selected_index := -1) -> void:
	if list == null:
		return
	list.clear()
	round_label.text = "RONDA %d" % round_number
	for index in range(combatants.size()):
		var entry: Dictionary = combatants[index]
		var marker := "▶ " if index == current_turn else "   "
		var hp := "%d/%d PV" % [int(entry.hp_current), int(entry.hp_max)]
		var statuses := " • " + str(entry.statuses) if not str(entry.statuses).is_empty() else ""
		list.add_item("%s%2d  %s  •  %s%s" % [marker, int(entry.initiative), entry.name, hp, statuses])
	if selected_index >= 0 and selected_index < list.item_count:
		list.select(selected_index)

func _changed() -> void:
	if not _applying:
		state_changed.emit()

func export_state() -> Dictionary:
	return {"combatants": combatants.duplicate(true), "current_turn": current_turn, "round": round_number}

func import_state(data: Dictionary) -> void:
	_applying = true
	combatants.clear()
	for saved in data.get("combatants", []):
		if saved is Dictionary:
			combatants.append(saved.duplicate(true))
	current_turn = clampi(int(data.get("current_turn", -1)), -1, combatants.size() - 1)
	round_number = maxi(int(data.get("round", 1)), 1)
	_applying = false
	_refresh()
