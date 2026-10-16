# Guía de programación — HojaPersonaje

Esta guía sirve como mapa del proyecto. Antes de modificar algo, haz una copia
de la carpeta o usa un sistema de versiones. Después de cada cambio abre el
proyecto en Godot y revisa **Depurador > Errores**.

## Cómo leer una línea de GDScript

```gdscript
const GRID_SIZE := 48.0
```

- `const`: valor que no debe cambiar mientras corre la aplicación.
- `GRID_SIZE`: nombre del valor. Los nombres en mayúsculas suelen ser ajustes.
- `:=`: Godot deduce el tipo automáticamente.
- `48.0`: tamaño actual de una casilla en píxeles.

```gdscript
var tokens: Array[Node2D] = []
```

- `var`: dato que sí cambia.
- `tokens`: nombre usado por el resto del archivo.
- `Array[Node2D]`: lista que solamente admite nodos 2D.
- `[]`: empieza vacía.

```gdscript
func set_zoom(value: float) -> void:
```

- `func`: declara una función.
- `set_zoom`: nombre usado para llamarla.
- `value: float`: recibe un número decimal.
- `-> void`: no devuelve ningún resultado.
- Las líneas tabuladas debajo pertenecen a esa función.

```gdscript
signal tokens_changed
```

Una señal avisa a otros nodos de que ocurrió algo. No hace nada hasta conectarla
con `.connect(...)`.

```gdscript
@rpc("authority", "call_remote", "reliable")
```

La función siguiente puede viajar por red:

- `authority`: solamente el anfitrión puede enviarla.
- `any_peer`: puede enviarla un jugador, pero la función debe validar permisos.
- `call_remote`: se ejecuta en las otras máquinas, no en quien la envía.
- `reliable`: llega completa y en orden; úsala para estado importante.
- `unreliable_ordered`: puede perder paquetes; úsala para movimiento continuo.

## Mapa de archivos

### `CharacterSheet.gd`

Controlador principal. Construye los menús, guarda hojas, administra la
biblioteca y coordina la mesa online.

Zonas importantes:

- Constantes al inicio: rutas, límites de tamaño, categorías y niveles.
- `_ready()`: prepara el proyecto al abrirlo.
- `_theme()`: colores y apariencia global.
- `_sheets_manager()`: biblioteca de hojas.
- `_refresh_sheets_list()`: filas de hojas guardadas.
- `_export_sheet_to_path()` / `_import_sheet_from_path()`: intercambio de hojas.
- `_host_online_table()` / `_join_online_table()`: crear o entrar a una mesa.
- `_online_peer_connected()`: todo lo que recibe un jugador nuevo.
- `_post_chat()` / `_receive_chat_message()`: chat y dados.
- `_save_table_state()`: guarda y sincroniza el estado de la mesa.

Este archivo es grande. Busca una función con `Ctrl + L` o con el buscador de
scripts antes de modificarla.

### `TabletopWorld.gd`

Es el mundo 2D real. Aquí están cámara, zoom, gestos, fichas, mapa, niebla,
dibujo, selección y permisos de movimiento.

Ajustes fáciles:

```gdscript
const GRID_SIZE := 48.0            # píxeles que ocupa una casilla de 5 pies
const EMPTY_WORLD_EXTENT := 6000.0 # espacio disponible sin mapa cargado
const ZOOM_SMOOTH_SPEED := 12.0    # rapidez de la animación del zoom
const MAX_HISTORY := 30            # cantidad de pasos para deshacer
```

No quites `_can_control_token()` ni `can_peer_control_token()`: impiden que un
jugador mueva fichas ajenas.

### `TabletopView.gd`

Puente entre la interfaz y `TabletopWorld.gd`. También reproduce GIF/vídeo y
recibe mapas, imágenes, hojas y música por internet.

- Funciones cortas como `zoom_in()` solamente redirigen la orden al mundo.
- Funciones `share_*` envían información.
- Funciones `sync_*` aplican información recibida.
- `_prepare_map_transfer()` reduce mapas demasiado grandes.
- `_on_chunk_transfer_completed()` decide qué hacer con cada archivo recibido.

### `ChunkTransfer.gd`

Divide archivos grandes en fragmentos para que el online no se congele.

