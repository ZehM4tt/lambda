if SERVER then AddCSLuaFile() end
local Taunts = {}
local Categories = {}
local function InsertCategory(category)
    local id = #Categories + 1
    Categories[id] = {
        Id = id,
        Name = category
    }
    return id
end

local function GetCategoryIndex(category)
    for k, v in pairs(Categories) do
        if v.Name == category then return v.Id end
    end
    return nil
end

local function InsertTaunt(categoryId, mdlCategory, name, files)
    if Categories[categoryId] == nil then
        error("Invalid category id.")
        return
    end

    Taunts[categoryId] = Taunts[categoryId] or {}
    Taunts[categoryId][mdlCategory] = Taunts[categoryId][mdlCategory] or {}
    local data = {
        Name = name,
        Sounds = files
    }

    table.insert(Taunts[categoryId][mdlCategory], data)
end

local CAT_TAUNTS = InsertCategory("Taunts")
local function InsertMultipleTaunts(categoryId, mdlCategory, tauntsTable)
    for name, sounds in pairs(tauntsTable) do
        InsertTaunt(categoryId, mdlCategory, name, type(sounds) == "table" and sounds or {sounds})
    end
end

local ZOMBIE_MOANS = {"npc/zombie/zombie_voice_idle1.wav", "npc/zombie/zombie_voice_idle2.wav", "npc/zombie/zombie_voice_idle3.wav", "npc/zombie/zombie_voice_idle4.wav", "npc/zombie/zombie_voice_idle5.wav", "npc/zombie/zombie_voice_idle6.wav", "npc/zombie/zombie_voice_idle7.wav", "npc/zombie/zombie_voice_idle8.wav", "npc/zombie/zombie_voice_idle9.wav", "npc/zombie/zombie_voice_idle10.wav", "npc/zombie/zombie_voice_idle11.wav", "npc/zombie/zombie_voice_idle12.wav", "npc/zombie/zombie_voice_idle13.wav", "npc/zombie/zombie_voice_idle14.wav"}
InsertMultipleTaunts(CAT_TAUNTS, "zombie", {
    ["Over there"] = "npc/zombie/zombie_alert1.wav",
    ["Over here"] = "npc/zombie/zombie_alert2.wav",
    ["Take cover"] = ZOMBIE_MOANS,
    ["I'm Ready"] = ZOMBIE_MOANS,
    ["Hi"] = ZOMBIE_MOANS,
    ["Yeah"] = ZOMBIE_MOANS,
    ["Okay"] = ZOMBIE_MOANS,
    ["No"] = ZOMBIE_MOANS,
    ["Nice"] = ZOMBIE_MOANS,
    ["Help"] = ZOMBIE_MOANS,
    ["Sorry"] = ZOMBIE_MOANS,
    ["Leave it alone"] = ZOMBIE_MOANS,
    ["I'm with you"] = ZOMBIE_MOANS,
    ["Ready when you are"] = ZOMBIE_MOANS,
    ["Whatever you say"] = ZOMBIE_MOANS,
    ["Let's go"] = ZOMBIE_MOANS,
    ["Excuse me"] = ZOMBIE_MOANS,
    ["Get down"] = ZOMBIE_MOANS,
    ["Heads up"] = ZOMBIE_MOANS,
    ["Fantastic"] = ZOMBIE_MOANS,
    ["Finally"] = ZOMBIE_MOANS,
    ["Good God"] = ZOMBIE_MOANS,
    ["Run for your life"] = ZOMBIE_MOANS,
    ["Run"] = ZOMBIE_MOANS,
    ["Behind you"] = ZOMBIE_MOANS,
    ["You got it"] = ZOMBIE_MOANS,
    ["Whoops"] = ZOMBIE_MOANS,
    ["Watch out"] = ZOMBIE_MOANS,
    ["Waiting for somebody?"] = ZOMBIE_MOANS,
    ["Like that"] = ZOMBIE_MOANS,
    ["We trusted you"] = ZOMBIE_MOANS,
    ["How about that"] = ZOMBIE_MOANS,
    ["Wanna bet"] = ZOMBIE_MOANS
})

