-- jobs.lua - TDMRP master job list
-- Updated: December 29, 2025
-- Complete overhaul with HP/AP/DT/Movement stats and backstories

----------------------------------------------------
-- CIVILIANS
----------------------------------------------------

TEAM_CITIZEN = DarkRP.createJob("Citizen", {
    color = Color(60, 200, 60, 255),
    model = {
        "models/player/Group01/male_01.mdl",
        "models/player/Group01/male_02.mdl",
        "models/player/Group01/male_03.mdl",
        "models/player/Group01/male_04.mdl",
        "models/player/Group01/male_05.mdl",
        "models/player/Group01/male_06.mdl",
        "models/player/Group01/male_07.mdl",
        "models/player/Group01/male_08.mdl",
        "models/player/Group01/male_09.mdl",
        "models/player/Group01/female_01.mdl",
        "models/player/Group01/female_02.mdl",
        "models/player/Group01/female_03.mdl",
        "models/player/Group01/female_04.mdl",
        "models/player/Group01/female_06.mdl",
    },
    description = [[You're just trying to survive in this god-forsaken city. The cops shoot first, the criminals steal everything, and someone keeps painting graffiti on your house that says "FREE REAL ESTATE." You've learned to duck when you hear gunshots (which is always).

Stats: Standard civilian - no combat bonuses
• 100 HP | No Armor | No DT
• Earn passive income by staying alive
• Cannot participate in control points]],
    weapons = {},
    command = "citizen",
    max = 0,
    salary = 45,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civilians",

    -- TDMRP Stats
    tdmrp_class = "civilian",
    tdmrp_required_bp = 0,
    tdmrp_hp = 100,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
})

