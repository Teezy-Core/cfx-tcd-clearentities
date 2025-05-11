Config = {}

--[[
▀█▀ █▀▀ █▀▀ ▀█ █▄█   █▀▀ █▀█ █▀█ █▀▀   █▀▄ █▀▀ █░█ █▀▀ █░░ █▀█ █▀█ █▀▄▀█ █▀▀ █▄░█ ▀█▀
░█░ ██▄ ██▄ █▄ ░█░   █▄▄ █▄█ █▀▄ ██▄   █▄▀ ██▄ ▀▄▀ ██▄ █▄▄ █▄█ █▀▀ █░▀░█ ██▄ █░▀█ ░█░
]]

Config.debugMode = true

Config.permissions = {
    'command',
    'god',
    'admin',
}

Config.defaultKey = 'F6'
Config.filterNetworked = {
    peds = false,
    vehicles = false,
    props = true
}

Config.excludeModelHashes = {
    -- Add model hashes to exclude from deletion
    -- Example: [GetHashKey('mp_m_freemode_01')] = true, -- Male MP Ped
}

Config.globalNotify = function(title, message, duration)
    -- This function is called when a notification is sent from the server to the client.
    TriggerServerEvent('cfx-tcd-clearentities:globalNotify', title, message, duration)
end

Config.notify = function(title, message, duration)
    -- This function is called when a notification is sent from the server to the client.
    print(('[%s] %s: %s'):format(title, message, duration))
end
