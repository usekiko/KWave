fx_version 'adamant'

lua54 'yes'
game 'gta5'
version '1.13.5'
author 'KW-Framework'
description 'A beautiful and simple NUI notification system for KW'

shared_script '@kw_core/imports.lua'

client_scripts { 'Config.lua', 'Notify.lua'}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css',
}