InsertMultipleTaunts(CAT_TAUNTS, "combine", {
    ["Over there"] = {"npc/metropolice/vo/move.wav", "npc/metropolice/vo/moveit.wav", "npc/metropolice/vo/moveit2.wav", "npc/metropolice/vo/examine.wav"},
    ["Over here"] = {"npc/metropolice/vo/holdthisposition.wav", "npc/metropolice/vo/holditrightthere.wav"},
    ["Take cover"] = "npc/metropolice/vo/takecover.wav",
    ["I'm Ready"] = {"npc/metropolice/vo/readytojudge.wav", "npc/metropolice/vo/readytoprosecute.wav", "npc/metropolice/vo/readytoamputate.wav"},
    ["Affirmative"] = {"npc/combine_soldier/vo/affirmative.wav", "npc/combine_soldier/vo/affirmative2.wav"},
    ["Nice"] = "npc/metropolice/vo/chuckle.wav",
    ["Help"] = "npc/metropolice/vo/help.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "alyx", {
    ["Over there"] = {"vo/k_lab/al_there.wav", "vo/novaprospekt/al_there.wav"},
    ["Over here"] = "vo/trainyard/al_overhere.wav",
    ["Take cover"] = "vo/npc/female01/takecover02.wav",
    ["Follow me"] = "vo/novaprospekt/al_followme01.wav",
    ["Let's get going"] = "vo/novaprospekt/al_letsgetgoing.wav",
    ["Cover me"] = {"vo/npc/alyx/coverme01.wav", "vo/npc/alyx/coverme02.wav", "vo/npc/alyx/coverme03.wav"},
    ["Let's go"] = {"vo/streetwar/alyx_gate/al_letsgo.wav", "vo/streetwar/alyx_gate/al_letsgo01.wav"},
    ["Excuse me"] = "vo/npc/alyx/al_excuse03.wav",
    ["Watch out"] = {"vo/npc/alyx/watchout01.wav", "vo/npc/alyx/watchout02.wav"}
})

InsertMultipleTaunts(CAT_TAUNTS, "monk", {
    ["Over there"] = "vo/ravenholm/exit_goquickly.wav",
    ["Over here"] = {"vo/ravenholm/shotgun_overhere.wav", "vo/ravenholm/monk_overhere.wav"},
    ["Take cover"] = "vo/ravenholm/bucket_guardwell.wav",
    ["Follow me"] = {"vo/ravenholm/monk_followme.wav", "vo/ravenholm/grave_stayclose.wav"},
    ["Cover me"] = {"vo/ravenholm/monk_coverme01.wav", "vo/ravenholm/monk_coverme02.wav", "vo/ravenholm/monk_coverme03.wav", "vo/ravenholm/monk_coverme04.wav", "vo/ravenholm/monk_coverme05.wav", "vo/ravenholm/monk_coverme07.wav"},
    ["Let's go"] = "vo/ravenholm/exit_goquickly.wav",
    ["Watch out"] = {"vo/ravenholm/monk_danger03.wav", "vo/ravenholm/monk_danger02.wav", "vo/ravenholm/monk_danger01.wav"},
    ["Behind you"] = "vo/ravenholm/firetrap_lookout.wav",
    ["Help"] = {"vo/ravenholm/monk_helpme01.wav", "vo/ravenholm/monk_helpme02.wav", "vo/ravenholm/monk_helpme04.wav", "vo/ravenholm/monk_helpme05.wav"}
})

