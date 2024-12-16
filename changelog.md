0.9.26 (in development)
- Added "Free-Roaming" mode when spectating
- Improved: Going in and out of the settings no longer clips into the player model.
- Improved: The medkit now uses the player hull to detect who to heal, revive uses now hull trace.
- Improved: Added some effects to the medkit to signal its current energy level.
- Fixed: NPC makers not respecting the spawn frequency -1 causing a lot of NPCs being spawned in some cases.
- Fixed: ep1_c17_00a: Don't cancel scripted_sequence on player death.
- Fixed: Weapons not properly transitioning for NPCs.
- Fixed: Entity outputs not firing in the correct order.
- Fixed: Weapons don't respawn at where they were first picked up.

0.9.25
- Improved: Hints will no longer show duplicates, instead it will renew the existing hint that has the same text.
- Improved: ep1_c17_05: Add a checkpoint after the hallway.
- Fixed: ep1_c17_02a: Alyx not picking up a shotgun.
- Fixed: No longer runs 'skill' concommand, it's blocked since version 201211.

0.9.24
- Fixed: trigger_multiple ignoring the delay time.

0.9.23
- Improved: Some minor performance improvements for level transitioning.
- Improved: Implemented "ShowLogo" input to env_message entity.
- Improved: ep1_citadel_00: Fixed T-pose on vortigaunt and remove leftover chapter messages.
- Improved: d3_breen_01: Get the functionality closer to the original.
- Improved: Add a button in the settings menu to revert colors.
- Improved: ep1_c17_05: Escorting the NPCs should be a bit more reliable now.
- Improved: Players that didn't make the changelevel trigger will not be forcefully teleported, they get the default spawn next map.
- Fixed: Transitioning doors have sometimes the wrong rotation.
- Fixed: HUD is now hidden when point_viewcontrol takes control.
- Fixed: Triggers not firing outputs when they are disabled and then enabled again while entities are touching it.
- Fixed: trigger_teleport not working properly with flying NPC's.
- Fixed: ep1_c17_06: Add a fail-safe timer to ensure Barney will board the train.

0.9.22
- Improved: Weapon selection weights, this should improve selecting the next weapon when current one is empty.
- Fixed: Level transition sometimes ignoring the transition volumes forcing players to spawn with the default loadout on the next map.
- Fixed: ep1_citadel_00: Alyx stops the scripted scene if player falls off the cliff.
- Fixed: Killing mission critical NPCs causes the game end text to show up twice in some cases.
- Fixed: d2_coast_07: Forcefield has a white square when returning from d2_coast_08.
- Fixed: d2_coast_07: Wrong vehicle checkpoint when returning from d2_coast_08.
- Fixed: d3_citadel_04: Added missing checkpoint for the elevator.

0.9.21
- Improved: lambda_gametype will now default to 'auto' and warns about a misconfiguration.

0.9.20
- Feature: Episode 1 support.
- Improved: Language localization of settings (English only as of now).
- Improved: When "Friendly Fire" and "Player Collision" both disabled, bullet can pass through other players.
- Improved: Lambda no longer override the localization already existing in the game.
- Improved: d2_coast_03: Give more supplies, hope this can help player fight with multiple gunships better.
- Improved: d2_coast_03: Mission critical NPCs now have protection to prevent dying from a car accident.
- Improved: The gravity gun punt has now an energy effect.
- Improved: Small performance improvements for cockroaches and also improved the logic.
- Added: Option to limit the maximum amount of cockroaches, convar is 'lambda_max_cockroaches', 0 disables all. 
- Fixed: Pickup SMG grenade showing wrong icon.
- Fixed: d2_coast_03: G-Man and Oddssa stay in the balcony forever.
- Fixed: d2_coast_03: Blocked a exploit where player can use it to skip the final scene.
- Fixed: Disallow commanding citizen NPCs that have an active schedule.
- Fixed: Enemy scaling was improperly calculcated, now the math is right.
- Fixed: Players can sometimes spawn in the void if they didn't make it to the end of the map.
- Changed: Added a new setting to block respawns until a checkpoint is activated, previously it relied on lambda_max_respawn_timeout being -1.

