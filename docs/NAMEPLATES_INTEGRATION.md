# YATP NamePlates Integration

## Descripción

Este módulo de YATP proporciona una interfaz de configuración integrada para el addon **Ascension NamePlates** a través de un sistema de tabs independiente que replica la estructura original del addon.

## Características

### ✅ **Funcionalidades Implementadas**

1. **Categoría Independiente**: NamePlates ahora tiene su propia sección principal en YATP (no está bajo Interface Hub)
2. **Sistema de Tabs**: Réplica el sistema de pestañas del addon original con Status, General, Friendly, Enemy y Personal
3. **Estado del Addon**: Muestra si Ascension NamePlates está disponible, cargado o no encontrado
4. **Carga Automática**: Permite cargar el addon de nameplates si está disponible pero no cargado
5. **Configuración Embebida**: Panel de configuración integrado directamente en YATP con las opciones más comunes
6. **Interfaz Adaptativa**: Muestra tabs de configuración solo cuando el addon está cargado

### 🎛️ **Estructura de Tabs**

#### **📊 Status Tab** (Siempre disponible)
- **Enable NamePlates Integration**: Activa/desactiva la integración
- **Addon Status**: Estado actual del addon (cargado/disponible/no encontrado)
- **Load NamePlates Addon**: Botón para cargar el addon
- **Open Original Configuration**: Acceso al panel original completo
- **Information**: Guía sobre los tabs disponibles

#### **⚙️ General Tab** (Disponible cuando el addon está cargado)
- **Style Settings**:
  - Classic Style toggle
  - Target Scale (0.8-1.4)
- **Clickable Area Settings**:
  - Clickable Width (50-200)
  - Clickable Height (20-80)  
  - Show Clickable Box (debug)

#### **👥 Friendly Tab**
- **Display Options**:
  - Name Only mode (sin barra de salud)
- **Health Bar Settings**:
  - Width (40-200)
  - Height (4-60)
  - Show Health Text toggle

#### **⚔️ Enemy Tab**  
- **Health Bar Settings**:
  - Width (40-200)
  - Height (4-60)
  - Show Health Text toggle
- **Cast Bar Settings**:
  - Enable Cast Bars toggle
  - Cast Bar Height (4-32)

#### **🎯 Enemy Target Tab**
- **Target Visibility**:
  - Target Scale (0.8-2.0) - Enhanced range for better visibility
- **Enhanced Target Options** (YATP-specific):
  - Highlight Enemy Target toggle
  - Highlight Color picker with transparency
  - Enhanced Target Border toggle
- **Target Health Display**:
  - Always Show Target Health Text
  - Target Health Format (Standard/Detailed/Percentage/Actual)

#### **🙋 Personal Tab**
- **Health Bar Settings**:
  - Width (40-200) 
  - Height (4-60)
  - Show Health Text toggle

### 📋 **Categorías de Configuración de NamePlates**

El addon de Ascension NamePlates proporciona estas categorías de configuración:

- **General**: Configuración general y área clickeable
- **Friendly**: Configuración para nameplates de unidades amigables
- **Enemy**: Configuración para nameplates de unidades enemigas  
- **Personal**: Configuración para tu propio nameplate

## Instalación

1. El módulo ya está incluido en YATP y se carga automáticamente
2. Aparece en **YATP → Interface Hub → NamePlates**
3. El addon de Ascension NamePlates debe estar disponible en tu cliente

## Uso

1. Abre la configuración de YATP (`/yatp`)
2. Ve a **Interface Hub** → **NamePlates**
3. Aquí puedes:
   - Ver el estado del addon de nameplates
   - Cargarlo si está disponible
   - Abrir su configuración directamente
   - Configurar opciones de integración

## Estructura Técnica

### Archivos Involucrados

- `modules/nameplates.lua` - Módulo principal de integración
- `nameplates/` - Carpeta con los archivos del addon extraído (para referencia)
- `locales/enUS.lua` - Cadenas de localización

### Funciones Principales

- `CheckNamePlatesAddon()` - Verifica disponibilidad del addon
- `LoadNamePlatesAddon()` - Intenta cargar el addon
- `OpenNamePlatesConfig()` - Abre la configuración del addon
- `GetNamePlatesStatus()` - Obtiene información del estado del addon

## Notas Técnicas

- El módulo no modifica ni interfiere con el funcionamiento del addon de nameplates
- Actúa como un proxy/interfaz para facilitar el acceso a la configuración
- Es compatible con la carga bajo demanda (LoadOnDemand) del addon de nameplates
- Utiliza el sistema de categorías de YATP para organización

## Compatibilidad

- **YATP**: v0.4.2+
- **Ascension NamePlates**: v1.0
- **Cliente**: Interface 30300 (WotLK 3.3.0)
- **Servidor**: Ascension WoW

## Localización

Actualmente soporta:
- Inglés (enUS) - Completo
- Español (esES) - Parcial (hereda de inglés)
- Francés (frFR) - Parcial (hereda de inglés)

## Desarrollo Futuro

### 🔄 **Posibles Mejoras**

1. **Configuración Embebida**: Mostrar algunas opciones básicas directamente en YATP
2. **Presets**: Crear configuraciones predefinidas para diferentes estilos
3. **Sincronización**: Sincronizar algunas configuraciones con otros módulos de YATP
4. **Importar/Exportar**: Funcionalidad para compartir configuraciones

### 🔧 **API para Desarrolladores**

```lua
-- Verificar si el módulo está disponible
local nameplatesModule = YATP:GetModule("NamePlates", true)
if nameplatesModule then
    -- Verificar estado del addon
    local status = nameplatesModule:GetNamePlatesStatus()
    
    -- Cargar addon si es posible
    nameplatesModule:LoadNamePlatesAddon()
    
    -- Abrir configuración
    nameplatesModule:OpenNamePlatesConfig()
end
```

## Autor

- **Zavah** - Desarrollo e integración en YATP
- **Ascension Team** - Addon original de NamePlates