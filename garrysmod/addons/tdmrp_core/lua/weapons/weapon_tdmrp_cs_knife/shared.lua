-- Knife (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Knife"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 6
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.HoldType = "knife"

SWEP.Primary.Sound = Sound("Weapon_Knife.Slash")
SWEP.Primary.HitSound = Sound("Weapon_Knife.Hit")
SWEP.Primary.HitWorldSound = Sound("Weapon_Knife.HitWall")
SWEP.Primary.Damage = 40
SWEP.Primary.RPM = 120
SWEP.Primary.Recoil = 0
SWEP.Primary.Spread = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Damage = 65  -- Stab damage
SWEP.Secondary.IronFOV = 0  -- No ADS for knife

SWEP.TDMRP_ShortName = "Knife"
SWEP.TDMRP_WeaponType = "melee"

-- Override PrimaryAttack for melee swing
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + (60 / (self.Primary.RPM or 120)))
    
    self:SendWeaponAnim(ACT_VM_MISSCENTER)
    self:EmitSound(self.Primary.Sound)
    
    if not IsValid(self.Owner) then return end
    
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    
    -- Melee trace
    local tr = util.TraceLine({
        start = self.Owner:GetShootPos(),
        endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 75,
        filter = self.Owner,
        mask = MASK_SHOT_HULL
    })
    
    if tr.Hit then
        if tr.Entity and IsValid(tr.Entity) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(self.Primary.Damage)
            dmginfo:SetAttacker(self.Owner)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageType(DMG_SLASH)
            tr.Entity:TakeDamageInfo(dmginfo)
            self:EmitSound(self.Primary.HitSound)
        else
            self:EmitSound(self.Primary.HitWorldSound)
        end
        
        -- Hit effect
        local effect = EffectData()
        effect:SetStart(tr.StartPos)
        effect:SetOrigin(tr.HitPos)
        effect:SetNormal(tr.HitNormal)
        util.Effect("Impact", effect)
    end
end

-- Secondary attack is a stab (more damage, slower)
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1.0)
    self:SetNextPrimaryFire(CurTime() + 1.0)
    
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    self:EmitSound(self.Primary.Sound)
    
    if not IsValid(self.Owner) then return end
    
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    
    -- Melee trace (slightly longer range for stab)
    local tr = util.TraceLine({
        start = self.Owner:GetShootPos(),
        endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 85,
        filter = self.Owner,
        mask = MASK_SHOT_HULL
    })
    
    if tr.Hit then
        if tr.Entity and IsValid(tr.Entity) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(self.Secondary.Damage or 65)
            dmginfo:SetAttacker(self.Owner)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageType(DMG_SLASH)
            tr.Entity:TakeDamageInfo(dmginfo)
            self:EmitSound(self.Primary.HitSound)
        else
            self:EmitSound(self.Primary.HitWorldSound)
        end
    end
end
