----------------------------------------------------
-- TDMRP Weapon Binding System (Blood Amethyst)
-- Server-side binding logic, persistence, death protection
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.Binding = TDMRP.Binding or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    BIND_TIME_PER_AMETHYST = 20 * 60,  -- 20 minutes in seconds
    MAX_BIND_TIME = 59 * 60 + 59,       -- 59:59 max (3599 seconds)
    RESPAWN_PENALTY = 30,               -- 30 seconds deducted on respawn
    SAVE_FILE = "tdmrp/bound_weapons.json",
    TICK_INTERVAL = 1,                  -- Update bind timers every 1 second
}

----------------------------------------------------
-- Network Strings (registered in sv_tdmrp_gemcraft.lua for load order)
-- TDMRP_ApplyAmethyst, TDMRP_BindUpdate, TDMRP_BindExpired
----------------------------------------------------

----------------------------------------------------
-- In-Memory Cache
-- Structure: PlayerCache[SteamID64] = { [weaponInstanceID] = { ... } }
----------------------------------------------------

local PlayerBoundWeapons = {}  -- Active bindings for online players
local DisconnectCache = {}     -- Cached weapons for disconnected players

----------------------------------------------------
-- Persistence: Load/Save to file
----------------------------------------------------

local function EnsureDataFolder()
    if not file.IsDir("tdmrp", "DATA") then
        file.CreateDir("tdmrp")
    end
end

local function LoadDisconnectCache()
    EnsureDataFolder()
    
    if file.Exists(CONFIG.SAVE_FILE, "DATA") then
        local json = file.Read(CONFIG.SAVE_FILE, "DATA")
        if json then
            local data = util.JSONToTable(json)
            if data then
                DisconnectCache = data
                print("[TDMRP Binding] Loaded " .. table.Count(DisconnectCache) .. " player disconnect caches")
                return
            end
        end
    end
    
    DisconnectCache = {}
    print("[TDMRP Binding] No disconnect cache found, starting fresh")
end

local function SaveDisconnectCache()
    EnsureDataFolder()
    
    local json = util.TableToJSON(DisconnectCache, true)
    if json then
        file.Write(CONFIG.SAVE_FILE, json)
    end
end

-- Load on server start
LoadDisconnectCache()

----------------------------------------------------
-- Helper: Get remaining bind time for a weapon
----------------------------------------------------

function TDMRP.Binding.GetRemainingTime(wep)
    if not IsValid(wep) then return 0 end
    
    local expireTime = wep:GetNWFloat("TDMRP_BindExpire", 0)
    if expireTime <= 0 then return 0 end
    
    local remaining = expireTime - CurTime()
    return math.max(0, remaining)
end

----------------------------------------------------
-- Helper: Check if weapon is currently bound
----------------------------------------------------

function TDMRP.Binding.IsBound(wep)
    return TDMRP.Binding.GetRemainingTime(wep) > 0
end

----------------------------------------------------
-- Helper: Add bind time to weapon
----------------------------------------------------

function TDMRP.Binding.AddBindTime(wep, seconds)
    if not IsValid(wep) then return false end
    
    local currentRemaining = TDMRP.Binding.GetRemainingTime(wep)
    local newTotal = currentRemaining + seconds
    
    -- Cap at max
    newTotal = math.min(newTotal, CONFIG.MAX_BIND_TIME)
    
    -- Set new expiration time
    local newExpire = CurTime() + newTotal
    wep:SetNWFloat("TDMRP_BindExpire", newExpire)
    
    -- Update instance if exists
    if wep.TDMRP_Instance then
        wep.TDMRP_Instance.bound_until = newTotal
    end
    
    -- IMPORTANT: Also store in fallback system (TestBindWeapons) for death persistence
    -- This ensures binding survives NWVar cleanup on death
    local owner = wep:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        local steamID = owner:SteamID64()
        TDMRP.TestBindWeapons = TDMRP.TestBindWeapons or {}
        TDMRP.TestBindWeapons[steamID] = {
            entID = wep:EntIndex(),
            expireTime = newExpire,
            class = wep:GetClass(),
            prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
            suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
            material = wep.TDMRP_StoredMaterial or wep:GetNWString("TDMRP_Material", ""),  -- CRITICAL: Preserve suffix material
            customName = wep:GetNWString("TDMRP_CustomName", "") or wep.TDMRP_CustomName or "",  -- CRITICAL: Preserve custom name
            crafted = wep:GetNWBool("TDMRP_Crafted", false),
        }
        
        -- CRITICAL: Send immediate bind update to client for HUD sync
        if TDMRP.SendBindUpdateToPlayer then
            TDMRP.SendBindUpdateToPlayer(owner, wep, newExpire)
        end
    end
    
    return true, newTotal
