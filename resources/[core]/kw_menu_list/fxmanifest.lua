fx_version 'adamant'

game 'gta5'
description 'A basic table-based menu system for KW Legacy.'
lua54 'yes'
version '1.13.5'


client_scripts {
	'@kw_core/imports.lua',
	'@kw_core/client/modules/wrapper.lua',
	'client/main.lua'
}

ui_page 'html/ui.html'

files {
	'html/ui.html',

	'html/css/app.css',

	'html/js/mustache.min.js',
	'html/js/app.js',

	'html/fonts/pdown.ttf',
	'html/fonts/bankgothic.ttf'
}

dependency 'kw_core'
