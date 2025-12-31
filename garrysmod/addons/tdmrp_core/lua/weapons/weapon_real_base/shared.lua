----------------------------------------------------
-- TDMRP Real Weapon Base (CSS Weapons)
-- Self-contained base for CS:S weapons with TDMRP integration
-- Copied and adapted from bob weapons reference (NOT runtime dependency)
-- Includes: RecoilPower, CSShootBullet, IronSights, TDMRP hooks
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

print("[TDMRP] Loading weapon_real_base...")

----------------------------------------------------
-- TDMRP Bullet Callback
-- Integrates hit numbers, headshot sounds, and gemcraft suffix effects
----------------------------------------------------
local cssHitDebounce = {}

local function TDMRP_HitImpact(attacker, tr, dmginfo)
    -- Default hit effect
    local hit = EffectData()
    hit:SetOrigin(tr.HitPos)
    hit:SetNormal(tr.HitNormal)
    hit:SetScale(20)
    util.Effect("effect_hit", hit)
    
    if not SERVER then return true end
    
    -- Get the weapon
    local wep = IsValid(attacker) and attacker:IsPlayer() and attacker:GetActiveWeapon()
    if not IsValid(wep) then return true end
    
    -- Run TDMRP modifier hooks (OnBulletHit for gemcraft suffixes like chain lightning)
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.RunModifierHook then
        TDMRP_WeaponMixin.RunModifierHook(wep, "OnBulletHit", tr, dmginfo)
    end
    
    -- Send hit number to attacker
    local target = tr.Entity
    if IsValid(target) and (target:IsPlayer() or target:IsNPC()) and target ~= attacker then
        -- Get base damage from weapon (dmginfo may be nil in bullet callback)
        local baseDmg = wep.Primary and wep.Primary.Damage or 25
        
        -- Check for quad damage buff FIRST (before calculating final damage)
        local isQuadDamage = false
        if TDMRP and TDMRP.ActiveSkills and TDMRP.ActiveSkills.ActiveBuffs then
            local buff = TDMRP.ActiveSkills.ActiveBuffs[attacker]
            if buff and buff.skill == "quaddamage" and CurTime() < buff.endTime then
                isQuadDamage = true
            end
        end
        
        -- Calculate display damage (quad applies 4x multiplier)
        local displayDamage = isQuadDamage and math.ceil(baseDmg * 4) or baseDmg
        
        if displayDamage > 0 then
            -- Debounce: only send one hit number per 0.1s per attacker-target combo
            local key = attacker:SteamID64() .. "_" .. target:EntIndex()
            local now = CurTime()
            local lastTime = cssHitDebounce[key] or 0
            
            if now - lastTime > 0.1 then
                cssHitDebounce[key] = now
                
                local hitPos = tr.HitPos or target:GetPos() + target:OBBCenter()
                
                -- Check if headshot
                local isHeadshot = false
                if tr.HitGroup == HITGROUP_HEAD then
                    isHeadshot = true
                end
                
                -- Fallback to bone distance for NPCs
                if not isHeadshot and hitPos then
                    local headBone = target:LookupBone("ValveBiped.Bip01_Head1")
                    if headBone then
                        local headPos = target:GetBonePosition(headBone)
                        if headPos then
                            isHeadshot = (headPos:Distance(hitPos) < 8.5)
                        end
                    end
                end
                
                -- Headshot multiplier for display (2x for CSS weapons)
                if isHeadshot then
                    displayDamage = displayDamage * 2
                end
                
                -- Check if killing blow (use actual damage being applied)
                local actualDamage = isQuadDamage and (baseDmg * 4) or baseDmg
                if isHeadshot then actualDamage = actualDamage * 2 end
                local willKill = (target:Health() - actualDamage) <= 0
                
                -- Send hit number via net (if network string exists)
                if util.NetworkStringToID("TDMRP_HitNumber") ~= 0 then
                    net.Start("TDMRP_HitNumber")
                        net.WriteVector(hitPos)
                        net.WriteUInt(math.min(math.Round(displayDamage), 65535), 16)
                        net.WriteBool(isHeadshot)
                        net.WriteBool(willKill)
                        net.WriteBool(isQuadDamage)
                    net.Send(attacker)
                    
                    -- Debug print for CSS hit numbers
                    print(string.format("[TDMRP CSS] Hit number sent: %d dmg, headshot=%s, quad=%s", 
                        displayDamage, tostring(isHeadshot), tostring(isQuadDamage)))
                end
                
                -- Play headshot kill sound in area radius
                if isHeadshot and willKill then
                    sound.Play("tdmrp/headshot.wav", hitPos, 80, 100, 1)
                end
            end
        end
    end
    
    return true