```gdscript
const CHUNK_SIZE := 48 * 1024       # bytes por fragmento
const CHUNKS_PER_FRAME := 4         # fragmentos enviados por fotograma
const TRANSFER_TIMEOUT_MS := 30000  # cancela tras 30 segundos sin datos
```

Reducir `CHUNKS_PER_FRAME` consume menos red por instante, pero tarda más. No
subas `CHUNK_SIZE` por encima de unos 64 KiB sin probar PC y Android.

### Archivos de capas

- `FogLayer.gd`: niebla de guerra.
- `GridLayer.gd`: cuadrícula de cinco pies.
- `DrawingLayer.gd`: lápiz y borrador.
- `MeasurementLayer.gd`: regla, cono y esfera.
- `TableToken.gd`: apariencia y datos de una ficha individual.
- `GifPlayback.gd`: carga y avance de GIF animados.
- `SheetZoomContainer.gd`: zoom táctil de las hojas.

### Carpeta `ui/`

Contiene escenas pequeñas y reutilizables. Los `.tscn` describen nodos y diseño;
los `.gd` contienen comportamiento. Modifica primero una escena desde el editor
de Godot si solo quieres mover o redimensionar controles.

## Cambios habituales

### Cambiar colores

En `CharacterSheet.gd`, busca:

```gdscript
const INK := Color("#eadfc4")
const MUTED := Color("#a99f89")
const GOLD := Color("#c99a52")
const PANEL := Color("#211f22")
const FIELD := Color("#171619")
```

Usa colores hexadecimales `#RRGGBB`. `_theme()` aplica esos valores a botones,
campos y paneles.

### Crear un skin nuevo

Los skins están en `SKIN_PRESETS`, al comienzo de `CharacterSheet.gd`. Copia uno
de los ejemplos y cambia su nombre y colores:

```gdscript
"Bosque": {
    "background": "#101a13", # fondo exterior de toda la aplicación
    "panel": "#1d2b20",      # tarjetas, ventanas y secciones
    "field": "#121b14",      # cajas donde se escribe
    "accent": "#79a85b",     # bordes, títulos y elementos destacados
    "text": "#edf3e8",       # texto normal
    "radius": 8,              # redondez de botones, campos y paneles
    "border": 1,              # grosor de los marcos
    "padding": 14,            # espacio interior de tarjetas y controles
    "spacing": 10,            # separación entre elementos
    "button_height": 42,      # altura mínima de la navegación
    "title_size": 17,         # tamaño de títulos de sección
    "accent_width": 4,        # ancho de la línea decorativa de títulos
    "shadow": 3               # profundidad de sombra; usa 0 para estilo plano
}
```

Reglas:

1. Separa cada skin con una coma.
2. Conserva las claves de color y de diseño del ejemplo.
3. Usa `#RRGGBB`; puedes obtener estos códigos con cualquier selector de color.
4. Guarda el script y vuelve a abrir la aplicación.
5. El botón **Skins**, junto a Guardar, mostrará automáticamente el preset.

`_apply_skin()` cambia colores y geometría: marcos, redondez, espacio interior,
separación, títulos y navegación. Después guarda la selección en
`user://appearance.json`. Los selectores manuales cambian la paleta sin perder
la estructura del skin activo.

Los ejemplos incluidos muestran cuatro enfoques distintos:

- **Minimalista:** plano, claro, compacto y casi sin marcos.
- **Medieval antiguo:** paneles amplios, bordes dorados y aspecto de pergamino.
- **Arcano cristal:** esquinas suaves, sombras profundas y brillo mágico.
- **Forja industrial:** esquinas rectas, marcos fuertes y distribución densa.

El cambio de color está agrupado por un `Timer` de 0,07 segundos. No elimines
`_flush_palette_changes()`: evita que arrastrar un selector reconstruya y guarde
la interfaz cientos de veces por segundo, especialmente en celulares.

La optimización utiliza además:

- `palette_font_controls`: caché de etiquetas, botones y campos; evita recorrer
  todo el árbol visual en cada cambio.
- `skin_managed_panels`: caché de paneles de hojas, biblioteca, herramientas y
  ventanas. El contenedor del mapa queda excluido para no teñir el tablero.
- `skin_style_cache`: comparte los mismos `StyleBoxFlat` entre controles con un
  estilo idéntico.
