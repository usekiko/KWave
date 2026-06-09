fx_version 'cerulean'

game 'gta5'
description 'A basic menu system for KW Legacy.'
lua54 'yes'
version '1.13.5'

client_scripts { '@kw_core/imports.lua', 'client/main.lua' }

ui_page 'web/build/index.html'

files { 'web/build/index.html', 'web/build/**/*' }

dependencies { 'kw_core' }
