extends Control

signal value_changed(value: int)

var value := 0
var maximum := 5
var positive_color := Color("#59b86b")
var negative_color := Color("#d45d52")
var empty_color := Color("#39373b")
var interactive := false

func _ready() -> void:
	custom_minimum_size = Vector2(220, 38)
	queue_redraw()

func configure(new_value: int, new_maximum: int, positive: Color, negative: Color) -> void:
	value = new_value
	maximum = maxi(new_maximum, 1)
	positive_color = positive
	negative_color = negative
	queue_redraw()

func set_interactive(enabled: bool) -> void:
	interactive = enabled
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if not interactive or not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var visible_count := mini(maximum, 20)
	var spacing := minf(22.0, (size.x - 12.0) / float(maxi(visible_count, 1)))
	var clicked := clampi(int(round((event.position.x - 10.0) / spacing)) + 1, 1, visible_count)
	# Tocar el último círculo lleno lo apaga; tocar otro establece el nuevo valor.
	value = clicked - 1 if value == clicked else clicked
	value_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var count := mini(maximum, 20)
	var radius := 8.0
	var spacing := minf(22.0, (size.x - 12.0) / float(maxi(count, 1)))
	var filled := mini(absi(value), count)
	# PERSONALIZACIÓN: cambia positive_color/negative_color para adaptar la mecánica.
	var active_color: Color = positive_color if value >= 0 else negative_color
	for index in range(count):
		var center := Vector2(10.0 + spacing * index, size.y * 0.5)
		draw_circle(center, radius, active_color if index < filled else empty_color)
		draw_circle(center, radius, active_color.lightened(0.25), false, 2.0)
	if maximum > 20:
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 48, size.y * 0.5 + 5), "/ %d" % maximum, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
