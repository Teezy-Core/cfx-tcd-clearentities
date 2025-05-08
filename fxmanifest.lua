fx_version 'cerulean'
game 'gta5'

name "cfx-tcd-clearentities"
description "Advanced Clear Entities"
author "Teezy Core Development"
version "1.0.0"

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'client/modules/*.lua',
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

ui_page 'dist/web/index.html'

files {
	'dist/**/*.*',
	'settings.json'
}

escrow_ignore {
	'**/**'
}

dependency 'ox_lib'

lua54 'yes'