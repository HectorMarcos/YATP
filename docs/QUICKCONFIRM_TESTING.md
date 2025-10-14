# QuickConfirm - Guía de Testing

## 🧪 Testing Checklist

### **Pre-requisitos**
- ✅ Addon cargado correctamente (`/yatp` abre el panel)
- ✅ Módulo QuickConfirm habilitado
- ✅ Branch: `feature/event-driven-quickconfirm`

---

## 📋 Casos de Prueba

### **Test 1: BoP Loot Confirmation**

#### Setup
1. Habilitar `Auto-confirm bind-on-pickup loot popups` en opciones YATP
2. Encontrar un mob o cofre que dropee items BoP

#### Steps
1. Matar mob o abrir cofre con item BoP
2. Lootear el item BoP
3. Observar comportamiento

#### Expected Result
- ✅ El popup de confirmación **NO** debería aparecer
- ✅ El item debería lootearse **instantáneamente**
- ✅ No debería haber delay perceptible (< 50ms)
- ✅ En chat debug (si está activado): `"QuickConfirm: Auto-confirmed BoP loot (slot: X)"`

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)

---

### **Test 2: Transmog Appearance Confirmation**

#### Setup
1. Habilitar `Auto-confirm transmog appearance popups` en opciones YATP
2. Tener AdiBags instalado (opcional, para testar integración)
3. Encontrar un item que tenga apariencia transmog nueva

#### Steps
1. Equipar o usar el item con apariencia nueva
2. Esperar el popup de confirmación
3. Observar comportamiento

#### Expected Result
- ✅ El popup debería aparecer brevemente (~50ms)
- ✅ Se debería confirmar automáticamente
- ✅ Si AdiBags está instalado, debería refrescarse después de 0.3s
- ✅ En chat debug: `"QuickConfirm: Auto-confirmed transmog appearance"`

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)

---

### **Test 3: Toggle de Opciones en Caliente**

#### Setup
1. Estar en juego con el addon cargado
2. Abrir opciones de YATP (`/yatp`)

#### Steps
1. **Desactivar** `Auto-confirm bind-on-pickup loot popups`
2. Intentar lootear item BoP
3. **Activar** `Auto-confirm bind-on-pickup loot popups`
4. Intentar lootear otro item BoP

#### Expected Result
- ✅ Con opción **desactivada**: popup normal (requiere confirmación manual)
- ✅ Con opción **activada**: popup se auto-confirma
- ✅ Los cambios deberían aplicarse **sin necesidad de /reload**

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)

---

### **Test 4: Performance y CPU Usage**

#### Setup
1. Instalar addon de profiling (ej: `Examiner` o usar `/fstack`)
2. Habilitar QuickConfirm

#### Steps
1. Estar idle en ciudad sin lootear nada (5 minutos)
2. Verificar CPU usage del addon
3. Lootear 10 items BoP seguidos
4. Verificar tiempo de respuesta

#### Expected Result
- ✅ CPU usage **idle**: ~0% (no polling)
- ✅ CPU usage **al lootear**: mínimo (solo evento)
- ✅ Tiempo de confirmación: **< 50ms** (instantáneo)
- ✅ No debería haber frame drops o stuttering

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)

---

### **Test 5: Compatibilidad con AdiBags**

#### Setup
1. Instalar AdiBags addon
2. Habilitar QuickConfirm con `autoTransmog = true`
3. Configurar `adiBagsRefreshDelay = 0.3`

#### Steps
1. Equipar item con apariencia transmog nueva
2. Esperar confirmación automática
3. Verificar que AdiBags se refresque

#### Expected Result
- ✅ Transmog se confirma automáticamente
- ✅ Después de 0.3s, AdiBags refresca su display
- ✅ Items transmog deberían moverse a categoría correcta
- ✅ En debug: `"QuickConfirm: Refreshed AdiBags after transmog"`

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)
- [ ] ⚠️ N/A (AdiBags no instalado)

---

### **Test 6: Fallback Hook Method**

#### Setup
1. Activar `Use Fallback Hook Method` en Advanced options
2. (Opcional) Crear condiciones donde evento falle

#### Steps
1. Verificar que transmog funciona con hook
2. Intentar casos edge (lag, popups múltiples, etc.)

#### Expected Result
- ✅ Hook debería activarse para transmog
- ✅ Debería funcionar incluso con lag
- ✅ No debería haber conflictos con otros addons

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)

---

### **Test 7: Disable Module**

#### Setup
1. QuickConfirm habilitado y funcionando
2. Estar en juego