InsertMultipleTaunts(CAT_TAUNTS, "barney", {
    ["Over there"] = "vo/streetwar/sniper/ba_letsgetgoing.wav",
    ["Over here"] = "vo/streetwar/sniper/ba_overhere.wav",
    ["Follow me"] = {"vo/npc/barney/ba_followme02.wav", "vo/npc/barney/ba_followme05.wav"},
    ["Let's go"] = "vo/npc/barney/ba_letsgo.wav",
    ["Watch out"] = "vo/npc/barney/ba_lookout.wav",
    ["Help"] = "vo/streetwar/rubble/ba_helpmeout.wav",
    ["Done"] = "vo/streetwar/nexus/ba_done.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "male", {
    ["Over there"] = {"vo/npc/male01/overthere01.wav", "vo/npc/male01/overthere02.wav"},
    ["Over here"] = "vo/npc/male01/overhere01.wav",
    ["Take cover"] = "vo/npc/male01/takecover02.wav",
    ["I'm Ready"] = {"vo/npc/male01/okimready01.wav", "vo/npc/male01/okimready02.wav", "vo/npc/male01/okimready03.wav"},
    ["Hi"] = {"vo/npc/male01/hi01.wav", "vo/npc/male01/hi02.wav"},
    ["Yeah"] = "vo/npc/male01/yeah02.wav",
    ["Okay"] = {"vo/npc/male01/ok01.wav", "vo/npc/male01/ok02.wav"},
    ["No"] = "vo/npc/male01/no01.wav",
    ["Nice"] = "vo/npc/male01/nice.wav",
    ["Help"] = "vo/npc/male01/help01.wav",
    ["Sorry"] = {"vo/npc/male01/sorry01.wav", "vo/npc/male01/sorry02.wav", "vo/npc/male01/sorry03.wav"},
    ["Leave it alone"] = "vo/npc/male01/answer38.wav",
    ["I'm with you"] = "vo/npc/male01/answer13.wav",
    ["Ready when you are"] = {"vo/npc/male01/readywhenyouare01.wav", "vo/npc/male01/readywhenyouare02.wav"},
    ["Whatever you say"] = "vo/npc/male01/squad_affirm03.wav",
    ["Let's go"] = {"vo/npc/male01/letsgo01.wav", "vo/npc/male01/letsgo02.wav"},
    ["Excuse me"] = {"vo/npc/male01/excuseme01.wav", "vo/npc/male01/excuseme02.wav"},
    ["Get down"] = "vo/npc/male01/getdown02.wav",
    ["Heads up"] = {"vo/npc/male01/headsup01.wav", "vo/npc/male01/headsup02.wav"},
    ["Fantastic"] = {"vo/npc/male01/fantastic01.wav", "vo/npc/male01/fantastic02.wav"},
    ["Finally"] = "vo/npc/male01/finally.wav",
    ["Good God"] = "vo/npc/male01/goodgod.wav",
    ["Run for your life"] = {"vo/npc/male01/runforyourlife01.wav", "vo/npc/male01/runforyourlife02.wav", "vo/npc/male01/runforyourlife03.wav"},
    ["Run"] = "vo/npc/male01/strider_run.wav",
    ["Behind you"] = {"vo/npc/male01/behindyou01.wav", "vo/npc/male01/behindyou02.wav"},
    ["You got it"] = "vo/npc/male01/yougotit02.wav",
    ["Whoops"] = "vo/npc/male01/whoops01.wav",
    ["Watch out"] = "vo/npc/male01/watchout.wav",
    ["Waiting for somebody?"] = "vo/npc/male01/waitingsomebody.wav",
    ["Like that"] = "vo/npc/male01/likethat.wav",
    ["We trusted you"] = {"vo/npc/male01/wetrustedyou01.wav", "vo/npc/male01/wetrustedyou02.wav"},
    ["How about that"] = "vo/npc/male01/answer25.wav",
    ["Wanna bet"] = "vo/npc/male01/answer27.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "female", {
    ["Over there"] = {"vo/npc/female01/overthere01.wav", "vo/npc/female01/overthere02.wav"},
    ["Over here"] = "vo/npc/female01/overhere01.wav",
    ["Take cover"] = "vo/npc/female01/takecover02.wav",
    ["I'm Ready"] = {"vo/npc/female01/okimready01.wav", "vo/npc/female01/okimready02.wav", "vo/npc/female01/okimready03.wav"},
    ["Hi"] = {"vo/npc/female01/hi01.wav", "vo/npc/female01/hi02.wav"},
    ["Yeah"] = "vo/npc/female01/yeah02.wav",
    ["Okay"] = {"vo/npc/female01/ok01.wav", "vo/npc/female01/ok02.wav"},
    ["No"] = "vo/npc/female01/no01.wav",
    ["Nice"] = {"vo/npc/female01/nice01.wav", "vo/npc/female01/nice02.wav"},
    ["Help"] = "vo/npc/female01/help01.wav",
    ["Sorry"] = {"vo/npc/female01/sorry01.wav", "vo/npc/female01/sorry02.wav", "vo/npc/female01/sorry03.wav"},
    ["Leave it alone"] = "vo/npc/female01/answer38.wav",
    ["I'm with you"] = "vo/npc/female01/answer13.wav",
    ["Ready when you are"] = {"vo/npc/female01/readywhenyouare01.wav", "vo/npc/female01/readywhenyouare02.wav"},
    ["Whatever you say"] = "vo/npc/female01/squad_affirm03.wav",
    ["Let's go"] = {"vo/npc/female01/letsgo01.wav", "vo/npc/female01/letsgo02.wav"},
    ["Excuse me"] = {"vo/npc/female01/excuseme01.wav", "vo/npc/female01/excuseme02.wav"},
    ["Get down"] = "vo/npc/female01/getdown02.wav",
    ["Heads up"] = {"vo/npc/female01/headsup01.wav", "vo/npc/female01/headsup02.wav"},
    ["Fantastic"] = {"vo/npc/female01/fantastic01.wav", "vo/npc/female01/fantastic02.wav"},
    ["Finally"] = "vo/npc/female01/finally.wav",
    ["Good God"] = "vo/npc/female01/goodgod.wav",
    ["Run for your life"] = {"vo/npc/female01/runforyourlife01.wav", "vo/npc/female01/runforyourlife02.wav", "vo/npc/female01/runforyourlife03.wav"},
    ["Run"] = "vo/npc/female01/strider_run.wav",
    ["Behind you"] = {"vo/npc/female01/behindyou01.wav", "vo/npc/female01/behindyou02.wav"},
    ["You got it"] = "vo/npc/female01/yougotit02.wav",
    ["Whoops"] = "vo/npc/female01/whoops01.wav",
    ["Watch out"] = "vo/npc/female01/watchout.wav",
    ["Waiting for somebody?"] = "vo/npc/female01/waitingsomebody.wav",
    ["Like that"] = "vo/npc/female01/likethat.wav",
    ["We trusted you"] = {"vo/npc/female01/wetrustedyou01.wav", "vo/npc/female01/wetrustedyou02.wav"},
    ["How about that"] = "vo/npc/female01/answer25.wav",
    ["Wanna bet"] = "vo/npc/female01/answer27.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "gman", {
    ["Rise and Shine"] = "vo/gman_misc/gman_riseshine.wav",
    ["Wake Up and Smell the Ashes"] = "vo/gman_misc/gman_04.wav",
    ["The Right Man in the Wrong Place"] = "vo/gman_misc/gman_03.wav",
    ["Prepare for Unforeseen Consequences"] = "vo/gman_misc/gman_03.wav",
    ["Time to Work"] = "vo/gman_misc/gman_02.wav",
    ["Is It Really That Time Again?"] = "vo/citadel/gman_exit02.wav",
    ["You've Done a Great Deal"] = "vo/citadel/gman_exit04.wav",
    ["Interesting Offers"] = "vo/citadel/gman_exit05.wav",
    ["Not at Liberty to Say"] = "vo/citadel/gman_exit08.wav",
    ["This Is Where I Get Off"] = "vo/citadel/gman_exit10.wav",
    ["We'll See About That"] = "vo/episode_1/intro/gman_wellseeaboutthat.wav",
    ["Your Hour Has Come Again"] = "vo/gman_misc/gman_02.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "breen", {
    ["Welcome"] = {"vo/Breencast/br_welcome01.wav", "vo/Breencast/br_welcome02.wav", "vo/Breencast/br_welcome03.wav", "vo/Breencast/br_welcome04.wav", "vo/Breencast/br_welcome05.wav", "vo/Breencast/br_welcome06.wav", "vo/Breencast/br_welcome07.wav"},
    ["Instinct"] = {"vo/Breencast/br_instinct01.wav", "vo/Breencast/br_instinct02.wav", "vo/Breencast/br_instinct03.wav", "vo/Breencast/br_instinct04.wav", "vo/Breencast/br_instinct05.wav", "vo/Breencast/br_instinct06.wav", "vo/Breencast/br_instinct07.wav", "vo/Breencast/br_instinct08.wav", "vo/Breencast/br_instinct09.wav", "vo/Breencast/br_instinct10.wav", "vo/Breencast/br_instinct11.wav", "vo/Breencast/br_instinct12.wav", "vo/Breencast/br_instinct13.wav", "vo/Breencast/br_instinct14.wav", "vo/Breencast/br_instinct15.wav", "vo/Breencast/br_instinct16.wav", "vo/Breencast/br_instinct17.wav", "vo/Breencast/br_instinct18.wav", "vo/Breencast/br_instinct19.wav", "vo/Breencast/br_instinct20.wav", "vo/Breencast/br_instinct21.wav", "vo/Breencast/br_instinct22.wav", "vo/Breencast/br_instinct23.wav", "vo/Breencast/br_instinct24.wav", "vo/Breencast/br_instinct25.wav"},
    ["Our Benefactors"] = {"vo/Breencast/br_overwatch01.wav", "vo/Breencast/br_overwatch02.wav", "vo/Breencast/br_overwatch03.wav", "vo/Breencast/br_overwatch04.wav", "vo/Breencast/br_overwatch05.wav", "vo/Breencast/br_overwatch06.wav", "vo/Breencast/br_overwatch07.wav", "vo/Breencast/br_overwatch08.wav", "vo/Breencast/br_overwatch09.wav"},
    ["Collaborate"] = {"vo/Breencast/br_collaboration01.wav", "vo/Breencast/br_collaboration02.wav", "vo/Breencast/br_collaboration03.wav", "vo/Breencast/br_collaboration04.wav", "vo/Breencast/br_collaboration05.wav", "vo/Breencast/br_collaboration06.wav", "vo/Breencast/br_collaboration07.wav", "vo/Breencast/br_collaboration08.wav", "vo/Breencast/br_collaboration09.wav", "vo/Breencast/br_collaboration10.wav", "vo/Breencast/br_collaboration11.wav"},
    ["Disruptor"] = {"vo/Breencast/br_disruptor01.wav", "vo/Breencast/br_disruptor02.wav", "vo/Breencast/br_disruptor03.wav", "vo/Breencast/br_disruptor04.wav", "vo/Breencast/br_disruptor05.wav", "vo/Breencast/br_disruptor06.wav", "vo/Breencast/br_disruptor07.wav", "vo/Breencast/br_disruptor08.wav"},
    ["To Freeman"] = {"vo/Breencast/br_tofreeman01.wav", "vo/Breencast/br_tofreeman02.wav", "vo/Breencast/br_tofreeman03.wav", "vo/Breencast/br_tofreeman04.wav", "vo/Breencast/br_tofreeman05.wav", "vo/Breencast/br_tofreeman06.wav", "vo/Breencast/br_tofreeman07.wav", "vo/Breencast/br_tofreeman08.wav", "vo/Breencast/br_tofreeman09.wav", "vo/Breencast/br_tofreeman10.wav", "vo/Breencast/br_tofreeman11.wav", "vo/Breencast/br_tofreeman12.wav"}
})

