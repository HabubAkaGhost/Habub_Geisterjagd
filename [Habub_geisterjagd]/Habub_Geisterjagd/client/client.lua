GhostHunt = {
    ghostEntities = {},
    ghostMetadata = {},
    playerPhotos = {},
    cooldown = false,
    bone = 28422,
    loc = { x = 0.0, y = 0.0, z = 0.0 },
    rot = { x = 0.0, y = 0.0, z = 0.0 },
    capturing = false
}

function GhostHunt:Init()
    Citizen.CreateThread(function()
        TriggerServerEvent('habub_geisterjagd:loadProgress')
    end)
    self:RegisterEvents()
end

function GhostHunt:RegisterEvents()
    RegisterNetEvent('habub_geisterjagd:loadProgress')
    AddEventHandler('habub_geisterjagd:loadProgress', function(caughtGhosts, huntCompleted)
        self:LoadProgress(caughtGhosts, huntCompleted)
    end)

    RegisterNetEvent('habub_geisterjagd:capture')
    AddEventHandler('habub_geisterjagd:capture', function()
        if not self.capturing and not self.cooldown then
            GhostHunt:SetCooldown(2500)
            self:HandleGhostHuntEvent()
        else
            exports.kq_link:Notify("Du musst noch kurz warten.", 'error')
        end
    end)

    RegisterNetEvent('habub_geisterjagd:photoConfirmed')
    AddEventHandler('habub_geisterjagd:photoConfirmed', function(ghostIndex)
        self:PhotoConfirmed(ghostIndex)
    end)

    RegisterNetEvent('habub_geisterjagd:client:safeRestart')
    AddEventHandler('habub_geisterjagd:client:safeRestart', function(caller)
        self:SafeRestart(caller)
    end)

    RegisterNetEvent('habub_geisterjagd:notifyCompletion')
    AddEventHandler('habub_geisterjagd:notifyCompletion', function()
        GhostHunt:Alert("Geisterjagd abgeschlossen", "Du kannst die Kamera jetzt mit ~g~/hcam ~w~ benutzen", 5000)
        PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
    end)
end

function GhostHunt:Alert(title, message, duration)
    Citizen.CreateThread(function()
        local scaleformHandle = RequestScaleformMovie("mp_big_message_freemode")

        while not HasScaleformMovieLoaded(scaleformHandle) do
            Citizen.Wait(0)
        end

        BeginScaleformMovieMethod(scaleformHandle, "SHOW_SHARD_CENTERED_MP_MESSAGE")
        PushScaleformMovieMethodParameterString(title)
        PushScaleformMovieMethodParameterString(message)
        PushScaleformMovieMethodParameterInt(2)
        PushScaleformMovieMethodParameterInt(64)
        EndScaleformMovieMethod()

        local startTime = GetGameTimer()
        local endTime = startTime + duration

        local x = 0.5
        local y = 0.3
        local width = 1.0
        local height = 1.0

        while GetGameTimer() < endTime do
            Citizen.Wait(0)
            DrawScaleformMovie(scaleformHandle, x, y, width, height, 0, 0, 0, 0, 0)
        end

        SetScaleformMovieAsNoLongerNeeded(scaleformHandle)
    end)
end

RegisterCommand('hcam', function()
    local function manageCamera()
        local playerPed = PlayerPedId()
        local isCameraAttached = false
        local cameraData = Config.camera
        local dict = 'amb@world_human_paparazzi@male@base'
        local anim = 'base'
        local flag = 50

        if not isCameraAttached then
            camera = SpawnObject(cameraData.model, GetEntityCoords(playerPed), 210.0, 270.0)
            SetEntityLights(camera, false)
            AttachEntityToEntity(
                camera, playerPed, GetPedBoneIndex(playerPed, 28422),
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                true, false, true, false, 2, true
            )

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(100)
            end
            TaskPlayAnim(playerPed, dict, anim, 2.0, 2.0, -1, flag or 1, 0, true, true, false)
            RemoveAnimDict(dict)
            isCameraAttached = true
            Citizen.CreateThread(function()
                while true do
                    DisableControlAction(0, 24, 1)
                    if IsControlJustPressed(0, 73) then
                        if camera ~= nil then
                            DetachEntity(camera, true, true)
                            DeleteObject(camera)
                            camera = nil
                            isCameraAttached = false
                            ClearPedTasks(playerPed)
                            return
                        end
                    elseif IsControlPressed(0, 24) then
                        SetEntityLights(camera, true)
                    elseif IsControlReleased(0, 24) then
                        SetEntityLights(camera, false)
                    end
                    Citizen.Wait(5)
                end
            end)
        end
    end
    if not GhostHunt.huntCompleted then
        exports.kq_link:Notify("Du musst erst die Geisterjagd abschließen, bevor du die Kamera nutzen kannst.", 'error')
    else
        manageCamera()
    end
end)

