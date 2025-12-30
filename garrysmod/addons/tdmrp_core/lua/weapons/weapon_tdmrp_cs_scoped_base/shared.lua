----------------------------------------------------
-- TDMRP CS:S Scoped Weapon Base
-- Base class for scoped CSS weapons (snipers, AUG, SG552)
-- Scope rendering ported from weapon_real_base_snip
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

-- Inherit from our CSS weapon base
SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.IsTDMRPWeapon = true
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

-- Scope defaults
SWEP.UseScope = true
SWEP.ScopeZooms = {4}
SWEP.ScopeScale = 0.4
SWEP.IronSightZoom = 1.3
SWEP.DrawParabolicSights = false

-- Scope state
SWEP.CurScopeZoom = 1

-- Recursion guard for Initialize
local initializingScopedWeapon = {}

----------------------------------------------------
-- Initialize scope tables on client
----------------------------------------------------
function SWEP:Initialize()
    -- Prevent stack overflow from recursive calls
    local id = tostring(self)
    if initializingScopedWeapon[id] then return end
    initializingScopedWeapon[id] = true
    
    -- Set weapon hold type
    self:SetWeaponHoldType(self.HoldType or "ar2")
    
    -- Apply TDMRP mixin system for tier scaling
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
    
    -- Set up scope tables on client
    if CLIENT and self.UseScope then
        self:InitScopeTables()
    end
    
    initializingScopedWeapon[id] = nil
end

function SWEP:InitScopeTables()
    local iScreenWidth = ScrW()
    local iScreenHeight = ScrH()
    
    -- Calculate scope geometry based on ScopeScale (same as weapon_real_base_snip)
    self.ScopeTable = {}
    self.ScopeTable.l = iScreenHeight * self.ScopeScale
    self.ScopeTable.x1 = 0.5 * (iScreenWidth + self.ScopeTable.l)
    self.ScopeTable.y1 = 0.5 * (iScreenHeight - self.ScopeTable.l)
    self.ScopeTable.x2 = self.ScopeTable.x1
    self.ScopeTable.y2 = 0.5 * (iScreenHeight + self.ScopeTable.l)
    self.ScopeTable.x3 = 0.5 * (iScreenWidth - self.ScopeTable.l)
    self.ScopeTable.y3 = self.ScopeTable.y2
    self.ScopeTable.x4 = self.ScopeTable.x3
    self.ScopeTable.y4 = self.ScopeTable.y1
    
    -- Fix for proper scope size
    self.ScopeTable.l = (iScreenHeight + 1) * self.ScopeScale
    
    -- Quad tables for filling corners
    self.QuadTable = {}
    self.QuadTable.x1 = 0
    self.QuadTable.y1 = 0
    self.QuadTable.w1 = iScreenWidth
    self.QuadTable.h1 = 0.5 * iScreenHeight - self.ScopeTable.l
    self.QuadTable.x2 = 0
    self.QuadTable.y2 = 0.5 * iScreenHeight + self.ScopeTable.l
    self.QuadTable.w2 = self.QuadTable.w1
    self.QuadTable.h2 = self.QuadTable.h1
    self.QuadTable.x3 = 0
    self.QuadTable.y3 = 0
    self.QuadTable.w3 = 0.5 * iScreenWidth - self.ScopeTable.l
    self.QuadTable.h3 = iScreenHeight
    self.QuadTable.x4 = 0.5 * iScreenWidth + self.ScopeTable.l
    self.QuadTable.y4 = 0
    self.QuadTable.w4 = self.QuadTable.w3
    self.QuadTable.h4 = self.QuadTable.h3
    
    -- Lens table for scope texture position
    self.LensTable = {}
    self.LensTable.x = self.QuadTable.w3
    self.LensTable.y = self.QuadTable.h1
    self.LensTable.w = 2 * self.ScopeTable.l
    self.LensTable.h = 2 * self.ScopeTable.l
    
    -- Crosshair table
    self.CrossHairTable = {}
    self.CrossHairTable.x11 = 0
    self.CrossHairTable.y11 = 0.5 * iScreenHeight
    self.CrossHairTable.x12 = iScreenWidth
    self.CrossHairTable.y12 = self.CrossHairTable.y11
    self.CrossHairTable.x21 = 0.5 * iScreenWidth
    self.CrossHairTable.y21 = 0
    self.CrossHairTable.x22 = 0.5 * iScreenWidth
    self.CrossHairTable.y22 = iScreenHeight
end

