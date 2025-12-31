----------------------------------------------------
-- TDMRP Death & Spawn System
-- Complete override of death/respawn for combat classes
-- Features:
--   - 5 second respawn delay with countdown
--   - Custom spawn points per class
--   - Control point spawn selection (hold WASD during spawn)
----------------------------------------------------

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.SpawnPoints = TDMRP.SpawnPoints or {}
TDMRP.DeathTimers = TDMRP.DeathTimers or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    RESPAWN_DELAY = 5,              -- Seconds before respawn is allowed
    SPAWN_IMMUNITY = 3,             -- Seconds of spawn protection
}

----------------------------------------------------
-- Network Strings
----------------------------------------------------

util.AddNetworkString("TDMRP_DeathScreen")
util.AddNetworkString("TDMRP_RespawnReady")
util.AddNetworkString("TDMRP_RequestRespawn")
util.AddNetworkString("TDMRP_SpawnComplete")
util.AddNetworkString("TDMRP_SpawnPointInfo")
util.AddNetworkString("TDMRP_RequestSpawnInfo")

----------------------------------------------------
-- Control Point Spawn Configuration
-- Maps control point IDs to spawn positions
-- Cops cannot spawn at CoS, Criminals cannot spawn at CrS
----------------------------------------------------

local ControlPointSpawns = {
    TS = {
        name = "Train Station",
        -- Spawn positions near the control point
        spawns = {
            { pos = Vector(1350, -4550, 660), ang = Angle(0, 90, 0) },
            { pos = Vector(1320, -4630, 660), ang = Angle(0, 90, 0) },
        },
        cop_allowed = true,
        crim_allowed = true,
    },
    CoS = {
        name = "Cop Spawn",
        spawns = {
            { pos = Vector(3658.75, 1703.97, 660), ang = Angle(0, 270, 0) },
        },
        cop_allowed = true,   -- Cops CAN spawn at their own captured home base
        crim_allowed = false,  -- Criminals CANNOT spawn near cop default spawn
    },
    MT = {
        name = "Movie Theater",
        spawns = {
            { pos = Vector(-2400, 2250, 845), ang = Angle(0, 0, 0) },
            { pos = Vector(-2450, 2250, 845), ang = Angle(0, 0, 0) },
        },
        cop_allowed = true,
        crim_allowed = true,
    },
    CrS = {
        name = "Crim Spawn",
        spawns = {
            { pos = Vector(-2767.97, 5470.38, 852), ang = Angle(0, 0, 0) },
        },
        cop_allowed = false,  -- Cops CANNOT spawn near criminal default spawn
        crim_allowed = true,   -- Criminals CAN spawn at their own captured home base
    },
    BA = {
        name = "Back Alley",
        spawns = {
            { pos = Vector(2130, 2540, 1156), ang = Angle(0, 180, 0) },
            { pos = Vector(2125, 2545, 1156), ang = Angle(0, 180, 0) },
        },
        cop_allowed = true,
        crim_allowed = true,
    },
}

-- Which control points are assigned to which WASD keys
local SpawnKeyMapping = {
    [1] = "TS",   -- W = Train Station
    [2] = "MT",   -- A = Movie Theater  
    [3] = "BA",   -- S = Back Alley (not in config yet, will be added)
    [4] = "CoS",  -- D = Cop Spawn (for criminals) / CrS (for cops)
}

----------------------------------------------------
-- Spawn Point Definitions (per map) - BASE SPAWNS
----------------------------------------------------