end

----------------------------------------------------
-- Helper: Remove bind from weapon
----------------------------------------------------

function TDMRP.Binding.Unbind(wep)
    if not IsValid(wep) then return end
    
    wep:SetNWFloat("TDMRP_BindExpire", 0)
    
    if wep.TDMRP_Instance then
        wep.TDMRP_Instance.bindExpire = nil
    end
end

----------------------------------------------------
-- Apply Amethyst: Add 20 min bind time
----------------------------------------------------

function TDMRP.Binding.ApplyAmethyst(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then
        return false, "Invalid player or weapon"
    end
    
    -- Check ownership
    if wep:GetOwner() ~= ply then
        return false, "You don't own this weapon"
    end
    
    -- Check if M9K weapon
    if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then
        return false, "This weapon cannot be bound"
    end
    
    -- Check current bind time
    local currentRemaining = TDMRP.Binding.GetRemainingTime(wep)
    if currentRemaining >= CONFIG.MAX_BIND_TIME then
        return false, "Weapon is already at maximum bind time (59:59)"
    end
    
    -- Add bind time
    local success, newTotal = TDMRP.Binding.AddBindTime(wep, CONFIG.BIND_TIME_PER_AMETHYST)
    
    if success then
        -- Format time for message
        local mins = math.floor(newTotal / 60)
        local secs = math.floor(newTotal % 60)
        local timeStr = string.format("%02d:%02d", mins, secs)
        
        return true, "Weapon bound! Total time: " .. timeStr
    end
    
    return false, "Failed to apply binding"
end

----------------------------------------------------
-- Net: Apply Amethyst Request
----------------------------------------------------

net.Receive("TDMRP_ApplyAmethyst", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Get weapon from client-sent EntIndex
    local entIndex = net.ReadUInt(16)
    local wep = ents.GetByIndex(entIndex)
    
    -- Fallback to active weapon if invalid
    if not IsValid(wep) then
        wep = ply:GetActiveWeapon()
    end
    
    -- Validate weapon
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] You must be holding a weapon!")
        return
    end
    
    -- Check if M9K weapon
    if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then
        ply:ChatPrint("[TDMRP] This weapon cannot be bound!")
        return
    end
    
    -- Check amethyst count using CountGem
    local amethystCount = 0
    if TDMRP.CountGem then
        amethystCount = TDMRP.CountGem(ply, "blood_amethyst")
    end
    
    if amethystCount < 1 then
        ply:ChatPrint("[TDMRP] You need 1 Blood Amethyst to bind a weapon!")
        return
    end
    
    -- Check if already at max
    local currentRemaining = TDMRP.Binding.GetRemainingTime(wep)
    if currentRemaining >= CONFIG.MAX_BIND_TIME then
        ply:ChatPrint("[TDMRP] This weapon is already at maximum bind time (59:59)!")
        return
    end
    
    -- Consume amethyst
    if TDMRP.ConsumeGem then
        local consumed = TDMRP.ConsumeGem(ply, "blood_amethyst", 1)
        if not consumed then
            ply:ChatPrint("[TDMRP] Failed to consume amethyst!")
            return
        end
    else
        ply:ChatPrint("[TDMRP] Error: ConsumeGem function not available!")
        return
    end
    
    -- Apply binding
    local success, message = TDMRP.Binding.ApplyAmethyst(ply, wep)
    
    if success then
        ply:ChatPrint("[TDMRP] " .. message)
        
        -- Send update to client
        net.Start("TDMRP_BindUpdate")
        net.WriteFloat(wep:GetNWFloat("TDMRP_BindExpire", 0))
        net.Send(ply)
    else
        ply:ChatPrint("[TDMRP] " .. message)
    end
end)

