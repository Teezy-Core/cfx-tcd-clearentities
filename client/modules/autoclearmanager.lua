local Utils = require 'client.modules.utils'
local EntityManager = require 'client.modules.entitymanager'

local AutoClearManager = {
    config = {
        enabled = false,
        intervalMinutes = 1,
        announceSeconds = 30
    },
    status = {
        enabled = false,
        nextClearTimestamp = 0,
        formattedTimeLeft = "Not scheduled",
        lastUpdateTime = 0
    },
    timers = {
        clearTimer = nil,
        announceTimer = nil
    }
}

function AutoClearManager.cancelTimers()
    if AutoClearManager.timers.clearTimer then
        AutoClearManager.timers.clearTimer = nil
    end
    
    if AutoClearManager.timers.announceTimer then
        AutoClearManager.timers.announceTimer = nil
    end
end


function AutoClearManager.scheduleNextClear(config)
    AutoClearManager.cancelTimers()
    
    if not AutoClearManager.config.enabled then
        AutoClearManager.status.enabled = false
        AutoClearManager.status.formattedTimeLeft = "Disabled"
        AutoClearManager.status.nextClearTimestamp = 0
   
        Utils.sendReactMessage('autoClearStatus', { 
            enabled = false,
            formattedTimeLeft = "Disabled"
        })
        return
    end

    local intervalMs = AutoClearManager.config.intervalMinutes * 60 * 1000
    local currentTime = GetGameTimer()
    local nextScheduledClear = currentTime + intervalMs

    AutoClearManager.status.enabled = true
    AutoClearManager.status.nextClearTimestamp = nextScheduledClear
    AutoClearManager.status.lastUpdateTime = currentTime

    AutoClearManager.timers.clearTimer = SetTimeout(intervalMs, function()
        if not AutoClearManager.config.enabled then return end

        local results = EntityManager.clearEntities('all', config)

        Utils.sendReactMessage('clearResult', { results = results })

        Config.globalNotify('System', 'All world entities have been cleared.', 5000)

        if AutoClearManager.config.enabled then
            AutoClearManager.scheduleNextClear(config)
        end
    end)

    if AutoClearManager.config.announceSeconds > 0 then
        local announceTime = intervalMs - (AutoClearManager.config.announceSeconds * 1000)
        if announceTime > 0 then
            AutoClearManager.timers.announceTimer = SetTimeout(announceTime, function()
                if AutoClearManager.config.enabled then
                    Config.globalNotify('System', 'All world entities will be cleared in ' .. AutoClearManager.config.announceSeconds .. ' seconds.', 5000)
                end
            end)
        end
    end
    
    local formattedTime = Utils.formatTimeLeft(intervalMs)
    AutoClearManager.status.formattedTimeLeft = formattedTime

    Utils.sendReactMessage('autoClearStatus', { 
        enabled = AutoClearManager.config.enabled,
        formattedTimeLeft = formattedTime
    })
end

function AutoClearManager.updateTimeLeftDisplay()
    if not AutoClearManager.config.enabled or AutoClearManager.status.nextClearTimestamp == 0 then
        return
    end
    
    local currentTime = GetGameTimer()
    local timeLeft = AutoClearManager.status.nextClearTimestamp - currentTime
    
    if timeLeft <= 0 then
        return
    end
    
    if (currentTime - AutoClearManager.status.lastUpdateTime) < 10000 then
        return
    end
    
    AutoClearManager.status.lastUpdateTime = currentTime
    AutoClearManager.status.formattedTimeLeft = Utils.formatTimeLeft(timeLeft)

    Utils.sendReactMessage('autoClearStatusUpdate', {
        enabled = AutoClearManager.config.enabled,
        timeLeft = timeLeft,
        formattedTimeLeft = AutoClearManager.status.formattedTimeLeft
    })
end


function AutoClearManager.applySettings(config)
    AutoClearManager.config.intervalMinutes = math.max(1, math.min(240, AutoClearManager.config.intervalMinutes))
    AutoClearManager.config.announceSeconds = math.max(0, math.min(120, AutoClearManager.config.announceSeconds))
    
    AutoClearManager.cancelTimers()
    
    if AutoClearManager.config.enabled then
        AutoClearManager.scheduleNextClear(config)
    else
        AutoClearManager.status.enabled = false
        AutoClearManager.status.formattedTimeLeft = "Disabled"
        AutoClearManager.status.nextClearTimestamp = 0
        
        Utils.sendReactMessage('autoClearStatus', { 
            enabled = false,
            formattedTimeLeft = "Disabled"
        })
    end
    
    Utils.debugPrint("Loaded auto-clear settings: " .. 
        (AutoClearManager.config.enabled and "Enabled" or "Disabled") .. 
        ", Interval: " .. AutoClearManager.config.intervalMinutes .. 
        "m, Announce: " .. AutoClearManager.config.announceSeconds .. "s")
end

function AutoClearManager.saveSettings()
    local settings = {
        enabled = AutoClearManager.config.enabled,
        intervalMinutes = AutoClearManager.config.intervalMinutes,
        announceSeconds = AutoClearManager.config.announceSeconds
    }

    TriggerServerEvent('cfx-tcd-cleanentities:saveAutoClearSettings', settings)
    
    Utils.debugPrint("Saving auto-clear settings: " ..
        (AutoClearManager.config.enabled and "Enabled" or "Disabled") ..
        ", Interval: " .. AutoClearManager.config.intervalMinutes .. 
        "m, Announce: " .. AutoClearManager.config.announceSeconds .. "s")
end

function AutoClearManager.loadSettings()
    TriggerServerEvent('cfx-tcd-cleanentities:requestAutoClearSettings')
    Utils.debugPrint("Requesting auto-clear settings from server")
end

function AutoClearManager.startPeriodicUpdate(config)
    Citizen.CreateThread(function()
        while true do
            AutoClearManager.updateTimeLeftDisplay()
            Wait(5000)
        end
    end)
end

return AutoClearManager