local SpawnPoints = {
    -- rp_downtown_v4c_v2 (and similar downtown maps)
    ["rp_c18_v1"] = {
        criminal = {
            { pos = Vector(-765.48, 5103.97, 904.03), ang = Angle(0, -130.44, 0) },
            { pos = Vector(-847.97, 4821.47, 904.03), ang = Angle(0, 81.07, 0) },
            { pos = Vector(-1140.23, 5103.97, 904.03), ang = Angle(0, -78.74, 0) },
            { pos = Vector(-694.57, 4579.23, 1032.03), ang = Angle(0, 93.04, 0) },
            { pos = Vector(-802.14, 4903.97, 1032.03), ang = Angle(0, -90.31, 0) },
        },
        cop = {
            { pos = Vector(4351.97, 576.03, 976.03), ang = Angle(0, 145.53, 0) },
            { pos = Vector(3184.03, 580.03, 928.03), ang = Angle(0, 22.02, 0) },
            { pos = Vector(2544.03, 496.03, 928.03), ang = Angle(0, 45.17, 0) },
            { pos = Vector(2508.37, 1315.61, 928.03), ang = Angle(0, -75.13, 0) },
            { pos = Vector(3259.64, 795.97, 928.03), ang = Angle(0, -26.24, 0) },
        },
    },
}

-- Aliases for similar maps
SpawnPoints["rp_downtown_v4c"] = SpawnPoints["rp_downtown_v4c_v2"]
SpawnPoints["rp_downtown_v2"] = SpawnPoints["rp_downtown_v4c_v2"]
SpawnPoints["rp_downtown_v4c_v3"] = SpawnPoints["rp_downtown_v4c_v2"]

----------------------------------------------------
-- Helper: Get spawn points for current map
----------------------------------------------------

local function GetMapSpawnPoints()
    local mapName = game.GetMap():lower()
    return SpawnPoints[mapName]
end

----------------------------------------------------
-- Helper: Get player's TDMRP class
----------------------------------------------------

local function GetPlayerClass(ply)
    if not IsValid(ply) then return "civilian" end
    
    local teamID = ply:Team()
    if not RPExtraTeams or not RPExtraTeams[teamID] then return "civilian" end
    
    return RPExtraTeams[teamID].tdmrp_class or "civilian"
end

----------------------------------------------------
-- Helper: Is combat class
----------------------------------------------------

local function IsCombatClass(ply)
    local class = GetPlayerClass(ply)
    return class == "cop" or class == "criminal"
end

----------------------------------------------------
-- Helper: Get random spawn point for class
----------------------------------------------------

