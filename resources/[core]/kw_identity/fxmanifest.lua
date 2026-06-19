fx_version 'adamant'

game 'gta5'
description 'Allows the player to Pick their characters: Name, Gender, Height and Date-of-birth.'
lua54 'yes'
version '1.13.5'

shared_scripts {
	'@ox_lib/init.lua',
	'@kw_core/imports.lua',
	'@kw_core/locale.lua',
}

server_scripts {
	'@pgsql/lib/PostgreSQL.lua',
	'locales/*.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'locales/*.lua',
	'config.lua',
	'client/main.lua'
}

files ({
	'web/dist/assets/**',
	'web/dist/**',
})

ui_page 'web/dist/index.html'

dependency 'kw_core'
