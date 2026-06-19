fx_version 'adamant'

game 'gta5'
author 'KW-Framework'
description 'A beautiful and simple Persistent Notification system for KW.'
version '1.13.5'
lua54 'yes'

client_scripts { 'TextUI.lua' }
shared_script '@kw_core/imports.lua'
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css'
}
