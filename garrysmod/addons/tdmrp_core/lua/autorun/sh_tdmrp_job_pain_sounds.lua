----------------------------------------------------
-- TDMRP Job Pain Sounds
-- Contextual pain sounds based on job classification
-- Triggers on significant damage (>10 HP)
----------------------------------------------------

TDMRP.JobPainSounds = TDMRP.JobPainSounds or {}

-- Job → Sound Group Mapping
-- "human" = HL2 human male pain sounds
-- "humanoid" = Combine Metro Cop pain sounds
-- nil = Exempt (silent)
TDMRP.JobPainSounds.JobClassification = {
    -- HUMAN JOBS (Police, Civilian, Mercs, Criminals)
    ["fieldsurgeon"] = "human",
    ["marine"] = "human",
    ["deadeye"] = "human",
    ["gangsterinitiate"] = "human",
    ["mercenary"] = "human",
    ["merchantofdeath"] = "human",
    ["mobboss"] = "human",
    ["thief"] = "human",
    
    -- HUMANOID JOBS (Combine-like models)
    ["policerecruit"] = "humanoid",
    ["armoredunit"] = "humanoid",
    ["armsmaster"] = "humanoid",
    ["recon"] = "humanoid",
    ["specialforces"] = "humanoid",
    ["vanguard"] = "humanoid",
    ["drevil"] = "humanoid",
    ["raider"] = "humanoid",
    ["tank"] = "humanoid",
    ["yamakazi"] = "humanoid",
    
    -- EXEMPT (Custom sounds provided later)
    ["masterchief"] = nil,
    ["dukenukem"] = nil,
}

-- Human Pain Sounds (HL2 male groans - pure pain, no dialogue)
TDMRP.JobPainSounds.HumanSounds = {
    "vo/npc/barney/ba_pain01.wav",
    "vo/npc/barney/ba_pain02.wav",
    "vo/npc/male01/pain02.wav",
    "vo/npc/male01/pain07.wav",
}

-- Humanoid Pain Sounds (Combine Metro Cop)
TDMRP.JobPainSounds.HumanoidSounds = {
    "npc/metropolice/pain1.wav",
    "npc/metropolice/pain2.wav",
    "npc/metropolice/pain3.wav",
    "npc/metropolice/pain4.wav",
}

-- Pain Sound Configuration
TDMRP.JobPainSounds.Config = {
    MinDamage = 1,               -- Only play sound on >1 damage
    Debounce = 0.4,              -- Seconds between pain sounds per player
    Volume = 75,                 -- Volume level (0-100)
    PitchMin = 80,               -- Minimum pitch (%)
    PitchMax = 120,              -- Maximum pitch (%)
}

-- Debounce tracking (per-player)
if SERVER then
    TDMRP.JobPainSounds.LastPainTime = {}
end

print("[TDMRP] Job pain sounds system loaded")