----------------------------------------------------
-- Timer: Check for expired bindings
----------------------------------------------------

local lastBindCheck = 0

hook.Add("Think", "TDMRP_BindingTimerCheck", function()
    local curTime = CurTime()
    
    -- Only check once per second
    if curTime - lastBindCheck < CONFIG.TICK_INTERVAL then return end
    lastBindCheck = curTime
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            for _, wep in ipairs(ply:GetWeapons()) do
                if IsValid(wep) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
                    local expireTime = wep:GetNWFloat("TDMRP_BindExpire", 0)
                    
                    -- Check if just expired (was bound, now expired)
                    if expireTime > 0 and expireTime <= curTime then
                        -- Mark as expired but don't unbind yet (wait until death)
                        wep:SetNWFloat("TDMRP_BindExpire", 0)
                        
                        -- Notify player
                        net.Start("TDMRP_BindExpired")
                        net.Send(ply)
                        
                        -- Send chat message
                        ply:ChatPrint("[TDMRP] Your " .. (wep:GetPrintName() or "weapon") .. "'s binding has worn off!")
                        ply:ChatPrint("[TDMRP] It will be dropped if you die after this life.")
                    end
                end
            end
        end
    end
end)

----------------------------------------------------
-- DISABLED: Death/respawn handling moved to sv_tdmrp_spawn_orchestrator.lua
-- The spawn orchestrator now handles all bound weapon collection and restoration
----------------------------------------------------
--[[
-- Track weapons that should be restored on respawn
local RespawnWeapons = {}

hook.Add("PlayerDeath", "TDMRP_BindingDeathProtect", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    
    local steamID = victim:SteamID64()
    RespawnWeapons[steamID] = RespawnWeapons[steamID] or {}
    
    -- Check all weapons for bound ones
    for _, wep in ipairs(victim:GetWeapons()) do
        if IsValid(wep) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
            local remaining = TDMRP.Binding.GetRemainingTime(wep)
            
            if remaining > 0 then
                -- Weapon is bound - save for respawn
                local weaponData = {
                    class = wep:GetClass(),
                    remaining = remaining,
                    instance = wep.TDMRP_Instance and table.Copy(wep.TDMRP_Instance) or nil,
                    tier = wep:GetNWInt("TDMRP_Tier", 1),
                    crafted = wep:GetNWBool("TDMRP_Crafted", false),
                    prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
                    suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
                }
                
                table.insert(RespawnWeapons[steamID], weaponData)
            end
        end
    end
end)

----------------------------------------------------
-- Respawn Hook: DISABLED - Now handled by sv_tdmrp_spawn_orchestrator.lua
-- The spawn orchestrator integrates bound weapon restore with loadout system
----------------------------------------------------

--[[
-- OLD RESPAWN RESTORE - Kept for reference
hook.Add("PlayerSpawn", "TDMRP_BindingRespawnRestore", function(ply)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID64()
    
    -- Delay slightly to let loadout finish
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        
        local savedWeapons = RespawnWeapons[steamID]
        if not savedWeapons or #savedWeapons == 0 then return end
        
        for _, weaponData in ipairs(savedWeapons) do
            -- Apply respawn penalty
            local newRemaining = weaponData.remaining - CONFIG.RESPAWN_PENALTY
            
            if newRemaining > 0 then
                -- Give weapon back
                local wep = ply:Give(weaponData.class)
                
                if IsValid(wep) then
                    -- Set bind time (with penalty applied)
                    local newExpire = CurTime() + newRemaining
                    wep:SetNWFloat("TDMRP_BindExpire", newExpire)
                    
                    -- Restore instance data
                    if weaponData.instance then
                        wep.TDMRP_Instance = weaponData.instance
                        wep.TDMRP_Instance.bindExpire = newExpire
                        
                        -- Apply instance stats
                        if TDMRP.ApplyM9KInstance then
                            TDMRP.ApplyM9KInstance(wep, wep.TDMRP_Instance)
                        end
                    end
                    
                    -- Restore NW values
                    wep:SetNWInt("TDMRP_Tier", weaponData.tier)
                    wep:SetNWBool("TDMRP_Crafted", weaponData.crafted)
                    wep:SetNWString("TDMRP_PrefixID", weaponData.prefixId)
                    wep:SetNWString("TDMRP_SuffixID", weaponData.suffixId)
                    
                    -- Format time for message
                    local mins = math.floor(newRemaining / 60)
                    local secs = math.floor(newRemaining % 60)
                    local timeStr = string.format("%02d:%02d", mins, secs)
                    
                    ply:ChatPrint("[TDMRP] Your bound " .. (wep:GetPrintName() or weaponData.class) .. " was restored! (-30s penalty, " .. timeStr .. " remaining)")
                end
            else
                -- Binding expired from penalty
                ply:ChatPrint("[TDMRP] Your " .. weaponData.class .. "'s binding expired due to the respawn penalty.")
            end
        end
        
        -- Clear saved weapons
        RespawnWeapons[steamID] = nil
    end)
end)
--]]

----------------------------------------------------
-- Disconnect Hook: Cache bound weapons
----------------------------------------------------

hook.Add("PlayerDisconnected", "TDMRP_BindingDisconnectCache", function(ply)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID64()
    local boundWeapons = {}
    
    -- Save all bound weapons
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
            local remaining = TDMRP.Binding.GetRemainingTime(wep)
            
            if remaining > 0 then
                local weaponData = {
                    class = wep:GetClass(),
                    remaining = remaining,
                    instance = wep.TDMRP_Instance and table.Copy(wep.TDMRP_Instance) or nil,
                    tier = wep:GetNWInt("TDMRP_Tier", 1),
                    crafted = wep:GetNWBool("TDMRP_Crafted", false),
                    prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
                    suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
                    disconnectTime = os.time(),
                }
                
                table.insert(boundWeapons, weaponData)
            end
        end
    end
    
    if #boundWeapons > 0 then
        DisconnectCache[steamID] = boundWeapons
        SaveDisconnectCache()
        print("[TDMRP Binding] Cached " .. #boundWeapons .. " bound weapons for " .. ply:Nick())
    else
        -- Clear any existing cache for this player
        if DisconnectCache[steamID] then
            DisconnectCache[steamID] = nil
            SaveDisconnectCache()
        end
    end
end)

----------------------------------------------------
-- Initial Spawn Hook: Restore cached weapons
----------------------------------------------------

hook.Add("PlayerInitialSpawn", "TDMRP_BindingReconnectRestore", function(ply)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID64()
    
    -- Check disconnect cache
    if not DisconnectCache[steamID] or #DisconnectCache[steamID] == 0 then return end
    
    -- Delay to let player fully spawn
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        
        local cachedWeapons = DisconnectCache[steamID]
        if not cachedWeapons then return end
        
        local restoredCount = 0
        
        for _, weaponData in ipairs(cachedWeapons) do
            -- Timer was paused while disconnected, so remaining time is preserved
            local remaining = weaponData.remaining
            
            if remaining > 0 then
                -- Give weapon back
                local wep = ply:Give(weaponData.class)
                
                if IsValid(wep) then
                    -- Set bind time
                    local newExpire = CurTime() + remaining
                    wep:SetNWFloat("TDMRP_BindExpire", newExpire)
                    
                    -- Restore instance data
                    if weaponData.instance then
                        wep.TDMRP_Instance = weaponData.instance
                        wep.TDMRP_Instance.bindExpire = newExpire
                        
                        -- Apply instance stats
                        if TDMRP.ApplyM9KInstance then
                            TDMRP.ApplyM9KInstance(wep, wep.TDMRP_Instance)
                        end
                    end
                    
                    -- Restore NW values
                    wep:SetNWInt("TDMRP_Tier", weaponData.tier)
                    wep:SetNWBool("TDMRP_Crafted", weaponData.crafted)
                    wep:SetNWString("TDMRP_PrefixID", weaponData.prefixId)
                    wep:SetNWString("TDMRP_SuffixID", weaponData.suffixId)
                    
                    restoredCount = restoredCount + 1
                end
            end
        end
        
        if restoredCount > 0 then
            ply:ChatPrint("[TDMRP] Welcome back! " .. restoredCount .. " bound weapon(s) have been restored to your inventory.")
        end
        
        -- Clear cache
        DisconnectCache[steamID] = nil
        SaveDisconnectCache()
    end)
end)

----------------------------------------------------
-- Export CountGem and ConsumeGem references
----------------------------------------------------

-- These will be set by sv_tdmrp_gemcraft.lua if it loads after
hook.Add("InitPostEntity", "TDMRP_BindingSetupHelpers", function()
    -- Look for existing CountGem/ConsumeGem functions
    if not TDMRP.CountGem then
        -- Check if defined in gemcraft
        timer.Simple(1, function()
            -- Will be available after gemcraft loads
        end)
    end
end)

----------------------------------------------------
-- Block /drop command for bound weapons
----------------------------------------------------

hook.Add("canDropWeapon", "TDMRP_BlockBoundWeaponDrop", function(ply, weapon)
    if not IsValid(weapon) then return end
    
    -- Check if weapon is bound
    local remaining = TDMRP.Binding.GetRemainingTime(weapon)
    if remaining > 0 then
        local mins = math.floor(remaining / 60)
        local secs = math.floor(remaining % 60)
        ply:ChatPrint(string.format("[TDMRP] Cannot drop bound weapon! Unbind it first using Blood Ruby (%02d:%02d remaining)", mins, secs))
        return false
    end
    
    -- Allow drop if not bound
    return nil  -- nil = let other hooks decide
end)

----------------------------------------------------
-- Debug: Test bound weapons system
----------------------------------------------------

concommand.Add("tdmrp_test_bind", function(ply)
    if not IsValid(ply) then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then
        ply:ChatPrint("[TDMRP Debug] You must hold a TDMRP weapon to test binding")
        return
    end
    
    -- Bind for 5 minutes
    local bindTime = 5 * 60
    local expireTime = CurTime() + bindTime
    
    -- Set NWFloat
    wep:SetNWFloat("TDMRP_BindExpire", expireTime)
    wep:SetNWFloat("TDMRP_BindUntil", bindTime)
    
    -- Create/update instance with binding info
    if not wep.TDMRP_Instance then
        wep.TDMRP_Instance = {}
        print("[TDMRP Debug] Created new instance for binding")
    end
    
    wep.TDMRP_Instance.bound_until = bindTime
    wep.TDMRP_Instance.bindExpire = expireTime
    
    -- CRITICAL: Also store on player so it persists through death
    local steamID = ply:SteamID64()
    TDMRP.TestBindWeapons = TDMRP.TestBindWeapons or {}
    TDMRP.TestBindWeapons[steamID] = {
        class = wep:GetClass(),
        expireTime = expireTime,
        bindTime = bindTime,
        entID = wep:EntIndex(),
    }
    
    print(string.format("[TDMRP Debug] Stored bind info for %s: class=%s, expire=%.1f, entID=%d", ply:Nick(), wep:GetClass(), expireTime, wep:EntIndex()))
    print(string.format("[TDMRP Debug] Instance bound_until=%d, bindExpire=%.1f", bindTime, expireTime))
    
    ply:ChatPrint(string.format("[TDMRP Debug] Weapon bound for %d seconds (expires at %.1f) - try /kill to test death protection", bindTime, expireTime))
    print(string.format("[TDMRP Debug] %s bound weapon %s (EntID=%d) - expire=%.1f", ply:Nick(), wep:GetClass(), wep:EntIndex(), expireTime))
end)

print("[TDMRP] sv_tdmrp_binding.lua loaded - Amethyst weapon binding system")