TEAM_FREERUNNER = DarkRP.createJob("Freerunner", {
    color = Color(60, 200, 60, 255),
    model = {"models/player/p2_chell.mdl"},
    description = [[You watched too many parkour videos on YouTube and now you can't stop jumping off buildings. Your mother is very concerned. Your knees are filled with regret. But man, do you look cool doing a wall run past the crossfire.

Stats: Speed Demon
• 100 HP | No Armor | No DT
• +40% Walk Speed | +27% Run Speed
• +38% Jump Power
• You're basically Sonic if Sonic made poor life choices]],
    weapons = {},
    command = "freerunner",
    max = 4,
    salary = 50,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civilians",

    -- TDMRP Stats
    tdmrp_class = "civilian",
    tdmrp_required_bp = 0,
    tdmrp_hp = 100,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
    tdmrp_walk_speed = 420,
    tdmrp_run_speed = 570,
    tdmrp_jump_power = 220,
})

TEAM_GUNDEALER = DarkRP.createJob("Gun Dealer", {
    color = Color(60, 200, 60, 255),
    model = {"models/player/monk.mdl"},
    description = [[You've read every gun magazine ever printed and spent your life savings on the ATF's "Do Not Call" list. Your shop motto is "If it shoots, we sell it. If it explodes, we sell it for more." No refunds. Especially not for the grenades.

Stats: Merchant of Death (Lite Edition)
• 100 HP | No Armor | No DT  
• Can spawn weapon shipments
• Licensed arms dealer
• Definitely not affiliated with any crime syndicates (wink)]],
    weapons = {},
    command = "gundealer",
    max = 3,
    salary = 60,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Civilians",

    -- TDMRP Stats
    tdmrp_class = "civilian",
    tdmrp_required_bp = 0,
    tdmrp_hp = 100,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
})

TEAM_CIVMEDIC = DarkRP.createJob("Medic", {
    color = Color(60, 200, 60, 255),
    model = {"models/player/alyx.mdl"},
    description = [[You went to medical school and came out with $400,000 in debt and a drinking problem. Now you patch up criminals and cops alike because "the Hippocratic Oath doesn't specify which side of a gang war you should help." Your mother wanted you to be a lawyer.

Stats: Florence Nightingale on a Budget
• 100 HP | No Armor | No DT
• Can heal other players
• Neutral to all factions
• Your prescription? Stop getting shot.]],
    weapons = {},
    command = "civmedic",
    max = 3,
    salary = 55,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civilians",

    -- TDMRP Stats
    tdmrp_class = "civilian",
    tdmrp_required_bp = 0,
    tdmrp_hp = 100,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
})

TEAM_HOBO = DarkRP.createJob("Hobo", {
    color = Color(60, 200, 60, 255),
    model = {"models/player/corpse1.mdl"},
    description = [[You used to have a house. You used to have a job. You used to have pants that fit. Now you have a shopping cart full of mysterious items and an encyclopedic knowledge of which dumpsters have the best food on Wednesdays. Your cardboard box has better insulation than most apartments.

Stats: Professional Survivor
• 100 HP | No Armor | No DT
• Can build improvised shelters
• Immune to dignity damage
• Your smell provides 15% concealment bonus]],
    weapons = {},
    command = "hobo",
    max = 4,
    salary = 10,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civilians",

    -- TDMRP Stats
    tdmrp_class = "civilian",
    tdmrp_required_bp = 0,
    tdmrp_hp = 100,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
})

TEAM_ANTIQUARIAN = DarkRP.createJob("Antiquarian", {
    color = Color(60, 200, 60, 255),
    model = {"models/player/hostage/hostage_03.mdl"},
    description = [[You collect weird artifacts and somehow nobody asks where you get them from. Your shop is filled with "ancient relics" that definitely aren't just spray-painted Walmart products. The Ruby Vat you sell? It's just a slow cooker with LED lights. Shh, don't tell anyone.

Stats: Collector of Curiosities (Requires 50 BP)
• 100 HP | No Armor | No DT
• Can purchase guncrafting entities
• Access to Ruby Vat and crafting supplies
• Your appraisal skill is "trust me bro"]],
    weapons = {},
    command = "antiquarian",
    max = 2,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civilians",

    -- TDMRP Stats
    tdmrp_class = "civilian",
    tdmrp_required_bp = 50,
    tdmrp_hp = 100,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
})

----------------------------------------------------
-- POLICE / COP CLASS
----------------------------------------------------

-- STARTER JOB (Locked after 60 BP)
TEAM_POLICERECRUIT = DarkRP.createJob("Police Recruit", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/police.mdl"},
    description = [[Fresh out of the academy and already questioning your career choices. Your training consisted of a 30-minute PowerPoint and a firm handshake. The chief assigned you to "The Zone" as a "character-building exercise." You're pretty sure that's just code for "we expect you to die."

Stats: Fresh Meat (Locked after 60 BP)
• 150 HP | No Armor | 10 DT (Rookie Kevlar)
• +25% Gem Drop Rate (Starter Bonus!)
• USP + MP5 Loadout
• Your kevlar says "TRAINEE" in bright orange letters]],
    weapons = {},
    command = "policerecruit",
    max = 6,
    salary = 70,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 0,
    tdmrp_max_bp = 60,
    tdmrp_starter_job = true,
    tdmrp_hp = 150,
    tdmrp_ap = 0,
    tdmrp_dt = 10,
    tdmrp_dt_name = "Rookie Kevlar",
})

-- TIER 2 JOBS (60 BP)
TEAM_SWAT = DarkRP.createJob("SWAT", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/riot.mdl"},
    description = [[You've kicked down so many doors that your leg has its own insurance policy. Your callsign is "Doorbuster" and your therapist says your "breach first, ask questions never" approach is "concerning." You respond by breaching into their office.

Stats: Door-Kicking Enthusiast (Requires 60 BP)
• 150 HP | 30 AP | 3 DT (Lightweight Kevlar)
• ACTIVE: Regeneration - +5 HP/s for 20 seconds
• HK45 + M4A1 Loadout
• 60s skill cooldown]],
    weapons = {},
    command = "swat",
    max = 4,
    salary = 80,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 60,
    tdmrp_hp = 150,
    tdmrp_ap = 30,
    tdmrp_dt = 3,
    tdmrp_dt_name = "Lightweight Kevlar",
    tdmrp_active_skill = "regeneration",
    tdmrp_active_desc = "+5 HP/s for 20 seconds. 60s cooldown.",
})