#### Steps
1. Desactivar módulo en opciones YATP
2. `/reload` (si es necesario)
3. Intentar lootear item BoP
4. Intentar equipar transmog

#### Expected Result
- ✅ Popups **NO** deberían auto-confirmarse
- ✅ Comportamiento vanilla de WoW
- ✅ No debería haber errores en chat

#### Actual Result
- [ ] ✅ Passed
- [ ] ❌ Failed (describe el issue)

---

## 🐛 Issues Conocidos y Soluciones

### **Issue 1: BoP loot no se auto-confirma**
```
Síntomas:
- Popup aparece y no se confirma automáticamente
- No hay mensaje de debug

Posibles causas:
1. Módulo no registró evento LOOT_BIND_CONFIRM
2. AceEvent-3.0 no está cargado correctamente
3. Opción autoBopLoot está desactivada

Solución:
/run print(YATP:GetModule("QuickConfirm"):IsEventRegistered("LOOT_BIND_CONFIRM"))
-- Debería imprimir: true

Si imprime false:
/reload
```

### **Issue 2: Transmog se confirma demasiado rápido**
```
Síntomas:
- No puedo ver qué apariencia estoy aprendiendo
- Popup desaparece antes de leerlo

Solución:
1. Aumentar delay en C_Timer.After de 0.05 a 0.1 o más
2. O desactivar autoTransmog temporalmente
```

### **Issue 3: AdiBags no se refresca**
```
Síntomas:
- Items transmog no se reorganizan después de aprender

Verificar:
1. AdiBags está instalado: /adibags
2. Delay configurado correctamente en opciones
3. Debug muestra mensaje de refresh

Solución:
- Aumentar adiBagsRefreshDelay a 0.5s o más
```

---

## 📊 Comparación con Versión Anterior

### **Métricas a Verificar**

| Aspecto | **Antes** | **Después** | **Verificado** |
|---------|-----------|-------------|----------------|
| Delay BoP loot | 0-600ms | 0ms | [ ] |
| CPU idle | ~1-2% | ~0% | [ ] |
| Confirmaciones exitosas | 95-98% | 99-100% | [ ] |
| Frame drops | Ocasionales | Ninguno | [ ] |
| Compatibilidad addons | Buena | Excelente | [ ] |

---

## 🎯 Testing Comandos Útiles

### **Debug Mode**
```lua
-- Activar debug global de YATP
/run YATP.Debug = true

-- Ver eventos registrados
/run for event in pairs(YATP:GetModule("QuickConfirm").events) do print(event) end

-- Verificar estado del módulo
/run print(YATP:GetModule("QuickConfirm"):IsEnabled())

-- Forzar re-registro de eventos
/run YATP:GetModule("QuickConfirm"):RegisterEvents()
```

### **Stress Testing**
```lua
-- Simular 100 confirmaciones de BoP
for i=1,100 do
    -- Lootear items BoP rápidamente
end

-- Verificar memoria usage
/run local before = collectgarbage("count"); C_Timer.After(5, function() print("Memory delta:", collectgarbage("count") - before, "KB") end)
```

---

## ✅ Testing Checklist Final

- [ ] Test 1: BoP Loot Confirmation ✅
- [ ] Test 2: Transmog Appearance ✅
- [ ] Test 3: Toggle Opciones ✅
- [ ] Test 4: Performance/CPU ✅
- [ ] Test 5: AdiBags Integration ✅
- [ ] Test 6: Fallback Hook ✅
- [ ] Test 7: Disable Module ✅
- [ ] No errores en `/console scriptErrors 1` ✅
- [ ] No memory leaks detectados ✅
- [ ] Funciona con otros addons populares ✅

---

## 📝 Reporte de Testing

**Fecha**: ___________  
**Tester**: ___________  
**Branch**: `feature/event-driven-quickconfirm`  
**Commit**: `27e6c55`  

### **Resumen**
- Tests Passed: __ / 7
- Tests Failed: __ / 7
- Issues Críticos: __
- Issues Menores: __

### **Notas Adicionales**
_Agregar comentarios, observaciones o issues encontrados aquí_

---

### **Aprobación para Merge**
- [ ] ✅ Todos los tests pasaron
- [ ] ✅ Performance mejorada vs versión anterior
- [ ] ✅ No hay regression bugs
- [ ] ✅ Documentación actualizada
- [ ] ✅ Ready to merge to `main`

**Aprobado por**: ___________  
**Fecha**: ___________