end

----------------------------------------------------
-- SWEP Base Definition
----------------------------------------------------

SWEP.Base = "weapon_base"
SWEP.PrintName = "Real Weapon Base"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

-- TDMRP Flags
SWEP.IsTDMRPWeapon = true
SWEP.IsTDMRPCSSWeapon = true
SWEP.UseMixinSystem = true
SWEP.Tier = 1

-- Viewmodel settings
SWEP.UseHands = true
SWEP.ViewModelFOV = 60
SWEP.DrawCrosshair = false
SWEP.CSMuzzleFlashes = false

-- Effects
SWEP.MuzzleEffect = "rg_muzzle_rifle"
SWEP.ShellEffect = "rg_shelleject"
SWEP.MuzzleAttachment = "1"
SWEP.ShellEjectAttachment = "2"
SWEP.EjectDelay = 0

-- Weapon settings
SWEP.HoldType = "pistol"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.SwayScale = 0

-- Primary fire settings
SWEP.Primary = {}
SWEP.Primary.Sound = Sound("Weapon_AK47.Single")
SWEP.Primary.Recoil = 0.5
SWEP.Primary.Damage = 25
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 30
SWEP.Primary.Delay = 0.1
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"
SWEP.Primary.RPM = 600
SWEP.Primary.Spread = 0.02

-- Secondary settings
SWEP.Secondary = {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.IronFOV = 65

-- Fire modes
SWEP.mode = "semi"

-- Iron sights positions
SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(0, 0, 0)
SWEP.SightsAng = Vector(0, 0, 0)

----------------------------------------------------
-- Initialize
----------------------------------------------------
function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "pistol")
    self.Reloadaftershoot = 0
    
    -- Apply TDMRP mixin if available
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
end

----------------------------------------------------
-- Deploy
----------------------------------------------------
function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self.Reloadaftershoot = CurTime() + 1
    self:SetIronsights(false)
    self:SetNextPrimaryFire(CurTime() + 1)
    return true
end

----------------------------------------------------
-- Reload
----------------------------------------------------
function SWEP:Reload()
    if self.Reloadaftershoot > CurTime() then return end
    
    self:DefaultReload(ACT_VM_RELOAD)
    
    if self:Clip1() < self.Primary.ClipSize and IsValid(self.Owner) and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
        if IsValid(self.Owner) then
            self.Owner:SetFOV(0, 0.15)
        end
        self:SetIronsights(false)
    end
end

----------------------------------------------------
-- Think - Handle iron sights
----------------------------------------------------
function SWEP:Think()
    self:IronSight()
end

----------------------------------------------------
-- IronSight Toggle
----------------------------------------------------
function SWEP:IronSight()
    if not IsValid(self.Owner) then return end
    
    if not self.Owner:KeyDown(IN_USE) then
        if self.Owner:KeyPressed(IN_ATTACK2) then
            self.Owner:SetFOV(self.Secondary.IronFOV or 65, 0.15)
            self:SetIronsights(true, self.Owner)
            if CLIENT then return end
        end
    end
    
    if self.Owner:KeyReleased(IN_ATTACK2) then
        self.Owner:SetFOV(0, 0.15)
        self:SetIronsights(false, self.Owner)
        if CLIENT then return end
    end
end

