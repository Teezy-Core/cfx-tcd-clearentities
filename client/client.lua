local Utils = require 'client.modules.utils'
local EntityManager = require 'client.modules.entitymanager'
local AutoClearManager = require 'client.modules.autoclearmanager'

local GetGameTimer = GetGameTimer
local Wait = Wait

local function showPanel()
    local results = EntityManager.getAllEntityCounts(Config)

    Utils.toggleNuiFrame('setVisible', true, {
        results = results,
        autoClearSettings = {
            enabled = AutoClearManager.config.enabled,
            intervalMinutes = AutoClearManager.config.intervalMinutes,
            announceSeconds = AutoClearManager.config.announceSeconds
        }
    })
end

RegisterNUICallback('exit', function(_, cb)
    Utils.toggleNuiFrame('setVisible', false)
    cb({})
end)

RegisterNUICallback('clearEntities', function(data, cb)
    -- Instead of clearing locally, send request to server
    TriggerServerEvent('cfx-tcd-clearentities:serverClearEntities', data.type)
    cb({ success = true })
end)

RegisterNUICallback('refreshEntities', function(_, cb)
    local results = EntityManager.getAllEntityCounts(Config)
    cb({ success = true, results = results })
end)

RegisterNUICallback('getAutoClearSettings', function(_, cb)
    cb({
        enabled = AutoClearManager.config.enabled,
        intervalMinutes = AutoClearManager.config.intervalMinutes,
        announceSeconds = AutoClearManager.config.announceSeconds
    })
end)

RegisterNUICallback('setAutoClearSettings', function(data, cb)
    local newSettings = {
        enabled = data.enabled,
        intervalMinutes = math.max(1, math.min(240, data.intervalMinutes or AutoClearManager.config.intervalMinutes)),
        announceSeconds = math.max(0, math.min(120, data.announceSeconds or AutoClearManager.config.announceSeconds))
    }

    local changed = 
        newSettings.enabled ~= AutoClearManager.config.enabled or
        newSettings.intervalMinutes ~= AutoClearManager.config.intervalMinutes or
        newSettings.announceSeconds ~= AutoClearManager.config.announceSeconds

    if changed then
        AutoClearManager.config.enabled = newSettings.enabled
        AutoClearManager.config.intervalMinutes = newSettings.intervalMinutes
        AutoClearManager.config.announceSeconds = newSettings.announceSeconds

        AutoClearManager.saveSettings()
        AutoClearManager.scheduleNextClear(Config)
    else
        if not AutoClearManager.config.enabled then
            AutoClearManager.status.enabled = false
            AutoClearManager.status.formattedTimeLeft = "Disabled"
            AutoClearManager.status.nextClearTimestamp = 0
        end
    end

    cb({
        success = true,
        config = AutoClearManager.config,
        status = {
            enabled = AutoClearManager.status.enabled,
            formattedTimeLeft = AutoClearManager.status.formattedTimeLeft
        }
    })
end)

RegisterNUICallback('getAutoClearStatus', function(_, cb)
    cb({
        enabled = AutoClearManager.status.enabled,
        formattedTimeLeft = AutoClearManager.status.formattedTimeLeft,
        nextClearTimestamp = AutoClearManager.status.nextClearTimestamp,
        currentTime = GetGameTimer()
    })
end)

RegisterCommand('cfx-tcd-cleanentities:show', function()
    Utils.executeIfAdmin(function()
        showPanel()
    end, nil, "You need admin permissions to open the Entity Cleaner.")
end, false)

RegisterNetEvent('cfx-tcd-cleanentities:receiveAutoClearSettings')
AddEventHandler('cfx-tcd-cleanentities:receiveAutoClearSettings', function(settings)
    if settings then
        AutoClearManager.config.enabled = settings.enabled
        AutoClearManager.config.intervalMinutes = settings.intervalMinutes
        AutoClearManager.config.announceSeconds = settings.announceSeconds

        AutoClearManager.applySettings(Config)
    end
end)

RegisterNetEvent('cfx-tcd-clearentities:globalNotify', function(title, message, duration)
    Config.notify(title, message, duration)
end)

RegisterKeyMapping('cfx-tcd-cleanentities:show', 'Open Entity Cleaner', 'keyboard', Config.defaultKey)

Citizen.CreateThread(function()
    AutoClearManager.loadSettings()

    AutoClearManager.startPeriodicUpdate(Config)

    Wait(1000)
    Utils.sendReactMessage('setShowPriorityStatus', { visible = true })
end)

-- Add handlers for server-triggered entity deletion
RegisterNetEvent('cfx-tcd-clearentities:deleteEntitiesOnClient')
AddEventHandler('cfx-tcd-clearentities:deleteEntitiesOnClient', function()
    local results = EntityManager.clearEntities('all', Config)
    Utils.sendReactMessage('clearResult', { results = results })
end)

RegisterNetEvent('cfx-tcd-clearentities:deleteEntityTypeOnClient')
AddEventHandler('cfx-tcd-clearentities:deleteEntityTypeOnClient', function(entityType)
    local results = EntityManager.clearEntities(entityType, Config)
    Utils.sendReactMessage('clearResult', { results = results })
end)

RegisterNetEvent('cfx-tcd-clearentities:clearResult')
AddEventHandler('cfx-tcd-clearentities:clearResult', function(result)
    -- Refresh entity counts after server-side clearing
    local results = EntityManager.getAllEntityCounts(Config)
    Utils.sendReactMessage('clearResult', { results = results })
end)