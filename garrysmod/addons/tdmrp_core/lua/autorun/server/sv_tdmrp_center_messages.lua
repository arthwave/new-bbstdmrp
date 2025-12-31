----------------------------------------------------
-- TDMRP Center Screen Messages (Server-Side)
-- Network strings and helper functions for sending
-- messages to players
----------------------------------------------------

if CLIENT then return end

----------------------------------------------------
-- Network Strings
----------------------------------------------------

util.AddNetworkString("TDMRP_CenterMessage")
util.AddNetworkString("TDMRP_DamageNotification")
util.AddNetworkString("TDMRP_EffectVignette")

----------------------------------------------------
-- Send Center Message to Player
----------------------------------------------------

-- Send a center screen message to a specific player
-- Example: TDMRP.SendCenterMessage(ply, "Blink blocked!", Color(255, 100, 100), 2)
function TDMRP.SendCenterMessage(ply, text, color, duration)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    color = color or Color(255, 255, 255)
    duration = duration or 2.0
    
    net.Start("TDMRP_CenterMessage")
        net.WriteString(text)
        net.WriteUInt(color.r, 8)
        net.WriteUInt(color.g, 8)
        net.WriteUInt(color.b, 8)
        net.WriteFloat(duration)
    net.Send(ply)
end

-- Broadcast center message to all players
function TDMRP.BroadcastCenterMessage(text, color, duration)
    color = color or Color(255, 255, 255)
    duration = duration or 2.0
    
    net.Start("TDMRP_CenterMessage")
        net.WriteString(text)
        net.WriteUInt(color.r, 8)
        net.WriteUInt(color.g, 8)
        net.WriteUInt(color.b, 8)
        net.WriteFloat(duration)
    net.Broadcast()
end

----------------------------------------------------
-- Send Damage Notification to Player
----------------------------------------------------

-- Send damage notification to victim
-- Example: TDMRP.SendDamageNotification(victim, attacker:Nick(), 45.5)
function TDMRP.SendDamageNotification(victim, attackerName, damage)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    
    net.Start("TDMRP_DamageNotification")
        net.WriteString(attackerName or "Unknown")
        net.WriteFloat(damage or 0)
    net.Send(victim)
end

----------------------------------------------------
-- Send Effect Vignette to Player
----------------------------------------------------

-- Show effect vignette on player's screen (e.g., frost slow, burning)
-- Example: TDMRP.SendEffectVignette(ply, Color(100, 150, 255, 80), 4)
function TDMRP.SendEffectVignette(ply, color, duration)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    color = color or Color(255, 255, 255, 100)
    duration = duration or 2.0
    
    net.Start("TDMRP_EffectVignette")
        net.WriteUInt(color.r, 8)
        net.WriteUInt(color.g, 8)
        net.WriteUInt(color.b, 8)
        net.WriteUInt(color.a, 8)
        net.WriteFloat(duration)
    net.Send(ply)
end

-- Clear effect vignette on player's screen
function TDMRP.ClearEffectVignette(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    net.Start("TDMRP_EffectVignette")
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8)
        net.WriteUInt(0, 8)
        net.WriteFloat(0)  -- Duration 0 = clear
    net.Send(ply)
end

----------------------------------------------------
-- Hook: Send damage notifications on player hurt
----------------------------------------------------

hook.Add("PlayerHurt", "TDMRP_DamageNotifications", function(victim, attacker, healthRemaining, damageTaken)
    if not IsValid(victim) or not IsValid(attacker) then return end
    if not attacker:IsPlayer() then return end
    if victim == attacker then return end  -- No self-damage notifications
    
    -- Send damage notification to victim
    TDMRP.SendDamageNotification(victim, attacker:Nick(), damageTaken)
end)

print("[TDMRP] sv_tdmrp_center_messages.lua loaded")
