extends Node

## Transferencias grandes divididas en paquetes pequeños.
## PERSONALIZACIÓN: baja CHUNK_SIZE si los celulares pierden paquetes o súbelo
## ligeramente en redes rápidas. Evita superar aproximadamente 64 KiB por RPC.
## Consulta res://GUIA_PROGRAMACION.md antes de añadir un nuevo tipo de archivo.
signal transfer_progress(kind: String, filename: String, percent: float)
signal transfer_completed(kind: String, filename: String, bytes: PackedByteArray, metadata: Dictionary)
signal transfer_failed(message: String)

const CHUNK_SIZE := 48 * 1024
const CHUNKS_PER_FRAME := 4
const MAX_TRANSFER_SIZE := 50 * 1024 * 1024
const MAX_LIBRARY_TRANSFER_SIZE := 8 * 1024 * 1024
const MAX_MUSIC_TRANSFER_SIZE := 25 * 1024 * 1024
const TRANSFER_TIMEOUT_MS := 30000

var outgoing: Array[Dictionary] = []
var incoming: Dictionary = {}

func _ready() -> void:
	set_process(true)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Prepara un archivo para un jugador. Devuelve false si el destino, tipo o
## tamaño no son seguros; no escribas en `outgoing` desde otros scripts.
func queue_transfer(peer_id: int, kind: String, filename: String, bytes: PackedByteArray, metadata := {}) -> bool:
	if peer_id <= 0 or peer_id not in multiplayer.get_peers() or kind not in ["map", "media", "music", "sheet", "library"] or bytes.is_empty() or bytes.size() > MAX_TRANSFER_SIZE:
		return false
	if kind == "library" and bytes.size() > MAX_LIBRARY_TRANSFER_SIZE:
		return false
	if kind == "music" and bytes.size() > MAX_MUSIC_TRANSFER_SIZE:
		return false
	# Mapas y escenas animadas sustituyen al envío anterior. Las hojas forman
	# una colección, por eso deben permanecer todas en la cola.
	if kind not in ["sheet", "library"]:
		_cancel_replaced_transfer(peer_id, kind)
	var transfer_id := "%s-%s-%s" % [multiplayer.get_unique_id(), Time.get_ticks_usec(), randi()]
	var total_chunks: int = ceili(float(bytes.size()) / CHUNK_SIZE)
	var safe_metadata: Dictionary = metadata.duplicate(true) if metadata is Dictionary else {}
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_MD5)
	hash_context.update(bytes)
	safe_metadata["checksum"] = hash_context.finish().hex_encode()
	outgoing.append({
		"peer_id": peer_id,
		"id": transfer_id,
		"kind": kind,
		"filename": filename.get_file().validate_filename(),
		"bytes": bytes,
		"metadata": safe_metadata,
		"index": 0,
		"total": total_chunks
	})
	_receive_start.rpc_id(peer_id, transfer_id, kind, filename.get_file(), bytes.size(), total_chunks, safe_metadata)
	return true

# Mantiene solo el envío más reciente de cada clase para cada jugador. Es útil
# si el director cambia dos veces de mapa o pulsa varias animaciones seguidas.
func _cancel_replaced_transfer(peer_id: int, kind: String) -> void:
	for index in range(outgoing.size() - 1, -1, -1):
		var transfer: Dictionary = outgoing[index]
		if int(transfer.get("peer_id", 0)) == peer_id and str(transfer.get("kind", "")) == kind:
			_receive_cancel.rpc_id(peer_id, str(transfer.get("id", "")), false)
			outgoing.remove_at(index)

func queue_transfer_to_all(kind: String, filename: String, bytes: PackedByteArray, metadata := {}) -> bool:
	var queued := false
	for peer_id in multiplayer.get_peers():
		queued = queue_transfer(peer_id, kind, filename, bytes, metadata) or queued
	return queued

