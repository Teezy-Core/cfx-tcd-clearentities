local Utils = {}

function Utils.formatTimeLeft(milliseconds)
    local seconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)

    if hours > 0 then
        local remainingMinutes = minutes % 60
        return string.format("%dh %dm", hours, remainingMinutes)
    else
        return string.format("%dm", minutes)
    end
end

function Utils.getFilteredEntities(poolName, config)
    local entities = GetGamePool(poolName)
    local filtered = {}
    local count = 0
    
    for _, entity in ipairs(entities) do
        local shouldInclude = true
        
        if poolName == 'CVehicle' and config.filterNetworked.vehicles then
            shouldInclude = NetworkGetEntityIsNetworked(entity)
        elseif poolName == 'CPed' and config.filterNetworked.peds then
            shouldInclude = NetworkGetEntityIsNetworked(entity) 
        elseif poolName == 'CObject' and config.filterNetworked.props then
            shouldInclude = NetworkGetEntityIsNetworked(entity)
        end

        if poolName == 'CPed' and IsPedAPlayer(entity) then
            shouldInclude = false
        end
        
        local modelHash = GetEntityModel(entity)
        if config.excludeModelHashes[modelHash] then
            shouldInclude = false
        end
        
        if shouldInclude then
            count = count + 1
            filtered[count] = entity
        end
    end
    
    return filtered, count
end

function Utils.toggleNuiFrame(name, shouldShow, data)
    SetNuiFocus(shouldShow, shouldShow)
    
    local message = { visible = shouldShow }
    if data then
        for key, value in pairs(data) do
            message[key] = value
        end
    end
    
    SendNUIMessage({
        action = name,
        data = message
    })
end

function Utils.sendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

function Utils.debugPrint(...)
    local currentResourceName = GetCurrentResourceName()
    local debugIsEnabled = GetConvarInt(('%s-debugMode'):format(currentResourceName), 0) == 1
    
    if not debugIsEnabled then return end
    local args <const> = { ... }

    local appendStr = ''
    for _, v in ipairs(args) do
        appendStr = appendStr .. ' ' .. tostring(v)
    end
    
    local msgTemplate = '^3[%s]^0%s'
    local finalMsg = msgTemplate:format(currentResourceName, appendStr)
    print(finalMsg)
end

function Utils.isPlayerAdmin(callback)
    if Utils._isAdminCache ~= nil then
        return callback(Utils._isAdminCache)
    end

    local playerId = PlayerId()
    local playerServerId = GetPlayerServerId(playerId)

    if not Utils._eventRegistered then
        RegisterNetEvent('cfx-tcd-cleanentities:adminPermissionsResult')
        Utils._eventRegistered = true
    end

    if Utils._adminCheckHandler then
        RemoveEventHandler(Utils._adminCheckHandler)
    end
    
    Utils._adminCheckHandler = AddEventHandler('cfx-tcd-cleanentities:adminPermissionsResult', function(hasPermission, frameworkAdmin)
        local isAdmin = hasPermission or frameworkAdmin

        Utils._isAdminCache = isAdmin
        
        callback(isAdmin)
        
        Citizen.SetTimeout(300000, function()
            Utils._isAdminCache = nil
        end)
    end)
    
    TriggerServerEvent('cfx-tcd-cleanentities:checkAdminPermissions', playerServerId)
end

function Utils.executeIfAdmin(cmd, params, errorMessage)
    Utils.isPlayerAdmin(function(isAdmin)
        if isAdmin then
            if type(cmd) == 'function' then
                cmd(params)
            elseif type(cmd) == 'string' then
                ExecuteCommand(cmd)
            end
        end
    end)
end

return Utils