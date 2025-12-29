----------------------------------------------------
-- TDMRP Slug Mode Keybind Handler
-- Detects E+R combination to toggle shotgun modes
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}

----------------------------------------------------
-- Keybind State
----------------------------------------------------

local ePressed = false
local rPressed = false
local lastToggleTime = 0
local TOGGLE_COOLDOWN = 1.0  -- Prevent spam

----------------------------------------------------
-- Network String
----------------------------------------------------

if CLIENT then
    net.Receive("TDMRP_ShotgunModeChanged", function()
        local wep = net.ReadEntity()
        local mode = net.ReadInt(4)
        
        -- Update local HUD immediately
        if IsValid(wep) then
            wep:SetNWInt("TDMRP_ShotgunMode", mode)
        end
    end)
end

----------------------------------------------------
-- Key Detection
----------------------------------------------------

hook.Add("Think", "TDMRP_SlugKeybind", function()
    if not IsValid(LocalPlayer()) then return end
    
    local ply = LocalPlayer()
    local wep = ply:GetActiveWeapon()
    
    -- Only process if holding a slug-enabled shotgun
    local isSlugEnabled = wep.IsSlugEnabled and wep:IsSlugEnabled() or TDMRP_WeaponMixin.IsSlugEnabled(wep)
    if not IsValid(wep) or not isSlugEnabled then return end
    
    -- Check key states
    local eDown = input.IsKeyDown(KEY_E)
    local rDown = input.IsKeyDown(KEY_R)
    
    -- Detect E+R combination (both keys pressed)
    if eDown and rDown then
        -- Check if this is the first frame both are pressed
        if not (ePressed and rPressed) then
            -- Keys just pressed together
            local now = CurTime()
            if now - lastToggleTime > TOGGLE_COOLDOWN then
                net.Start("TDMRP_RequestSlugToggle")
                net.SendToServer()
                lastToggleTime = now
            end
        end
    end
    
    -- Update pressed states
    ePressed = eDown
    rPressed = rDown
end)

print("[TDMRP] cl_tdmrp_slug_keybind.lua loaded - Slug mode keybind initialized")