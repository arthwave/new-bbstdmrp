----------------------------------------------------
-- TDMRP: RPM Overrides for M9K Weapons
-- Nerfs high-RPM weapons to prevent particle emitter overflow
-- and leave headroom for berserk/fire rate buffs
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}
TDMRP.RPMOverrides = {
    -- Extreme nerf
    ["tdmrp_m9k_minigun"] = 600,         -- Was 3500
    
    -- Very high RPM nerfs
    ["tdmrp_m9k_vector"] = 850,          -- Was 1000
    
    -- High RPM nerfs (950 -> 800)
    ["tdmrp_m9k_famas"] = 800,           -- Was 950
    ["tdmrp_m9k_mp7"] = 800,             -- Was 950
    
    -- High RPM nerfs (900 -> 850)
    ["tdmrp_m9k_fg42"] = 850,            -- Was 900
    ["tdmrp_m9k_smgp90"] = 850,          -- Was 900 (P90)
    ["tdmrp_m9k_mp9"] = 850,             -- Was 900
    ["tdmrp_m9k_vikhr"] = 850,           -- Was 900
    ["tdmrp_m9k_val"] = 850,             -- Was 900
    ["tdmrp_m9k_tar21"] = 850,           -- Was 900
    
    -- Moderate nerf
    ["tdmrp_m9k_tec9"] = 800,            -- Was 825
    ["tdmrp_m9k_glock"] = 800,           -- Nerf for balance
}

-- Apply RPM override when weapon is created
hook.Add("OnEntityCreated", "TDMRP_RPMOverrides", function(ent)
    if not IsValid(ent) or not ent:IsWeapon() then return end
    
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        
        local class = ent:GetClass()
        local overrideRPM = TDMRP.RPMOverrides[class]
        
        if overrideRPM and ent.Primary then
            ent.Primary.RPM = overrideRPM
            ent.Primary.Delay = 60 / overrideRPM
            
            if SERVER then
                print(string.format("[TDMRP] Applied RPM override to %s: %d RPM", class, overrideRPM))
            end
        end
    end)
end)

print("[TDMRP] RPM overrides loaded")