TEAM_FIELDSURGEON = DarkRP.createJob("Field Surgeon", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/barney.mdl"},
    description = [[You graduated medical school with honors, then immediately forgot everything when bullets started flying. Now your medical advice is "apply pressure and pray" and your bedside manner is "stop crying, I've seen worse." (You haven't. This is the worst.)

Stats: Combat Medic (Requires 60 BP)
• 125 HP | 50 AP | 3 DT (Lightweight Kevlar)
• ACTIVE: Healing Aura - Rapidly heal nearby allies
• P228 + FAMAS Loadout
• Equipped with Medic Gun]],
    weapons = {},
    command = "fieldsurgeon",
    max = 3,
    salary = 90,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 60,
    tdmrp_hp = 125,
    tdmrp_ap = 50,
    tdmrp_dt = 3,
    tdmrp_dt_name = "Lightweight Kevlar",
    tdmrp_active_skill = "healingaura",
    tdmrp_active_desc = "Rapidly regenerates nearby allies.",
    tdmrp_has_healgun = true,
})

TEAM_ARMSMASTER = DarkRP.createJob("Armsmaster", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/combine_soldier_prisonguard.mdl"},
    description = [[You're the guy who repairs everyone's guns while mumbling about "proper maintenance schedules." Your turret deployments are legendary, mostly because they've killed more teammates than enemies. Everyone's afraid to tell you because you control the ammo supply.

Stats: Combat Engineer (Requires 60 BP)
• 150 HP | 50 AP | 4 DT (Surplus Kevlar)
• ACTIVE: Overcharge - Full HP/AP + Enemy fire rate -80% for 4s
• SIG P229R + M416 Loadout
• Can deploy sentry turrets]],
    weapons = {},
    command = "armsmaster",
    max = 2,
    salary = 85,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 60,
    tdmrp_hp = 150,
    tdmrp_ap = 50,
    tdmrp_dt = 4,
    tdmrp_dt_name = "Surplus Kevlar",
    tdmrp_active_skill = "overcharge",
    tdmrp_active_desc = "Full HP/AP for self and allies. -80% enemy fire rate for 4s.",
    tdmrp_can_deploy_sentry = true,
})

-- TIER 3 JOBS (100 BP)
TEAM_MARINE = DarkRP.createJob("Marine", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/urban.mdl"},
    description = [[You eat crayons for breakfast. Not because you have to, but because the red ones taste like victory. Your battle cry is "OORAH" and you've been banned from three different mess halls for "aggressive chewing." The criminals fear you. Your dentist fears you more.

Stats: Frontline Assault (Requires 100 BP)
• 150 HP | 50 AP | 5 DT (Heavy Duty Kevlar)
• ACTIVE: Quad Damage - 4x damage for 3 seconds
• Desert Eagle + SCAR Loadout
• Crayon consumption: Classified]],
    weapons = {},
    command = "marine",
    max = 3,
    salary = 95,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 100,
    tdmrp_hp = 150,
    tdmrp_ap = 50,
    tdmrp_dt = 5,
    tdmrp_dt_name = "Heavy Duty Kevlar",
    tdmrp_active_skill = "quaddamage",
    tdmrp_active_desc = "Quadruple damage for 3 seconds.",
})

TEAM_SPECIALFORCES = DarkRP.createJob("Special Forces", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/gasmask.mdl"},
    description = [[Your file is 90% redacted and the other 10% just says "DO NOT ENGAGE." You've been to places that don't exist and done things that never happened. Your therapist has a therapist because of you. When asked about your hobbies, you stare into the distance for 30 minutes.

Stats: Precision Eliminator (Requires 100 BP)
• 125 HP | 30 AP | 3 DT (Lightweight Kevlar)
• ACTIVE: Accuracy - +100% accuracy for 5 seconds
• Colt 1911 + Scout Sniper Loadout
• Kill count: CLASSIFIED]],
    weapons = {},
    command = "specialforces",
    max = 3,
    salary = 90,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 100,
    tdmrp_hp = 125,
    tdmrp_ap = 30,
    tdmrp_dt = 3,
    tdmrp_dt_name = "Lightweight Kevlar",
    tdmrp_active_skill = "accuracy",
    tdmrp_active_desc = "100% increased accuracy for 5 seconds.",
})

