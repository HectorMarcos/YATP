# ¿Por qué no se carga Ascension_NamePlates?

## El Problema

El addon **Ascension_NamePlates** tiene `LoadOnDemand: 1` en su archivo `.toc`. Esto significa que aunque esté **habilitado** (enabled), **NO se carga automáticamente** al iniciar el juego.

Puedes verificar esto con:
```
/run print("Enabled:", select(4, GetAddOnInfo("Ascension_NamePlates")))
/run print("Loaded:", IsAddOnLoaded("Ascension_NamePlates"))
```

Probablemente verás:
- **Enabled: true** (está habilitado)
- **Loaded: false** (pero no está cargado!)

## La Solución

Hay **DOS formas** de resolver esto:

---

### ✅ Solución 1: Forzar carga desde YATP (rápido)

**Ventaja:** No cierra el juego  
**Desventaja:** Puede que no siempre funcione con addons LoadOnDemand

1. En el juego: `/yatp`
2. Ve a **NamePlates** → **Status**
3. Clic en: **"Enable & Force Load"**
4. Si ves "Success!", ¡listo!

---

### ✅✅ Solución 2: Quitar LoadOnDemand (PERMANENTE - Recomendado)

**Ventaja:** Solución permanente, funciona siempre  
**Desventaja:** Requiere cerrar el juego

#### Opción A: Usar el script automático

1. **CIERRA el juego completamente**
2. Doble clic en: `Fix_Ascension_NamePlates_LoadOnDemand.ps1`
3. Sigue las instrucciones en pantalla
4. Inicia el juego → el addon se cargará automáticamente

#### Opción B: Hacerlo manualmente

1. **CIERRA el juego completamente**
2. Navega a: `Interface\AddOns\Ascension_NamePlates\`
3. Abre `Ascension_NamePlates.toc` con Notepad
4. Encuentra la línea:
   ```
   ## LoadOnDemand: 1
   ```
5. Cámbiala a:
   ```
   ## LoadOnDemand: 0
   ```
6. Guarda el archivo
7. Inicia el juego → el addon se cargará automáticamente

---

## ¿Qué hace cada solución?

### LoadOnDemand: 1 (original)
- El addon está habilitado pero **NO se carga** al inicio
- Necesitas cargarlo manualmente con `/run LoadAddOn("Ascension_NamePlates")`
- Cada vez que inicias el juego, debes cargarlo de nuevo
- **Problema:** Es molesto y a veces no funciona bien

### LoadOnDemand: 0 (modificado)
- El addon está habilitado **Y se carga automáticamente** al inicio
- No necesitas hacer nada, simplemente funciona
- Cada vez que inicias el juego, ya está activo
- **Solución:** Funciona como cualquier otro addon normal

---

## Verificar que funciona

Después de aplicar la solución, verifica que el addon esté cargado:

```
/run print("Loaded:", IsAddOnLoaded("Ascension_NamePlates"))
```

Deberías ver: **Loaded: true**

También puedes verificar que el addon está funcionando:
- Los nameplates deben mostrarse
- `/yatp` → NamePlates → Status debe mostrar "Loaded: true"
- Deberías ver las pestañas de configuración en YATP

---

## Conflictos con otros addons

Si instalaste **Plater**, **TidyPlates**, **Kui_Nameplates** u otro addon de nameplates, estos pueden desactivar Ascension_NamePlates automáticamente.

Para verificar conflictos:
1. `/yatp` → NamePlates → Status
2. Clic en: **"Check for Conflicting Addons"**
3. Si encuentra conflictos, desactiva el otro addon:
   ```
   /run DisableAddOn("NombreDelAddon")
   /reload
   ```

---

## Preguntas Frecuentes

**P: ¿Es seguro modificar el archivo .toc?**  
R: Sí, solo estás cambiando un valor de configuración. El script crea un backup automático por si acaso.

**P: ¿Ascension permitirá esto?**  
R: Sí, no estás modificando la funcionalidad del addon, solo cuándo se carga. Es como cambiar una configuración.

**P: ¿Tendré que hacer esto cada vez?**  
R: No, una vez que quites LoadOnDemand, el addon se cargará automáticamente siempre.

**P: ¿Qué pasa si actualizo el cliente de Ascension?**  
R: Es posible que sobrescriba el archivo .toc y tengas que volver a aplicar la solución.

**P: ¿Puedo revertir los cambios?**  
R: Sí, simplemente vuelve a cambiar `LoadOnDemand: 0` a `LoadOnDemand: 1`, o usa el archivo backup que el script creó.

---

## Archivos incluidos

- **REACTIVAR_ASCENSION_NAMEPLATES.txt** - Guía completa con todas las opciones
- **Fix_Ascension_NamePlates_LoadOnDemand.ps1** - Script automático de PowerShell
- **README_LoadOnDemand_Fix.md** - Este archivo (explicación técnica)

---

Creado por **YATP** (Yet Another Turtle Project)  
Módulo NamePlates - Mejoras para Ascension_NamePlates