InsertMultipleTaunts(CAT_TAUNTS, "vortigaunt", {
    ["The Freeman"] = "vo/npc/vortigaunt/freeman.wav",
    ["All For Freedom"] = "vo/npc/vortigaunt/forfreedom.wav",
    ["We Serve The Same Mystery"] = "vo/npc/vortigaunt/mystery.wav",
    ["Our Finest Poet"] = "vo/npc/vortigaunt/poet.wav",
    ["We Are Yours"] = "vo/npc/vortigaunt/weareyours.wav",
    ["The Eli Vance"] = "vo/eli_lab/vort_elab_use01.wav",
    ["Vortigese"] = {"vo/npc/vortigaunt/vortigese02.wav"},
    ["Hold Still"] = "vo/npc/vortigaunt/holdstill.wav",
    ["Caution"] = "vo/npc/vortigaunt/caution.wav",
    ["To The Void"] = "vo/npc/vortigaunt/tothevoid.wav",
    ["Stand Clear"] = "vo/npc/vortigaunt/standclear.wav",
    ["Accompany"] = "vo/npc/vortigaunt/accompany.wav",
    ["Greetings"] = "vo/npc/vortigaunt/greetingsfm.wav",
    ["Satisfaction"] = "vo/npc/vortigaunt/satisfaction.wav",
    ["As You Wish"] = "vo/npc/vortigaunt/asyouwish.wav",
    ["Certainly"] = "vo/npc/vortigaunt/certainly.wav",
    ["Gladly"] = "vo/npc/vortigaunt/gladly.wav",
    ["With Pleasure"] = "vo/npc/vortigaunt/pleasure.wav",
    ["We Remember The Freeman"] = "vo/npc/vortigaunt/vmono_03.wav",
    ["No Distance Between Us"] = "vo/npc/vortigaunt/vmono_04.wav",
    ["Unity of Purpose"] = "vo/npc/vortigaunt/vmono_10.wav",
    ["Your Song We Sing"] = "vo/npc/vortigaunt/vmono_11.wav",
    ["Grief and Jubilation"] = "vo/npc/vortigaunt/vmono_12.wav",
    ["Talisman of Victory"] = "vo/npc/vortigaunt/vmono_16.wav",
    ["We Take Our Stand"] = "vo/npc/vortigaunt/vmono_24.wav",
    ["We Are You, Freeman"] = "vo/npc/vortigaunt/vmono_30.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "eli", {
    ["It's Good to See You"] = "vo/eli_lab/eli_greeting.wav",
    ["Go With Alyx"] = {"vo/eli_lab/eli_gowithalyx01.wav", "vo/eli_lab/eli_gowithalyx02.wav", "vo/eli_lab/eli_gowithalyx03.wav"},
    ["Look Around"] = "vo/eli_lab/eli_lookaround.wav",
    ["The Portal"] = {"vo/eli_lab/eli_portal01.wav", "vo/eli_lab/eli_portal02.wav"},
    ["Be Careful"] = {"vo/eli_lab/eli_staytogether01.wav", "vo/eli_lab/eli_staytogether02.wav"},
    ["The Surface"] = {"vo/eli_lab/eli_surface.wav", "vo/eli_lab/eli_surface_b.wav"},
    ["Vile Business"] = {"vo/eli_lab/eli_vilebiz01.wav", "vo/eli_lab/eli_vilebiz02.wav", "vo/eli_lab/eli_vilebiz03.wav", "vo/eli_lab/eli_vilebiz04.wav"},
    ["Welcome to the Lab"] = "vo/eli_lab/eli_welcometolab.wav",
    ["Alyx, Honey"] = "vo/eli_lab/eli_alyxhoney.wav",
    ["Fine Scientist"] = "vo/eli_lab/eli_finesci.wav",
    ["Good Vortigaunt"] = "vo/eli_lab/eli_goodvort.wav",
    ["Gordon With Us"] = "vo/eli_lab/eli_gordonwith.wav",
    ["I'll Handle This"] = {"vo/eli_lab/eli_handle.wav", "vo/eli_lab/eli_handle_b.wav"},
    ["Ladies"] = "vo/eli_lab/eli_ladies.wav",
    ["Little While"] = "vo/eli_lab/eli_littlewhile.wav",
    ["Look, Gordon"] = "vo/eli_lab/eli_lookgordon.wav",
    ["MIT"] = "vo/eli_lab/eli_mit.wav",
    ["The Photo"] = {"vo/eli_lab/eli_photo01.wav", "vo/eli_lab/eli_photo02.wav"},
    ["Safety First"] = "vo/eli_lab/eli_safety.wav",
    ["One More Thing"] = "vo/eli_lab/eli_thing.wav",
    ["I Want You to Have This"] = "vo/eli_lab/eli_wantyou.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "kleiner", {
    ["Greetings"] = "combined/k_lab/k_lab_kl_mygoodness02_cc.wav",
    ["Almost Forgot"] = "combined/k_lab/k_lab_kl_almostforgot_cc.wav",
    ["Blast"] = "combined/k_lab/k_lab_kl_blast_cc.wav",
    ["Charger"] = "combined/k_lab/k_lab_kl_charger01_cc.wav",
    ["Debeaked"] = "combined/k_lab/k_lab_kl_debeaked_cc.wav",
    ["Excellent"] = "combined/k_lab/k_lab_kl_excellent_cc.wav",
    ["Few Moments"] = "combined/k_lab/k_lab_kl_fewmoments01_cc.wav",
    ["Fit Glove"] = "combined/k_lab/k_lab_kl_fitglove01_cc.wav",
    ["Get Out Run"] = "combined/k_lab/k_lab_kl_getoutrun01_cc.wav",
    ["Lamarr"] = "combined/k_lab/k_lab_kl_hedyno02_cc.wav",
    ["Hello Alyx"] = "combined/k_lab/k_lab_kl_helloalyx01_cc.wav",
    ["Initializing"] = "combined/k_lab/k_lab_kl_initializing_cc.wav",
    ["Massless Field Flux"] = "combined/k_lab/k_lab_kl_masslessfieldflux_cc.wav",
    ["Now Now"] = "combined/k_lab/k_lab_kl_nownow01_cc.wav",
    ["Opportune Time"] = "combined/k_lab/k_lab_kl_opportunetime01_cc.wav",
    ["Packing"] = "combined/k_lab/k_lab_kl_packing01_cc.wav",
    ["Project You"] = "combined/k_lab/k_lab_kl_projectyou_cc.wav",
    ["Red Letter Day"] = "combined/k_lab/k_lab_kl_redletterday01_cc.wav",
    ["Slip In"] = "combined/k_lab/k_lab_kl_slipin01_cc.wav",
    ["Suit Fits"] = "combined/k_lab/k_lab_kl_suitfits01_cc.wav",
    ["Wish I Knew"] = "combined/k_lab/k_lab_kl_wishiknew_cc.wav"
})