-- TIER 4 JOBS (120 BP)
TEAM_RECON = DarkRP.createJob("Recon", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/swat.mdl"},
    description = [[You're basically a ghost with a gun. Your stealth suit makes you 50% invisible, which sounds cool until you realize criminals keep bumping into you in hallways. You've mastered the art of "tactical lurking" and your blink ability lets you teleport away from awkward conversations.

Stats: Shadow Operative (Requires 120 BP)
• 125 HP | No Armor | No DT
• +50% Movement Speed | 50% Transparency
• ACTIVE: Blink - Teleport forward (3 charges)
• Five-Seven + Honey Badger PDW Loadout]],
    weapons = {},
    command = "recon",
    max = 2,
    salary = 100,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 120,
    tdmrp_hp = 125,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
    tdmrp_walk_speed = 450,
    tdmrp_run_speed = 675,
    tdmrp_jump_power = 160,
    tdmrp_transparency = 127,
    tdmrp_active_skill = "blink",
    tdmrp_active_desc = "Teleport in facing direction. 3 charges, 1s between uses.",
})

----------------------------------------------------
-- BP LOSS ZONE (Cop)
----------------------------------------------------

TEAM_VANGUARD = DarkRP.createJob("Vanguard", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/fear2/atc_heavy.mdl"},
    description = [[You're the guy who charges in first and asks questions never. Your combat philosophy is "overwhelming firepower solves most problems" and your therapist says you have "an unhealthy relationship with explosions." You wear more armor than a medieval knight and run faster than should be physically possible.

Stats: Berserker Assault (Requires 100 BP | ⚠️ -1 BP on Death)
• 125 HP | 100 AP | 7 DT (Advanced Kevlar)
• ACTIVE: Berserk - Triple fire rate for 8 seconds
• Glock + AK-47 Loadout
• Warning: Death penalizes 1 BP]],
    weapons = {},
    command = "vanguard",
    max = 2,
    salary = 100,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 100,
    tdmrp_bp_on_death = 1,
    tdmrp_hp = 125,
    tdmrp_ap = 100,
    tdmrp_dt = 7,
    tdmrp_dt_name = "Advanced Kevlar",
    tdmrp_active_skill = "berserk",
    tdmrp_active_desc = "Triple fire rate for 8 seconds.",
})

TEAM_ARMOREDUNIT = DarkRP.createJob("Armored Unit", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/combine_super_soldier.mdl"},
    description = [[You are THE tank. The walking fortress. The man who makes enemy bullets file complaints. Your suit was designed by scientists who asked "what if we made a person into a refrigerator?" You move like a glacier and hit like a planet. Criminals see you and immediately start searching for a new career.

Stats: Unstoppable Juggernaut (Requires 150 BP | ⚠️ -2 BP on Death)
• 250 HP | 80 AP | 12 DT (Prototype Bulletshield)
• -30% Movement Speed | -50% Jump Height
• ACTIVE: Invincibility - 10 seconds of being literally unkillable
• Desert Eagle + M249 SAW Loadout]],
    weapons = {},
    command = "armoredunit",
    max = 2,
    salary = 110,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 150,
    tdmrp_bp_on_death = 2,
    tdmrp_hp = 250,
    tdmrp_ap = 80,
    tdmrp_dt = 12,
    tdmrp_dt_name = "Prototype Bulletshield",
    tdmrp_walk_speed = 210,
    tdmrp_run_speed = 270,
    tdmrp_jump_power = 100,
    tdmrp_active_skill = "invincibility",
    tdmrp_active_desc = "Become invulnerable for 10 seconds.",
})

