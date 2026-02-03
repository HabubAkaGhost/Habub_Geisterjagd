
function L(text)
    if Locale and Locale[text] then
        return Locale[text]
    end
    return text
end

function IsTableEmpty(t)
    for _, v in pairs(t) do
        if v == '' then
            return true
        end
        return false
    end
    return true
end

function DrawMissionText(text, time)
    SetTextEntry_2("STRING")
    AddTextComponentString(text)
    DrawSubtitleTimed(time or 30000, 1)
end

function PlayAnim(dict, anim, flag, ped, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    TaskPlayAnim(ped or PlayerPedId(), dict, anim, 2.0, 2.0, duration or 1.0, flag or 1, 0, true, true, false)
    RemoveAnimDict(dict)
end


function SpawnObject(objHash, coords, heading, networked)
    RequestModel(objHash)
    while not HasModelLoaded(objHash) do
        Wait(1)
    end
    local object = CreateObjectNoOffset(objHash, coords.x, coords.y, coords.z, networked, true, 1)
    SetEntityHeading(object, heading) 
    return object
end



function CreateBlip(coords, sprite, color, alpha, scale, message)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, alpha)
    SetBlipScale(blip, scale)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(message)
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, true)
    return blip
end