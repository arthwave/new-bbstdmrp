----------------------------------------------------
-- TDMRP CS:S Weapon Wrapper Base
-- Wraps CS:S weapons with TDMRP mixin system
-- Includes bullet callback integration for gemcraft suffixes
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

-- Inherit from our real weapon base
SWEP.Base = "weapon_real_base"
SWEP.IsTDMRPWeapon = true
SWEP.IsTDMRPCSSWeapon = true  -- Flag to identify CSS weapons for callback handling
SWEP.UseMixinSystem = true
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Tier = 1

-- Default stats for CSS weapons
SWEP.Primary.RPM = 600
SWEP.Primary.Damage = 25
SWEP.Primary.Spread = 0.02
SWEP.Primary.Recoil = 0.5
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

-- Hit number debounce for CSS weapons
local cssHitDebounce = {}

-- Store the current firing weapon for callback access
local currentFiringWeapon = nil
local currentBulletDamage = 0

----------------------------------------------------
-- TDMRP Bullet Callback for CSS Weapons
-- This replaces the basic HitImpact callback with TDMRP integration
-- Enables: hit numbers, headshot sounds, and gemcraft suffix effects
----------------------------------------------------
local function TDMRP_CSSBulletCallback(attacker, tr, dmginfo)
    -- Default hit effect
    local hit = EffectData()
    hit:SetOrigin(tr.HitPos)
    hit:SetNormal(tr.HitNormal)
    hit:SetScale(20)
    util.Effect("effect_hit", hit)
    
    if not SERVER then return true end
    
    -- Use stored weapon reference (more reliable than GetActiveWeapon during callback)
    local wep = currentFiringWeapon
    if not IsValid(wep) then
        wep = IsValid(attacker) and attacker:IsPlayer() and attacker:GetActiveWeapon()
    end
    if not IsValid(wep) then 
        print("[TDMRP CSS Callback] No valid weapon found!")
        return true 
    end
    
    -- DEBUG: Check suffix ID
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    print(string.format("[TDMRP CSS Callback] Weapon: %s | SuffixID: '%s' | Hit: %s", 
        wep:GetClass(), suffixId, IsValid(tr.Entity) and tr.Entity:GetClass() or "world"))
    
    -- Create proper dmginfo if not provided (FireBullets callback dmginfo can be incomplete)
    if not dmginfo or not dmginfo.GetDamage then
        dmginfo = DamageInfo()
        dmginfo:SetDamage(currentBulletDamage or wep.Primary.Damage or 25)
        dmginfo:SetAttacker(attacker)
        dmginfo:SetInflictor(wep)
        dmginfo:SetDamageType(DMG_BULLET)
    end
    
    -- Run TDMRP modifier hooks (OnBulletHit for gemcraft suffixes like chain lightning)
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.RunModifierHook then
        print("[TDMRP CSS Callback] Calling RunModifierHook(OnBulletHit)")
        TDMRP_WeaponMixin.RunModifierHook(wep, "OnBulletHit", tr, dmginfo)
    else
        print("[TDMRP CSS Callback] ERROR: TDMRP_WeaponMixin.RunModifierHook not found!")
    end
    
    -- Send hit number to attacker
    local target = tr.Entity
    if IsValid(target) and (target:IsPlayer() or target:IsNPC()) and target ~= attacker then
        local dmg = dmginfo:GetDamage()
        if dmg > 0 then
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
                
                -- Check if killing blow
                local willKill = (target:Health() - dmg) <= 0
                
                -- Check for quad damage buff
                local isQuadDamage = false
                local displayDamage = dmg
                if TDMRP and TDMRP.ActiveSkills and TDMRP.ActiveSkills.ActiveBuffs then
                    local buff = TDMRP.ActiveSkills.ActiveBuffs[attacker]
                    if buff and buff.skill == "quaddamage" and CurTime() < buff.endTime then
                        isQuadDamage = true
                        displayDamage = math.ceil(dmg * 4)
                    end
                end
                
                -- Send hit number via net
                net.Start("TDMRP_HitNumber")
                    net.WriteVector(hitPos)
                    net.WriteUInt(math.min(math.Round(displayDamage), 65535), 16)
                    net.WriteBool(isHeadshot)
                    net.WriteBool(willKill)
                    net.WriteBool(isQuadDamage)
                net.Send(attacker)
                
                -- Play headshot kill sound in area radius (if killing headshot)
                if isHeadshot and willKill then
                    sound.Play("tdmrp/headshot.wav", hitPos, 80, 100, 1)
                end
            end
        end
    end
    
    return true