TEAM_MAYOR = DarkRP.createJob("Mayor", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/breen.mdl"},
    description = [[You got this job through a combination of charisma, bribery, and a surprisingly good lasagna at the campaign dinner. Now you buff your allies with motivational speeches that definitely aren't just screaming "GO! SHOOT THINGS!" Your Rally ability is legendary. Your approval ratings are not.

Stats: Inspiring Commander (Requires 200 BP | ⚠️ -5 BP on Death)
• 150 HP | 100 AP | 5 DT (Heavy Duty Kevlar)
• PASSIVE: Buff Aura - Nearby allies get stat boosts
• PASSIVE: Ammo Regen - Nearby allies regenerate ammo
• ACTIVE: Rally - +30% MS, 2x cap speed, +100 AP for allies
• Requires 5+ players online to become Mayor]],
    weapons = {},
    command = "mayor",
    max = 1,
    salary = 120,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Police",
    customCheck = function(ply) return #player.GetAll() >= 5 end,
    CustomCheckFailMsg = "At least 5 players must be online to become Mayor.",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 200,
    tdmrp_bp_on_death = 5,
    tdmrp_hp = 150,
    tdmrp_ap = 100,
    tdmrp_dt = 5,
    tdmrp_dt_name = "Heavy Duty Kevlar",
    tdmrp_has_buff_aura = true,
    tdmrp_ammo_regen_aura = true,
    tdmrp_active_skill = "rally",
    tdmrp_active_desc = "+30% MS for 8s, 2x capture speed, +100 AP for 10s.",
})

-- ELITE JOB (1000 BP)
TEAM_MASTERCHIEF = DarkRP.createJob("Master Chief", {
    color = Color(80, 150, 255, 255),
    model = {"models/Halo4/Spartans/masterchief_player.mdl"},
    description = [[You've been awake for 500 years and you're STILL not used to the armor chafing. Humanity's greatest super-soldier, now working for whatever city this is because "galactic threats were too easy." Your plasma rifle sounds like the future and your footsteps echo with the weight of a thousand dead aliens.

Stats: SPARTAN-117 (Requires 1000 BP | ⚠️ -10 BP on Death)
• 200 HP | 150 AP | 8 DT (Mjolnir Armor)
• +20% Movement Speed | +50% Jump Height
• ACTIVE: Plasma Rifle - Energy weapon burst attack
• M6D Magnum + MA5B Assault Rifle Loadout
• "I need a weapon."]],
    weapons = {},
    command = "masterchief",
    max = 1,
    salary = 150,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Police",

    -- TDMRP Stats
    tdmrp_class = "cop",
    tdmrp_required_bp = 1000,
    tdmrp_bp_on_death = 10,
    tdmrp_hp = 200,
    tdmrp_ap = 150,
    tdmrp_dt = 15,
    tdmrp_dt_name = "Mark VI Mjolnir",
    tdmrp_walk_speed = 360,         -- 120% of 300
    tdmrp_run_speed = 540,          -- 120% of 450
    tdmrp_jump_power = 240,         -- 1.5x of 160
    tdmrp_active_skill = "plasmarifle",
    tdmrp_active_desc = "Deploy devastating Plasma Rifle.",
    tdmrp_voice_lines = true,
})

----------------------------------------------------
-- CRIMINAL CLASS
----------------------------------------------------

-- STARTER JOB (Locked after 60 BP)
TEAM_GANGSTERINITIATE = DarkRP.createJob("Gangster Initiate", {
    color = Color(255, 150, 40, 255),
    model = {
        "models/player/Group03/male_02.mdl",
        "models/player/Group03/male_03.mdl",
        "models/player/Group03/Male_04.mdl",
        "models/player/Group03/male_08.mdl",
    },
    description = [[You just got jumped into the gang and your "initiation" involved stealing a car that turned out to be an undercover cop. Now you owe favors to people whose names you can't pronounce. But hey, at least you get a cool title and access to the criminal underworld's worst parking spots.

Stats: Fresh Blood (Locked after 60 BP)
• 150 HP | No Armor | 10 DT (Rookie Kevlar)
• +25% Gem Drop Rate (Starter Bonus!)
• Glock + MAC-11 Loadout
• Your gang nickname is probably something embarrassing]],
    weapons = {},
    command = "gangsterinitiate",
    max = 6,
    salary = 60,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 0,
    tdmrp_max_bp = 60,
    tdmrp_starter_job = true,
    tdmrp_hp = 150,
    tdmrp_ap = 0,
    tdmrp_dt = 10,
    tdmrp_dt_name = "Rookie Kevlar",
})

