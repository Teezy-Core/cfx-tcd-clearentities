local playerSettings = {}
local configFile = "settings.json"

local defaultSettings = {
    enabled = false,
    intervalMinutes = 1,
    announceSeconds = 30
}

local serverSettings = {
    enabled = false,
    intervalMinutes = 1,
    announceSeconds = 30
}

local function loadSettingsFromFile()
    local fileContent = LoadResourceFile(GetCurrentResourceName(), configFile)
    if fileContent then
        local success, result = pcall(function()
            return json.decode(fileContent)
        end)

        if success and result then
            print("[TCD] Loaded settings from file")
            return result
        else
            print("[TCD] Error parsing settings file, using defaults")
        end
    else
        print("[TCD] Settings file not found, will create one")
    end
    return defaultSettings
end

local function saveSettingsToFile(settings)
    local saveSettings = {
        enabled = settings.enabled == true,
        intervalMinutes = math.max(1, math.min(240, settings.intervalMinutes or defaultSettings.intervalMinutes)),
        announceSeconds = math.max(0, math.min(120, settings.announceSeconds or defaultSettings.announceSeconds))
    }

    local fileContent = json.encode(saveSettings)

    local success = SaveResourceFile(GetCurrentResourceName(), configFile, fileContent, -1)

    if success then
        print("[TCD] Settings saved successfully to " .. configFile)
        serverSettings = saveSettings
    else
        print("[TCD] Failed to save settings to " .. configFile)
    end

    return saveSettings
end

Citizen.CreateThread(function()
    local loadedSettings = loadSettingsFromFile()

    serverSettings = {
        enabled = loadedSettings.enabled == true,
        intervalMinutes = math.max(1, math.min(240, loadedSettings.intervalMinutes or defaultSettings.intervalMinutes)),
        announceSeconds = math.max(0, math.min(120, loadedSettings.announceSeconds or defaultSettings.announceSeconds))
    }

    if not LoadResourceFile(GetCurrentResourceName(), configFile) then
        saveSettingsToFile(serverSettings)
    end

    print("[TCD] Auto-clear settings initialized: " ..
        (serverSettings.enabled and "Enabled" or "Disabled") ..
        ", Interval: " .. serverSettings.intervalMinutes ..
        "m, Announce: " .. serverSettings.announceSeconds .. "s")
end)

RegisterNetEvent('cfx-tcd-cleanentities:saveAutoClearSettings')
AddEventHandler('cfx-tcd-cleanentities:saveAutoClearSettings', function(settings)
    local src = source

    if settings and type(settings) == 'table' then
        local savedSettings = saveSettingsToFile(settings)

        playerSettings[src] = savedSettings

        print("[TCD] Saved settings for source " .. src .. ": " ..
            (savedSettings.enabled and "Enabled" or "Disabled") ..
            ", Interval: " .. savedSettings.intervalMinutes ..
            "m, Announce: " .. savedSettings.announceSeconds .. "s")
    else
        print("[TCD] Invalid settings object received from source " .. src)
    end
end)

RegisterNetEvent('cfx-tcd-clearentities:globalNotify', function(title, message, duration)
    TriggerClientEvent('cfx-tcd-clearentities:globalNotify', -1, title, message, duration)
end)

RegisterNetEvent('cfx-tcd-cleanentities:requestAutoClearSettings')
AddEventHandler('cfx-tcd-cleanentities:requestAutoClearSettings', function()
    local src = source

    playerSettings[src] = serverSettings

    TriggerClientEvent('cfx-tcd-cleanentities:receiveAutoClearSettings', src, serverSettings)

    print("[TCD] Sent settings to source " .. src .. ": " ..
        (serverSettings.enabled and "Enabled" or "Disabled") ..
        ", Interval: " .. serverSettings.intervalMinutes ..
        "m, Announce: " .. serverSettings.announceSeconds .. "s")
end)

RegisterNetEvent('cfx-tcd-cleanentities:checkAdminPermissions')
AddEventHandler('cfx-tcd-cleanentities:checkAdminPermissions', function(playerId)
    local source = source
    local hasAcePermission = false

    for _, permission in ipairs(Config.permissions) do
        if IsPlayerAceAllowed(source, permission) then
            hasAcePermission = true
            break
        end
    end

    local frameworkAdmin = false

    local QBCore = exports['qb-core']:GetCoreObject()
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            frameworkAdmin = Player.PlayerData.admin or Player.PlayerData.group == 'admin' or
            Player.PlayerData.group == 'god'
        end
    end

    TriggerClientEvent('cfx-tcd-cleanentities:adminPermissionsResult', source, hasAcePermission, frameworkAdmin)
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerSettings[src] = nil
end)

if not DoesFileExist then
    function DoesFileExist(path)
        local fileContent = LoadResourceFile(GetCurrentResourceName(),
            path:gsub("resources/" .. GetCurrentResourceName() .. "/", ""))
        return fileContent ~= nil
    end
end