Old instruction: https://github.com/Zipcore/Timer
Don't worry about CS:GO color.

You want to know a cvar type "sm cvar pluginname"
You want to know a command type "sm cmds pluginname"

For minigame, surf, bhop servers some plugins are not necessary. 
You have to check what plugin you put on your server.
Please read all docs "docs/modules" to know.

if you upgrade the timer you need to execute one querie.
UPDATE ranks SET auth = REPLACE(auth, 'STEAM_0', 'STEAM_1')

you can keep you old rankings.cfg and physics.cfg but you have to replace the settings.cfg
you have an example settings for minigane here "addons/sourcemod/configs/timer/settings_exmaples"


drapi_hide_radar 				= just hide the useless radar.
drapi_join_team_message			= beautiful connect message.
drapi_radio_message				= block the radio chat.
drapi_thirdperson_bhop			= allow the 3rd view.
drapi_timer_finish_message		= message when player finish the track.
drapi_timer_levelup				= message when player win a rank. Better to use with my rankings.cfg
drapi_timer_mapzones_effects	= sprite who is delimited the start, end, stage zones.
drapi_timer_mayamode			= maya mode to see your face usefull to see skins. check my physics.cfg to use it
drapi_timer_replay				= Replay the WR for Auto[normal], Auto[no boost], legit and Slowmotion[no limit].
drapi_timer_server_settings		= set some cvars check your settings.cfg. Server section.
drapi_unlock_full_team			= Add spawn to allow bots without full team message, also people can join T or CT.