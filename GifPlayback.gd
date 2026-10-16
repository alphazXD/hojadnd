extends RefCounted

# Utilidad compartida para GIF externos. GIFTexture almacena los fotogramas,
# pero no avanza el tiempo por sí sola; esa tarea normalmente corresponde a
# GIFPlayer. Usamos avance manual porque también funciona dentro de Sprite2D y
# RichTextLabel, donde no se puede insertar un GIFPlayer como imagen.

static func load_texture(path: String) -> Texture2D:
	if not ClassDB.class_exists(&"GIFTexture") or not FileAccess.file_exists(path):
		return null
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	return ClassDB.class_call_static(&"GIFTexture", &"load_from_buffer", bytes) as Texture2D

static func advance(texture: Texture2D, current_frame: int, elapsed: float, delta: float) -> Vector2:
	if texture == null or not texture.is_class(&"GIFTexture"):
		return Vector2(current_frame, elapsed)
	var frame_count: int = int(texture.call(&"get_frame_count"))
	if frame_count <= 1:
		return Vector2(0, 0.0)
	elapsed += delta
	var frame: int = clampi(current_frame, 0, frame_count - 1)
	var safety := 0
	while safety < frame_count:
		var delay: float = maxf(float(texture.call(&"get_frame_delay", frame)), 0.01)
		if elapsed < delay:
			break
		elapsed -= delay
		frame = (frame + 1) % frame_count
		safety += 1
	texture.call(&"set_frame", frame)
	return Vector2(frame, elapsed)