InsertMultipleTaunts(CAT_TAUNTS, "odessa", {
    ["Greetings"] = {"vo/coast/odessa/nlo_greet_freeman.wav", "vo/coast/odessa/nlo_greet_intro.wav"},
    ["At Your Service"] = "vo/coast/odessa/nlo_cub_service.wav",
    ["Carry On"] = "vo/coast/odessa/nlo_cub_carry.wav",
    ["Farewell"] = "vo/coast/odessa/nlo_cub_farewell.wav",
    ["The Road Ahead"] = "vo/coast/odessa/nlo_cub_roadahead.wav",
    ["You'll Make It"] = "vo/coast/odessa/nlo_cub_youllmakeit.wav",
    ["Warning"] = "vo/coast/odessa/nlo_cub_warning.wav",
    ["That's That"] = "vo/coast/odessa/nlo_cub_thatsthat.wav",
    ["Where Was I?"] = "vo/coast/odessa/nlo_cub_wherewasi.wav",
    ["Volunteer"] = "vo/coast/odessa/nlo_cub_volunteer.wav",
    ["Open Gate"] = "vo/coast/odessa/nlo_cub_opengate.wav",
    ["Radio"] = "vo/coast/odessa/nlo_cub_radio.wav",
    ["Follow Me"] = {"vo/coast/odessa/male01/stairman_follow01.wav", "vo/coast/odessa/male01/stairman_follow03.wav"},
    ["Get Your Vehicle"] = "vo/coast/odessa/male01/nlo_getyourjeep.wav",
    ["Drive Safely"] = "vo/coast/odessa/male01/nlo_citizen_drivesafe.wav",
    ["Cheer"] = {"vo/coast/odessa/male01/nlo_cheer01.wav", "vo/coast/odessa/male01/nlo_cheer02.wav", "vo/coast/odessa/male01/nlo_cheer03.wav", "vo/coast/odessa/male01/nlo_cheer04.wav"}
})


