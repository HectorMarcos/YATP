# Quest Tracker Module - YATP

## Descripción General

El módulo Quest Tracker mejora significativamente la experiencia del rastreador de misiones del juego, proporcionando características avanzadas de visualización, personalización y seguimiento automático.

## Características Principales

### 🎯 Visualización Mejorada
- **Niveles de Misión**: Muestra el nivel de cada misión en el rastreador
- **Porcentajes de Progreso**: Calcula y muestra porcentajes de completado para objetivos
- **Modo Compacto**: Opción para una visualización más condensada
- **Código de Color por Dificultad**: Colorea las misiones según su dificultad relativa

### 🎨 Personalización Visual
- **Escala del Rastreador**: Ajusta el tamaño (0.5x a 2.0x)
- **Transparencia**: Control de transparencia (10% a 100%)
- **Bloqueo de Posición**: Previene el movimiento accidental del rastreador
- **Iconos de Misión**: Muestra iconos representativos para cada tipo de misión

### 🔔 Sistema de Notificaciones
- **Notificaciones de Progreso**: Alertas cuando se actualiza el progreso
- **Sonidos de Completado**: Reproduce sonidos al completar misiones
- **Alertas de Objetivos**: Notificaciones para objetivos individuales completados

### 🤖 Seguimiento Automático
- **Auto-seguimiento de Nuevas**: Rastrea automáticamente misiones recién aceptadas
- **Auto-desactivar Completadas**: Retira automáticamente misiones completadas del rastreador
- **Límite Personalizable**: Configura el máximo de misiones a seguir simultáneamente (5-50)

### 📋 Opciones de Organización
- **Ordenamiento Personalizado**: Varias opciones de ordenamiento disponibles
  - Por nivel de misión
  - Por zona geográfica
  - Por distancia al objetivo
- **Resaltado de Objetivos Cercanos**: Destaca objetivos próximos al jugador

## Comandos de Acceso Rápido

- `/questtracker` - Abre la configuración del módulo
- `/qt` - Atajo para abrir la configuración

## Configuración

El módulo se integra completamente con el sistema de configuración de YATP. Accede a través de:

1. Panel de configuración de YATP
2. Comandos de chat mencionados arriba
3. Desde el menú de interfaz del juego

### Categorías de Configuración

#### Opciones de Visualización
- Control de características de visualización mejorada
- Configuración de niveles y porcentajes
- Modo compacto y códigos de color

#### Configuración Visual
- Escala y transparencia del rastreador
- Opciones de posición y bloqueo

#### Notificaciones
- Control de alertas de progreso
- Configuración de sonidos
- Alertas de objetivos completados

#### Seguimiento Automático
- Auto-seguimiento de misiones nuevas
- Gestión automática de misiones completadas
- Límites de seguimiento simultáneo

## Compatibilidad

### Eventos Utilizados
- `QUEST_WATCH_UPDATE` - Actualización del seguimiento de misiones
- `QUEST_LOG_UPDATE` - Actualización del registro de misiones
- `UI_INFO_MESSAGE` - Mensajes de interfaz de usuario
- `QUEST_COMPLETE` - Completado de misiones
- `PLAYER_ENTERING_WORLD` - Entrada al mundo

### APIs del Juego
- `C_QuestLog.GetNumQuestLogEntries()`
- `C_QuestLog.GetInfo()`
- `C_QuestLog.IsComplete()`
- `C_QuestLog.GetQuestObjectives()`
- `C_QuestLog.RemoveQuestWatch()`

## Notas Técnicas

### Rendimiento
- Usa hooks no intrusivos en las funciones del rastreador
- Cache inteligente de información de misiones
- Evita actualizaciones excesivas mediante throttling

### Estructura de Datos
El módulo mantiene una tabla local `trackedQuests` que almacena:
```lua
trackedQuests[questID] = {
    title = "Título de la Misión",
    level = 25,
    difficultyLevel = "normal",
    isComplete = false,
    objectives = {...}
}
```

### Migraciones
El sistema incluye soporte para migración de configuraciones entre versiones, asegurando que las preferencias del usuario se mantengan al actualizar.

## Ideas para Desarrollo Futuro

- Integración con mapamundi para mostrar rutas óptimas
- Filtros avanzados por tipo de misión
- Estadísticas de completado de misiones
- Backup/restauración de configuraciones
- Perfiles de configuración por personaje
- Integración con addons de mapas populares

## Contribución

Para contribuir al desarrollo de este módulo:

1. Haz fork del repositorio
2. Crea una rama para tu funcionalidad (`git checkout -b feature/nueva-funcionalidad`)
3. Realiza commits descriptivos
4. Abre un Pull Request

## Localización

El módulo incluye soporte completo para:
- 🇺🇸 Inglés (enUS) - Completo
- 🇪🇸 Español (esES) - Completo  
- 🇫🇷 Francés (frFR) - Completo

Para agregar un nuevo idioma, crea un archivo en `locales/` siguiendo el patrón existente.