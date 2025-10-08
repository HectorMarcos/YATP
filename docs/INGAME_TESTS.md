# YATP - Guía de Pruebas Ingame (Rama perf/optimizations)

Esta guía cubre validación funcional y chequeos de rendimiento tras los refactors.

## Preparación General

1. Actualiza/copía la carpeta `YATP` (rama `perf/optimizations`) al directorio de AddOns.
2. Inicia el cliente y verifica que no aparecen errores Lua al cargar.
3. Activa Debug Mode: Interfaz > AddOns > YATP > Extras > Debug Mode.
4. (Opcional) Activa profiling CPU: `/console scriptProfile 1` y `/reload` (si tu build lo soporta).
5. Abre consola de chat para ver mensajes de debug.

## Herramientas de Diagnóstico

- `/yatpsched`: lista tareas del scheduler y stats (sólo con Debug Mode).
- `/fstack`: inspeccionar frames (burbujas de chat, buffs, etc.).
- `/dump GetCVar("maxfpsbk")`: verificar cambios de FPS en background.
- Comando de CPU (si disponible):

```lua
/run UpdateAddOnCPUUsage(); local n=GetNumAddOns(); for i=1,n do local name=GetAddOnInfo(i); local u=GetAddOnCPUUsage(i); if u>0 then print(name,u) end end
```

## 1. Scheduler Central

Objetivo: Confirmar que reemplaza múltiples OnUpdate.

Pasos:
 
1. Ejecuta `/yatpsched`.
2. Verifica presencia de tareas: `HotkeysUpdate`, `ChatBubblesPostSweeps` (aparece tras detectar una burbuja) y tareas temporales de transmog cuando salta un popup.
3. Asegura que no se listan tareas fantasma tras desactivar los módulos relacionados.

Criterio de éxito: No aparecen errores y las tareas incrementan su contador `runs` con ritmo esperado.

## 2. Hotkeys (Acción y Tint)

Objetivo: Batching correcto y tint refresca sin lag visible.

Pasos:
 
1. Sitúate en barra con varias habilidades (ideal 24+ botones visibles).
2. Cambia distancia a un objetivo: íconos fuera de rango deben recolorarse en ≤0.3s.
3. Gasta recurso (mana/energía) y verifica color de “Not Enough Mana”/“Unusable”.
4. Cambia `Trigger on Key Down` y pulsa una acción: sentir menor latencia.
5. Verifica que no hay spikes de FPS al spamear habilidades.

Criterio de éxito: Cambios de rango/uso reflejados; FPS estable comparado con versión previa.

## 3. ChatBubbles

Objetivo: Burbujas sin artwork, texto estilizado; sin reaparición de borde.

Pasos:
 
1. Asegura en opciones de juego que los chat bubbles están ON.
2. En /say escribe 3–4 mensajes; cada bubble debe salir sólo con texto (sin fondo).
3. Desactiva el módulo; las burbujas vuelven a estilo original.

Criterio de éxito: Ninguna textura residual reaparece tras varios mensajes y en zonas con muchos NPCs.

## 4. QuickConfirm (Transmog y Exit)

Objetivo: Auto-confirm funcional con reintentos.

Pasos:
 
1. Forzar popup de transmog (coleccionar apariencia) – observa debug `schedule transmog retries`.
2. Popup debe cerrarse solo en ≤1s.
3. (La auto-confirmación de salida se ha eliminado en esta rama.)

Criterio de éxito: Sin mensajes “retries exhausted” salvo que el popup desaparezca antes.

## 5. PlayerAuras

Objetivo: Nuevo layout con reuse arrays y throttle más alto.

Pasos:
 
1. Aplica varios buffs (mínimo > 12) para verificar multi‑fila.
2. Cambia “Buffs per Row” y confirma re‑layout en ≤0.2s tras aplicar.
3. Marca un buff en lista de filtros y observa desaparición en próximo refresh.
4. Cambia escala de ícono y dirección (LEFT/RIGHT) – posiciones correctas.
5. Verifica que duración no agrega GC evidente (sin micro‑tirones al expirar efectos cortos).

Criterio de éxito: No flicker; orden alfabético funciona al seleccionarlo.

## 6. ChatFilters

Objetivo: Filtrado sigue funcionando y menos overhead.

Pasos:
 
1. Forzar (si puedes) mensajes de “Interface action failed”/“UI Error...” y verificar supresión.
2. Activar/desactivar toggles y confirmar que dejan pasar el mensaje.
3. Activar `Suppress Login Welcome Lines` y /reload: mensajes de bienvenida/uptime no aparecen.

Criterio de éxito: Contadores en UI (Session Stats) incrementan y no hay supresiones falsas.

## 7. Background FPS Fix / Tweaks

Objetivo: Aplicar y restaurar valor de `maxfpsbk`.

Pasos:
 
1. Anota valor actual: `/dump GetCVar("maxfpsbk")`.
2. Activa módulo y establece un valor diferente (e.g., 30).
3. Cambia de ventana (Alt+Tab) 5s y vuelve: observa caída de FPS a ~cap.
4. Desactiva módulo y confirma que valor previo se restaura.

Criterio de éxito: Variable vuelve exactamente al valor original.

## 8. InfoBar

Objetivo: Actualización periódica y colores de durabilidad.

Pasos:
 
1. Forzar daño en equipo (baja un ítem < threshold configurado) y observar color rojo si <= umbral.
2. Cambiar intervalo de actualización a 0.2s y volver a 1s; variación en reactividad.

Criterio de éxito: Texto se actualiza sin flicker.

## 9. Medición Básica de Rendimiento

(Con y sin Debug Mode para evitar overhead de logging)

1. Ubicación concurrida (ciudad) y en combate. Anota FPS medio (5 muestras) con módulo clave ON/OFF:

- ChatBubbles
- Hotkeys (intervalo actual vs versión anterior si disponible)
- PlayerAuras

1. Observa `lua memory` si tu cliente lo expone. Verifica que no crece indefinidamente (>5 MB extra sostenidos) después de 5 minutos idle.

## 10. Validación de Reversibilidad

1. Desactiva cada módulo desde su toggle y confirma que su funcionalidad original (Blizzard default) regresa sin errores.
2. /reload y revisa que ajustes persisten.

## Checklist Rápido (Marcar al probar)

- [ ] Scheduler tareas visibles y sin errores
- [ ] Hotkeys tint y keydown OK
- [ ] ChatBubbles sin artwork
- [ ] QuickConfirm transmog OK
- [ ] QuickConfirm exit OK
- [ ] PlayerAuras layout OK
- [ ] ChatFilters suprime correcto
- [ ] Background FPS cap aplica/restaura
- [ ] InfoBar métricas correctas
- [ ] Sin errores Lua durante toda la sesión

## Problemas Comunes / Debug Tips

| Síntoma | Posible causa | Acción |
|--------|---------------|--------|
| Transmog no se auto-confirma | Texto no recogido / which distinto | Activar Debug Mode, copiar which y añadirlo a `TRANSMOG_WHICH` |
| Burbuja reaparece con fondo | Otro addon re-aplica textura | Repetir mensaje y verificar orden de carga (conflicto) |
| FPS cae en ciudad | Alto número de otros addons con scanning | Desactivar addons para aislar / revisar profiler |
| Buff no se oculta | Nombre exacto con mayúsculas diferente | Revisar nombre exacto via tooltip y volver a añadir |

## Siguientes Pasos (Opcional)

- Añadir modo de profiling integrado: tarea scheduler que calcule delta promedio de ejecución por módulo.
- Exponer sliders de intervalos avanzados para usuarios avanzados.

---

Fin de la guía.
