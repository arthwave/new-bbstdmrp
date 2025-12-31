-- cl_tdmrp_shatter.lua
-- Client-side shatter explosion effects

if not CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.Shatter = TDMRP.Shatter or {}

-- Receive explosion effect from server
net.Receive("TDMRP_ShatterExplosion", function()
    local pos = net.ReadVector()
    
    -- Create additional visual effects
    TDMRP.Shatter.CreateExplosionEffect(pos)
end)

function TDMRP.Shatter.CreateExplosionEffect(pos)
    -- Orange/yellow flash
    local dlight = DynamicLight(0)
    if dlight then
        dlight.pos = pos
        dlight.r = 255
        dlight.g = 180
        dlight.b = 50
        dlight.brightness = 3
        dlight.decay = 1000
        dlight.size = 200
        dlight.dietime = CurTime() + 0.3
    end
    
    -- Rock debris particles
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 12 do
            local particle = emitter:Add("effects/spark", pos)
            if particle then
                particle:SetVelocity(VectorRand() * math.Rand(100, 300))
                particle:SetLifeTime(0)
                particle:SetDieTime(math.Rand(0.3, 0.6))
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(3, 6))
                particle:SetEndSize(0)
                particle:SetColor(255, 200, 100)
                particle:SetGravity(Vector(0, 0, -600))
                particle:SetCollide(true)
                particle:SetBounce(0.3)
            end
        end
        
        -- Dust cloud
        for i = 1, 6 do
            local particle = emitter:Add("particle/smokesprites_0001", pos)
            if particle then
                particle:SetVelocity(VectorRand() * math.Rand(50, 150))
                particle:SetLifeTime(0)
                particle:SetDieTime(math.Rand(0.5, 1.0))
                particle:SetStartAlpha(150)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(20, 40))
                particle:SetEndSize(math.Rand(60, 100))
                particle:SetColor(180, 160, 140)
                particle:SetGravity(Vector(0, 0, 50))
                particle:SetRoll(math.Rand(0, 360))
                particle:SetRollDelta(math.Rand(-2, 2))
            end
        end
        
        emitter:Finish()
    end
end

print("[TDMRP] cl_tdmrp_shatter.lua loaded - Shatter effects ready")
