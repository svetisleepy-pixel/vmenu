fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nx_shop_robbery'
author 'NX Framework'
description 'Store robbery loop with skill checks and dispatch calls.'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'nx_target',
    'nx_lib',
    'nx_dispatch'
}