0.9.19
- Fixed: SWEPs that use custom CalcView not working correctly.
- Fixed: Hide the builtin crosshair when SWEPs have custom ones.

0.9.18
- Improved: env_screenoverlay now works like behavior from HL2.
- Improved: d1_trainstation_05: Breen now plays the expected cutscene.
- Improved: d3_citadel_03: Reworked confiscation field area to make it process faster.
- Improved: d3_c17_10b map script.
- Fixed: env_screenoverlay causing error on some unexpected cases.
- Fixed: Open settings menu and close it too fast will leave a slider bar at top of screen.
- Fixed: d2_coast_10: Vehicle not being removed after parking it in the warehouse.
- Fixed: d3_citadel_03: A lua error at the beginning of the round and a rare potential soft-lock.
- Fixed: d3_breen_01: Breen can get stuck on the chair making the cutscene a bit slower.
- Fixed: Default difficulty is now "Normal" rather than "Very easy"
- Fixed: d1_canals_07: Metrocop didn't use the turret.
- Fixed: d3_c17_06b: Player can kill a friendly NPC and probability trigger a soft-lock.
- Fixed: d3_c17_10b: Player died in laser room, make the map unable to proceed.
- Fixed: Gravity gun animation doesn't properly works when breaking a ammo crate.

0.9.17
- Improved: Addon compatibility, Lambda will attempt to recover if there are conflicts and warns about it.

0.9.16
- Improved: Major performance improvements with lots of players on the server.
- Improved: Setting lambda_gametype to "auto" will detect the right gametype based on the loaded map.
- Improved: Scoreboard UI tweaks, allows to show more information provided by game type.
- Improved: d1_trainstation_05: Move alyx a bit further back for the introduction scene.
- Improved: Cockroaches have better performance and better behavior.
- Fixed: d1_trainstation_04: Don't despawn metropolice on street.
- Fixed: ep1_citadel_00: Dog intro scene not working correctly.
- Fixed: Screen overlays can get stuck when the map restarts while overlays are active.
- Fixed: NPCs stepping on cockroaches did nothing.
- Changed: Scoreboard will now show at the end of each map, this can be controlled by 'lambda_changelevel_delay'.
- Added: Support for skins and bodygroups on playermodels.

0.9.15
- Fixed: Incorrect addon structure causing custom content to not load for clients. [Regression]
- Fixed: 'lambda_allow_npcdmg' having no effect, mission critical NPCs are now protected from player damage when disabled.

0.9.14
- Feature: Checkpoints can now have a timeout, setting is controlled by 'lambda_checkpoint_timeout', 0 disables the timeout.
- Improved: Environmental player speech is now an option 'lambda_player_speech', 0 disables it.
- Improved: Damage player speech is now an option 'lambda_player_damage_speech', 0 disables it.
- Improved: Miscellaneous improvements to the gamemode menu.
- Improved: Console command registration.
- Improved: Render always the player when in settings menu.
- Improved: d1_trainstation_05 map script.
- Improved: d1_trainstation_06 map script, move med-kit further away.
- Improved: d3_citadel_01 map script.
- Improved: d3_citadel_02 map script.
- Improved: d3_citadel_03 map script.
- Improved: d3_citadel_04 map script.
- Improved: d3_citadel_05 map script.
- Added: A hint for players that have not yet opened the gamemode menu.
- Added: A warning notification for players starting the gamemode in Singleplayer mode.
- Added: Player name on top of death effect.
- Fixed: Player sometimes loose ammo over map transitioning.
- Fixed: Gravity Gun not being able to get objects behind fences.
- Fixed: Gravity Gun not allowing to punt non-debris ragdolls.
- Fixed: Gravity Gun effects breaking when transitioning from third-person to first-person view.
- Fixed: Gravity Gun not respecting setting for glow mode.
- Fixed: Gravity Gun light comes from player instead of the gun.
- Fixed: SWEPS fired by NPCs being extremly inaccurate, fixes some weapon addon compatibility issues.
- Fixed: Reset leftover global states if none provided in mapscript.
- Fixed: Lambda menu hint displaying the wrong binding.
- Changed: Do not give all weapons on missing map scripts.

