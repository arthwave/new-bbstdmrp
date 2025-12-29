-- jobs.lua - TDMRP master job list
-- Updated: December 17, 2025
-- Complete overhaul with HP/AP/DT/Movement stats

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
    description = [[Regular civilian. No PvP involvement. Default job.]],
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
    description = [[Parkour-oriented civ job with high speed and jump. No PvP.]],
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
    description = [[Civilian gun dealer. Sells weapons to others. No PvP.]],
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
    description = [[Civilian medic. Focused on healing others. No PvP.]],
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
    description = [[Hobo. Roleplay / flavor civilian. No PvP.]],
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
    description = [[Specialized civ used to purchase entities for advanced guncrafting (Ruby Vat, etc.).]],
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
    description = [[Starter cop job. Increased gem drop rate. Locked after 60 BP.]],
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
    tdmrp_max_bp = 60,              -- Locked after 60 BP
    tdmrp_starter_job = true,       -- Flag for increased gem drops
    tdmrp_hp = 150,
    tdmrp_ap = 0,
    tdmrp_dt = 10,
    tdmrp_dt_name = "Rookie Kevlar",
})

-- TIER 2 JOBS (60 BP)
TEAM_SWAT = DarkRP.createJob("SWAT", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/riot.mdl"},
    description = [[Assault rifle specialist with regeneration ability.]],
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
    description = [[Police medic with healing aura and healing gun.]],
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
    description = [[Combat engineer. Can deploy sentry turrets and use Overcharge ability.]],
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
    description = [[Close-range combat specialist with Quad Damage ability.]],
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
    description = [[Long-range sniper with Accuracy ability.]],
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
    description = [[Stealth unit with 50% transparency, +50% speed, and Blink teleport.]],
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
    tdmrp_walk_speed = 450,         -- +50% of 300
    tdmrp_run_speed = 675,          -- +50% of 450
    tdmrp_jump_power = 160,
    tdmrp_transparency = 127,       -- 50% opacity (255 * 0.5)
    tdmrp_active_skill = "blink",
    tdmrp_active_desc = "Teleport in facing direction. 3 charges, 1s between uses.",
})

----------------------------------------------------
-- BP LOSS ZONE (Cop)
----------------------------------------------------

TEAM_VANGUARD = DarkRP.createJob("Vanguard", {
    color = Color(80, 150, 255, 255),
    model = {"models/player/fear2/atc_heavy.mdl"},
    description = [[Heavy assault with Berserk ability. -1 BP on death.]],
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
    description = [[Heavy tank with Invincibility. Very slow. -2 BP on death.]],
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
    description = [[Strategic leader with Rally aura. Requires 5+ players. -5 BP on death.]],
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
    description = [[Elite Spartan. 120% speed, 1.5x jump, Plasma Rifle active. -10 BP on death.]],
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
    description = [[Starter criminal job. Increased gem drop rate. Locked after 60 BP.]],
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
    tdmrp_max_bp = 60,              -- Locked after 60 BP
    tdmrp_starter_job = true,       -- Flag for increased gem drops
    tdmrp_hp = 150,
    tdmrp_ap = 0,
    tdmrp_dt = 10,
    tdmrp_dt_name = "Rookie Kevlar",
})

-- TIER 2 JOBS (60 BP)
TEAM_THIEF = DarkRP.createJob("Thief", {
    color = Color(255, 150, 40, 255),
    model = {"models/player/arctic.mdl"},
    description = [[Assault rifle specialist with tank-style ability.]],
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
    description = [[Criminal medic with healing aura and healing gun.]],
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
    description = [[Criminal gun dealer with Drone Strike ability.]],
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
    description = [[Close-range combat specialist with Quad Damage ability.]],
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
    description = [[Long-range sniper with Accuracy ability.]],
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
    description = [[Glass cannon. 80 HP, 160% speed, knife + deagle. Knife Storm ability.]],
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
    tdmrp_walk_speed = 480,         -- 160% of 300
    tdmrp_run_speed = 720,          -- 160% of 450
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
    description = [[Auto shotgun specialist with Berserk ability. -1 BP on death.]],
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
    description = [[Heavy tank with Invincibility. Very slow. -2 BP on death.]],
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
    description = [[Strategic leader with Rally aura. Requires 5+ players. -10 BP on death.]],
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
    description = [[Elite badass. 350 HP, +10 HP/s regen after 5s. -10 BP on death.]],
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
    tdmrp_passive_regen = 10,       -- HP/s after 5s no damage
    tdmrp_regen_delay = 5,          -- Seconds before regen kicks in
    tdmrp_active_skill = "dukenukem_special",  -- TBD
    tdmrp_active_desc = "TBD - Duke's special ability.",
    tdmrp_voice_lines = true,
})

----------------------------------------------------
-- DEFAULT TEAM
----------------------------------------------------

local GM = GM or GAMEMODE
GM.DefaultTeam = TEAM_CITIZEN

print("[TDMRP] jobs.lua loaded with full stat definitions")
