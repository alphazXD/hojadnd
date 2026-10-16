class_name SheetZoomContainer
extends Container

## Contenedor de zoom uniforme para Hoja, Inventario y Conjuros.
## PERSONALIZACIÓN: el rango se controla desde CharacterSheet.gd. Este nodo
## mantiene el tamaño desplazable sincronizado con la escala visual, evitando
## que los Container internos se reorganicen durante un pellizco.

var zoom := 1.0

func set_zoom(value: float) -> void:
	if is_equal_approx(zoom, value):
		return
	zoom = maxf(value, 0.01)
	update_minimum_size()
	queue_sort()
	queue_redraw()

func _get_minimum_size() -> Vector2:
	var content := _content()
	if content == null:
		return Vector2.ZERO
	return content.get_combined_minimum_size() * zoom

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_content()

func _layout_content() -> void:
	var content := _content()
	if content == null:
		return
	var minimum := content.get_combined_minimum_size()
	# Al alejar, el contenido recibe más espacio lógico antes de escalarse; al
	# acercar conserva como mínimo su diseño natural y activa el scroll exterior.
	var logical_size := Vector2(maxf(size.x / zoom, minimum.x), maxf(size.y / zoom, minimum.y))
	content.position = Vector2.ZERO
	content.pivot_offset = Vector2.ZERO
	content.scale = Vector2.ONE * zoom
	content.size = logical_size

func _content() -> Control:
	for child in get_children():
		if child is Control:
			return child
	return null
