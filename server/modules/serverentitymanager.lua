local ServerEntityManager = {}

function ServerEntityManager.clearAllEntities()
    TriggerClientEvent('cfx-tcd-clearentities:deleteEntitiesOnClient', -1)
    
    return {
        success = true,
        timestamp = os.time()
    }
end

function ServerEntityManager.clearEntityType(entityType)
    TriggerClientEvent('cfx-tcd-clearentities:deleteEntityTypeOnClient', -1, entityType)
    
    return {
        success = true,
        entityType = entityType,
        timestamp = os.time()
    }
end

return ServerEntityManager