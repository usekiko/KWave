fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'DTF Death Messages - Custom kill feed with weapon icons, headshots, distance, multi-kills'
author 'DTF'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'kw_notify'
}
