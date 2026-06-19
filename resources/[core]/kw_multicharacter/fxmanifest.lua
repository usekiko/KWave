fx_version 'cerulean'
game 'gta5'
author 'KW-Framework - Linden - KASH'
description 'Allows players to have multiple characters on the same account.'
version '1.13.5'
lua54 'yes'

dependencies { 'kw_core', 'kw_context', 'kw_identity', 'kw_skin' }

shared_scripts { '@kw_core/imports.lua', '@kw_core/locale.lua', 'locales/*.lua', 'config.lua' }

server_scripts {
    '@oxpsql/lib/PostgreSQL.lua',
    'server/*.lua',
    'server/modules/*.lua'
}

client_scripts {
   "client/modules/*.lua",
   'client/*.lua'
}

ui_page 'web/build/index.html'

files { 'web/build/index.html', 'web/build/**/*.*'}
