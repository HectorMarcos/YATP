--========================================================--
-- YATP - Lightweight Central Scheduler
--========================================================--
-- Objetivo: Unificar tareas periódicas (antes múltiples OnUpdate frames)
-- Proporciona:
--   YATP:GetScheduler():AddTask(name, interval, func, opts)
--   YATP:GetScheduler():RemoveTask(name)
--   YATP:GetScheduler():Reschedule(name, newInterval)
--   YATP:GetScheduler():RunNow(name)
--   YATP:GetScheduler():SetEnabled(name, enabled)
--   YATP:GetScheduler():ForEach(function(name, task) ... end)
-- Características:
--   * Un único OnUpdate con bucket de tiempo acumulado.
--   * Soporta 'spread' para escalonar la primera ejecución y evitar bursts.
--   * Manejo de errores aislado con pcall para evitar romper el loop.
--   * Estadísticas simples de ejecución (lastRun, runCount, totalTime, avg ms) opcional.
-- Uso previsto: migrar Hotkeys, QuickConfirm, ChatBubbles sweeps, etc.

local ADDON = "YATP"
local YATP = LibStub and LibStub("AceAddon-3.0", true) and LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end

local Scheduler = {}
Scheduler.__index = Scheduler

local frame
local tasks = {}
local time = GetTime

local function EnsureFrame()
    if frame then return end
    frame = CreateFrame("Frame", "YATP_SchedulerFrame")
    frame:SetScript("OnUpdate", function(_, elapsed)
        local now = time()
        for name, t in pairs(tasks) do
            if t.enabled ~= false and t.nextRun <= now then
                local started = debugprofilestop and debugprofilestop() or 0
                pcall(t.func, t.context)
                local ended = debugprofilestop and debugprofilestop() or 0
                -- stats
                t.lastRun = now
                t.runCount = (t.runCount or 0) + 1
                if ended > started then
                    local dur = (ended - started) / 1000 -- ms -> ms (debugprofilestop devuelve ms?)
                    t.totalTime = (t.totalTime or 0) + dur
                end
                -- reprogramar
                local interval = t.interval
                if type(interval) == "function" then
                    local okInt, dyn = pcall(interval, t)
                    if okInt and type(dyn) == "number" and dyn > 0 then
                        interval = dyn
                    else
                        interval = 0.2 -- fallback razonable
                    end
                end
                t.nextRun = now + interval
            end
        end
    end)
end

function Scheduler:AddTask(name, interval, func, opts)
    if not name or not func or interval == nil then return end
    if tasks[name] then -- actualizar existente
        local t = tasks[name]
        t.interval = interval
        t.func = func
        if type(opts) == "table" then
            for k,v in pairs(opts) do t[k] = v end
        end
        return t
    end
    local now = time()
    local spread = (type(opts) == "table" and opts.spread) or 0
    local numericInterval = interval
    if type(numericInterval) == "function" then
        local okEval, dyn = pcall(numericInterval)
        if okEval and type(dyn) == "number" and dyn > 0 then
            numericInterval = dyn
        else
            numericInterval = 0.2
        end
    end
    if numericInterval <= 0 then numericInterval = 0.01 end
    local firstDelay = numericInterval
    if spread and spread > 0 then
        local maxSpread = spread
        if maxSpread > numericInterval then maxSpread = numericInterval end
        firstDelay = math.random() * maxSpread
    end
    tasks[name] = {
        name = name,
        interval = interval,
        func = func,
        enabled = (type(opts) == "table" and opts.enabled == false) and false or true,
        nextRun = now + firstDelay,
        context = (type(opts) == "table" and opts.context) or nil,
    }
    EnsureFrame()
    return tasks[name]
end

function Scheduler:RemoveTask(name)
    tasks[name] = nil
end

function Scheduler:Reschedule(name, newInterval)
    local t = tasks[name]
    if not t or not newInterval or newInterval <= 0 then return end
    t.interval = newInterval
    t.nextRun = time() + newInterval
end

function Scheduler:RunNow(name)
    local t = tasks[name]
    if not t then return end
    t.nextRun = 0
end

function Scheduler:SetEnabled(name, enabled)
    local t = tasks[name]
    if not t then return end
    t.enabled = enabled and true or false
end

function Scheduler:GetTask(name)
    return tasks[name]
end

function Scheduler:ForEach(fn)
    for n,t in pairs(tasks) do fn(n,t) end
end

function Scheduler:Stats(name)
    local t = tasks[name]
    if not t then return nil end
    local avg
    if t.runCount and t.runCount > 0 and t.totalTime then
        avg = t.totalTime / t.runCount
    end
    return {
        lastRun = t.lastRun,
        runCount = t.runCount or 0,
        totalTime = t.totalTime or 0,
        avg = avg or 0,
        interval = t.interval,
    }
end

-- Exponer instancia única vía YATP
local singleton
function YATP:GetScheduler()
    if not singleton then
        singleton = setmetatable({}, Scheduler)
        EnsureFrame()
    end
    return singleton
end

-- Debug helper comando opcional (solo si modo debug) para listar tareas
SLASH_YATPSCHED1 = "/yatpsched"
SlashCmdList["YATPSCHED"] = function()
    if not YATP:IsDebug() then
        return
    end
    local s = YATP:GetScheduler()
    s:ForEach(function(name, t)
        local stats = s:Stats(name)
        print(string.format("[Sched] %s interval=%.2f runs=%d avg=%.3fms", name, stats.interval or -1, stats.runCount, stats.avg or 0))
    end)
end