----------------------------------------------------
-- PrimaryAttack
----------------------------------------------------
function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    if not IsValid(self.Owner) then return end
    if self.Owner:WaterLevel() > 2 then return end
    
    -- Run suffix OnPreFire hook (for Doubleshot flag, etc)
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.RunModifierHook then
        TDMRP_WeaponMixin.RunModifierHook(self, "OnPreFire")
    end
    
    local delay = self.Primary.Delay
    if not delay or delay <= 0 then
        delay = 60 / (self.Primary.RPM or 600)
    end
    
    self.Reloadaftershoot = CurTime() + delay
    self:SetNextSecondaryFire(CurTime() + delay)
    self:SetNextPrimaryFire(CurTime() + delay)
    
    self:EmitSound(self.Primary.Sound)
    self:RecoilPower()
    self:TakePrimaryAmmo(1)
    
    if (game.SinglePlayer() and SERVER) or CLIENT then
        self:SetNWFloat("LastShootTime", CurTime())
    end
end

----------------------------------------------------
-- CanPrimaryAttack
----------------------------------------------------
function SWEP:CanPrimaryAttack()
    if self:Clip1() <= 0 and self.Primary.ClipSize > -1 then
        self:SetNextPrimaryFire(CurTime() + 0.5)
        self:EmitSound("Weapons/ClipEmpty_Pistol.wav")
        return false
    end
    return true
end

----------------------------------------------------
-- RecoilPower - Determines accuracy based on movement/stance
-- Now integrates with TDMRP.Accuracy system for consistent penalties
----------------------------------------------------
function SWEP:RecoilPower()
    if not IsValid(self.Owner) then return end
    
    local dmg = self.Primary.Damage or 25
    local recoil = self.Primary.Recoil or 0.5
    local numShots = self.Primary.NumShots or 1
    local cone = self.Primary.Cone or self.Primary.Spread or 0.02
    
    -- Apply TDMRP accuracy system if available
    if TDMRP and TDMRP.Accuracy and TDMRP.Accuracy.GetCurrentSpread then
        cone = TDMRP.Accuracy.GetCurrentSpread(self.Owner, self)
    end
    
    if not self.Owner:IsOnGround() then
        -- In air
        if self:GetIronsights() then
            self:CSShootBullet(dmg, recoil, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * recoil, math.Rand(-1, 1) * recoil, 0))
        else
            self:CSShootBullet(dmg, recoil * 2.5, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (recoil * 2.5), math.Rand(-1, 1) * (recoil * 2.5), 0))
        end
    elseif self.Owner:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)) then
        -- Moving (spread already adjusted by accuracy system)
        if self:GetIronsights() then
            self:CSShootBullet(dmg, recoil / 2, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (recoil / 1.5), math.Rand(-1, 1) * (recoil / 1.5), 0))
        else
            self:CSShootBullet(dmg, recoil * 1.5, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (recoil * 1.5), math.Rand(-1, 1) * (recoil * 1.5), 0))
        end
    elseif self.Owner:Crouching() then
        -- Crouching
        if self:GetIronsights() then
            self:CSShootBullet(dmg, 0, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (recoil / 3), math.Rand(-1, 1) * (recoil / 3), 0))
        else
            self:CSShootBullet(dmg, recoil / 2, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (recoil / 2), math.Rand(-1, 1) * (recoil / 2), 0))
        end
    else
        -- Standing still
        if self:GetIronsights() then
            self:CSShootBullet(dmg, recoil / 6, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (recoil / 2), math.Rand(-1, 1) * (recoil / 2), 0))
        else
            self:CSShootBullet(dmg, recoil, numShots, cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * recoil, math.Rand(-1, 1) * recoil, 0))
        end
    end
end