local function GetRandomSpawnPoint(class)
    local mapPoints = GetMapSpawnPoints()
    if not mapPoints then return nil end
    
    local classPoints = mapPoints[class]
    if not classPoints or #classPoints == 0 then return nil end
    
    return classPoints[math.random(#classPoints)]
end

----------------------------------------------------
-- Helper: Check if control point is owned by team
----------------------------------------------------

local function IsControlPointOwnedBy(pointID, teamClass)
    if not TDMRP or not TDMRP.CapturePoints then
        print("[TDMRP Spawn] WARNING: TDMRP.CapturePoints not initialized!")
        return false
    end
    
    -- IMPORTANT: Read owner from PointData (runtime state), NOT Points (static definition)
    -- Points table has the static config, PointData has the actual capture state
    if not TDMRP.CapturePoints.PointData then
        print("[TDMRP Spawn] WARNING: TDMRP.CapturePoints.PointData not initialized!")
        return false
    end
    
    local pointData = TDMRP.CapturePoints.PointData[pointID]
    if not pointData then 
        print(string.format("[TDMRP Spawn] WARNING: PointData for '%s' not found!", tostring(pointID)))
        return false 
    end
    
    local ownerState = pointData.owner
    local ownerName = "UNKNOWN"
    if ownerState == TDMRP.CapturePoints.OWNER_NEUTRAL then ownerName = "NEUTRAL"
    elseif ownerState == TDMRP.CapturePoints.OWNER_COP then ownerName = "COP"
    elseif ownerState == TDMRP.CapturePoints.OWNER_CRIM then ownerName = "CRIM"
    elseif ownerState == TDMRP.CapturePoints.OWNER_CONTESTED then ownerName = "CONTESTED"
    end
    
    print(string.format("[TDMRP Spawn] Point %s owner: %s (%d) | Checking for: %s", 
        pointID, ownerName, ownerState or -1, teamClass))
    
    if teamClass == "cop" then
        return ownerState == TDMRP.CapturePoints.OWNER_COP
    elseif teamClass == "criminal" then
        return ownerState == TDMRP.CapturePoints.OWNER_CRIM
    end
    
    return false
end

----------------------------------------------------
-- Helper: Get available spawn points for player
-- Returns table of {name, available, pointID} for each WASD key
----------------------------------------------------

local function GetAvailableSpawnPoints(ply)
    local class = GetPlayerClass(ply)
    local availablePoints = {}
    
    -- Define which points map to which keys based on class
    -- D key shows the player's OWN home base control point
    local keyMapping
    if class == "cop" then
        keyMapping = {
            [1] = "TS",   -- W = Train Station
            [2] = "MT",   -- A = Movie Theater
            [3] = "BA",   -- S = Back Alley
            [4] = "CoS",  -- D = Cop Spawn (cops' own home base)
        }
    else  -- criminal
        keyMapping = {
            [1] = "TS",   -- W = Train Station
            [2] = "MT",   -- A = Movie Theater
            [3] = "BA",   -- S = Back Alley
            [4] = "CrS",  -- D = Criminal Spawn (criminals' own home base)
        }
    end
    
    for keyIndex = 1, 4 do
        local pointID = keyMapping[keyIndex]
        local cpConfig = ControlPointSpawns[pointID]
        
        if cpConfig then
            -- Check if this class can use this spawn
            local classAllowed = (class == "cop" and cpConfig.cop_allowed) or 
                                (class == "criminal" and cpConfig.crim_allowed)
            
            -- Check if the control point is owned by the player's team
            local owned = IsControlPointOwnedBy(pointID, class)
            
            local isAvailable = classAllowed and owned
            
            print(string.format("[TDMRP Spawn] Key %d: %s | classAllowed=%s, owned=%s, available=%s",
                keyIndex, pointID, tostring(classAllowed), tostring(owned), tostring(isAvailable)))
            
            table.insert(availablePoints, {
                name = cpConfig.name,
                available = isAvailable,
                pointID = pointID,
            })
        else
            -- Point not configured, mark as unavailable
            print(string.format("[TDMRP Spawn] Key %d: %s - NOT CONFIGURED", keyIndex, tostring(pointID)))
            table.insert(availablePoints, {
                name = pointID or "???",
                available = false,
                pointID = pointID,
            })
        end
    end
    
    return availablePoints, keyMapping
end

----------------------------------------------------
-- Helper: Get spawn position for control point
----------------------------------------------------

local function GetControlPointSpawn(pointID)
    local cpConfig = ControlPointSpawns[pointID]
    if not cpConfig or not cpConfig.spawns or #cpConfig.spawns == 0 then
        return nil
    end
    
    return cpConfig.spawns[math.random(#cpConfig.spawns)]
end

----------------------------------------------------
-- Network: Send spawn point info to client
----------------------------------------------------

net.Receive("TDMRP_RequestSpawnInfo", function(len, ply)
    if not IsValid(ply) then return end
    
    local availablePoints = GetAvailableSpawnPoints(ply)
    
    net.Start("TDMRP_SpawnPointInfo")
        net.WriteUInt(#availablePoints, 4)
        for _, point in ipairs(availablePoints) do
            net.WriteString(point.name)
            net.WriteBool(point.available)
        end
    net.Send(ply)
end)

----------------------------------------------------
-- Hook: Player Death - Start respawn timer for combat classes
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_CombatDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    if not IsCombatClass(victim) then return end
    
    local steamID = victim:SteamID64()
    local class = GetPlayerClass(victim)
    
    print(string.format("[TDMRP Death] %s (%s) died - starting %ds respawn timer", 
        victim:Nick(), class, CONFIG.RESPAWN_DELAY))
    
    -- Store death time
    TDMRP.DeathTimers[steamID] = {
        deathTime = CurTime(),
        respawnTime = CurTime() + CONFIG.RESPAWN_DELAY,
        class = class,
        canRespawn = false,
    }
    
    -- Send death screen to client
    net.Start("TDMRP_DeathScreen")
        net.WriteFloat(CONFIG.RESPAWN_DELAY)
        net.WriteString(class)
    net.Send(victim)
    
    -- Also send spawn point availability
    local availablePoints = GetAvailableSpawnPoints(victim)
    net.Start("TDMRP_SpawnPointInfo")
        net.WriteUInt(#availablePoints, 4)
        for _, point in ipairs(availablePoints) do
            net.WriteString(point.name)
            net.WriteBool(point.available)
        end
    net.Send(victim)
    
    -- Timer to enable respawn
    timer.Simple(CONFIG.RESPAWN_DELAY, function()
        if not IsValid(victim) then return end
        
        local data = TDMRP.DeathTimers[steamID]
        if data then
            data.canRespawn = true
            
            -- Notify client they can respawn
            net.Start("TDMRP_RespawnReady")
            net.Send(victim)
            
            print(string.format("[TDMRP Death] %s can now respawn", victim:Nick()))
        end
    end)
end)

----------------------------------------------------
-- Hook: Prevent auto-respawn during timer
----------------------------------------------------

hook.Add("PlayerDeathThink", "TDMRP_PreventAutoRespawn", function(ply)
    if not IsValid(ply) then return end
    if not IsCombatClass(ply) then return end
    
    local steamID = ply:SteamID64()
    local data = TDMRP.DeathTimers[steamID]
    
    if data and not data.canRespawn then
        -- Block respawn - return true to prevent default behavior
        return true
    end
    
    -- Allow respawn but don't auto-spawn (let them press a key)
    if data and data.canRespawn then
        if ply:KeyPressed(IN_ATTACK) or ply:KeyPressed(IN_ATTACK2) or ply:KeyPressed(IN_JUMP) then
            -- Respawn requested via key press
            ply:Spawn()
            return true
        end
        return true  -- Block auto-respawn, wait for key press
    end
end)

----------------------------------------------------
-- Network: Client requests respawn
----------------------------------------------------

net.Receive("TDMRP_RequestRespawn", function(len, ply)
    if not IsValid(ply) then return end
    if ply:Alive() then return end
    
    local steamID = ply:SteamID64()
    local data = TDMRP.DeathTimers[steamID]
    
    if not data or not data.canRespawn then
        print(string.format("[TDMRP Death] %s tried to respawn but timer not ready", ply:Nick()))
        return
    end
    
    -- Get spawn location selection (W/A/S/D for control points, or default)
    local spawnSelection = net.ReadUInt(3)  -- 0=default, 1=W, 2=A, 3=S, 4=D
    
    -- Validate control point spawn selection
    if spawnSelection > 0 then
        local availablePoints, keyMapping = GetAvailableSpawnPoints(ply)
        local selectedPoint = availablePoints[spawnSelection]
        
        if not selectedPoint or not selectedPoint.available then
            print(string.format("[TDMRP Death] %s tried to spawn at unavailable point %d", ply:Nick(), spawnSelection))
            spawnSelection = 0  -- Fall back to default spawn
        end
    end
    
    print(string.format("[TDMRP Death] %s requesting respawn | Selection: %d", ply:Nick(), spawnSelection))
    
    -- Store selection for PlayerSpawn hook
    ply.TDMRP_SpawnSelection = spawnSelection
    
    -- Spawn the player
    ply:Spawn()
end)

----------------------------------------------------
-- Hook: Apply spawn position on PlayerSpawn
----------------------------------------------------

hook.Add("PlayerSpawn", "TDMRP_CombatSpawn", function(ply, transition)
    if transition then return end
    if not IsValid(ply) then return end
    if not IsCombatClass(ply) then return end
    
    local steamID = ply:SteamID64()
    local class = GetPlayerClass(ply)
    local spawnSelection = ply.TDMRP_SpawnSelection or 0
    
    -- Clear death timer
    TDMRP.DeathTimers[steamID] = nil
    
    -- Small delay to ensure spawn is complete
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        local spawnPoint = nil
        local spawnType = "base"
        
        -- Check if spawning at control point
        if spawnSelection > 0 then
            local availablePoints, keyMapping = GetAvailableSpawnPoints(ply)
            local selectedPoint = availablePoints[spawnSelection]
            
            if selectedPoint and selectedPoint.available then
                local pointID = selectedPoint.pointID
                spawnPoint = GetControlPointSpawn(pointID)
                spawnType = pointID
            end
        end
        
        -- Fall back to base spawn if control point spawn not available
        if not spawnPoint then
            spawnPoint = GetRandomSpawnPoint(class)
            spawnType = "base"
        end
        
        if spawnPoint then
            ply:SetPos(spawnPoint.pos)
            ply:SetEyeAngles(spawnPoint.ang)
            print(string.format("[TDMRP Spawn] %s spawned at %s spawn (%s)", ply:Nick(), spawnType, class))
        else
            print(string.format("[TDMRP Spawn] No spawn points for %s on %s", class, game.GetMap()))
        end
        
        -- Apply spawn immunity
        ply:GodEnable()
        ply.TDMRP_SpawnImmunity = true
        
        timer.Simple(CONFIG.SPAWN_IMMUNITY, function()
            if IsValid(ply) then
                ply:GodDisable()
                ply.TDMRP_SpawnImmunity = false
                ply:ChatPrint("Spawn protection ended")
            end
        end)
        
        -- Clear spawn selection
        ply.TDMRP_SpawnSelection = nil
        
        -- Notify client spawn is complete
        net.Start("TDMRP_SpawnComplete")
        net.Send(ply)
    end)
end)

----------------------------------------------------
-- Hook: Block damage during spawn immunity
----------------------------------------------------

hook.Add("EntityTakeDamage", "TDMRP_SpawnImmunity", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end
    
    if target.TDMRP_SpawnImmunity then
        return true  -- Block damage
    end
end)

----------------------------------------------------
-- Admin Commands
----------------------------------------------------

concommand.Add("tdmrp_addspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        print("You must be a superadmin to use this command")
        return
    end
    
    local class = args[1]
    if class ~= "cop" and class ~= "criminal" then
        ply:ChatPrint("Usage: tdmrp_addspawn <cop|criminal>")
        return
    end
    
    local pos = ply:GetPos()
    local ang = ply:EyeAngles()
    
    local code = string.format('{ pos = Vector(%.2f, %.2f, %.2f), ang = Angle(0, %.2f, 0) },', 
        pos.x, pos.y, pos.z, ang.y)
    
    print("[TDMRP Spawn] Add this line to SpawnPoints[\"" .. game.GetMap() .. "\"]." .. class .. ":")
    print(code)
    
    ply:ChatPrint("Spawn point recorded! Check server console for the code.")
end)

concommand.Add("tdmrp_testspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        print("You must be an admin to use this command")
        return
    end
    
    local class = args[1]
    if class ~= "cop" and class ~= "criminal" then
        ply:ChatPrint("Usage: tdmrp_testspawn <cop|criminal>")
        return
    end
    
    local spawnPoint = GetRandomSpawnPoint(class)
    if not spawnPoint then
        ply:ChatPrint("No spawn points defined for " .. class .. " on this map!")
        return
    end
    
    ply:SetPos(spawnPoint.pos)
    ply:SetEyeAngles(spawnPoint.ang)
    ply:ChatPrint("Teleported to random " .. class .. " spawn point")
end)

concommand.Add("tdmrp_listspawns", function(ply, cmd, args)
    local mapPoints = GetMapSpawnPoints()
    
    if not mapPoints then
        print("[TDMRP Spawn] No spawn points defined for map: " .. game.GetMap())
        if IsValid(ply) then
            ply:ChatPrint("No spawn points defined for this map!")
        end
        return
    end
    
    print("[TDMRP Spawn] Spawn points for " .. game.GetMap() .. ":")
    
    for class, points in pairs(mapPoints) do
        print("  " .. class .. ": " .. #points .. " spawn points")
    end
    
    if IsValid(ply) then
        ply:ChatPrint("Spawn point list printed to server console")
    end
end)

print("[TDMRP] sv_tdmrp_spawnpoints.lua loaded - Death & Spawn system for combat classes")
print("[TDMRP] Current map: " .. game.GetMap() .. " | Has spawn points: " .. tostring(GetMapSpawnPoints() ~= nil))
