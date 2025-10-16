# Solución: Bloquear el Glow del Mouseover en Nameplates

## 🎯 Problema Resuelto

Cuando pasas el cursor del ratón sobre un nameplate, aparece un **borde blanco/amarillo brillante** alrededor de la barra de salud. Este efecto visual es causado por el **borde del healthBar cambiando de color** de negro a blanco/amarillo.

## ✅ Solución Implementada

Se ha implementado un sistema que **bloquea los cambios de color del borde** cuando se hace mouseover, eliminando completamente el efecto de glow.

## 🔧 Cómo Funciona

El sistema intercepta la función `SetVertexColor` del borde y la reemplaza con una versión que mantiene el color bloqueado en lugar de permitir cambios.

### Detalles Técnicos:
1. **Captura el color original** del borde (normalmente negro)
2. **Guarda la función original** `SetVertexColor`
3. **Reemplaza la función** con una versión que ignora los nuevos colores
4. **Mantiene el color bloqueado** incluso cuando el juego intenta cambiarlo

## 📋 Cómo Usar

### Opción 1: Configuración en la Interfaz

1. Abre el menú de YATP: `/yatp` o Escape → Interfaz → YATP
2. Ve a **NamePlates → General**
3. Busca la sección **"Block Mouseover Border Glow (YATP Custom)"**
4. Activa **"Block Mouseover Border Glow"**

### Opción 2: Comando de Consola (Temporal)

Para probar rápidamente:
```lua
/yatpnp blockborder
```
Este comando bloqueará el glow inmediatamente en todos los nameplates activos. Es temporal y se revertirá al recargar la UI.

## ⚙️ Opciones de Configuración

### 1. **Block Mouseover Border Glow**
- **Tipo:** Toggle (On/Off)
- **Descripción:** Activa/desactiva el bloqueo del glow
- **Por defecto:** Desactivado
- **Ubicación:** YATP → NamePlates → General

### 2. **Keep Original Border Color**
- **Tipo:** Toggle (On/Off)
- **Descripción:** Mantiene el color original del borde (normalmente negro)
- **Por defecto:** Activado
- **Nota:** Si se desactiva, puedes elegir un color personalizado

### 3. **Custom Border Color**
- **Tipo:** Color Picker (RGBA)
- **Descripción:** Color personalizado para el borde (solo si "Keep Original Border Color" está desactivado)
- **Por defecto:** Negro (0, 0, 0, 1)
- **Nota:** Puedes elegir cualquier color, incluyendo transparencia

## 🎨 Ejemplos de Uso

### Ejemplo 1: Borde Negro Permanente (Recomendado)
```
Block Mouseover Border Glow: ✅ Enabled
Keep Original Border Color: ✅ Enabled
```
**Resultado:** El borde permanece negro siempre, sin glow en mouseover.

### Ejemplo 2: Borde Azul Personalizado
```
Block Mouseover Border Glow: ✅ Enabled
Keep Original Border Color: ❌ Disabled
Custom Border Color: Azul (0, 0.5, 1, 1)
```
**Resultado:** Todos los bordes serán azules y no cambiarán en mouseover.

### Ejemplo 3: Sin Borde Visible
```
Block Mouseover Border Glow: ✅ Enabled
Keep Original Border Color: ❌ Disabled
Custom Border Color: Transparente (0, 0, 0, 0)
```
**Resultado:** Los bordes serán invisibles.

## 🔄 Cambios en Tiempo Real

Todos los cambios en la configuración se aplican **inmediatamente** sin necesidad de recargar la UI:
- Activar/desactivar el bloqueo
- Cambiar entre color original y personalizado
- Ajustar el color personalizado

## 🛠️ Comandos de Consola

### Comandos de Debug (usados durante la investigación):
```lua
/yatpnp debug          -- Activa el modo debug para ver cambios
/yatpnp test           -- Prueba el debug en el mouseover actual
/yatpnp blockborder    -- Bloquea el borde temporalmente (para pruebas)
/yatpnp help           -- Muestra todos los comandos
```

## 📊 Datos de la Investigación

Durante la investigación se descubrió que:

1. **`selectionHighlight`** - NO era el culpable (Alpha=0.00, nunca se activaba)
2. **`aggroHighlight`** - NO era el culpable (Alpha=0.00, nunca se activaba)
3. **`healthBar.border`** - ¡ERA EL CULPABLE!
   - Textura: `SolidTexture`
   - Color normal: `RGBA(0, 0, 0, 1)` (Negro)
   - Color en mouseover: `RGBA(1, 1, 1, 1)` (Blanco) - Esto creaba el glow

### Método de Detección:
Se utilizó el comando `/yatpnp blockborder` que bloqueaba forzosamente el color del borde en negro. Al hacer mouseover y ver que el glow desaparecía, se confirmó que el borde era el responsable.

## 🚀 Beneficios

1. **Elimina Distracción Visual:** Sin el glow brillante, es más fácil concentrarse
2. **Reduce Fatiga Visual:** Menos cambios bruscos de brillo
3. **Personalizable:** Puedes elegir el color del borde que prefieras
4. **Rendimiento:** Mínimo impacto, solo reemplaza una función
5. **Compatible:** Funciona junto con el addon Ascension_NamePlates

## ⚠️ Notas Importantes

- **Recargar UI:** Si desactivas el bloqueo, la función original se restaura automáticamente
- **Compatibilidad:** Funciona con el sistema de threat colors (los colores de amenaza tienen prioridad sobre el borde)
- **Nameplates Nuevos:** El bloqueo se aplica automáticamente a nameplates que aparecen después de activarlo
- **Reversible:** Puedes desactivarlo en cualquier momento sin efectos secundarios

## 🐛 Solución de Problemas

### El glow todavía aparece
1. Verifica que "Block Mouseover Border Glow" esté activado
2. Recarga la UI: `/reload`
3. Verifica que no haya otros addons de nameplates conflictivos

### Los bordes desaparecieron completamente
1. Desactiva "Block Mouseover Border Glow"
2. Si el problema persiste, desactiva y reactiva el módulo de NamePlates en YATP

### Quiero restaurar el comportamiento original
1. Ve a YATP → NamePlates → General
2. Desactiva "Block Mouseover Border Glow"
3. El comportamiento normal se restaurará inmediatamente

## 📝 Créditos

Investigación y desarrollo realizado mediante:
- Sistema de debug exhaustivo con hooks en múltiples eventos
- Escaneo de frames, texturas y regiones
- Pruebas de bloqueo selectivo de funciones
- Análisis de cambios de estado antes/después del mouseover

## 🎉 Resultado Final

¡Problema resuelto! Ahora tienes control total sobre el glow del mouseover en los nameplates. Puedes eliminarlo por completo o personalizarlo como prefieras.
