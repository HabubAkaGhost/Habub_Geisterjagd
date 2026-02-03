if GetResourceState('kq_link') ~= 'started' then
    error('^6[KQ_LINK FEHLT] ^1kq_link ist erforderlich, läuft aber nicht! Stelle sicher, dass es installiert und gestartet ist, bevor ' .. GetCurrentResourceName())
end
