local managerPed
local clipboard
local plrTruck
local targetBlip
local locationBlip
local targetTrailer
local trailerBlip

local hasCorrectTrailer = false
local truckingState = 0 -- 0 = going to pick up, 1 = going to drop off
local gotDropOffLocation = false

local onDuty = false

local function SpawnPed(hash,coords)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(1)
        RequestModel(hash)
        dbug('Requesting : ' .. hash)
    end

    local ped = CreatePed(1,hash,coords.x, coords.y, coords.z -1, coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    SetModelAsNoLongerNeeded(hash)

    return ped

end

local function SpawnManager()
    local clipboardProp = 'p_amb_clipboard_01'
    local animDict = 'missfam4'

    managerPed = SpawnPed(Config.Manager.model, Config.Manager.coords)

    RequestModel(clipboardProp)
    while not HasModelLoaded(clipboardProp) do
        Citizen.Wait(1)
        RequestModel(clipboardProp)
        dbug('Requesting : ' .. clipboardProp)
    end

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(1)
        RequestAnimDict(animDict)
        dbug('Requesting : ' .. animDict)
    end

    clipboard = CreateObject(clipboardProp,
    Config.Manager.coords.x, Config.Manager.coords.y, Config.Manager.coords.z,
    false, false, false)

    TaskPlayAnim(managerPed, animDict, 'base', 2.0, 2.0, 50000000, 51, 0, 
    false, false, false)

    AttachEntityToEntity(
    clipboard,
    managerPed,
    GetPedBoneIndex(managerPed, 36029), 
    0.16, 0.08, 0.1, -130, -50.0, 0.0,
    true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(clipboardProp)

end

local function SpawnTruck()
    local truckModel = Config.Truck.model
    local truckcoords = Config.Truck.coords

    RequestModel(truckModel)
    while not HasModelLoaded(truckModel) do
        Citizen.Wait(1)
        RequestModel(truckModel)
        dbug('Requesting : ' .. truckModel)
    end

    plrTruck = CreateVehicle(truckModel,truckcoords.x, truckcoords.y, truckcoords.z, truckcoords.w, true, true)
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(plrTruck))
    SetVehicleFuelLevel(plrTruck, 100.0)
    

end

local function SpawnTrailer(pickupInfo)
    RequestModel(pickupInfo.model)
    while not HasModelLoaded(pickupInfo.model) do
        Citizen.Wait(1)
        RequestModel(pickupInfo.model)
        dbug('Requesting : ' .. pickupInfo.model)
    end

    targetTrailer = CreateVehicle(pickupInfo.model, 
    pickupInfo.coords.x, pickupInfo.coords.y, pickupInfo.coords.z, pickupInfo.coords.w, true, true)

    SetEntityHeading(targetTrailer, pickupInfo.coords.w)

    local trailerLocation = GetEntityCoords(targetTrailer)

    trailerBlip = AddBlipForCoord(trailerLocation.x,trailerLocation.y,trailerLocation.z)
    SetBlipSprite(trailerBlip, 479)
    SetBlipColour(trailerBlip, 43)
    SetBlipScale(trailerBlip, 0.65)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Trailer')
    EndTextCommandSetBlipName(trailerBlip)

end

local function SetPickupBlip(coords)
    RemoveBlip(targetBlip)

    targetBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipColour(targetBlip, 3)
    SetBlipRoute(targetBlip, true)
    SetBlipRouteColour(targetBlip, 3)
    SetBlipScale(trailerBlip, 0.45)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Destination')
    EndTextCommandSetBlipName(targetBlip)
    
end

local function GetPickupLocation()
    local pickupindex = math.random(1, #Config.PickUpLocation)

    local pickupLocation = Config.PickUpLocation[pickupindex]

    SetPickupBlip(pickupLocation.coords)
    SpawnTrailer(pickupLocation)
end

local function GetDropOffLocation()
    gotDropOffLocation = true

    local dropoffindex = math.random(1, #Config.DropoffLocation)

    local dropoffLocation = Config.DropoffLocation[dropoffindex]

    SetPickupBlip(dropoffLocation.coords)


end


local function StartJob()
    dbug('Started Job')
    onDuty = true
    SpawnTruck()
    GetPickupLocation()

end

RegisterCommand('truckerVal', function ()
    dbug('Ped       : ' .. managerPed)
    dbug('clipboard : ' .. clipboard)
    dbug('Duty      : ' .. tostring(onDuty))
    dbug('Truck     : ' .. plrTruck)
    dbug('Trailer   : ' .. targetTrailer)

end, false)


-- Create Blip for job location
Citizen.CreateThread(function ()
    locationBlip = AddBlipForCoord(180.09, 2793.35, 45.66)
    SetBlipSprite(locationBlip, 477)
    SetBlipColour(locationBlip, 65)
    SetBlipScale(locationBlip, 0.75)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Trucker Job')
    EndTextCommandSetBlipName(locationBlip)
end)

-- ox_Target menu
Citizen.CreateThread(function ()

    SpawnManager()

    exports.ox_target:addLocalEntity(managerPed, {
        {
            distance = 1.5,
            name = 'Trucker Job',
            icon = Config.Manager.targetData.icon,
            label = Config.Manager.targetData.label,

            canInteract = function ()
                if not onDuty then return true end
            end,

            onSelect = function()
                lib.showContext('truck_manager_context')
            end
        }
    })

end)

-- Drop off and Trailer blip - loop
Citizen.CreateThread(function ()
    while true do
        Wait(1000)
        if onDuty then
            local trailerLocation = GetEntityCoords(targetTrailer)
            SetBlipCoords(trailerBlip,trailerLocation.x,trailerLocation.y,trailerLocation.z)

            if not hasCorrectTrailer then
                if IsPedInVehicle(PlayerPedId(), plrTruck, true) then
                    if IsVehicleAttachedToTrailer(plrTruck) then
                        local _, trailer = GetVehicleTrailerVehicle(plrTruck)
                        if trailer == targetTrailer then
                            hasCorrectTrailer = true

                            local trailerLocation = GetEntityCoords(targetTrailer)
                            SetBlipCoords(trailerBlip,trailerLocation.x,trailerLocation.y,trailerLocation.z)
                        else
                            hasCorrectTrailer = false

                            local trailerLocation = GetEntityCoords(targetTrailer)
                            SetBlipCoords(trailerBlip,trailerLocation.x,trailerLocation.y,trailerLocation.z)
                        end

                    end
                end
            elseif not gotDropOffLocation then
                -- has correct trailer
                GetDropOffLocation()
            end
        end
    end
end)

--ox_lib Context Menu
lib.registerContext({
    id = 'truck_manager_context',
    title = 'Trucking Job',
    options = {
        {
            title = 'Start Job',
            description = 'Click here to start a job',
            onSelect = function(args)
                StartJob()
            end,
        },
    },

})

AddEventHandler('OnResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    DeleteObject(managerPed)
    DeleteObject(clipboard)
    DeleteVehicle(plrTruck)
    DeleteVehicle(targetTrailer)
    RemoveBlip(targetBlip)
end)
