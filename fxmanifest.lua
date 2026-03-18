fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'vmenu_drugs'
author 'Codex'
description 'Standalone drug gathering/processing/usage system with ox_inventory'
version '1.0.0'

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

client_export 'useDrug'
