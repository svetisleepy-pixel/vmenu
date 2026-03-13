fx_version 'cerulean'
game 'gta5'

name 'vmenu_cocaine'
author 'Codex'
description 'ESX cocaine plant harvesting, processing, and usage system'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
