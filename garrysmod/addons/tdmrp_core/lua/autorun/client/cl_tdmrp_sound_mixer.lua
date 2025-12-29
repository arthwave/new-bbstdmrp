----------------------------------------------------
-- TDMRP Weapon Sound Volume Reducer
-- Reduces all weapon sounds by 40% for better hitsound prominence
----------------------------------------------------

if not CLIENT then return end

-- Track weapon sounds and reduce volume
local function IsWeaponSound(soundName)
    if not soundName then return false end
    
    local lower = string.lower(soundName)
    
    -- Check for weapon sound patterns
    return string.find(lower, "weapons/") ~= nil or
           string.find(lower, "physics/metal/") ~= nil or
           string.find(lower, "physics/impact/") ~= nil
end

-- Hook into sound emission on client
hook.Add("EntityEmitSound", "TDMRP_ReduceWeaponVolume", function(data)
    if not data then return end
    
    local soundName = data.SoundName or ""
    
    if IsWeaponSound(soundName) then
        -- Reduce sound level (dB scale)
        data.SoundLevel = (data.SoundLevel or 75) - 10  -- -10 dB roughly = 40% volume reduction
        
        print(string.format("[TDMRP] Reduced: %s (level: %d)", soundName, data.SoundLevel))
    end
end)

print("[TDMRP] Weapon sound volume reducer loaded (-40%)")


