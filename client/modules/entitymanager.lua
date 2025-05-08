local Utils = require 'client.modules.utils'

local EntityManager = {}

function EntityManager.clearEntityType(poolName, config)
    local entities, _ = Utils.getFilteredEntities(poolName, config)
    local startTypeTime = GetGameTimer()
    local count = 0
    
    for _, entity in ipairs(entities) do
        if poolName ~= 'CPed' or (poolName == 'CPed' and not IsPedAPlayer(entity)) then
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
                count = count + 1
            end
        end
    end

    local timeElapsed = GetGameTimer() - startTypeTime
    return count, timeElapsed
end

function EntityManager.getAllEntityCounts(config)
    local vehicleStartTime = GetGameTimer()
    local _, vehicleCount = Utils.getFilteredEntities('CVehicle', config)
    local vehicleTime = GetGameTimer() - vehicleStartTime
    
    local pedStartTime = GetGameTimer()
    local _, pedCount = Utils.getFilteredEntities('CPed', config)
    local pedTime = GetGameTimer() - pedStartTime
    
    local propStartTime = GetGameTimer()
    local _, propCount = Utils.getFilteredEntities('CObject', config)
    local propTime = GetGameTimer() - propStartTime
    
    return {
        { type = 'vehicles', label = config.filterNetworked.vehicles and 'Networked Vehicles' or 'Vehicles', count = vehicleCount, ms = vehicleTime },
        { type = 'peds', label = config.filterNetworked.peds and 'Networked Peds' or 'Peds', count = pedCount, ms = pedTime },
        { type = 'props', label = config.filterNetworked.props and 'Networked Props' or 'Props', count = propCount, ms = propTime }
    }
end

function EntityManager.clearEntities(entityType, config)
    if entityType == 'all' then
        local vehiclesStartTime = GetGameTimer()
        local vehiclesCleared, _ = EntityManager.clearEntityType('CVehicle', config)
        local vehiclesTime = GetGameTimer() - vehiclesStartTime
        
        local pedsStartTime = GetGameTimer()
        local pedsCleared, _ = EntityManager.clearEntityType('CPed', config)
        local pedsTime = GetGameTimer() - pedsStartTime
        
        local propsStartTime = GetGameTimer()
        local propsCleared, _ = EntityManager.clearEntityType('CObject', config)
        local propsTime = GetGameTimer() - propsStartTime
        
        -- Get fresh entity counts
        local _, vehicleCount = Utils.getFilteredEntities('CVehicle', config)
        local _, pedCount = Utils.getFilteredEntities('CPed', config)
        local _, propCount = Utils.getFilteredEntities('CObject', config)
        
        return {
            { type = 'vehicles', label = config.filterNetworked.vehicles and 'Networked Vehicles' or 'Vehicles', count = vehicleCount, ms = vehiclesTime },
            { type = 'peds', label = config.filterNetworked.peds and 'Networked Peds' or 'Peds', count = pedCount, ms = pedsTime },
            { type = 'props', label = config.filterNetworked.props and 'Networked Props' or 'Props', count = propCount, ms = propsTime }
        }
    else
        -- For single entity type, clear and measure
        local poolName = entityType == 'vehicles' and 'CVehicle' or (entityType == 'peds' and 'CPed' or 'CObject')
        local _, clearTime = EntityManager.clearEntityType(poolName, config)
        
        -- Get fresh entity counts after clearing
        return EntityManager.getAllEntityCounts(config)
    end
end

return EntityManager