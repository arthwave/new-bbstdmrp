-- Pump Shotgun (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Pump Shotgun"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 4
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_shot_m3super90.mdl"
SWEP.WorldModel = "models/weapons/w_shot_m3super90.mdl"
SWEP.HoldType = "shotgun"

SWEP.Primary.Sound = Sound("Weapon_M3.Single")
SWEP.Primary.Damage = 20
SWEP.Primary.RPM = 68
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Spread = 0.08
SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "buckshot"
SWEP.Primary.NumShots = 6

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.5, -12, 2.8)
SWEP.IronSightsAng = Vector(1.5, 0, 0)
SWEP.SightsPos = Vector(-5.5, -12, 2.8)
SWEP.SightsAng = Vector(1.5, 0, 0)

SWEP.TDMRP_ShortName = "Pump Shotgun"
SWEP.TDMRP_WeaponType = "shotgun"

-- Shell-by-shell reload for shotgun
SWEP.ReloadState = 0  -- 0 = not reloading, 1 = start, 2 = inserting, 3 = finish
SWEP.ReloadTime = 0

function SWEP:Reload()
    if self:Clip1() >= self.Primary.ClipSize then return end
    if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    if self.ReloadState ~= 0 then return end
    
    -- Start reload sequence
    self.ReloadState = 1
    self.ReloadTime = CurTime() + 0.5
    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
    self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:Think()
    -- Handle shell-by-shell reload
    if self.ReloadState == 1 and CurTime() >= self.ReloadTime then
        -- Start inserting shells
        self.ReloadState = 2
        self.ReloadTime = CurTime() + 0.45
        self:SendWeaponAnim(ACT_VM_RELOAD)
    elseif self.ReloadState == 2 and CurTime() >= self.ReloadTime then
        -- Insert a shell
        self:SetClip1(self:Clip1() + 1)
        self.Owner:RemoveAmmo(1, self.Primary.Ammo)
        
        -- Check if we need more shells
        if self:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            -- Insert another shell
            self.ReloadTime = CurTime() + 0.45
            self:SendWeaponAnim(ACT_VM_RELOAD)
        else
            -- Finish reload
            self.ReloadState = 3
            self.ReloadTime = CurTime() + 0.5
            self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
        end
    elseif self.ReloadState == 3 and CurTime() >= self.ReloadTime then
        -- Done reloading
        self.ReloadState = 0
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end
    
    -- Allow canceling reload with attack
    if self.ReloadState == 2 and self.Owner:KeyDown(IN_ATTACK) then
        self.ReloadState = 3
        self.ReloadTime = CurTime() + 0.5
        self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
    end
end

function SWEP:PrimaryAttack()
    -- Cancel reload if shooting
    if self.ReloadState ~= 0 then return end
    
    if not self:CanPrimaryAttack() then return end
    
    local rpm = self.Primary.RPM or 68
    local damage = self.Primary.Damage or 20
    local spread = self.Primary.Spread or 0.08
    local numShots = self.Primary.NumShots or 6
    
    self:EmitSound(self.Primary.Sound)
    self:ShootBullet(damage, numShots, spread)
    self:TakePrimaryAmmo(1)
    self:SetNextPrimaryFire(CurTime() + (60 / rpm))
    
    -- Recoil
    if IsValid(self.Owner) and self.Owner:IsPlayer() then
        local recoil = self.Primary.Recoil or 1.5
        self.Owner:ViewPunch(Angle(-recoil * 2, math.Rand(-0.5, 0.5), 0))
    end
    
    -- Play pump animation after a delay
    timer.Simple(0.5, function()
        if IsValid(self) then
            self:SendWeaponAnim(ACT_SHOTGUN_PUMP)
        end
    end)
end