0.9.13
- Fixed: d2_coast_11: Not giving everyone weapon_bugbait.
- Fixed: d2_coast_03: Combine binoculars corrupting view for all players.
- Fixed: Players not being credited for kills with ragdolls and mega gravity gun.
- Added: env_screenoverlay multiplayer support.

0.9.12
- Fixed: Only auto switch to weapons when still holding the empty gun.
- Fixed: HL2:EP1/HL2:DM game types not working correctly [Regression]
- Fixed: NPCs ragdolls would have different pose when killed with gravity gun.
- Improved: Gravity gun functions now closer to the original and interpolates at clients frame time.
- Added: Support for ep1_citadel_00 (Episode 1).
- Added: Support for ep1_citadel_01 (Episode 1).
- Added: Support for ep1_citadel_02b (Episode 1).
- Added: Support for ep1_citadel_03 (Episode 1).
- Added: Support for ep1_citadel_03 (Episode 1).

0.9.11
- Fixed: Lua error on death when dropped weapon can not be spawned.
- Fixed: Player shouting out enemies in pre-criminal state.
- Fixed: Settings camera menu will follow the player now.
- Improved: Gravity Gun on ground now has random colors instead of black.
- Improved: Minor performance optimizations for the gravity gun.
- Improved: Walking animations on moving platforms.

0.9.10
- Improved: Ability to register game types via addons.

0.9.9
- Fixed: Sprint not working correctly with newer Garry's Mod version (dev).
- Fixed: Sound not playing when sprinting is denied.

0.9.8
- Fixed: Soundscrapes playing indefinitely

0.9.7
- Fixed: env_credits throwing errors if credits file is missing.
- Fixed: entities not registering outputs via AcceptInput
- Fixed: point_viewcontrol having uninitialized angle.
- Fixed: d3_c17_02 having default player loadout.
- Fixed: PLAYER_META:Give not working in rare cases.

0.9.6
- Feature: Accelerated backhopping
- Feature: env_credits multiplayer support.
- Improved: Removed Cockroaches from kill feed, players will no longer get points for killing them.
- Improved: Keep track of physcannon color when dropped.
- Improved: d3_breen_01: Place all players in the same pod to not skip the scene.
- Improved: Transitioning from d3_citadel_05 to d3_breen_01
- Improved: Better round restart info.
- Improved: Players get the medkit now at d1_trainstation_06 instead of d1_trainstation_05.
- Fixed: Potential crash after changelevel.
- Fixed: point_viewcontrol not behaving like original.
- Fixed: Some entity outputs being fired twice.
- Fixed: Lua errors when cleaning up map during players view controlled by point_viewcontrol.
- Fixed: d3_breen_01: Platforms would stop moving if player reached top.
- Fixed: Medkit not properly working in singleplayer.
- Fixed: Selection of best weapon on depleted ammo and player spawn.
- Fixed: Settings not correctly clamped.
- Fixed: Physcannon throwing errors when players die.
- Fixed: Settings showing up twice.
- Fixed: Vehicles getting displayed in kill feed instead of player.
- Fixed: d3_citadel_05: Default weapons not being removed.
- Fixed: d3_citadel_05: Keep the pod cycle active after the player left the area.
- Fixed: Networked variables being overwritten by client ignoring server value.

0.9.5
- Improved: Add projected textures as an option for physcannon glow, enabled by default (physcannon_glow = 1)
- Fixed: Physcannon not dropping attached object when weapon dropped.

0.9.4
- Feature: Add 'LambdaInitializeMapList(maplist)' hook, allows addons to add/remove maps from the list.
- Fixed: Vote system did not consider amount of voters, 2/3 is required to be a valid vote.
- Fixed: Gravity gun throwing errors in some cases.

