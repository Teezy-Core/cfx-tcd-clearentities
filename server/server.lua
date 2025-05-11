local playerSettings = {}
local configFile = "settings.json"
local ServerEntityManager = require 'server.modules.serverentitymanager'

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

-- Add server-side events for clearing entities
RegisterNetEvent('cfx-tcd-clearentities:serverClearEntities')
AddEventHandler('cfx-tcd-clearentities:serverClearEntities', function(entityType)
    local src = source
    
    -- Check if source has admin permissions
    local hasPermission = false
    for _, permission in ipairs(Config.permissions) do
        if IsPlayerAceAllowed(src, permission) then
            hasPermission = true
            break
        end
    end
    
    local QBCore = exports['qb-core']:GetCoreObject()
    local Player = QBCore and QBCore.Functions.GetPlayer(src)
    local frameworkAdmin = Player and (Player.PlayerData.admin or Player.PlayerData.group == 'admin' or Player.PlayerData.group == 'god')
    
    if hasPermission or frameworkAdmin then
        local result
        if entityType == 'all' then
            result = ServerEntityManager.clearAllEntities()
            
            -- Broadcast notification to all clients
            TriggerClientEvent('cfx-tcd-clearentities:globalNotify', -1, 'System', 'All world entities have been cleared.', 5000)
        else
            result = ServerEntityManager.clearEntityType(entityType)
            
            -- Broadcast notification to all clients
            TriggerClientEvent('cfx-tcd-clearentities:globalNotify', -1, 'System', entityType:gsub("^%l", string.upper) .. ' have been cleared.', 5000)
        end
        
        -- Return results to the requesting client
        TriggerClientEvent('cfx-tcd-clearentities:clearResult', src, result)
    else
        -- Send permission denied message
        TriggerClientEvent('cfx-tcd-clearentities:globalNotify', src, 'Error', 'You do not have permission to clear entities.', 5000)
    end
end)

-- Server-side auto clearing timer
local clearTimer = nil

local function scheduleClearEntities(interval)
    if clearTimer then
        clearTimer = nil
    end
    
    if not serverSettings.enabled then
        return
    end
    
    local intervalMs = interval * 60 * 1000
    
    clearTimer = SetTimeout(intervalMs, function()
        if serverSettings.enabled then
            -- Announce entity clearing if configured
            if serverSettings.announceSeconds > 0 then
                TriggerClientEvent('cfx-tcd-clearentities:globalNotify', -1, 'System', 'All world entities will be cleared in ' .. serverSettings.announceSeconds .. ' seconds.', 5000)
                
                -- Wait for announcement time before clearing
                SetTimeout(serverSettings.announceSeconds * 1000, function()
                    ServerEntityManager.clearAllEntities()
                    TriggerClientEvent('cfx-tcd-clearentities:globalNotify', -1, 'System', 'All world entities have been cleared.', 5000)
                    
                    -- Schedule next clear
                    scheduleClearEntities(serverSettings.intervalMinutes)
                end)
            else
                -- Clear immediately with no announcement
                ServerEntityManager.clearAllEntities()
                TriggerClientEvent('cfx-tcd-clearentities:globalNotify', -1, 'System', 'All world entities have been cleared.', 5000)
                
                -- Schedule next clear
                scheduleClearEntities(serverSettings.intervalMinutes)
            end
        end
    end)
end

-- Apply settings and start the auto clear scheduler
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

    -- At the end of the function, start the scheduler
    if clearTimer then
        clearTimer = nil
    end
    
    if serverSettings.enabled then
        scheduleClearEntities(serverSettings.intervalMinutes)
    end
end)

-- Start the auto clear scheduler when resource starts
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

    -- At the end of the thread, start the scheduler
    if serverSettings.enabled then
        scheduleClearEntities(serverSettings.intervalMinutes)
    end
end)