----------------------------------------------------
-- Scope toggle on secondary attack
----------------------------------------------------
function SWEP:SecondaryAttack()
    if not IsValid(self.Owner) then return end
    
    local bScope = self:GetNWBool("Scope", false)
    
    if self.UseScope then
        if bScope then
            -- Cycle through zoom levels or exit scope
            local numZooms = #(self.ScopeZooms or {4})
            self.CurScopeZoom = (self.CurScopeZoom or 1) + 1
            
            if self.CurScopeZoom > numZooms then
                -- Exit scope
                self:SetNWBool("Scope", false)
                self:SetNWBool("M9K_Ironsights", false)
                self:SetNWFloat("ScopeZoom", 1)
                self.CurScopeZoom = 1
                self.Owner:SetFOV(0, 0.2)
            else
                -- Next zoom level
                local newZoom = self.ScopeZooms[self.CurScopeZoom]
                self:SetNWFloat("ScopeZoom", newZoom)
                self.Owner:SetFOV(75 / newZoom, 0.1)
            end
        else
            -- Enter scope
            self:SetNWBool("Scope", true)
            self:SetNWBool("M9K_Ironsights", true)
            self.CurScopeZoom = 1
            local zoom = self.ScopeZooms[1] or 4
            self:SetNWFloat("ScopeZoom", zoom)
            self.Owner:SetFOV(75 / zoom, 0.2)
        end
        
        self:EmitSound("weapons/zoom.wav", 50, 100)
    else
        -- Fallback to iron sights
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
    
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

----------------------------------------------------
-- Reset scope on holster
----------------------------------------------------
function SWEP:Holster(wep)
    if IsValid(self.Owner) then
        self.Owner:SetFOV(0, 0)
    end
    self:SetNWBool("Scope", false)
    self:SetNWBool("M9K_Ironsights", false)
    self:SetNWFloat("ScopeZoom", 1)
    self.CurScopeZoom = 1
    return true
end

----------------------------------------------------
-- Reset scope on death/drop
----------------------------------------------------
function SWEP:OnDrop()
    if IsValid(self.Owner) then
        self.Owner:SetFOV(0, 0)
    end
    self:SetNWBool("Scope", false)
    self:SetNWBool("M9K_Ironsights", false)
    self:SetNWFloat("ScopeZoom", 1)
    self.CurScopeZoom = 1
end

----------------------------------------------------
-- Draw scope overlay on client (ported from weapon_real_base_snip)
----------------------------------------------------
if CLIENT then
    local SCOPEFADE_TIME = 0.4
    
    function SWEP:DrawHUD()
        if not self.UseScope then return end
        
        -- Ensure scope tables are initialized
        if not self.LensTable then
            self:InitScopeTables()
        end
        
        local bScope = self:GetNWBool("Scope", false)
        
        -- Handle scope fade effect
        if bScope ~= self.bLastScope then
            self.bLastScope = bScope
            self.fScopeTime = CurTime()
        elseif bScope then
            local fScopeZoom = self:GetNWFloat("ScopeZoom", 1)
            if fScopeZoom ~= self.fLastScopeZoom then
                self.fLastScopeZoom = fScopeZoom
                self.fScopeTime = CurTime()
            end
        end
        
        local fScopeTime = self.fScopeTime or 0
        
        -- Draw fade-in/out black overlay
        if fScopeTime > CurTime() - SCOPEFADE_TIME then
            local Mul = 1 - math.Clamp((CurTime() - fScopeTime) / SCOPEFADE_TIME, 0, 1)
            surface.SetDrawColor(0, 0, 0, 255 * Mul)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end
        
        if bScope then
            -- Draw crosshairs
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawLine(self.CrossHairTable.x11, self.CrossHairTable.y11, self.CrossHairTable.x12, self.CrossHairTable.y12)
            surface.DrawLine(self.CrossHairTable.x21, self.CrossHairTable.y21, self.CrossHairTable.x22, self.CrossHairTable.y22)
            
            -- Draw scope lens texture
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/scope_normal"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
            
            -- Fill in black borders (top, bottom, left, right quads)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(self.QuadTable.x1 - 2.5, self.QuadTable.y1 - 2.5, self.QuadTable.w1 + 5, self.QuadTable.h1 + 5)
            surface.DrawRect(self.QuadTable.x2 - 2.5, self.QuadTable.y2 - 2.5, self.QuadTable.w2 + 5, self.QuadTable.h2 + 5)
            surface.DrawRect(self.QuadTable.x3 - 2.5, self.QuadTable.y3 - 2.5, self.QuadTable.w3 + 5, self.QuadTable.h3 + 5)
            surface.DrawRect(self.QuadTable.x4 - 2.5, self.QuadTable.y4 - 2.5, self.QuadTable.w4 + 5, self.QuadTable.h4 + 5)
        end
    end
    
    -- Hide viewmodel when scoped
    function SWEP:PreDrawViewModel(vm, wep, ply)
        if self:GetNWBool("Scope", false) then
            return true  -- Don't draw
        end
    end
    
    -- Translate FOV for scope zoom
    function SWEP:TranslateFOV(current_fov)
        local fScopeZoom = self:GetNWFloat("ScopeZoom", 1)
        if self:GetNWBool("Scope", false) and fScopeZoom > 1 then
            return current_fov / fScopeZoom
        end
        return current_fov
    end
end
