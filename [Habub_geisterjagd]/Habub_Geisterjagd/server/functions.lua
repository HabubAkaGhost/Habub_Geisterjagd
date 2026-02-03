function GetIdentifier(player)
    local identifier = GetPlayerIdentifiers(player)[1]:gsub(":", "")
    if Config.alternativeIdentifier.enabled then
        for k,v in pairs(GetPlayerIdentifiers(player)) do
            
            if string.sub(v, 1, string.len(Config.alternativeIdentifier.identifier)) == Config.alternativeIdentifier.identifier then
                identifier = v:gsub(":", "")
            end
        end
    end
    return identifier 
end