0.9.3
- Feature: Realism difficulty, for people who like a challenge.
- Feature: Medkit was added to heal and revive players, received in d1_trainstation_05.
- Feature: lambda_weapondropmode allows to specify what players drop on death.
- Feature: Implemented env_zoom with multiplayer support.
- Feature: Implemented point_viewcontrol with multiplayer support.
- Feature: Player flinching animations that indicates the hit position of damage.
- Improved: Allow gametype to auto start without players.
- Improved: (F1) Player menu overhaul.
- Improved: Checkpoints were rebalanced, encourage players to revive others.
- Improved: Physcannon prediction has now a tolerance before being attached clientside.
- Improved: Physcannon glow was reduced.
- Improved: Kill feed overhaul, now considers screen resolution.
- Improved: Replaced bullet impact sounds with more realistic ones.
- Improved: Proxy animation models for episodic support, currently incomplete.
- Fixed: PLAYER:Give not working properly in some cases.
- Fixed: Physcannon not networking idle time causing stuttery momvement.
- Fixed: d1_town_02 lock door to prevent backtracking.
- Fixed: Physcannon missing sprites glow sprites on end caps.
- Fixed: Vehicle view not resetting roll.
- Fixed: Item respawn spam.
- Fixed: d2_prison_05 blocking players near map end.
- Fixed: NPC Maker not spawning NPCs in some cases.
- Fixed: d1_trainstation_01 queue sometimes blocking the player.
- Fixed: Don't render player blockades in Skybox rendering pass.
- Fixed: Gravity Gun not resetting beam properly on FP/TP view change.
- Fixed: Some delayed inputs firing after map reset.
- Fixed: trigger displaying waiting info when requested not to.
- Fixed: Pending entity outputs not being cleared on map restart.
- Fixed: Round information HUDs missing when first connected.

0.9.2:
- Fixed: logic_auto and trigger_auto firing too many events.
- Improved: Slightly offset the glow on physcannon to prevent culling.

0.9.1:
- Feature: Dynamic crosshair overhaul, no longer requires capturing the framebuffer, can be changed in the options menu.
- Feature: Native game hints.
- Feature: Deathmatch gametype, set lambda_gametype convar to 'hl2dm' to try it out.
- Feature: Ability to command friendly NPCs via the Context menu.
- Feature: Vote system, allows players to vote: Skip Map, Change to Map, Kick Player, Restart Round.
- Feature: Allow players to kill every NPC, the game will restart the map if a critical NPC died, set 'lambda_allow_npcdmg' to 0 to disable this.
- Feature: Cockroaches, more or less like the classic ones from Half-Life 1, can be found hiding under objects.
- Feature: Gore effects when crushed or exploded, set 'lambda_gore' to 0 disable, enabled by default.
- Feature: Difficulty can be now set via 'lambda_difficulty', values 1: Very Easy, 2: Easy, 3: Normal, 4: Hard, 5: Very Hard
- Feature: Gravity Gun Glow, can be turned by setting 'physcannon_glow' to 0.
- Improved: Combine will now emit hurt sounds when taking damage.
- Improved: Allow to select all known player models the server has.
- Improved: Player sounds and taunts are now specific to the player model type.
- Improved: Replaced some killicons, credits to _Kilburn for the icons.
- Improved: The scoreboard has some improvements to better match gametypes and their rules.
- Improved: Flashlight no longer drains suit energy.
- Improved: Overall performance improvements for server and client.
- Improved: Players will no longer have empty grenades or slams in their inventory.
- Added: Game content mounting for episodic content, automatically creates and mounts GMA based on gametype.
- Added: ConVar to block moving weapons/items by shooting them, 'lambda_prevent_item_move <bool>'.
- Added: ConVar to disable ammo limits, 'lambda_limit_default_ammo <bool>'.
- Fixed: trigger_hurt using invalid damage type.
- Fixed: d2_coast_01 having default map items
- Fixed: d2_coast_03 having default map items.
- Fixed: Prediction errors caused by 'friendly_encounter' game state.
- Fixed: Physcannon not stopping looping sounds and not detaching on player death.
- Fixed: Physcannon ignoring the mass.
- Fixed: Physcannon spamming animation events.
- Fixed: Physcannon unable to push back enemies such as headcrabs.
- Fixed: Weapons can only be picked up once now per player.
- Fixed: Player not spawning properly when starting with d3_c17_07.
- Fixed: Player being left behind after battle in d3_c17_07.
- Fixed: Disallow players going back in d1_town_02 preventing disruptive play.
- Fixed: Missing changelevel blockade in d3_c17_07.
- Fixed: Prevent player from going back in d1_town_02
- Fixed: NPC's sometimes not playing the scene under unknown situations.
- Fixed: Server sometimes not starting a new round 
- Fixed: Scripted scenes getting stuck, forced playback after timeout.
- Fixed: Networked velocity per client, no longer using estimates on player animations.
- Fixed: Enemies not enabled when going back from d2_coast_08 to d2_coast_07.
- Fixed: Remove more default map spawn items, managed by Lambda.
- Fixed: Reset global state on d1_trainstation_01 to d1_trainstation_05.
- Fixed: d1_trainstation_05 do not lock up players in barney room by an invisible wall.
- Fixed: Prevent non-players enforcing touch events on triggers.
- Fixed: Settings not replicating.
- Fixed: d3_c17_07 creating infinite soldiers when player does not meet alyx.
- Fixed: Barney to appear twice on d3_c17_10a.
- Fixed: Barney to appear twice on d3_c17_10b.
- Fixed: Players not getting the crowbar on d1_trainstation_06.
- Fixed: Suit would recharge too fast, prevents players from infinite sprinting.
- Fixed: Ragdolls wouldn't be properly transitioned.

