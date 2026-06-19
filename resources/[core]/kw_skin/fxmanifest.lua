fx_version 'adamant'

game 'gta5'
description 'Allows players to customise their character\'s appearance'
version '1.13.5'
lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'@kw_core/locale.lua',
	'locales/*.lua',
	'@kw_core/imports.lua',
	'config.lua',
}

server_scripts {
	'@pgsql/lib/PostgreSQL.lua',
	'server/main.lua'
}

client_scripts {
	'client/main.lua',
	'client/modules/*.lua'
}

dependencies {
	'kw_core',
	'skinchanger'
}
