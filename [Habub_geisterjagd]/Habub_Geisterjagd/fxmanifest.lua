fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'Habub_scripts'
description 'Habub Geisterjagd'
version '1.0.0'

data_file 'DLC_ITYP_REQUEST' 'stream/habub_hunt_camera.ytyp'

shared_scripts {
    'link_check.lua'
}

server_scripts {
    'server/functions.lua',
    'config.lua',
    'server/server.lua'
}

client_scripts {
    'client/functions.lua',
    'config.lua',
    'client/client.lua'
}

files {
    'stream/*'
}
