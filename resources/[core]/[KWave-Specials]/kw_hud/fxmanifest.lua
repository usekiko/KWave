fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'KWave'
description 'KWave Modern HUD'
version '2.0.0'

shared_script {
	'@ox_lib/init.lua',
	'config/config.lua'
}

client_scripts {
	'client/*.lua',
	'config/config.client.lua',
}

server_scripts {
	'@oxpsql/lib/PostgreSQL.lua',
	'config/config.server.lua',
	'server/version_check.lua',
}

ui_page 'web/dist/index.html'

files {
	'web/dist/index.html',
	'web/dist/assets/*.*',
	'web/dist/**/*.*'
}

escrow_ignore {
	'config/*.lua',
	'client/*.lua',
	'server/version_check.lua',
}
dependency '/assetpacks'