- `pending_palette_keys`: permite actualizar solamente el fondo o el texto cuando
  los demás colores no cambiaron.
- `appearance_save_timer`: espera 0,65 segundos antes de escribir en disco.

Los controles creados dinámicamente se añaden mediante `node_added`. Si creas un
control de una clase completamente nueva, incorpórala a `_cache_palette_control()`.

Durante `_apply_data()` se activa temporalmente `applying_skin`. Esto impide que
los cinco colores guardados en una hoja provoquen cinco reconstrucciones. La
paleta se aplica una sola vez al terminar. La apariencia tampoco llama a
`_update_skills()`: colores y estadísticas son responsabilidades separadas.

La apariencia se conserva en `user://appearance.json`, que es almacenamiento
privado y persistente de cada dispositivo. `_persist_appearance_now()` fuerza el
guardado al cerrar, pulsar Atrás, perder el foco o mandar la app al segundo plano.
Por eso no requiere permisos de almacenamiento en Android.

### Cambiar el tamaño de la cuadrícula

Cambia `GRID_SIZE` en `TabletopWorld.gd`. Recuerda que la aplicación interpreta
cada casilla como cinco pies; revisa también `GridLayer.gd` y
`MeasurementLayer.gd` si quieres cambiar esa regla.

### Añadir un tipo de hoja

1. Añádelo a `SHEET_TYPES` en `CharacterSheet.gd`.
2. Define qué campos se muestran en `_update_sheet_type_view()`.
3. Incluye sus datos en el guardado y la carga.
4. Añade un icono en `_refresh_sheets_list()`.

### Añadir una categoría a la biblioteca

Edita `LIBRARY_CATEGORIES` en `CharacterSheet.gd`. Si necesita una acción
especial, añade el caso correspondiente en las funciones de la biblioteca.

### Añadir un nuevo tipo de archivo online

1. Añade el nombre permitido en `ChunkTransfer.gd`.
2. Define un límite de bytes.
3. En `TabletopView.gd`, crea una función `share_*`.
4. Procesa el resultado en `_on_chunk_transfer_completed()`.
5. Valida extensión, tamaño y remitente antes de escribir el archivo.

## Reglas para no romper el online

1. El anfitrión es el peer `1` y es la autoridad de mapa, niebla y estado global.
2. Un cliente nunca debe aceptar estado global enviado por otro cliente.
3. No envíes archivos grandes directamente con `.rpc(...)`; usa
   `ChunkTransfer.gd`.
4. Las rutas `user://` son privadas de cada dispositivo. Envía bytes, no rutas.
5. Valida tamaños y extensiones antes de guardar contenido recibido.
6. No conviertas movimiento continuo a `reliable`; provocaría retraso acumulado.
7. Al añadir estado nuevo, inclúyelo en `_online_peer_connected()` para quienes
   entren cuando la partida ya comenzó.

## Guardado y rutas

- `res://`: archivos incluidos dentro del proyecto. En una app exportada son de
  solo lectura.
- `user://`: archivos creados por cada usuario. Funciona en PC y Android.
- `ProjectSettings.globalize_path(...)`: convierte una ruta de Godot en ruta del
  sistema operativo cuando una API lo necesita.

Nunca guardes datos del jugador en `res://`.

## Cómo comprobar tus cambios

1. Guarda el script.
2. Revisa si Godot muestra un punto rojo junto a alguna línea.
3. Ejecuta primero en PC.
4. Prueba crear y cargar una hoja.
5. Para cambios online, abre dos copias: una crea la mesa y otra se une.
6. Comprueba un jugador que entra después de cargar mapa, fichas y música.
7. Finalmente genera un APK nuevo; un APK anterior no contiene los cambios.

## Comentarios recomendados

Comenta la intención, no lo obvio:

```gdscript
# Correcto: explica por qué existe esta comprobación.
# Evita devolver al servidor una ruta user:// que solo existe en este celular.
world.set_token_image(token_index, path, false)

# Poco útil: solamente repite la línea.
# Pone la imagen de la ficha.
world.set_token_image(token_index, path, false)
```

Usa `##` encima de una función si quieres que Godot muestre la explicación como
documentación contextual. Usa `# PERSONALIZACIÓN:` para localizar rápidamente
los valores pensados para cambiarse.