-- TIER 2 JOBS (60 BP)
TEAM_THIEF = DarkRP.createJob("Thief", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/arctic.mdl"},
    description = [[You've stolen so many things that your hands automatically pickpocket people when you shake them. Your apartment is furnished entirely with "borrowed" goods and your lawyer is on speed dial. The cops hate you. Your landlord hates you more (the rent was also stolen).

Stats: Sticky Fingers (Requires 60 BP)
• 150 HP | 30 AP | 3 DT (Lightweight Kevlar)
• ACTIVE: Regeneration - +5 HP/s for 20 seconds
• P228 + MP5 Loadout
• 60s skill cooldown]],
    weapons = {},
    command = "thief",
    max = 4,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 60,
    tdmrp_hp = 150,
    tdmrp_ap = 30,
    tdmrp_dt = 3,
    tdmrp_dt_name = "Lightweight Kevlar",
    tdmrp_active_skill = "regeneration",
    tdmrp_active_desc = "+5 HP/s for 20 seconds. 60s cooldown.",
})

TEAM_DREVIL = DarkRP.createJob("Dr. Evil", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/lordvipes/rerc_vector/vector_cvp.mdl"},
    description = [[You lost your medical license for "creative interpretations of the Hippocratic Oath." Now you patch up criminals while monologuing about your plans for world domination. Your demand for "ONE MILLION DOLLARS" was laughed at, so you settled for healing bad guys for cash.

Stats: Unlicensed Physician (Requires 60 BP)
• 125 HP | 50 AP | 3 DT (Lightweight Kevlar)
• ACTIVE: Healing Aura - Rapidly heal nearby allies
• USP + FAMAS Loadout
• Equipped with Medic Gun
• Your pinky was surgically attached to your face]],
    weapons = {},
    command = "drevil",
    max = 3,
    salary = 90,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 60,
    tdmrp_hp = 125,
    tdmrp_ap = 50,
    tdmrp_dt = 3,
    tdmrp_dt_name = "Lightweight Kevlar",
    tdmrp_active_skill = "healingaura",
    tdmrp_active_desc = "Rapidly regenerates nearby allies.",
    tdmrp_has_healgun = true,
})

TEAM_MERCHANTOFDEATH = DarkRP.createJob("Merchant of Death", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/guerilla.mdl"},
    description = [[You sell weapons to anyone with cash and a pulse. Morality is just a checkbox you uncheck at the door. Your warehouse is an armory, your clients are war criminals, and your Yelp reviews are surprisingly positive. The drone strike button was a Black Friday impulse buy.

Stats: Arms Dealer (Requires 60 BP)
• 150 HP | 50 AP | 4 DT (Custom Kevlar)
• ACTIVE: Drone Strike - Call down explosive payload at cursor
• SIG P229R + AK-47 Loadout
• 60s skill cooldown
• Return policy: All sales final (especially the lethal ones)]],
    weapons = {},
    command = "merchantofdeath",
    max = 2,
    salary = 85,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 60,
    tdmrp_hp = 150,
    tdmrp_ap = 50,
    tdmrp_dt = 4,
    tdmrp_dt_name = "Custom Kevlar",
    tdmrp_active_skill = "dronestrike",
    tdmrp_active_desc = "Call down drone strike at cursor. 60s cooldown.",
})

-- TIER 3 JOBS (100 BP)
TEAM_MERCENARY = DarkRP.createJob("Mercenary", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/phoenix.mdl"},
    description = [[Money talks and you listen VERY carefully. You've fought for 47 different countries, 3 corporations, and one guy who just really hated his neighbor. Your moral compass spins like a roulette wheel and lands on "highest bidder." Quad Damage turns you into a walking war crime.

Stats: Professional Killer (Requires 100 BP)
• 150 HP | 50 AP | 5 DT (Heavy Duty Kevlar)
• ACTIVE: Quad Damage - 4x damage for 3 seconds
• Desert Eagle + SCAR Loadout
• "Nothing personal, kid."]],
    weapons = {},
    command = "mercenary",
    max = 3,
    salary = 80,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 100,
    tdmrp_hp = 150,
    tdmrp_ap = 50,
    tdmrp_dt = 5,
    tdmrp_dt_name = "Heavy Duty Kevlar",
    tdmrp_active_skill = "quaddamage",
    tdmrp_active_desc = "Quadruple damage for 3 seconds.",
})

