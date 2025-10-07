--========================================================--
-- YATP - Core.lua
-- Yet Another Tweaks Pack
--========================================================--

local ADDON_NAME = "YATP"
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true)

-------------------------------------------------
-- Core addon object
-------------------------------------------------
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then return end

-------------------------------------------------
-- Defaults
-------------------------------------------------
local defaults = {
    profile = {
        modules = {}, -- cada módulo guardará aquí su config
    }
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function YATP:OnInitialize()
    self.db = AceDB:New("YATP_DB", defaults, true)
    self.modules = self.modules or {}
    self.categories = self.categories or {}          -- tablas de opciones por categoría
    self.categoryFrames = self.categoryFrames or {}  -- referencias a frames de InterfaceOptions

    self:Print("|cff33ff99YATP|r inicializando...")

    local version = GetAddOnMetadata(ADDON_NAME, "Version") or "?"

    -- Panel raíz (solo página "About"). Las categorías se registran como sub-panels
    self.options = {
        type = "group",
        name = "YATP",
        args = {
            desc = { type = "description", name = L["A modular collection of interface tweaks and utilities."], fontSize = "medium", order = 1 },
            author = { type = "description", name = string.format("%s: %s", L["Author"] or "Author", "Zavah"), order = 2 },
            ver = { type = "description", name = string.format("%s: %s", L["Version"] or "Version", version), order = 3 },
            spacer = { type = "description", name = "\n", order = 4 },
            note = { type = "description", name = L["Select a category tab to configure modules."] or "Select a category tab to configure modules.", order = 5 },
        },
    }

    AceConfig:RegisterOptionsTable("YATP", self.options)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("YATP", "YATP")

    -- Crear categorías base para que aparezcan con el símbolo '+' aunque estén vacías
    self:EnsureCategory("Interface", 10)
    self:EnsureCategory("QualityOfLife", 11, true) -- placeholder

    -- Comando por chat
    self:RegisterChatCommand("yatp", "ChatCommand")

    self:Print("YATP inicializado correctamente.")
end

-------------------------------------------------
-- Crear / asegurar categoría (panel secundario)
-------------------------------------------------
function YATP:EnsureCategory(category, order, withPlaceholder)
    if self.categories[category] then return self.categories[category] end

    local key = "YATP-" .. category
    -- Aceptamos dos posibles claves: "QualityOfLife" (sin espacios) y "Quality of Life" (con espacios)
    local localizedName = L[category] or L[category == "QualityOfLife" and "Quality of Life" or category] or category

    local opts = {
        type = "group",
        name = localizedName,
        order = order or 100,
        childGroups = "tab", -- dentro de la categoría los módulos serán tabs
        args = {}
    }
    if withPlaceholder then
        opts.args.placeholder = { type = "description", name = L["No modules in this category yet."] or "No modules in this category yet.", order = 1 }
    end

    self.categories[category] = opts
    AceConfig:RegisterOptionsTable(key, opts)
    local frame = AceConfigDialog:AddToBlizOptions(key, localizedName, "YATP")
    self.categoryFrames[category] = frame
    return opts
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function YATP:OnEnable()
    self:Print("YATP cargado. Usa /yatp para configurar.")
end

-------------------------------------------------
-- Registro de módulos
-------------------------------------------------
function YATP:RegisterModule(name, module)
    if not name or not module then
        self:Print("Error: módulo inválido.")
        return
    end

    if self.modules[name] then
        self:Print("Módulo '" .. name .. "' ya está registrado.")
        return
    end

    self.modules[name] = module
    self:Print("Registrando módulo: " .. name)

    if type(module.OnModuleInitialize) == "function" then
        -- Inicializar el módulo
        local success, err = pcall(function() module:OnModuleInitialize() end)
        if not success then
            self:Print("Error inicializando módulo " .. name .. ": " .. tostring(err))
        else
            self:Print("Módulo " .. name .. " inicializado correctamente.")
        end
    end
end

-------------------------------------------------
-- Añadir opciones al panel
-------------------------------------------------
function YATP:AddModuleOptions(name, optionsTable, category)
    if not name or not optionsTable then return end
    category = category or "Interface"

    local catOpts = self:EnsureCategory(category)
    if not catOpts.args then catOpts.args = {} end

    if catOpts.args.placeholder then
        catOpts.args.placeholder = nil
    end

    -- Siempre crear un grupo para el módulo (consistente y visible)
    -- Calcular orden en base a cuántos grupos ya hay (ignorando placeholder)
    local count = 0
    for k,_ in pairs(catOpts.args) do
        if k ~= "placeholder" then count = count + 1 end
    end
    local order = 10 + count

    catOpts.args[name] = {
        type = "group",
        name = L[name] or name,
        order = order,
        args = optionsTable.args or {},
    }
    -- Tabs sólo si más de un módulo
    local realModules = 0
    for k,v in pairs(catOpts.args) do
        if type(v) == "table" and v.type == "group" and k ~= "placeholder" then
            realModules = realModules + 1
        end
    end
    catOpts.childGroups = (realModules > 1) and "tab" or nil

    AceConfigRegistry:NotifyChange("YATP-" .. category)
    self:Print(string.format("Opciones registradas para módulo '%s' en categoría '%s'", name, category))
end

-------------------------------------------------
-- Abrir configuración
-------------------------------------------------
function YATP:OpenConfig(target)
    -- Abrir raíz siempre primero para asegurar lista expandible
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- doble llamada por bug

    if not target or target:trim() == "" then
        return -- About ya visible al seleccionar raíz
    end

    -- ¿Es una categoría?
    if self.categoryFrames[target] then
        InterfaceOptionsFrame_OpenToCategory(self.categoryFrames[target])
        InterfaceOptionsFrame_OpenToCategory(self.categoryFrames[target])
        return
    end

    -- Buscar módulo dentro de categorías
    for cat, opts in pairs(self.categories) do
        if opts.args and opts.args[target] then
            local frame = self.categoryFrames[cat]
            if frame then
                InterfaceOptionsFrame_OpenToCategory(frame)
                InterfaceOptionsFrame_OpenToCategory(frame)
                -- Seleccionar el grupo (tab) del módulo dentro de la categoría
                AceConfigDialog:SelectGroup("YATP-" .. cat, target)
            end
            return
        end
    end
end

-------------------------------------------------
-- Chat Command
-------------------------------------------------
function YATP:ChatCommand(input)
    input = input and input:trim():lower() or ""

    if input == "" then
        self:OpenConfig()
    elseif input == "modules" then
        self:Print("Módulos registrados:")
        for name in pairs(self.modules) do
            self:Print(" - " .. name)
        end
    elseif input == "reload" then
        ReloadUI()
    else
        self:Print("Comandos disponibles:")
        self:Print("/yatp → abre la configuración")
        self:Print("/yatp modules → lista los módulos activos")
        self:Print("/yatp reload → recarga la interfaz")
    end
end

-------------------------------------------------
-- Helper para localización
-------------------------------------------------
function YATP:L(key)
    return L[key] or key
end
