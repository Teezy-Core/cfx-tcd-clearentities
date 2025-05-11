local ServerEntityManager = {}

function ServerEntityManager.clearAllEntities()
    -- Broadcast to all clients to delete entities
    TriggerClientEvent('cfx-tcd-clearentities:deleteEntitiesOnClient', -1)
    
    -- Return success message
    return {
        success = true,
        timestamp = os.time()
    }
end

function ServerEntityManager.clearEntityType(entityType)
    -- Broadcast to all clients to delete specific entity type
    TriggerClientEvent('cfx-tcd-clearentities:deleteEntityTypeOnClient', -1, entityType)
    
    -- Return success message
    return {
        success = true,
        entityType = entityType,
        timestamp = os.time()
    }
end

return ServerEntityManager