fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'KW PvP - FPS Boost Optimizer'
version '1.0.0'
author 'Kiko'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/headshot.mp3'
}