function GhostHunt:SetCooldown(time)
    self.cooldown = true
    Citizen.CreateThread(function()
        Citizen.Wait(time)
        self.cooldown = false
    end)
end

function GhostHunt:HSVToRGB(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6

    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    elseif i == 5 then return v, p, q
    end
end

function GhostHunt:SpawnCamera()
    if self.huntCompleted then return end

    local cameraData = Config.camera
    local camRot = Config.camera.rotation
    local camera = SpawnObject(cameraData.model, cameraData.coords, 210.0, 0)
    FreezeEntityPosition(camera, 1)
    SetEntityCollision(camera, 0, 0)
    SetEntityRotation(camera, camRot[1], camRot[2], camRot[3], 2, true)

    self:AddCameraInteraction(camera)
end

function GhostHunt:AddCameraInteraction(camera)
    exports.kq_link:AddInteractionEntity(
        camera, vector3(0, 0, 0.5), L('[E] um Kamera zu nehmen'), L('Kamera nehmen'),
        38, function() self:OnInteract() end, function() return self:CanInteract() end, {}, 5.0, 'fas fa-hand'
    )
end

function GhostHunt:LoadProgress(caughtGhosts, huntCompleted)
    self.playerPhotos = caughtGhosts or {}
    self.huntCompleted = huntCompleted or false
    self:SpawnCamera()
    self:SpawnGhosts()
end

function GhostHunt:PlayGhostEffects(dataTable, newGhost)
    self.ghostMetadata[newGhost].animPlay = true

    RequestAnimDict('ANIM@SCRIPTED@FREEMODE@IG2_GHOST@')
    while not HasAnimDictLoaded('ANIM@SCRIPTED@FREEMODE@IG2_GHOST@') do
        Citizen.Wait(100)
    end

    PlayEntityAnim(newGhost, 'float_1', 'ANIM@SCRIPTED@FREEMODE@IG2_GHOST@', 1000.0, true, true, true, 0, 136704)

    local particleDict = "scr_srr_hal"
    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Citizen.Wait(0)
    end
    UseParticleFxAsset(particleDict)
    StartParticleFxLoopedOnEntity('scr_srr_hal_ghost_haze', newGhost, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 1.0, false, false, false)
    RemoveNamedPtfxAsset('scr_srr_hal')
    RemoveAnimDict('ANIM@SCRIPTED@FREEMODE@IG2_GHOST@')
end

function GhostHunt:ManageGhostSpawning()
    Citizen.CreateThread(function()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())

            for i, ghostData in ipairs(Config.ghosts) do
                local ghost = self.ghostEntities[i]
                local ghostCoords = ghostData.coords
                local distance = #(playerCoords - vector3(ghostCoords[1], ghostCoords[2], ghostCoords[3]))

                if distance > 150.0 then
                    if ghost then
                        self.ghostMetadata[ghost].animPlay = false
                        if Config.blips.enabled then
                            RemoveBlip(self.ghostMetadata[ghost].blip)
                            self.ghostMetadata[ghost].blip = nil
                        end

                        DeleteEntity(ghost)
                        self.ghostEntities[i] = nil
                    end
                elseif distance <= 150.0 and not ghost and not GhostHunt.playerPhotos[i] then
                    local newGhost = SpawnObject(ghostData.model, ghostCoords, ghostCoords[4], 0)
                    SetEntityCollision(newGhost, 0, 0)
                    SetEntityAsMissionEntity(newGhost, true, true)
                    self.ghostEntities[i] = newGhost
                    self.ghostMetadata[newGhost] = {
                        index = i,
                        coords = ghostCoords,
                        animPlay = false
                    }
                    if Config.blips.enabled and not self.ghostMetadata[newGhost].blip then
                        self.ghostMetadata[newGhost].blip = CreateBlip(ghostCoords, 484, 81, 255, 1.0, "Geist")
                    end
                end

                if ghost and distance <= 50.0 and not self.ghostMetadata[ghost].animPlay then
                    self:PlayGhostEffects(self.ghostMetadata, ghost)
                end
            end

            Citizen.Wait(1000)
        end
    end)
end

function GhostHunt:SpawnGhosts()
    self:ManageGhostSpawning()
end