func cancel_all() -> void:
	for transfer in outgoing:
		_receive_cancel.rpc_id(int(transfer.peer_id), str(transfer.id), true)
	for transfer_id in incoming:
		var sender_id: int = int(incoming[transfer_id].get("sender_id", 0))
		if sender_id > 0 and sender_id in multiplayer.get_peers():
			_cancel_outgoing.rpc_id(sender_id, str(transfer_id))
	outgoing.clear()
	incoming.clear()
	transfer_failed.emit("Transferencia cancelada.")

@rpc("any_peer", "call_remote", "reliable")
func _cancel_outgoing(transfer_id: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	for index in range(outgoing.size() - 1, -1, -1):
		var transfer: Dictionary = outgoing[index]
		if str(transfer.get("id", "")) == transfer_id and int(transfer.get("peer_id", 0)) == sender_id:
			outgoing.remove_at(index)

func _on_peer_disconnected(peer_id: int) -> void:
	var removed := false
	for index in range(outgoing.size() - 1, -1, -1):
		if int(outgoing[index].get("peer_id", 0)) == peer_id:
			outgoing.remove_at(index)
			removed = true
	# Para un cliente, el anfitrión siempre es el peer 1. Si desaparece, ningún
	# archivo parcial debe sobrevivir hasta una reconexión posterior.
	if peer_id == 1 and not multiplayer.is_server() and not incoming.is_empty():
		incoming.clear()
		removed = true
	if removed:
		transfer_failed.emit("Transferencia interrumpida: el jugador se desconectó.")

func _on_server_disconnected() -> void:
	if outgoing.is_empty() and incoming.is_empty():
		return
	outgoing.clear()
	incoming.clear()
	transfer_failed.emit("Transferencia interrumpida: se perdió la conexión con la mesa.")

## Envía pocos fragmentos por fotograma para mantener fluida la interfaz móvil.
func _process(_delta: float) -> void:
	_cleanup_timed_out_transfers()
	var sent_this_frame := 0
	while sent_this_frame < CHUNKS_PER_FRAME and not outgoing.is_empty():
		var transfer: Dictionary = outgoing[0]
		var index: int = int(transfer.index)
		var bytes: PackedByteArray = transfer.bytes
		var start: int = index * CHUNK_SIZE
		var length: int = mini(CHUNK_SIZE, bytes.size() - start)
		var chunk: PackedByteArray = bytes.slice(start, start + length)
		_receive_chunk.rpc_id(int(transfer.peer_id), str(transfer.id), index, chunk)
		index += 1
		transfer.index = index
		outgoing[0] = transfer
		transfer_progress.emit(str(transfer.kind), str(transfer.filename), float(index) / float(transfer.total) * 100.0)
		if index >= int(transfer.total):
			_receive_finish.rpc_id(int(transfer.peer_id), str(transfer.id))
			outgoing.pop_front()
		sent_this_frame += 1

@rpc("any_peer", "call_remote", "reliable")
func _receive_start(transfer_id: String, kind: String, filename: String, total_bytes: int, total_chunks: int, metadata: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if incoming.has(transfer_id) and int(incoming[transfer_id].get("sender_id", -1)) != sender_id:
		return
	# Los clientes solo aceptan transferencias del servidor. El servidor solo
	# acepta de jugadores el tipo Biblioteca, nunca mapas, hojas ni animaciones.
	if (not multiplayer.is_server() and sender_id != 1) or (multiplayer.is_server() and kind != "library"):
		transfer_failed.emit("Transferencia rechazada por origen no autorizado.")
		return
	var expected_chunks: int = ceili(float(total_bytes) / CHUNK_SIZE) if total_bytes > 0 else 0
	var size_limit := MAX_LIBRARY_TRANSFER_SIZE if kind == "library" else (MAX_MUSIC_TRANSFER_SIZE if kind == "music" else MAX_TRANSFER_SIZE)
	if kind not in ["map", "media", "music", "sheet", "library"] or total_bytes <= 0 or total_bytes > size_limit or total_chunks <= 0 or total_chunks != expected_chunks:
		transfer_failed.emit("Transferencia rechazada por tamaño inválido.")
		return
	incoming[transfer_id] = {"kind": kind, "filename": filename.get_file().validate_filename(), "expected": total_bytes, "total": total_chunks, "next": 0, "bytes": PackedByteArray(), "metadata": metadata.duplicate(true), "sender_id": sender_id, "updated_at": Time.get_ticks_msec()}
	transfer_progress.emit(kind, filename, 0.0)

@rpc("any_peer", "call_remote", "reliable")
func _receive_chunk(transfer_id: String, index: int, chunk: PackedByteArray) -> void:
	if not incoming.has(transfer_id):
		return
	var transfer: Dictionary = incoming[transfer_id]
	if int(transfer.get("sender_id", -1)) != multiplayer.get_remote_sender_id():
		return
	if index != int(transfer.next) or chunk.is_empty() or chunk.size() > CHUNK_SIZE:
		incoming.erase(transfer_id)
		transfer_failed.emit("La transferencia llegó incompleta o desordenada.")
		return
	var bytes: PackedByteArray = transfer.bytes
	if bytes.size() + chunk.size() > int(transfer.expected):
		incoming.erase(transfer_id)
		transfer_failed.emit("La transferencia excedió el tamaño anunciado.")
		return
	bytes.append_array(chunk)
	transfer.bytes = bytes
	transfer.next = index + 1
	transfer.updated_at = Time.get_ticks_msec()
	incoming[transfer_id] = transfer
	transfer_progress.emit(str(transfer.kind), str(transfer.filename), float(transfer.next) / float(transfer.total) * 100.0)

@rpc("any_peer", "call_remote", "reliable")
func _receive_finish(transfer_id: String) -> void:
	if not incoming.has(transfer_id):
		return
	var transfer: Dictionary = incoming[transfer_id]
	if int(transfer.get("sender_id", -1)) != multiplayer.get_remote_sender_id():
		return
	incoming.erase(transfer_id)
	var bytes: PackedByteArray = transfer.bytes
	if bytes.size() != int(transfer.expected) or int(transfer.next) != int(transfer.total):
		transfer_failed.emit("La transferencia terminó antes de recibir todos los datos.")
		return
	var expected_checksum := str(transfer.metadata.get("checksum", ""))
	if not expected_checksum.is_empty():
		var hash_context := HashingContext.new()
		hash_context.start(HashingContext.HASH_MD5)
		hash_context.update(bytes)
		if hash_context.finish().hex_encode() != expected_checksum:
			transfer_failed.emit("El archivo recibido no superó la comprobación de integridad.")
			return
	var completed_metadata: Dictionary = transfer.metadata.duplicate(true)
	completed_metadata["sender_peer_id"] = int(transfer.get("sender_id", 0))
	transfer_completed.emit(str(transfer.kind), str(transfer.filename), bytes, completed_metadata)

@rpc("any_peer", "call_remote", "reliable")
func _receive_cancel(transfer_id: String, show_message: bool) -> void:
	if incoming.has(transfer_id) and int(incoming[transfer_id].get("sender_id", -1)) != multiplayer.get_remote_sender_id():
		return
	incoming.erase(transfer_id)
	if show_message:
		transfer_failed.emit("Transferencia cancelada por el anfitrión.")

func _cleanup_timed_out_transfers() -> void:
	var now: int = Time.get_ticks_msec()
	var expired: Array[String] = []
	for transfer_id in incoming:
		if now - int(incoming[transfer_id].get("updated_at", now)) > TRANSFER_TIMEOUT_MS:
			expired.append(str(transfer_id))
	for transfer_id in expired:
		incoming.erase(transfer_id)
		transfer_failed.emit("Una transferencia se interrumpió por falta de conexión.")
