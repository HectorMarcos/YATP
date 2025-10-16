# Nameplate Mouseover Debug System

## Descripción

Sistema de debug implementado para interceptar y analizar el comportamiento de los nameplates cuando se hace mouseover (pasar el cursor del ratón por encima).

## Objetivo

Identificar qué está ocurriendo cuando se hace mouseover sobre un nameplate para poder bloquearlo posteriormente. Esto incluye:

- Efectos de glow/brillo que aparecen al hacer hover
- Cambios en el highlight/resaltado
- Modificaciones en el borde del nameplate
- Cambios en la barra de salud
- Cualquier otro comportamiento visual automático

## Comandos Disponibles

### Activar/Desactivar Debug
```
/yatpnp debug
```
Alterna el modo debug. Cuando está activado, se imprimirán mensajes detallados en el chat cada vez que hagas mouseover sobre un nameplate.

### Probar Mouseover Actual
```
/yatpnp test
```
Ejecuta el debug inmediatamente sobre la unidad que está actualmente bajo tu cursor.

### Reaplicar Hooks
```
/yatpnp hooks
```
Reaaplica los hooks de mouseover a todos los nameplates activos. Útil si algunos nameplates no están siendo monitoreados.

### Ayuda
```
/yatpnp help
```
Muestra la lista de comandos disponibles.

## Información que Reporta el Debug

Cuando el modo debug está activado y haces mouseover sobre un nameplate, se imprimirá:

1. **Detección del Mouseover**
   - Nombre de la unidad
   - GUID (identificador único) de la unidad

2. **Estado del selectionHighlight**
   - Si está visible o no
   - Valor de alpha/transparencia

3. **Estado del aggroHighlight**
   - Si está visible o no
   - Valor de alpha/transparencia

4. **Barra de Salud**
   - Colores actuales (RGBA)
   - Estado del borde (si existe)

5. **Información del Frame**
   - Frame level (nivel de visualización)
   - Frame strata (capa de visualización)
   - Si es el mouseover actual

6. **Eventos de Script**
   - OnEnter: Se dispara cuando el cursor entra en el nameplate
   - OnLeave: Se dispara cuando el cursor sale del nameplate

## Uso Típico

### Paso 1: Activar Debug
```
/yatpnp debug
```
Verás: `[YATP NamePlates] Mouseover debug mode ENABLED`

### Paso 2: Hacer Mouseover
Simplemente pasa el cursor del ratón por encima de los nameplates de las unidades en el juego.

### Paso 3: Observar el Chat
En el chat aparecerán mensajes detallados como:
```
[YATP NamePlates] MOUSEOVER DETECTED: Training Dummy (GUID: 0x...)
[YATP NamePlates] Found matching nameplate for: Training Dummy
[YATP NamePlates] ===== NAMEPLATE STATE DEBUG: Training Dummy =====
  selectionHighlight: Shown=true, Alpha=0.25
  aggroHighlight: Shown=false, Alpha=0.00
  healthBar color: R=1.00, G=0.00, B=0.00, A=1.00
  healthBar.border: Shown=true, Alpha=1.00
  Frame Level: 3, Strata: MEDIUM
  Is Mouseover: true
[YATP NamePlates] ===== END DEBUG =====
```

### Paso 4: Desactivar Debug
Una vez que hayas recopilado la información necesaria:
```
/yatpnp debug
```
Verás: `[YATP NamePlates] Mouseover debug mode DISABLED`

## Próximos Pasos

Con la información recopilada del debug, podremos:

1. **Identificar el elemento responsable**: Determinar si es `selectionHighlight`, `aggroHighlight`, el borde, u otro elemento.

2. **Crear funciones de bloqueo**: Implementar código que intercepte y desactive estos efectos.

3. **Hacer hooks específicos**: Enganchar en las funciones que activan estos efectos para prevenir su ejecución.

## Notas Técnicas

### Hooks Implementados

El sistema hookea las siguientes funciones:

1. **UPDATE_MOUSEOVER_UNIT**: Evento del cliente que se dispara cuando cambia la unidad bajo el cursor
2. **OnEnter (Script)**: Se ejecuta cuando el cursor entra en el frame del nameplate
3. **OnLeave (Script)**: Se ejecuta cuando el cursor sale del frame del nameplate
4. **NAME_PLATE_UNIT_ADDED**: Evento cuando se añade un nuevo nameplate (para hookear dinámicamente)

### Estructura del Código

- `Module:SetupMouseoverDebug()`: Inicializa el sistema de debug
- `Module:OnMouseoverDebug()`: Manejador del evento UPDATE_MOUSEOVER_UNIT
- `Module:HookMouseoverOnNameplate(nameplate)`: Aplica hooks a un nameplate específico
- `Module:DebugNameplateState(nameplate)`: Imprime el estado completo de un nameplate
- `Module:SlashCommand(input)`: Maneja los comandos de consola

### Flags de Control

- `Module.mouseoverDebugEnabled`: Booleano que controla si el debug está activo
- `nameplate.UnitFrame.mouseoverHooked`: Flag para evitar hookear el mismo frame múltiples veces

## Consejos de Uso

1. **Activa el debug solo cuando lo necesites**: El debug puede generar mucho spam en el chat si lo dejas activado permanentemente.

2. **Usa /yatpnp test**: Si solo quieres ver el estado de una unidad específica sin activar el modo continuo.

3. **Prueba con diferentes tipos de unidades**: Enemigos, aliados, NPCs, jugadores, etc., pueden tener comportamientos diferentes.

4. **Observa los valores de alpha**: Un alpha de 0.00 significa invisible, 1.00 completamente visible.

5. **Presta atención a qué elementos están "Shown"**: Un elemento puede tener alpha pero no estar visible si Shown=false.
