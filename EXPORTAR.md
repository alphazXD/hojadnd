# Exportar Hoja Personaje

Versión preparada: **1.1.0**. En Android corresponde a `versionCode 2`, por lo
que puede instalarse como actualización de la primera compilación.

## Archivos generados para 1.1.0

- `build/windows/HojaPersonaje.exe`: compilación release para Windows.
- `build/android/HojaPersonaje.apk`: APK instalable firmado con la clave debug
  local de Godot. Sirve para pruebas y para actualizar otra compilación debug
  firmada con esa misma clave.
- `build/android/HojaPersonaje-unsigned-release.apk`: compilación release sin
  firma. No se puede instalar ni publicar hasta firmarla con la clave release.

No distribuyas el archivo `unsigned-release` directamente.

El proyecto ya incluye presets para **Windows Desktop** y **Android** en `export_presets.cfg`.

## Requisito común

En Godot 4.6.2 abre **Editor > Administrar plantillas de exportación** e instala las plantillas correspondientes exactamente a la versión `4.6.2.stable`.

## Windows

1. Abre **Proyecto > Exportar**.
2. Selecciona **Windows Desktop**.
3. Pulsa **Exportar proyecto**.
4. El destino configurado es `build/windows/HojaPersonaje.exe`.

## Android

Además de las plantillas, instala:

- OpenJDK 17.
- Android SDK.
- Android SDK Platform Tools.
- Android SDK Build Tools.

Después configura en **Editor > Configuración del editor > Exportar > Android** las rutas de Java SDK y Android SDK.

1. Abre **Proyecto > Exportar**.
2. Selecciona **Android**.
3. Pulsa **Exportar proyecto**.
4. El destino configurado es `build/android/HojaPersonaje.apk`.

El identificador Android configurado es `com.alphaz.hojapersonaje`, la orientación es horizontal y el permiso de Internet está habilitado para las partidas online.

### Actualizar sin perder datos

- Exporta siempre con el mismo identificador `com.alphaz.hojapersonaje`.
- Firma todas las versiones públicas con el mismo archivo keystore y alias.
- Instala el APK nuevo encima del anterior; no desinstales la aplicación.
- Nunca vuelvas a usar un `version/code` anterior. La próxima actualización
  deberá usar como mínimo el código `3`.
- Antes de publicar, prueba que hojas, campañas, mapas, música y apariencia
  continúan disponibles después de actualizar.

Cambiar o perder la clave de firma impide actualizar una instalación existente.

Actualmente no hay una clave release configurada en Godot. Antes de una entrega
pública, configura la misma clave usada en la primera versión. Si la versión
anterior fue un APK debug generado en este mismo equipo, el APK de prueba actual
puede instalarse encima porque conserva la misma clave debug.

## Limitación móvil de la biblioteca

La extracción y visualización interna de PDF utiliza Python, `pypdf` y Poppler en PC. Estas herramientas externas no se incluyen en Android; las hojas, mesa, mapas, fichas, dados, chat, inventario y conjuros sí son compatibles con la exportación móvil.
