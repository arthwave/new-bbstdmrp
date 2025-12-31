----------------------------------------------------
-- TDMRP Frost Suffix Effects (Client-Side)
-- Handles particle visuals and HUD indicators
----------------------------------------------------

if SERVER then return end

-- Track local player's frost slow level
local localPlayerSlowLevel = 0

----------------------------------------------------
-- Network Handler: Frost Slow Update
----------------------------------------------------

net.Receive("TDMRP_FrostSlowUpdate", function()
    local target = net.ReadEntity()
    local slowLevel = net.ReadFloat()
    
    if IsValid(target) and target == LocalPlayer() then
        localPlayerSlowLevel = slowLevel
    end
end)

----------------------------------------------------
-- Network Handler: Frost Death Explosion
----------------------------------------------------

net.Receive("TDMRP_FrostDeathExplosion", function()
    local deathPos = net.ReadVector()
    TDMRP_RenderFrostDeathExplosion(deathPos)
end)

----------------------------------------------------
-- Frost Death Explosion Visual Effect
----------------------------------------------------

function TDMRP_RenderFrostDeathExplosion(pos)
    -- Layer 1: Snowflake burst (use env_snow particles)
    local function SpawnSnowflakes()
        local snowflakeCount = 50
        local spreadRadius = 200
        
        for i = 1, snowflakeCount do
            local angle = (i / snowflakeCount) * math.pi * 2
            local randomRadius = math.Rand(0, spreadRadius)
            local randomHeight = math.Rand(0, 150)
            
            local spawnPos = pos + Vector(
                math.cos(angle) * randomRadius,
                math.sin(angle) * randomRadius,
                randomHeight
            )
            
            local particle = {
                pos = spawnPos,
                vel = Vector(
                    math.Rand(-100, 100),
                    math.Rand(-100, 100),
                    math.Rand(-50, -200)  -- Downward
                ),
                scale = math.Rand(0.5, 2.0),
                life = 0,
                maxLife = math.Rand(3, 4),
                color = Color(200, 230, 255, 255),
                model = "particle/snow.vmt"
            }
            
            table.insert(TDMRP.Frost.Particles, particle)
        end
    end
    
    -- Layer 2: Ice shard burst (using small rock props)
    local function SpawnIceShards()
        local shardCount = 20
        local shardSpeed = 800
        
        for i = 1, shardCount do
            local angle = (i / shardCount) * math.pi * 2
            local pitch = math.Rand(-60, 60) * math.pi / 180
            
            local direction = Vector(
                math.cos(angle) * math.cos(pitch),
                math.sin(angle) * math.cos(pitch),
                math.sin(pitch)
            ):GetNormalized()
            
            local particle = {
                pos = pos + direction * 20,
                vel = direction * (shardSpeed + math.Rand(-200, 200)),
                scale = math.Rand(0.3, 0.8),
                life = 0,
                maxLife = 0.5,  -- Quick cleanup
                color = Color(173, 216, 230, 255),  -- Light blue
                model = "models/props_junk/rock001a.mdl",
                isModel = true
            }
            
            table.insert(TDMRP.Frost.Particles, particle)
        end
    end
    
    -- Layer 3: Frost ring decal on ground
    local function SpawnFrostRing()
        local groundTrace = util.QuickTrace(pos, Vector(0, 0, -1000), NULL)
        if not groundTrace.Hit then return end
        
        local groundPos = groundTrace.HitPos + Vector(0, 0, 1)  -- Slightly above ground
        
        local particle = {
            pos = groundPos,
            vel = Vector(0, 0, 0),
            scale = 0,  -- Start at 0
            maxScale = 2.0,
            life = 0,
            maxLife = 2,
            color = Color(150, 200, 255, 200),
            decal = true,
            radius = 0
        }
        
        table.insert(TDMRP.Frost.Particles, particle)
    end
    
    -- Play sound (already handled server-side, but add local sound for immersion)
    LocalPlayer():EmitSound("tdmrp/suffixsounds/offrostdeath.mp3", 100)
    
    -- Spawn all particle effects
    if not TDMRP.Frost then
        TDMRP.Frost = {}
        TDMRP.Frost.Particles = {}
    end
    
    if not TDMRP.Frost.Particles then
        TDMRP.Frost.Particles = {}
    end
    
    SpawnSnowflakes()
    SpawnIceShards()
    SpawnFrostRing()
