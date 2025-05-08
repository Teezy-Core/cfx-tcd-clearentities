if Config.debugMode then
    local Utils = require 'client.modules.utils'
    RegisterCommand('tcd:spawnvehicle', function(source, args, rawCommand)
        Utils.executeIfAdmin(function()
            local vehicleName = args[1] or 'adder'
            local count = math.min(tonumber(args[2]) or 1, 20)

            RequestModel(vehicleName)

            while not HasModelLoaded(vehicleName) do
                Wait(500)
            end

            local playerPed = PlayerPedId()
            local playerHeading = GetEntityHeading(playerPed)

            for i = 1, count do
                local xOffset = i * 4.0
                local pos = GetOffsetFromEntityInWorldCoords(playerPed, xOffset, 0.0, 0.0)

                local vehicle = CreateVehicle(vehicleName, pos.x, pos.y, pos.z, playerHeading, true, false)

                if i == 1 then
                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                end
            end
        end, nil, "You need admin permissions to spawn vehicles.")
    end, false)

    RegisterCommand('tcd:spawnped', function(source, args, rawCommand)
        Utils.executeIfAdmin(function()
            local pedName = args[1] or 'a_m_m_skater_01'
            local count = math.min(tonumber(args[2]) or 1, 20)

            RequestModel(pedName)

            while not HasModelLoaded(pedName) do
                Wait(500)
            end

            local playerPed = PlayerPedId()
            local playerHeading = GetEntityHeading(playerPed)

            for i = 1, count do
                local xOffset = i * 4.0
                local pos = GetOffsetFromEntityInWorldCoords(playerPed, xOffset, 0.0, 0.0)

                local ped = CreatePed(4, pedName, pos.x, pos.y, pos.z, playerHeading, true, false)
                SetEntityAsMissionEntity(ped, true, true)
            end
        end, nil, "You need admin permissions to spawn peds.")
    end, false)

    RegisterCommand('tcd:spawnprop', function(source, args, rawCommand)
        Utils.executeIfAdmin(function()
            local propName = args[1] or 'prop_barrel_01a'
            local count = math.min(tonumber(args[2]) or 1, 20)

            RequestModel(propName)

            while not HasModelLoaded(propName) do
                Wait(500)
            end

            local playerPed = PlayerPedId()

            for i = 1, count do
                local xOffset = i * 4.0
                local pos = GetOffsetFromEntityInWorldCoords(playerPed, xOffset, 0.0, 0.0)

                local prop = CreateObject(propName, pos.x, pos.y, pos.z, true, false, true)
                SetEntityAsMissionEntity(prop, true, true)
                PlaceObjectOnGroundProperly(prop)
                FreezeEntityPosition(prop, false)
            end
        end, nil, "You need admin permissions to spawn props.")
    end, false)
end