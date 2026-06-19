fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'KW Core - Basic server notifications and utilities'
author 'Kiko'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'kw_core',
}
