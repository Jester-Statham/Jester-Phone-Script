-- main.lua — JESTER PHONE v2.10 (Stable Loader)
print("[Jester Phone] Запуск загрузчика...")

local function loadModule(name, url)
    print("[Jester Loader] Загружаю: " .. name)
   
    for attempt = 1, 5 do
        local ts = os.time()
        local rnd = math.random(10000000, 99999999)
        local fullUrl = url .. "?t=" .. ts .. "&r=" .. rnd .. "&v=2.10"
       
        local httpResult
        local success = pcall(function()
            httpResult = game:HttpGet(fullUrl, true)
        end)
       
        if success and httpResult and #httpResult > 100 then
            local loadSuccess, result = pcall(loadstring, httpResult)
            if loadSuccess and result then
                local module = result()
                if type(module) == "table" then
                    print("[Jester Phone] ✅ " .. name .. " успешно загружен")
                    return module
                end
            end
        end
       
        warn("[Jester Phone] Попытка " .. attempt .. " для " .. name .. " провалилась")
        task.wait(0.8)
    end
   
    warn("[Jester Phone] ❌ Критически не удалось загрузить " .. name)
    return nil
end

-- ═══════════════════════════════════════════════════════
-- URL-ы
-- ═══════════════════════════════════════════════════════
local BASE_URL = "https://raw.githubusercontent.com/Jester-Statham/Jester-Phone-Script/refs/heads/main/"

local URLS = {
    core      = BASE_URL .. "NEW_core.lua",
    widgets   = BASE_URL .. "NEW_widgets.lua",
    settings  = BASE_URL .. "NEW_settings.lua",
    logs      = BASE_URL .. "NEW_logs.lua",
   
    explorer  = BASE_URL .. "Explorer.lua",
    movement  = BASE_URL .. "Movement.lua",
    autofarm  = BASE_URL .. "AutoTycoon.lua",
    injector  = BASE_URL .. "Injector_1.2.lua",
    superman  = BASE_URL .. "SuperMan_App.lua",
}

-- ═══════════════════════════════════════════════════════
-- ЗАГРУЗКА
-- ═══════════════════════════════════════════════════════
local Core = loadModule("Core", URLS.core)
if not Core then
    error("[jester phone] Критическая ошибка: Core не загрузился.")
end

assert(type(Core.new) == "function", "[jester phone] Core повреждён")

local phone = Core.new()

-- Виджеты
if URLS.widgets then
    local Widgets = loadModule("Widgets", URLS.widgets)
    if Widgets then
        phone.WidgetsModule = Widgets
        phone.Themes = Widgets.Themes
    end
end

-- Регистрация приложений
local appsToLoad = {
    { name = "Settings",  url = URLS.settings },
    { name = "Logs",      url = URLS.logs },
    { name = "Explorer",  url = URLS.explorer },
    { name = "Movement",  url = URLS.movement },
    { name = "AutoTycoon", url = URLS.autofarm },
    { name = "Injector",  url = URLS.injector },
    { name = "SuperMan",  url = URLS.superman },
}

for _, appInfo in ipairs(appsToLoad) do
    if appInfo.url then
        local app = loadModule(appInfo.name, appInfo.url)
        if app then
            phone:RegisterApp(app)
        end
    end
end

-- Запуск
phone:Start()

print("[Jester Phone] ✅ Запущен v" .. (phone.Version or "2.10"))
print("[Jester Phone] Приложений: " .. tostring(#phone.Apps))
