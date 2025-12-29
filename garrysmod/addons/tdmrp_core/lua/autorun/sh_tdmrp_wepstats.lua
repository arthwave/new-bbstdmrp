-- sh_tdmrp_wepstats.lua
TDMRP = TDMRP or {}

function TDMRP.GetWeaponDisplayName(wep)
    if not IsValid(wep) then return "" end

    local custom = wep:GetNWString("TDMRP_CustomName", "")
    if custom ~= "" then return custom end

    return wep:GetPrintName() or wep:GetClass()
end
