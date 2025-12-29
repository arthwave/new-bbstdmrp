-- sv_tdmrp_loadouts.lua
-- Ensure default job weapons are TDMRP instances (Common tier)

if not SERVER then return end

TDMRP = TDMRP or {}

local IGNORE_CLASSES = {
    weapon_physgun = true,
    gmod_tool      = true,
    gmod_camera    = true,
    keys           = true,
    pocket         = true,
    weapon_keypadchecker = true,
    arrest_stick = true,
    unarrest_stick = true,
    door_ram = true
}

hook.Add("PlayerLoadout", "TDMRP_AssignDefaultWeaponInstances", function(ply)
    -- Skip civilians - they should keep default DarkRP weapons
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    if job and job.tdmrp_class == "civilian" then
        print(string.format("[TDMRP Loadouts] Skipping weapon instance conversion for civilian: %s", ply:Nick()))
        return
    end
    
    -- run a tick later so DarkRP has finished giving weapons
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        if not TDMRP.NewWeaponInstance or not TDMRP.ApplyInstanceToSWEP then return end

        local tierCommon = TDMRP.TIER_COMMON or 1
        local weaponCount = 0

        for _, wep in ipairs(ply:GetWeapons()) do
            if not IsValid(wep) then continue end

            local class = wep:GetClass()

            -- Skip non-combat junk
            if IGNORE_CLASSES[class] then continue end

            -- Already has an instance? Don't double-assign
            if wep.TDMRP_InstanceID then continue end

            print(string.format("[TDMRP Loadouts] Converting weapon to instance: %s (player: %s)", class, ply:Nick()))
            weaponCount = weaponCount + 1

            -- Ensure base stats are cached
            if TDMRP.EnsureBaseStats then
                TDMRP.EnsureBaseStats(class)
            end

            -- Make a Common instance
            local inst = TDMRP.NewWeaponInstance(class, tierCommon)
            if inst then
                if TDMRP.RecalculateInstanceStats then
                    TDMRP.RecalculateInstanceStats(inst)
                end
                TDMRP.ApplyInstanceToSWEP(wep, inst)
                wep.TDMRP_InstanceID = inst.id
            end
        end
        
        if weaponCount > 0 then
            print(string.format("[TDMRP Loadouts] Converted %d weapons for %s", weaponCount, ply:Nick()))
        end
    end)
end)