function GhostHunt:GhostDisappear(ghostID)
    local alpha = 255
    local groundZ = 0.0
    local ghost = self.ghostEntities[ghostID]
    local coords = self.ghostMetadata[ghost].coords

    Citizen.CreateThread(function()
        while alpha >= 5 do
            alpha = alpha - 5
            Citizen.Wait(60)
        end
    end)

    Citizen.CreateThread(function()
        while alpha >= 5 do
            SetEntityAlpha(ghost, alpha, 1)
            groundZ = groundZ + 0.05
            SetEntityCoords(ghost, coords[1], coords[2], coords[3] + groundZ, 0.0, 0.0, 0)
            Citizen.Wait(10)
        end
    end)

    RemoveBlip(self.ghostMetadata[ghost].blip)
end

function GhostHunt:HandleGhostHuntEvent()
    local closestGhost = self:ClosestGhost()
    if closestGhost then
        self:TakePhotoOfGhost(closestGhost)
    end
end

function GhostHunt:TakePhotoOfGhost(ghost)
    self.capturing = true
    local ghostID = self.ghostMetadata[ghost].index
    local playerPed = PlayerPedId()
    local camera = self:AttachCameraToPlayer(playerPed)

    GhostHunt:GhostDisappear(ghostID)

    PlayAnim('amb@world_human_paparazzi@male@base', 'base', 1, playerPed, 3000)
    Citizen.Wait(1500)
    PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", 1)
    Citizen.Wait(1500)
    ClearPedTasks(playerPed)
    TriggerServerEvent('habub_geisterjagd:photoTaken', ghostID)
    DeleteEntity(camera)
    self.capturing = false
end

function GhostHunt:ClosestGhost()
    if not self.capturing and not IsPedInAnyVehicle(PlayerPedId(), 1) then
        for _, ghost in pairs(self.ghostEntities) do
            if self:IsGhostInRange(ghost) then
                return ghost
            end
        end
        return nil
    end
end

function GhostHunt:IsGhostInRange(ghost)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local ghostCoords = self.ghostMetadata[ghost].coords
    local distance = #(playerCoords - vector3(ghostCoords[1], ghostCoords[2], ghostCoords[3]))

    if distance <= 20.0 and IsEntityOnScreen(ghost) and not GhostHunt.capturing then
        TaskTurnPedToFaceEntity(PlayerPedId(), ghost, 1000)
        Citizen.Wait(1000)
        return true
    end
    return false
end

function GhostHunt:AttachCameraToPlayer(playerPed)
    local cameraData = Config.camera
    local camera = SpawnObject(cameraData.model, GetEntityCoords(playerPed), 150.0, 1)
    AttachEntityToEntity(camera, playerPed, GetPedBoneIndex(playerPed, self.bone), self.loc.x, self.loc.y, self.loc.z, self.rot.x, self.rot.y, self.rot.z, true, false, true, false, 2, true)
    return camera
end

function GhostHunt:OnInteract()
    TriggerServerEvent('habub_geisterjagd:getCamera')
    self:SetCooldown(5000)
end

function GhostHunt:CanInteract()
    return not self.cooldown and not IsPedInAnyVehicle(PlayerPedId(), 1)
end

function GhostHunt:PhotoConfirmed(ghostIndex)
    self.playerPhotos[ghostIndex] = true
    if self.ghostEntities[ghostIndex] then
        RemoveBlip(self.ghostMetadata[self.ghostEntities[ghostIndex]].blip)
        DeleteEntity(self.ghostEntities[ghostIndex])
        self.ghostMetadata[self.ghostEntities[ghostIndex]] = nil
        self.ghostEntities[ghostIndex] = nil
    end
end

function GhostHunt:SafeRestart(caller)
    local entities = GetGamePool('CObject')
    for _, entity in pairs(entities) do
        if DoesEntityExist(entity) and self:IsDeletableModel(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end

    if caller == GetPlayerServerId(PlayerId()) then
        Citizen.Wait(2000)
        ExecuteCommand('ensure ' .. GetCurrentResourceName())
    end
end

function GhostHunt:IsDeletableModel(entity)
    local deleteModels = { 'ls_hunt_camera', 'm23_1_prop_m31_ghostrurmeth_01a', 'm23_1_prop_m31_ghostskidrow_01a', 'm23_1_prop_m31_ghostzombie_01a', 'm23_1_prop_m31_ghostjohnny_01a', 'm23_1_prop_m31_ghostsalton_01a' }
    local entityModel = GetEntityModel(entity)
    for _, model in ipairs(deleteModels) do
        if GetHashKey(model) == entityModel then
            return true
        end
    end
    return false
end

GhostHunt:Init()
