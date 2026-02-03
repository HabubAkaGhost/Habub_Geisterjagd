if GetResourceState('kq_link') ~= 'started' then
    error('^6[KQ_LINK MISSING] ^1kq_link is required but not running! Make sure that you\'ve got it installed and started before ' .. GetCurrentResourceName())
end