----------------------------------------------------
-- CSShootBullet - Fire bullets with TDMRP callback
----------------------------------------------------
function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
    if not IsValid(self.Owner) then return end
    
    numbul = numbul or 1
    cone = cone or 0.01
    
    -- Check for Doubleshot suffix - if flag set, double the bullets
    if self.TDMRP_DoubleShotNextFire then
        numbul = numbul * 2
    end
    
    local bullet = {}
    bullet.Num = numbul
    bullet.Src = self.Owner:GetShootPos()
    bullet.Dir = self.Owner:GetAimVector()
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 1
    bullet.Force = 0.5 * dmg
    bullet.Damage = dmg
    bullet.Callback = TDMRP_HitImpact  -- TDMRP integrated callback
    
    self.Owner:FireBullets(bullet)
    
    -- Run suffix OnBulletFired hook (for tracers, etc)
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.RunModifierHook then
        TDMRP_WeaponMixin.RunModifierHook(self, "OnBulletFired", {
            numBullets = numbul,
            damage = dmg,
            spread = cone
        })
    end
    
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:MuzzleFlash()
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    
    -- Muzzle effect
    local fx = EffectData()
    fx:SetEntity(self)
    fx:SetOrigin(self.Owner:GetShootPos())
    fx:SetNormal(self.Owner:GetAimVector())
    fx:SetAttachment(tonumber(self.MuzzleAttachment) or 1)
    util.Effect(self.MuzzleEffect or "rg_muzzle_rifle", fx)
    
    -- Shell ejection
    local wep = self
    timer.Simple(self.EjectDelay or 0, function()
        if not IsFirstTimePredicted() then return end
        if not IsValid(wep) or not IsValid(wep.Owner) then return end
        
        local shellFx = EffectData()
        shellFx:SetEntity(wep)
        shellFx:SetNormal(wep.Owner:GetAimVector())
        shellFx:SetAttachment(tonumber(wep.ShellEjectAttachment) or 2)
        util.Effect(wep.ShellEffect or "rg_shelleject", shellFx)
    end)
    
    -- Recoil
    if (game.SinglePlayer() and SERVER) or (not game.SinglePlayer() and CLIENT) then
        local eyeang = self.Owner:EyeAngles()
        eyeang.pitch = eyeang.pitch - recoil
        self.Owner:SetEyeAngles(eyeang)
    end
end

----------------------------------------------------
-- Iron Sights Functions
----------------------------------------------------
function SWEP:SetIronsights(b, ply)
    self:SetNWBool("Ironsights", b or false)
end

function SWEP:GetIronsights()
    return self:GetNWBool("Ironsights", false)
end

----------------------------------------------------
-- GetViewModelPosition - Iron sights view offset
----------------------------------------------------
local IRONSIGHT_TIME = 0.15

function SWEP:GetViewModelPosition(pos, ang)
    if SERVER then return pos, ang end
    if not self.IronSightsPos then return pos, ang end
    
    local bIron = self:GetNWBool("Ironsights")
    
    if bIron ~= self.bLastIron then
        self.bLastIron = bIron
        self.fIronTime = CurTime()
        
        if bIron then
            self.SwayScale = 0.3
            self.BobScale = 0.1
        else
            self.SwayScale = 1.0
            self.BobScale = 1.0
        end
    end
    
    local fIronTime = self.fIronTime or 0
    
    if not bIron and fIronTime < CurTime() - IRONSIGHT_TIME then
        return pos, ang
    end
    
    local Mul = 1.0
    
    if fIronTime > CurTime() - IRONSIGHT_TIME then
        Mul = math.Clamp((CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1)
        if not bIron then Mul = 1 - Mul end
    end
    
    local Offset = self.IronSightsPos
    
    if self.IronSightsAng then
        ang = ang * 1
        ang:RotateAroundAxis(ang:Right(), self.IronSightsAng.x * Mul)
        ang:RotateAroundAxis(ang:Up(), self.IronSightsAng.y * Mul)
        ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z * Mul)
    end
    
    local Right = ang:Right()
    local Up = ang:Up()
    local Forward = ang:Forward()
    
    pos = pos + Offset.x * Right * Mul
    pos = pos + Offset.y * Forward * Mul
    pos = pos + Offset.z * Up * Mul
    
    return pos, ang
end

----------------------------------------------------
-- SecondaryAttack (empty - handled by Think/IronSight)
----------------------------------------------------
function SWEP:SecondaryAttack()
    -- Iron sights handled in Think
end

print("[TDMRP] weapon_real_base loaded - Self-contained CSS weapon base with TDMRP integration")
