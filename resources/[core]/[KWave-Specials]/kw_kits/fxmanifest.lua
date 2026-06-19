fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'KW Kits - Daily kit system with ox_inventory and oxpsql'
author 'Kiko'
version '1.0.0'

server_scripts {
    '@oxpsql/lib/PostgreSQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'ox_inventory',
    'oxpsql',
    'kw_notify'
}
