fx_version 'bodacious'

game 'gta5'
author 'KW-Framework & Brayden'
description 'A simplistic context menu for KW.'
lua54 'yes'
version '1.13.5'

ui_page 'index.html'

shared_script '@kw_core/imports.lua'

client_scripts {
    'config.lua',
    'main.lua',
}

files {
    'index.html'
}

dependencies {
    'kw_core'
}
