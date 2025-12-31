-- cl_tdmrp_homing.lua
-- Client-side homing impact effects

if not CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.Homing = TDMRP.Homing or {}

-- Receive impact effect from server
net.Receive("TDMRP_HomingImpact", function()
    local pos = net.ReadVector()
    
    -- Create impact visual effects
    TDMRP.Homing.CreateImpactEffect(pos)
end)

function TDMRP.Homing.CreateImpactEffect(pos)
    -- Red flash
    local dlight = DynamicLight(0)
    if dlight then
        dlight.pos = pos
        dlight.r = 255
        dlight.g = 50
        dlight.b = 50
        dlight.brightness = 2
        dlight.decay = 1500
        dlight.size = 100
        dlight.dietime = CurTime() + 0.2
    end
    
    -- Spark burst
    local emitter = ParticleEmitter(pos)
    if emitter then
        -- Red sparks
        for i = 1, 8 do
            local particle = emitter:Add("effects/spark", pos)
            if particle then
                particle:SetVelocity(VectorRand() * math.Rand(80, 200))
                particle:SetLifeTime(0)
                particle:SetDieTime(math.Rand(0.2, 0.4))
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(2, 4))
                particle:SetEndSize(0)
                particle:SetColor(255, 50, 50)
                particle:SetGravity(Vector(0, 0, -400))
                particle:SetCollide(true)
                particle:SetBounce(0.3)
            end
        end
        
        -- Small blood-like mist (to match grind_flesh sound)
        for i = 1, 4 do
            local particle = emitter:Add("particle/smokesprites_0001", pos)
            if particle then
                particle:SetVelocity(VectorRand() * math.Rand(30, 80))
                particle:SetLifeTime(0)
                particle:SetDieTime(math.Rand(0.3, 0.5))
                particle:SetStartAlpha(100)
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(8, 15))
                particle:SetEndSize(math.Rand(20, 30))
                particle:SetColor(150, 30, 30)
                particle:SetGravity(Vector(0, 0, -100))
            end
        end
        
        emitter:Finish()
    end
end

print("[TDMRP] cl_tdmrp_homing.lua loaded - Homing impact effects ready")
