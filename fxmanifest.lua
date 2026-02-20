fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'vmenu Codex'
description 'All-in-one ESX admin panel with moderation, reports, announcements, community service and logs'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}
