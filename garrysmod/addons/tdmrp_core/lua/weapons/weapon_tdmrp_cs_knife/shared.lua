-- Knife (CS:S Wrapper) - Throwable
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Throwing Knife"
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

-- Secondary = Throwing knife (uses XBowBolt ammo)
SWEP.Secondary.Damage = 85  -- Thrown knife damage
SWEP.Secondary.IronFOV = 0  -- No ADS for knife
SWEP.Secondary.Ammo = "XBowBolt"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 5  -- Start with 5 throwing knives

SWEP.ThrowVelocity = 2000  -- How fast knives fly
SWEP.ThrowSound = Sound("weapons/knife/knife_slash1.wav")

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

-- Secondary attack throws a knife (consumes XBowBolt ammo)
function SWEP:SecondaryAttack()
    if not IsValid(self.Owner) then return end
    
    -- Check for throwing knife ammo
    local ammoCount = self.Owner:GetAmmoCount("XBowBolt")
    if ammoCount <= 0 then
        self:EmitSound("weapons/clipempty_pistol.wav")
        self:SetNextSecondaryFire(CurTime() + 0.5)
        return
    end
    
    self:SetNextSecondaryFire(CurTime() + 0.8)
    self:SetNextPrimaryFire(CurTime() + 0.8)
    
    -- Play throw animation
    self:SendWeaponAnim(ACT_VM_MISSCENTER2)
    self:EmitSound(self.ThrowSound)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    
    if SERVER then
        -- Consume ammo
        self.Owner:RemoveAmmo(1, "XBowBolt")
        
        -- Create thrown knife entity
        local knife = ents.Create("prop_physics")
        if not IsValid(knife) then return end
        
        knife:SetModel("models/weapons/w_knife_t.mdl")
        knife:SetPos(self.Owner:GetShootPos() + self.Owner:GetAimVector() * 20)
        knife:SetAngles(self.Owner:EyeAngles())
        knife:Spawn()
        knife:Activate()
        
        -- Set collision group to not hit owner initially
        knife:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        
        -- Throw it
        local phys = knife:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(self.Owner:GetAimVector() * self.ThrowVelocity)
            phys:AddAngleVelocity(Vector(0, 1500, 0))  -- Spin
        end
        
        -- Store owner and damage info
        knife.ThrownKnife = true
        knife.ThrownBy = self.Owner
        knife.KnifeDamage = self.Secondary.Damage or 85
        knife.SpawnTime = CurTime()
        
        -- Handle collision damage
        knife:AddCallback("PhysicsCollide", function(ent, data)
            if not ent.ThrownKnife then return end
            if CurTime() - ent.SpawnTime < 0.1 then return end  -- Grace period
            
            local hitEnt = data.HitEntity
            if IsValid(hitEnt) and hitEnt ~= ent.ThrownBy then
                if hitEnt:IsPlayer() or hitEnt:IsNPC() then
                    local dmginfo = DamageInfo()
                    dmginfo:SetDamage(ent.KnifeDamage)
                    dmginfo:SetAttacker(ent.ThrownBy or Entity(0))
                    dmginfo:SetInflictor(ent)
                    dmginfo:SetDamageType(DMG_SLASH)
                    dmginfo:SetDamagePosition(data.HitPos)
                    hitEnt:TakeDamageInfo(dmginfo)
                    
                    -- Play hit sound
                    ent:EmitSound("weapons/knife/knife_hitwall1.wav")
                end
            end
            
            -- Remove after a few seconds
            timer.Simple(5, function()
                if IsValid(ent) then
                    ent:Remove()
                end
            end)
        end)
        
        -- Safety remove
        timer.Simple(10, function()
            if IsValid(knife) then
                knife:Remove()
            end
        end)
    end
end

-- Give starting ammo on equip
function SWEP:Equip(newOwner)
    if SERVER and IsValid(newOwner) then
        -- Give starting throwing knives if they have none
        local currentAmmo = newOwner:GetAmmoCount("XBowBolt")
        if currentAmmo < 5 then
            newOwner:GiveAmmo(5 - currentAmmo, "XBowBolt", true)
        end
    end
end
