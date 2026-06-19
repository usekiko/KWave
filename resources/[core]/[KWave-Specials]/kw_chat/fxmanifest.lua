fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'KW Chat - Enhanced Black & White Chat System'
version '2.0.0'
author 'Kiko'
provide 'chat'

shared_scripts {
    'config.lua'
}

server_scripts {
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
}
