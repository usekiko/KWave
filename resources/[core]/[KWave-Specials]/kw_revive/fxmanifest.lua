fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Standalone Revive System - Compatible with KW'
version '1.0.0'

shared_scripts {
    '@kw_core/imports.lua'
}

server_scripts {
    '@oxpsql/lib/PostgreSQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'kw_notify'
}