InsertMultipleTaunts(CAT_TAUNTS, "mossman", {
    ["Airlock"] = {"vo/eli_lab/mo_airlock01.wav", "vo/eli_lab/mo_airlock02.wav", "vo/eli_lab/mo_airlock03.wav", "vo/eli_lab/mo_airlock04.wav", "vo/eli_lab/mo_airlock05.wav", "vo/eli_lab/mo_airlock06.wav", "vo/eli_lab/mo_airlock07.wav", "vo/eli_lab/mo_airlock08.wav", "vo/eli_lab/mo_airlock09.wav", "vo/eli_lab/mo_airlock10.wav", "vo/eli_lab/mo_airlock11.wav", "vo/eli_lab/mo_airlock12.wav", "vo/eli_lab/mo_airlock13.wav", "vo/eli_lab/mo_airlock14.wav"},
    ["Alyx on Watch"] = "vo/eli_lab/mo_alyxonwatch.wav",
    ["Anyway"] = "vo/eli_lab/mo_anyway04.wav",
    ["Bad Capacitor"] = {"vo/eli_lab/mo_badcapacitor01.wav", "vo/eli_lab/mo_badcapacitor02.wav"},
    ["Deliberately"] = "vo/eli_lab/mo_deliberately.wav",
    ["Difference"] = "vo/eli_lab/mo_difference.wav",
    ["Dig Up"] = "vo/eli_lab/mo_digup01.wav",
    ["Extra Help"] = {"vo/eli_lab/mo_extrahelp01.wav", "vo/eli_lab/mo_extrahelp02.wav", "vo/eli_lab/mo_extrahelp03.wav", "vo/eli_lab/mo_extrahelp04.wav", "vo/eli_lab/mo_extrahelp05.wav", "vo/eli_lab/mo_extrahelp06.wav", "vo/eli_lab/mo_extrahelp07.wav", "vo/eli_lab/mo_extrahelp08.wav"},
    ["Go to Eli"] = {"vo/eli_lab/mo_gotoeli01.wav", "vo/eli_lab/mo_gotoeli02.wav", "vo/eli_lab/mo_gotoeli03.wav", "vo/eli_lab/mo_gotoeli04.wav"},
    ["Go with Alyx"] = {"vo/eli_lab/mo_gowithalyx01.wav", "vo/eli_lab/mo_gowithalyx02.wav"},
    ["Here's Eli"] = {"vo/eli_lab/mo_hereseli01.wav", "vo/eli_lab/mo_hereseli02.wav"},
    ["Hurry Up"] = "vo/eli_lab/mo_hurryup01.wav",
    ["Look Who's Here"] = "vo/eli_lab/mo_lookwho01.wav",
    ["No Blame"] = "vo/eli_lab/mo_noblame.wav",
    ["Not a Toy"] = "vo/eli_lab/mo_notatoy.wav",
    ["Postdoc"] = {"vo/eli_lab/mo_postdoc01.wav", "vo/eli_lab/mo_postdoc02.wav"},
    ["Real Honor"] = "vo/eli_lab/mo_realhonor02.wav",
    ["Relay"] = {"vo/eli_lab/mo_relay01.wav", "vo/eli_lab/mo_relay02.wav", "vo/eli_lab/mo_relay03.wav"},
    ["Take to Eli"] = "vo/eli_lab/mo_taketoeli.wav",
    ["This Way, Doctor"] = "vo/eli_lab/mo_thiswaydoc.wav"
})

function GM:GetTauntCategories()
    return Categories
end

function GM:GetTauntCategoryId(category)
    return GetCategoryIndex(category)
end

function GM:GetTaunts(categoryId, mdlCategory)
    return Taunts[categoryId][mdlCategory]
end

function GM:GetPlayerTaunts(ply, categoryId)
    local mdlCategory = ply:GetModelCategory()
    return self:GetTaunts(categoryId, mdlCategory)
end

function GM:GetAvailableTauntCategories()
    local categories = {"auto"}
    for _, categoryTaunts in pairs(Taunts) do
        for mdlCategory, _ in pairs(categoryTaunts) do
            if not table.HasValue(categories, mdlCategory) then table.insert(categories, mdlCategory) end
        end
    end
    return categories
end