TEAM_DEADEYE = DarkRP.createJob("Deadeye", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/leet.mdl"},
    description = [[You can shoot a fly off a cop's hat from 500 meters. Your sniper rifle has more scratches than a DJ's turntable, each one representing a "successful contract." You spend your free time calculating bullet drop for fun and your optometrist says your eyesight is "terrifying."

Stats: Precision Assassin (Requires 100 BP)
• 125 HP | 30 AP | 3 DT (Lightweight Kevlar)
• ACTIVE: Accuracy - +100% accuracy for 5 seconds
• Colt 1911 + AWP Loadout
• Confirmed kills: You stopped counting]],
    weapons = {},
    command = "deadeye",
    max = 3,
    salary = 85,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 100,
    tdmrp_hp = 125,
    tdmrp_ap = 30,
    tdmrp_dt = 3,
    tdmrp_dt_name = "Lightweight Kevlar",
    tdmrp_active_skill = "accuracy",
    tdmrp_active_desc = "100% increased accuracy for 5 seconds.",
})

-- TIER 4 JOBS (120 BP)
TEAM_YAMAKAZI = DarkRP.createJob("Yamakazi", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/charple.mdl"},
    description = [[You're what happens when parkour meets psychopathy. Running on rooftops, throwing knives at cops, living your best anime villain life. Your health is a joke but you move so fast they can't hit you anyway. The Knife Storm ability is legally classified as "showing off."

Stats: Blade Dancer (Requires 120 BP)
• 80 HP | No Armor | No DT (Glass Cannon!)
• +60% Movement Speed | +25% Jump Height
• ACTIVE: Knife Storm - Knives in all directions
• Desert Eagle + Throwing Knife Loadout
• You've definitely naruto-run in public]],
    weapons = {},
    command = "yamakazi",
    max = 3,
    salary = 75,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 120,
    tdmrp_hp = 80,
    tdmrp_ap = 0,
    tdmrp_dt = 0,
    tdmrp_dt_name = "None",
    tdmrp_walk_speed = 480,
    tdmrp_run_speed = 720,
    tdmrp_jump_power = 200,
    tdmrp_active_skill = "knifestorm",
    tdmrp_active_desc = "Shoot knives in all directions. 30s cooldown.",
})

----------------------------------------------------
-- BP LOSS ZONE (Criminal)
----------------------------------------------------

TEAM_RAIDER = DarkRP.createJob("Raider", {
    color = Color(255, 150, 40, 255),
    model = {"models/characters/nanosuit2/nanosuit_player.mdl"},
    description = [[You found a nanosuit in a dumpster and now you're unstoppable. Or maybe the suit found YOU. Either way, you've got cutting-edge military tech and zero training manual. The Berserk mode makes you fire faster than your brain can process, which is honestly not that different from normal.

Stats: Nanotech Berserker (Requires 100 BP | ⚠️ -1 BP on Death)
• 125 HP | 100 AP | 7 DT (Advanced Kevlar)
• ACTIVE: Berserk - Triple fire rate for 8 seconds
• Glock + SPAS-12 Loadout
• Warning: Death penalizes 1 BP
• Suit malfunction count: 47]],
    weapons = {},
    command = "raider",
    max = 2,
    salary = 100,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 100,
    tdmrp_bp_on_death = 1,
    tdmrp_hp = 125,
    tdmrp_ap = 100,
    tdmrp_dt = 7,
    tdmrp_dt_name = "Advanced Kevlar",
    tdmrp_active_skill = "berserk",
    tdmrp_active_desc = "Triple fire rate for 8 seconds.",
})

TEAM_TANK = DarkRP.createJob("T.A.N.K.", {
    color = Color(255, 150, 40, 255),
    model = {"models/gacommissions/mw19/player/juggernaut_cmb_elite.mdl"},
    description = [[Tactical Armored Neutralization Kombatant. The acronym was clearly made up first. You're a walking apocalypse in a suit that probably violates several international arms treaties. Invincibility makes you literally unkillable, which you've tested by walking through minefields "for fun."

Stats: Walking Fortress (Requires 150 BP | ⚠️ -2 BP on Death)
• 250 HP | 100 AP | 12 DT (Counterfeit SuperKevlar)
• -30% Movement Speed | -50% Jump Height
• ACTIVE: Invincibility - 10 seconds of pure immunity
• Desert Eagle + M249 SAW Loadout
• "I am the tank. The tank is me."]],
    weapons = {},
    command = "tank",
    max = 2,
    salary = 115,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 150,
    tdmrp_bp_on_death = 2,
    tdmrp_hp = 250,
    tdmrp_ap = 100,
    tdmrp_dt = 12,
    tdmrp_dt_name = "Counterfeit SuperKevlar",
    tdmrp_walk_speed = 210,
    tdmrp_run_speed = 270,
    tdmrp_jump_power = 100,
    tdmrp_active_skill = "invincibility",
    tdmrp_active_desc = "Become invulnerable for 10 seconds.",
})

TEAM_MOBBOSS = DarkRP.createJob("Mob Boss", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/gman_high.mdl"},
    description = [[You run this city's crime like a Fortune 500 company, complete with performance reviews and hostile takeovers (literal ones). Your suit costs more than most cars and your briefcase contains either important documents or a Tommy gun. Probably both. The Rally ability inspires your goons through the power of "or else."

Stats: Kingpin (Requires 200 BP | ⚠️ -10 BP on Death)
• 150 HP | 100 AP | 5 DT (Heavy Duty Kevlar)
• PASSIVE: Buff Aura - Nearby allies get stat boosts
• PASSIVE: Ammo Regen - Nearby allies regenerate ammo
• ACTIVE: Rally - +30% MS, 2x cap speed, +100 AP for allies
• Requires 5+ players online to become Mob Boss]],
    weapons = {},
    command = "mobboss",
    max = 1,
    salary = 120,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",
    customCheck = function(ply) return #player.GetAll() >= 5 end,
    CustomCheckFailMsg = "At least 5 players must be online to become Mob Boss.",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 200,
    tdmrp_bp_on_death = 10,
    tdmrp_hp = 150,
    tdmrp_ap = 100,
    tdmrp_dt = 5,
    tdmrp_dt_name = "Heavy Duty Kevlar",
    tdmrp_has_buff_aura = true,
    tdmrp_ammo_regen_aura = true,
    tdmrp_active_skill = "rally",
    tdmrp_active_desc = "+30% MS for 8s, 2x capture speed, +100 AP for 10s.",
})