0.9:
- Removed: Freezing physics when trying to jump off them.
- Removed: Animation blending. 
- Fixed: Giving players more ammo than they can carry on weapon pickup.
- Fixed: Weapon damage not properly set via cvars. 
- Fixed: d1_canals_05 not opening gate, manually possible now. 
- Fixed: Giving default ammo ammount, only give what player carried from level to level. 
- Fixed: Draws the player weapon with player tracker now. 
- Fixed: Checkpoints not properly resetting. 
- Fixed: Death symbol using incorrect eye position. 
- Fixed: Weapon switching not stopping reload. 
- Fixed: Output log vanishing if EPOE is present. 
- Fixed: Hopefully fixed players timing out while they shouldn't. 
- Fixed: Player tracking being invisible in some cases. Better debug info on triggers. 
- Fixed: Player tracking being client option, now server side.
- Fixed: Grenade duplicating on death. 
- Fixed: User never signaled connection, consider him fully connected when message arrives.
- Fixed: Commands being unable to ran from server console.
- Fixed: Bots having invalid models. 
- Fixed: Sprint sound not working on singleplayer game.
- Fixed: Passing nil ent on Touch.
- Fixed: Calling Touch manually if the player left a trigger that disabled EndTouch events.
- Fixed: Autoreload not reloading mapscripts.
- Fixed: d1_trainstation_05 messing up barneys spawn if player is nearby, simply closing the soda door.
- Fixed: Dog disappearing in d3_c17_02.
- Fixed: Door never opening in d3_c17_03.
- Fixed: Pickup hud not being properly aligned and sized.
- Fixed: Fire sounds not stopping in some cases.
- Fixed: Player unable to select weapons using passenger seat.
- Fixed: Player seeing the vehicle symbol when inside vehicle.
- Improved: Precision on GetSyncedTimestamp. 
- Improved: Minor performance improvements. 
- Improved: Reduced distance of player stats.
- Improved: Player tracking option.
- Improved: Modified player tracker to be less annoying when barely visible.
- Feature: Custom gravity gun rewritten from scratch with support of the mega gravity gun and prediction support.
- Feature: Dynamic checkpoint selection. 
- Feature: Players will consider their souroundings and use shout outs accordingly.
- Feature: Made the player timeout a convar.
- Feature: Custom HUD colors.
- Feature: Settings menu for player models, admin settings etc. on F1.
- Feature: Teleport heuristic to allow changes on collision rules.
- Feature: Allow player collisions.
- Feature: Friendly fire support.
- Feature: No respawn support.
