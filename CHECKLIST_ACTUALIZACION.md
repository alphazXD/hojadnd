# Checklist de publicación 1.1.0

## Antes de compilar

- [x] Godot 4.6.2 y sus plantillas de exportación están instalados.
- [ ] Java 17 y Android SDK están configurados en el editor.
- [ ] La clave release es la misma utilizada en la versión 1.0.0. Actualmente
  solo está configurada la clave debug local de Godot.
- [ ] Existe una copia de seguridad de una campaña real de prueba.

## Pruebas funcionales

- [x] El ejecutable de Windows inicia en Godot 4.6.2 y cierra sin errores (código 0).
- [x] APK inspeccionado: ARM64, Android mínimo 7 (API 24), objetivo Android 15 (API 35).
- [x] APK usa el selector de documentos del sistema y no solicita permisos amplios de almacenamiento.
- [ ] Crear, guardar, cerrar y volver a abrir una hoja.
- [ ] Exportar e importar una hoja en PC y Android.
- [ ] Cambiar skin y color, cerrar la app y verificar que se conservan.
- [ ] Cargar mapa, mover fichas, usar niebla, dibujos y mediciones.
- [ ] Abrir una partida entre dos dispositivos en redes diferentes.
- [ ] Comprobar entrada tardía con mapa, fichas, chat, iniciativa y música.
- [ ] Probar desconexión y reconexión.
- [ ] Reproducir GIF, OGV y música compartida.
- [ ] Revisar hoja de personaje, monstruo, inventario, conjuros y biblioteca.

## Actualización Android

- [ ] Instalar primero la versión anterior con datos de prueba.
- [ ] Instalar 1.1.0 encima, sin desinstalar.
- [ ] Confirmar que `user://` conserva hojas, campañas, mapas y apariencia.
- [ ] Confirmar que Android muestra versión 1.1.0 y código 2.

## Entrega

- [x] Exportar Windows en `build/windows/HojaPersonaje.exe`.
- [x] Exportar Android en `build/android/HojaPersonaje.apk`.
- [x] APK de prueba verificado con firmas v2 y v3.
- [x] Identificador `com.alphaz.hojapersonaje`, versión 1.1.0 y código 2 verificados.
- [x] Permiso de Internet incluido para las partidas online.
- [x] Actividad de inicio e iconos Android incluidos en el paquete final.
- [ ] Analizar ambos archivos con antivirus.
- [ ] Guardar de forma segura el keystore y su contraseña.
- [x] Entregar también `CHANGELOG.md` con las novedades.
