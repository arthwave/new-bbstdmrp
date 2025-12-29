-- entities/tdmrp_loot_orb/init.lua

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

-- Colors for visuals
local LootColors = {
    money          = Color(255, 215,   0), -- gold
    gem_blood_ruby = Color(255,  50,  50),
    gem_blood_sapphire = Color( 80, 160, 255),
    gem_blood_emerald  = Color( 80, 220, 120),
    gem_blood_amethyst = Color(180,  80, 255),
    gem_blood_diamond  = Color(120, 255, 255),
    scrap         = Color(210, 210, 210),  -- silver
    weapon        = Color(255, 128, 0),
}

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetModelScale(0.4, 0)
    self:PhysicsInit(SOLID_NONE)
    self:SetMoveType(MOVETYPE_FLY)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    self.DieTime    = CurTime() + 4
    self.Target     = nil
    self.LootType   = self.LootType   or "money"
    self.LootSub    = self.LootSub    or ""
    self.Amount     = self.Amount     or 0
    self.HasGranted = false

    -- Network type for client visuals
    self:SetNWString("TDMRP_LootType", self.LootType)
    self:SetNWString("TDMRP_LootSub",  self.LootSub)

    local key = self.LootType
    if self.LootType == "gem" then
        key = "gem_" .. (self.LootSub or "")
    end

    local col = LootColors[key] or Color(255, 255, 255)
    self:SetColor(col)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)

    -- Trail (wispy)
    util.SpriteTrail(self, 0, col, false,
        8,   -- start width
        0,   -- end width
        0.8, -- lifetime
        1 / 12,
        "trails/laser.vmt"
    )
end

-- Called right after we spawn it, from serverside spawner
function ENT:SetupLoot(target, lootType, lootSub, amount)
    self.Target   = target
    self.LootType = lootType or "money"
    self.LootSub  = lootSub or ""
    self.Amount   = amount or 0
end

local function GrantLoot(ent)
    if ent.HasGranted then return end
    ent.HasGranted = true

    local ply = ent.Target
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if ent.LootType == "money" then
        if ply.addMoney then
            ply:addMoney(ent.Amount or 0)
        end
        ply:ChatPrint(string.format("[TDMRP] You gained $%d.", ent.Amount or 0))

    elseif ent.LootType == "gem" then
        if TDMRP_AddGem then
            TDMRP_AddGem(ply, ent.LootSub, 1)
        end
        ply:ChatPrint(string.format("[TDMRP] You obtained 1x %s.", ent.LootSub or "gem"))

    elseif ent.LootType == "scrap" then
        if TDMRP_AddScrap then
            TDMRP_AddScrap(ply, ent.Amount or 1)
        end
        ply:ChatPrint(string.format("[TDMRP] You obtained %dx scrap.", ent.Amount or 1))

    elseif ent.LootType == "weapon" then
        -- Weapon drops: store directly into TDMRP inventory
        if not TDMRP_AddItem then return end

        local wepClass = ent.LootSub
        local tierID   = ent.Amount or 2

        if not wepClass or wepClass == "" then return end

        local item = {
            kind        = "weapon",
            class       = wepClass,
            tier        = tierID,   -- 2/3/5 from TDMRP_RollDropTier
            stats       = {},       -- we can fill this when we implement stat rolls
            cosmetic    = {},
            bound_until = 0,
        }

        local id = TDMRP_AddItem(ply, item)
        if id then
            ply:ChatPrint(string.format(
                "[TDMRP] Weapon drop stored (#%d): %s (Tier %d).",
                id, wepClass, tierID
            ))
        end
    end
end

function ENT:Think()
    if not self.Target then
        if CurTime() >= (self.DieTime or 0) then
            self:Remove()
        end
        self:NextThink(CurTime() + 0.05)
        return true
    end

    if CurTime() >= (self.DieTime or 0) then
        -- Failsafe: award even if distance never closed
        GrantLoot(self)
        self:Remove()
        return
    end

    if IsValid(self.Target) then
        local targetPos = self.Target:EyePos()
        local pos       = self:GetPos()
        local dir       = (targetPos - pos)
        local dist      = dir:Length()

        if dist < 20 then
            GrantLoot(self)
            self:Remove()
            return
        end

        dir:Normalize()
        local speed = 25
        self:SetVelocity(dir * speed)
    end

    self:NextThink(CurTime())
    return true
end
