fx_version 'cerulean'
game 'common'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
node_version '22'

name 'oxpsql'
author 'KWave'
version '1.0.0'
license 'LGPL-3.0-or-later'
description 'FXServer to PostgreSQL communication via node-postgres'

dependencies {
    '/server:12913',
}

client_script 'ui.lua'
server_script 'dist/build.js'

files {
	'web/build/index.html',
	'web/build/**/*'
}

ui_page 'web/build/index.html'

provide 'pgsql'
provide 'oxpsql'

convar_category 'oxpsql' {
	'Configuration',
	{
		{ 'Connection string', 'pgsql_connection_string', 'CV_STRING', 'postgresql://user:password@localhost/database' },
		{ 'Debug', 'pgsql_debug', 'CV_BOOL', 'false' }
	}
}
