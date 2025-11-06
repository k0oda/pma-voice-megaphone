fx_version 'cerulean'
game 'gta5'

author 'k0oda'
description 'Megaphone addon for pma-voice with audio submix effects'
version '1.0.0'

lua54 'yes'

dependencies {
    'pma-voice'
}

shared_script 'shared.lua'

client_scripts {
    'client/megaphone.lua'
}