end

-- Flag to prevent recursion
local initializingWeapon = {}

function SWEP:Initialize()
    -- Prevent stack overflow from recursive calls
    local id = tostring(self)
    if initializingWeapon[id] then return end
    initializingWeapon[id] = true
    
    -- Set weapon hold type (this is all weapon_real_base does in Initialize)
    self:SetWeaponHoldType(self.HoldType or "pistol")
    
    -- Apply TDMRP mixin system for tier scaling
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
    
    initializingWeapon[id] = nil
end

----------------------------------------------------
-- Override CSShootBullet to use TDMRP callback
-- This enables gemcraft suffixes (chain lightning, etc.) on CSS weapons
----------------------------------------------------
function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
    numbul = numbul or 1
    cone = cone or 0.01
    
    -- Store weapon reference and damage for callback access
    currentFiringWeapon = self
    currentBulletDamage = dmg
    
    local bullet = {}
    bullet.Num = numbul
    bullet.Src = self.Owner:GetShootPos()
    bullet.Dir = self.Owner:GetAimVector()
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 1
    bullet.Force = 0.5 * dmg
    bullet.Damage = dmg
    bullet.Callback = TDMRP_CSSBulletCallback  -- Use TDMRP callback instead of HitImpact
    
    self.Owner:FireBullets(bullet)
    
    -- Clear weapon reference after firing
    currentFiringWeapon = nil
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:MuzzleFlash()
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    
    -- Muzzle effect
    local fx = EffectData()
    fx:SetEntity(self.Weapon)
    fx:SetOrigin(self.Owner:GetShootPos())
    fx:SetNormal(self.Owner:GetAimVector())
    fx:SetAttachment(self.MuzzleAttachment or "1")
    util.Effect(self.MuzzleEffect or "rg_muzzle_rifle", fx)
    
    -- Shell eject effect
    timer.Simple(self.EjectDelay or 0, function()
        if not IsFirstTimePredicted() then return end
        
        local sfx = EffectData()
        sfx:SetEntity(self.Weapon)
        if not IsValid(self.Owner) then return end
        sfx:SetNormal(self.Owner:GetAimVector())
        sfx:SetAttachment(self.ShellEjectAttachment or "2")
        util.Effect(self.ShellEffect or "rg_shelleject", sfx)
    end)
    
    -- Eye angle recoil
    if (game.SinglePlayer() and SERVER) or (not game.SinglePlayer() and CLIENT) then
        local eyeang = self.Owner:EyeAngles()
        eyeang.pitch = eyeang.pitch - recoil
        self.Owner:SetEyeAngles(eyeang)
    end
    
    -- Trigger OnBulletFired hook for gemcraft prefixes
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.RunModifierHook then
        TDMRP_WeaponMixin.RunModifierHook(self, "OnBulletFired")
    end
end

local deployingWeapon = {}

function SWEP:Deploy()
    -- Prevent stack overflow from recursive calls
    local id = tostring(self)
    if deployingWeapon[id] then return true end
    deployingWeapon[id] = true
    
    -- Call base Deploy
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
    self.Reloadaftershoot = CurTime() + 1
    self:SetIronsights(false)
    self.Weapon:SetNextPrimaryFire(CurTime() + 1)
    
    -- Set networked stats for HUD
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
        TDMRP_WeaponMixin.SetNetworkedStats(self)
    end
    
    deployingWeapon[id] = nil
    return true
end

local equippingWeapon = {}

function SWEP:Equip(newOwner)
    -- Prevent stack overflow from recursive calls  
    local id = tostring(self)
    if equippingWeapon[id] then return end
    equippingWeapon[id] = true
    
    -- Reapply mixin on equip
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
    
    equippingWeapon[id] = nil
end

function SWEP:SetTier(newTier)
    if not SERVER then return end
    newTier = math.Clamp(newTier or 1, 1, 4)
    self.Tier = newTier
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
end

function SWEP:GetTier()
    return self.Tier or 1
end
