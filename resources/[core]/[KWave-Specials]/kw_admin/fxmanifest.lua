fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'DTF Admin - Tablet-style admin menu with kick, ban, teleport, give items'
author 'DTF'
version '1.0.0'

server_scripts {
    '@oxpsql/lib/PostgreSQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'kw_core',
    'ox_inventory',
    'kw_notify'
}
