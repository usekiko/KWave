fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'KW Death Messages - Custom kill feed with weapon icons, headshots, distance, multi-kills'
author 'Kiko'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
}
