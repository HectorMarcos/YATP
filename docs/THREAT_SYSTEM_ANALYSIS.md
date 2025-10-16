# Threat System Analysis
**Fecha**: 2025-10-16
**Rama**: fix-threat-color-issue

## Problema Reportado
El threat system está aplicando colores a las nameplates sin estar en party, posiblemente después de los últimos cambios realizados.

## Código Analizado

### Función: `UpdateNameplateThreat` (línea 1316)
- ✅ Verifica si el threat system está habilitado
- ✅ Verifica si el jugador está en grupo: `if not IsInGroup() and not IsInRaid() then return end`
- ✅ Retorna early si `threatLevel == "none"`

### Función: `GetThreatLevel` (línea 1362)
- ✅ Verifica si está en grupo: `if not IsInGroup() and not IsInRaid() then return "none" end`
- ✅ Verifica si la unidad es atacable
- ⚠️ **POSIBLE ISSUE**: Verifica si ambos están en combate: `if not UnitAffectingCombat(unit) or not UnitAffectingCombat("player")`
- ⚠️ **POSIBLE ISSUE**: Verificaciones de targeting que podrían dar falsos positivos

### Verificaciones de Combate/Targeting:
```lua
-- Verifica combate (puede ser true incluso solo)
if not UnitAffectingCombat(unit) or not UnitAffectingCombat("player") then
    return "none"
end

-- Verifica targeting directo
local isTargetingPlayerOrPet = (unitTarget == playerName) or (petName and unitTarget == petName)
local isPlayerTargeting = (playerTarget == unitName)

if not isTargetingPlayerOrPet and not isPlayerTargeting then
    return "none"
end
```

## Posibles Causas del Problema

### 1. **Condición de Carrera al Salir del Grupo**
- Cuando el jugador sale de un grupo, puede haber un breve momento donde:
  - Los colores de threat ya están aplicados
  - El evento `GROUP_LEFT` se dispara
  - Pero los colores no se limpian inmediatamente de todas las nameplates

### 2. **Verificación de Combat State Insuficiente**
- La verificación `UnitAffectingCombat("player")` puede ser true cuando estás solo
- Aunque hay verificación de `IsInGroup()`, podría haber un timing issue

### 3. **Falta de Limpieza al Cambiar Estado del Grupo**
- La función `OnGroupChanged` actualiza indicadores pero podría no limpiar completamente
- Función `ClearAllThreatColors` existe pero puede no llamarse en todos los casos

### 4. **Mouseover Highlight Interaction**
- En `ApplyThreatToHealthBar` (línea 1445), hay protección contra mouseover
- Pero esta protección podría fallar si mouseover system está deshabilitado

## Escenarios a Probar

1. ✓ Estar en party, entrar en combate → Los colores deberían aparecer
2. ✓ Salir del party mientras está en combate → Los colores deberían desaparecer inmediatamente
3. ✓ Estar solo y entrar en combate → NO deberían aparecer colores
4. ✓ Entrar a party después de estar solo → Verificar que funciona correctamente

## Soluciones Propuestas

### Solución 1: Agregar Verificación Extra en GetThreatLevel
Agregar una verificación de doble seguridad al inicio de `GetThreatLevel`:
```lua
-- Double-check: Never apply threat colors when solo, regardless of combat state
if not IsInGroup() and not IsInRaid() then
    return "none"
end
```
**Estado**: Ya existe esta verificación ✓

### Solución 2: Forzar Limpieza Inmediata al Salir del Grupo
Mejorar `OnGroupChanged` para limpiar inmediatamente:
```lua
function Module:OnGroupChanged()
    if not self.db.profile.threatSystem.enabled then return end
    
    -- If player is now solo, immediately clear all threat colors
    if not IsInGroup() and not IsInRaid() then
        self:ClearAllThreatColors()
    else
        -- Update threat indicators for group members
        self:UpdateAllThreatIndicators()
    end
end
```

### Solución 3: Agregar Limpieza en UpdateAllThreatIndicators
Agregar verificación al inicio de `UpdateAllThreatIndicators`:
```lua
function Module:UpdateAllThreatIndicators()
    if not self.db.profile.threatSystem.enabled then 
        return 
    end
    
    -- Clear colors if solo
    if not IsInGroup() and not IsInRaid() then
        self:ClearAllThreatColors()
        return
    end
    
    -- Update threat for all active nameplates
    -- ... resto del código
end
```

### Solución 4: Mejorar ClearAllThreatColors
Asegurar que la limpieza es completa y afecta tanto colores como datos:
```lua
function Module:ClearAllThreatColors()
    -- Remove threat colors from all nameplates
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            -- Reset to default enemy color
            self:ResetHealthBarColor(nameplate.UnitFrame)
        end
    end
    
    -- Clear threat data
    if self.threatData then
        self.threatData = {}
    end
end
```

## Recomendación

Implementar **Soluciones 2 y 3** simultáneamente:
1. Mejorar `OnGroupChanged` para detectar cuando el jugador queda solo y limpiar inmediatamente
2. Agregar verificación defensiva en `UpdateAllThreatIndicators` para prevenir que se apliquen colores cuando está solo

Esto crea múltiples capas de protección contra el problema.

## Próximos Pasos

1. ✅ Crear rama: `fix-threat-color-issue`
2. ⏳ Implementar soluciones propuestas
3. ⏳ Probar en juego:
   - Solo en combate (NO debe haber colores)
   - En party en combate (DEBE haber colores)
   - Salir de party durante combate (colores deben desaparecer)
4. ⏳ Verificar que no hay regresiones en otros sistemas
5. ⏳ Commit y documentar cambios
