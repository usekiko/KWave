fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'KW Admin - Tablet-style admin menu with kick, ban, teleport, give items'
author 'Kiko'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

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
}
