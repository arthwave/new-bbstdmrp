-- Real Weapon Base Class
-- Base class for Counter-Strike Source weapons

if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Real Weapon Base"
SWEP.DrawCrosshair = true
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary = {}
SWEP.Primary.Damage = 20
SWEP.Primary.RPM = 600
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "pistol"
SWEP.Primary.Sound = Sound("weapons/pistol/pistol_fire1.wav")
SWEP.Primary.Spread = 0.02
SWEP.Primary.Recoil = 0.5
SWEP.Primary.Automatic = false

SWEP.Secondary = {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.IronFOV = 55

-- Iron sights positions (can be overridden by child weapons)
SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(0, 0, 0)
SWEP.SightsAng = Vector(0, 0, 0)

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType or "pistol")
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    
    local rpm = self.Primary.RPM or 600
    local damage = self.Primary.Damage or 20
    local spread = self.Primary.Spread or 0.02
    local numShots = self.Primary.NumShots or 1
    
    self:EmitSound(self.Primary.Sound)
    self:ShootBullet(damage, numShots, spread)
    self:TakePrimaryAmmo(1)
    self:SetNextPrimaryFire(CurTime() + (60 / rpm))
    
    -- Recoil
    if IsValid(self.Owner) and self.Owner:IsPlayer() then
        local recoil = self.Primary.Recoil or 0.5
        self.Owner:ViewPunch(Angle(-recoil, 0, 0))
    end
end

function SWEP:SecondaryAttack()
    -- Toggle iron sights
    if not IsValid(self.Owner) then return end
    
    local isADS = self:GetNWBool("M9K_Ironsights", false)
    
    if isADS then
        self.Owner:SetFOV(0, 0.3)
        self:SetNWBool("M9K_Ironsights", false)
    else
        local ironFOV = (self.Secondary and self.Secondary.IronFOV) or 55
        self.Owner:SetFOV(ironFOV, 0.3)
        self:SetNWBool("M9K_Ironsights", true)
    end
end

function SWEP:Reload()
    self:DefaultReload(ACT_VM_RELOAD)
end

function SWEP:ShootBullet(damage, numbullets, aimcone)
    if not IsValid(self.Owner) then return end
    
    local bullet = {}
    bullet.Num = numbullets or 1
    bullet.Src = self.Owner:GetShootPos()
    bullet.Dir = self.Owner:GetAimVector()
    bullet.Spread = Vector(aimcone, aimcone, 0)
    bullet.Tracer = 4
    bullet.Force = damage * 0.5
    bullet.Damage = damage
    bullet.AmmoType = self.Primary.Ammo or "pistol"
    
    self.Owner:FireBullets(bullet)
    
    -- Muzzle flash
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

-- Iron sights compatibility for TDMRP mixin
function SWEP:SetIronsights(b, ply)
    self:SetNWBool("M9K_Ironsights", b or false)
end

function SWEP:GetIronsights()
    return self:GetNWBool("M9K_Ironsights", false)
end
