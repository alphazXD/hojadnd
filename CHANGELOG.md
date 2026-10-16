# Historial de versiones

## 1.1.0 — Primera actualización

### Añadido

- Cuatro skins completos: Minimalista, Medieval antiguo, Arcano cristal y
  Forja industrial.
- Apariencia persistente por dispositivo y adaptación para celular.
- Indicador de carga al importar hojas.
- Sincronización inicial de chat, iniciativa, retratos, fichas y música online.
- Transferencias fragmentadas para mapas, animaciones, hojas, biblioteca y
  música.
- Guía de programación y personalización del proyecto.

### Mejorado

- Interfaz adaptable en PC y Android.
- Caché de controles, paneles y estilos para cambios de apariencia más rápidos.
- Guardado diferido de colores para reducir escrituras en celulares.
- Exportación e importación de hojas mediante el selector nativo de Android.
- Seguridad de RPC y permisos de fichas en partidas online.
- Entrada de jugadores durante partidas ya iniciadas.
- Pantalla de inicio inmediata mientras se prepara la interfaz completa.
- Construcción de cachés visuales en una sola pasada durante el arranque.
- Renderizador OpenGL Compatibility en celulares para reducir el tiempo de
  entrada y ampliar la compatibilidad con dispositivos modestos.

### Corregido

- Archivos exportados vacíos en Android y validación posterior a la escritura.
- Filas desalineadas en la biblioteca de hojas.
- Congelamiento aparente durante la importación.
- Estado global que no llegaba cuando la mesa no tenía fichas.
- Retratos que podían desaparecer por rutas privadas de otro dispositivo.
- Música grande enviada en una sola llamada de red.
- Transferencias canceladas que continuaban usando ancho de banda.
- Actualizaciones duplicadas al cargar colores desde una hoja.

## 1.0.0 — Versión inicial

- Primera versión funcional de la hoja de personaje y mesa virtual.