end

----------------------------------------------------
-- Particle Update and Rendering (Think Hook)
----------------------------------------------------

if not TDMRP.Frost then
    TDMRP.Frost = {}
    TDMRP.Frost.Particles = {}
end

local function UpdateAndRenderFrostParticles()
    if not TDMRP.Frost.Particles then return end
    
    local particlesToRemove = {}
    
    for i, particle in ipairs(TDMRP.Frost.Particles) do
        particle.life = particle.life + FrameTime()
        
        if particle.life >= particle.maxLife then
            table.insert(particlesToRemove, i)
        else
            -- Update position
            if not particle.decal then
                particle.pos = particle.pos + particle.vel * FrameTime()
                particle.vel = particle.vel + Vector(0, 0, -800 * FrameTime())  -- Gravity
            end
            
            -- Render particle
            if particle.isModel then
                -- Render 3D model for ice shards
                local alpha = 255 * (1 - (particle.life / particle.maxLife))
                
                cam.Start3D()
                    render.SetMaterial(Material("models/props_combine/combine_interface_disp"))
                    render.DrawWireframeBox(particle.pos, Angle(0, 0, 0), 
                        Vector(-particle.scale, -particle.scale, -particle.scale),
                        Vector(particle.scale, particle.scale, particle.scale),
                        Color(173, 216, 230, alpha),
                        true)
                cam.End3D()
            elseif particle.decal then
                -- Render expanding frost ring
                particle.radius = particle.scale * 200 * (particle.life / particle.maxLife)
                
                local alpha = 200 * (1 - (particle.life / particle.maxLife))
                
                cam.Start3D()
                    render.DrawWireframeBox(particle.pos, Angle(0, 0, 0),
                        Vector(-particle.radius, -particle.radius, -0.5),
                        Vector(particle.radius, particle.radius, 0.5),
                        Color(150, 200, 255, alpha),
                        true)
                cam.End3D()
            else
                -- Render snowflake
                local alpha = 180 * (1 - (particle.life / particle.maxLife))
                
                cam.Start3D()
                    render.SetMaterial(Material("particle/snow"))
                    local pos = particle.pos
                    local size = particle.scale * 4
                    render.DrawQuadEasy(pos, Vector(0, 0, 1), size, size,
                        Color(particle.color.r, particle.color.g, particle.color.b, alpha))
                cam.End3D()
            end
        end
    end
    
    -- Remove dead particles
    for i = #particlesToRemove, 1, -1 do
        table.remove(TDMRP.Frost.Particles, particlesToRemove[i])
    end
end

hook.Add("Think", "TDMRP_FrostParticles", UpdateAndRenderFrostParticles)

----------------------------------------------------
-- HUD Indicator for Slow Effect
----------------------------------------------------

local function DrawFrostSlowHUD()
    if localPlayerSlowLevel <= 0 then return end
    
    local scrW = ScrW()
    local scrH = ScrH()
    local indicatorX = scrW - 120
    local indicatorY = scrH - 150
    local iconSize = 32
    
    -- Background
    draw.RoundedBox(8, indicatorX - 20, indicatorY - 20, 100, 70, Color(0, 0, 0, 200))
    
    -- Snowflake icon (text-based)
    draw.SimpleText("❄", "TDMRP_Header", indicatorX, indicatorY, 
        Color(173, 216, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Slow percentage text
    draw.SimpleText(math.floor(localPlayerSlowLevel) .. "%", "TDMRP_Body", 
        indicatorX, indicatorY + 25, Color(173, 216, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Progress bar
    local barWidth = 80
    local barHeight = 8
    local filledWidth = barWidth * (localPlayerSlowLevel / 50)
    
    draw.RoundedBox(4, indicatorX - barWidth/2, indicatorY + 45, barWidth, barHeight, Color(50, 50, 50, 200))
    draw.RoundedBox(4, indicatorX - barWidth/2, indicatorY + 45, filledWidth, barHeight, Color(0, 150, 255, 255))
end

hook.Add("HUDPaint", "TDMRP_FrostSlowHUD", DrawFrostSlowHUD)

print("[TDMRP] cl_tdmrp_frost_effects.lua loaded")
