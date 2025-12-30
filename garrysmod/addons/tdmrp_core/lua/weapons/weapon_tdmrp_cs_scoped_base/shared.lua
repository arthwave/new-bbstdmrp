----------------------------------------------------
-- TDMRP CS:S Scoped Weapon Base
-- Base class for scoped CSS weapons (snipers, AUG, SG552)
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
-- Draw scope overlay on client
----------------------------------------------------
if CLIENT then
    local scopeTexture = surface.GetTextureID("scope/scope_normal")
    
    function SWEP:DrawHUD()
        if not self.UseScope then return end
        
        local bScope = self:GetNWBool("Scope", false)
        if not bScope then return end
        
        local sw, sh = ScrW(), ScrH()
        local scopeSize = sh
        local scopeX = (sw - scopeSize) / 2
        local scopeY = (sh - scopeSize) / 2
        
        -- Draw crosshairs
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawLine(0, sh / 2, sw, sh / 2)
        surface.DrawLine(sw / 2, 0, sw / 2, sh)
        
        -- Draw scope overlay
        surface.SetTexture(scopeTexture)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawTexturedRect(scopeX, scopeY, scopeSize, scopeSize)
        
        -- Fill corners black
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, scopeX, sh)
        surface.DrawRect(scopeX + scopeSize, 0, sw - scopeX - scopeSize, sh)
    end
    
    -- Hide viewmodel when scoped
    function SWEP:PreDrawViewModel(vm, wep, ply)
        if self:GetNWBool("Scope", false) then
            return true  -- Don't draw
        end
    end
end
