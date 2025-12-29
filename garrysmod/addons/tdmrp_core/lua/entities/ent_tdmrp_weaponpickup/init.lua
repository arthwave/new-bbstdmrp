-- init.lua

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

TDMRP = TDMRP or {}

function ENT:Initialize()
    -- The shop will set self.WeaponWorldModel before Spawn()
    self:SetModel(self.WeaponWorldModel or "models/weapons/w_rif_m4a1.mdl")

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:SetWeaponData(item)
    -- Called server-side when the shop/inventory creates this pickup.
    if not item or type(item) ~= "table" then return end

    -- store the class
    if item.class and item.class ~= "" then
        if self.SetWeaponClass then
            self:SetWeaponClass(item.class)
        else
            self.WeaponClass = item.class
        end
    end

    -- If an instance object is provided, persist it server-side and attach by id
    if item.instance and item.instance.id then
        TDMRP = TDMRP or {}
        TDMRP.WeaponInstances = TDMRP.WeaponInstances or {}
        TDMRP.WeaponInstances[item.instance.id] = item.instance
        self.TDMRP_InstanceID = item.instance.id
    end

    -- Also store Tier / CustomName / Prefix / Suffix as NW vars to help clients
    if item.tier then
        self:SetNWInt("TDMRP_Tier", item.tier)
    end
    if item.customName and item.customName ~= "" then
        self:SetNWString("TDMRP_CustomName", item.customName)
    end
    if item.prefix and item.prefix ~= "" then
        self:SetNWString("TDMRP_Prefix", item.prefix)
    end
    if item.suffix and item.suffix ~= "" then
        self:SetNWString("TDMRP_Suffix", item.suffix)
    end

    -- Optionally set world model if provided
    if item.worldModel and item.worldModel ~= "" then
        self:SetModel(item.worldModel)
    end
end


function ENT:Use(ply, caller)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local class = self.WeaponClass or (self.GetWeaponClass and self:GetWeaponClass()) or nil
    if not class or class == "" then return end

    -- 🔒 Don’t allow giving a second copy of the same class
    if ply:HasWeapon(class) then
        ply:ChatPrint("[TDMRP] You already have this weapon type equipped. Store or drop it first.")
        return
    end

    local wep = ply:Give(class)
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] Failed to equip weapon " .. tostring(class) .. ".")
        return
    end

    -- If there is a TDMRP instance attached to this pickup, apply it
    if self.TDMRP_InstanceID and TDMRP.GetWeaponInstance and TDMRP.ApplyInstanceToSWEP then
        local inst = TDMRP.GetWeaponInstance(self.TDMRP_InstanceID)
        if inst then
            TDMRP.ApplyInstanceToSWEP(wep, inst)
            wep.TDMRP_InstanceID = inst.id
        end
    else
        -- Fallback: if NW vars exist on the pickup, try to copy them to the weapon
        if wep.SetNWInt and self.GetNWInt then
            -- Set tier and lock it to prevent Equip() from resetting
            local tier = self:GetNWInt("TDMRP_Tier", 1)
            wep.Tier = tier
            wep.TDMRP_TierLocked = true
            
            -- Copy cosmetic data
            wep:SetNWInt("TDMRP_Tier", tier)
            wep:SetNWString("TDMRP_CustomName", self:GetNWString("TDMRP_CustomName", ""))
            wep:SetNWString("TDMRP_Prefix", self:GetNWString("TDMRP_Prefix", ""))
            wep:SetNWString("TDMRP_Suffix", self:GetNWString("TDMRP_Suffix", ""))
            
            -- Copy stat NW variables from pickup entity to weapon
            wep:SetNWInt("TDMRP_Damage",  self:GetNWInt("TDMRP_Damage", 0))
            wep:SetNWInt("TDMRP_RPM",     self:GetNWInt("TDMRP_RPM", 0))
            wep:SetNWInt("TDMRP_Recoil",  self:GetNWInt("TDMRP_Recoil", 0))
            wep:SetNWInt("TDMRP_Accuracy", self:GetNWInt("TDMRP_Accuracy", 0))
            
            -- Also update the weapon's Primary table for actual gameplay behavior
            if wep.Primary then
                local dmg = self:GetNWInt("TDMRP_Damage", 0)
                local rpm = self:GetNWInt("TDMRP_RPM", 0)
                local recoil = self:GetNWInt("TDMRP_Recoil", 0)
                local spread = self:GetNWInt("TDMRP_Accuracy", 0)
                
                if dmg > 0 then wep.Primary.Damage = dmg end
                if rpm > 0 then wep.Primary.Delay = 60 / rpm end
                if recoil >= 0 then wep.Primary.Recoil = recoil end
                if spread >= 0 then wep.Primary.Cone = spread end
            end
        end
    end

    ply:SelectWeapon(class)
    self:Remove()
end
