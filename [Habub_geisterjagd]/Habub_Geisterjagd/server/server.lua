RegisterCommand('habub_geisterjagd_restart', function(source)
    local _source = source
    TriggerClientEvent('habub_geisterjagd:client:safeRestart', -1, _source)
end, true)

local GhostHunt = {}

local playerProgress = {}
GhostHunt.__index = GhostHunt

function GhostHunt:new()
    local self = setmetatable({}, GhostHunt)
    self.allPlayersPhotos = {}
    return self
end

function GhostHunt:RegisterUsableItem()
    exports.kq_link:RegisterUsableItem('hs_camera', function(source)
        TriggerClientEvent('habub_geisterjagd:capture', source)
    end)
end

function GhostHunt:OnPlayerConnecting()
    AddEventHandler('playerConnecting', function()
        local src = source
        local identifier = self:GetIdentifier(src)
        if not self.allPlayersPhotos[identifier] then
            self.allPlayersPhotos[identifier] = {}
        end
    end)
end

function GhostHunt:LoadProgressEvent()
    RegisterNetEvent('habub_geisterjagd:loadProgress')
    AddEventHandler('habub_geisterjagd:loadProgress', function()
        local playerId = source
        local progress = playerProgress[playerId] or { caughtGhosts = {}, huntCompleted = false }
        TriggerClientEvent('habub_geisterjagd:loadProgress', playerId, progress.caughtGhosts, progress.huntCompleted)
    end)
end

function GhostHunt:PhotoTakenEvent()
    RegisterNetEvent('habub_geisterjagd:photoTaken')
    AddEventHandler('habub_geisterjagd:photoTaken', function(ghostID)
        local playerId = source
        if not playerProgress[playerId] then
            playerProgress[playerId] = {
                caughtGhosts = {},
                huntCompleted = false
            }
        end

        playerProgress[playerId].caughtGhosts[ghostID] = true
        TriggerClientEvent('habub_geisterjagd:photoConfirmed', playerId, ghostID)

        if CheckAllPhotosTaken(playerId) then
            playerProgress[playerId].huntCompleted = true
            TriggerClientEvent('habub_geisterjagd:notifyCompletion', playerId, true)
        end
    end)
end

function CheckAllPhotosTaken(playerId)
    local totalGhosts = #Config.ghosts
    local photographedCount = 0

    for _, caught in pairs(playerProgress[playerId].caughtGhosts) do
        if caught then
            photographedCount = photographedCount + 1
        end
    end

    return photographedCount == totalGhosts
end

function GhostHunt:GetCameraEvent()
    RegisterNetEvent('habub_geisterjagd:getCamera')
    AddEventHandler('habub_geisterjagd:getCamera', function()
        local src = source
        local itemCount = exports.kq_link:GetPlayerItemCount(src, 'hs_camera')
        if itemCount < 1 then
            exports.kq_link:AddPlayerItem(src, 'hs_camera', 1, 0)
        end
    end)
end

function GhostHunt:GetIdentifier(src)
    return GetPlayerIdentifier(src, 0)
end

local ghostHuntInstance = GhostHunt:new()
ghostHuntInstance:RegisterUsableItem()
ghostHuntInstance:OnPlayerConnecting()
ghostHuntInstance:LoadProgressEvent()
ghostHuntInstance:PhotoTakenEvent()
ghostHuntInstance:GetCameraEvent()
