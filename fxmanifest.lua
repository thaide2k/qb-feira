fx_version 'cerulean'
game 'gta5'

description 'QB Feira - Sistema de Venda de Weed'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'qb-tablet',
    'qb-venices'
}