-- ELITE JOB (1000 BP)
TEAM_DUKENUKEM = DarkRP.createJob("Duke Nukem", {
    color = Color(255, 150, 40, 255),
    model = {"models/JesseV92/player/misc/dukenukem.mdl"},
    description = [[Hail to the King, baby! You've been kicking ass and chewing bubblegum since before most of these criminals were born. And you're ALL out of gum. Your muscles have muscles, your one-liners are legendary, and your passive regeneration means you're basically immortal. Time to kick alien ass... wait, wrong game. Time to kick COP ass!

Stats: The King (Requires 1000 BP | ⚠️ -10 BP on Death)
• 350 HP | No Armor | 10 DT (Sheer Badassery)
• +10% Movement Speed | +12% Jump Height
• PASSIVE: Regenerates +10 HP/s after 5s out of combat
• ACTIVE: Duke's Special (TBD - Something awesome)
• Loadout: Whatever the hell he wants
• "It's time to kick ass and chew bubblegum..."]],
    weapons = {},
    command = "dukenukem",
    max = 1,
    salary = 150,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Criminals",

    -- TDMRP Stats
    tdmrp_class = "criminal",
    tdmrp_required_bp = 1000,
    tdmrp_bp_on_death = 10,
    tdmrp_hp = 350,
    tdmrp_ap = 0,
    tdmrp_dt = 10,
    tdmrp_dt_name = "Sheer Badassery",
    tdmrp_walk_speed = 330,
    tdmrp_run_speed = 510,
    tdmrp_jump_power = 180,
    tdmrp_passive_regen = 10,
    tdmrp_regen_delay = 5,
    tdmrp_active_skill = "dukenukem_special",
    tdmrp_active_desc = "TBD - Duke's special ability.",
    tdmrp_voice_lines = true,
})

----------------------------------------------------
-- DEFAULT TEAM
----------------------------------------------------

local GM = GM or GAMEMODE
GM.DefaultTeam = TEAM_CITIZEN

print("[TDMRP] jobs.lua loaded with full stat definitions")
