----------------------------------------------------
-- TDMRP CS:S Scoped Weapon Base
-- Base class for scoped CSS weapons (snipers, AUG, SG552)
-- Scope rendering ported from bobs_scoped_base (M9K)
-- Uses HOLD-TO-SCOPE system like M9K weapons
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

-- Inherit from our CSS weapon base
SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.IsTDMRPWeapon = true
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

-- Scope defaults (M9K-style flags)
SWEP.UseScope = true
SWEP.ScopeZooms = {4}
SWEP.ScopeScale = 0.5
SWEP.ReticleScale = 0.6
SWEP.IronSightZoom = 1.3
SWEP.DrawCrosshair = false
SWEP.XHair = false  -- For returning crosshair after scope

-- M9K-style scope type flags (only set ONE to true per weapon)
SWEP.Secondary = SWEP.Secondary or {}
SWEP.Secondary.ScopeZoom = 4
SWEP.Secondary.UseACOG = false
SWEP.Secondary.UseMilDot = false
SWEP.Secondary.UseSVD = false
SWEP.Secondary.UseParabolic = false
SWEP.Secondary.UseElcan = false
SWEP.Secondary.UseGreenDuplex = false
SWEP.Secondary.UseAimpoint = false

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
    
    -- Calculate scope geometry (same as bobs_scoped_base)
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
    
    -- Quad tables for filling corners (black borders)
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
    
    -- Reticle table for ACOG-style scopes (chevron, crosshairs)
    self.ReticleTable = {}
    self.ReticleTable.wdivider = 3.125
    self.ReticleTable.hdivider = 1.7579 / self.ReticleScale
    self.ReticleTable.x = (iScreenWidth / 2) - ((iScreenHeight / self.ReticleTable.hdivider) / 2)
    self.ReticleTable.y = (iScreenHeight / 2) - ((iScreenHeight / self.ReticleTable.hdivider) / 2)
    self.ReticleTable.w = iScreenHeight / self.ReticleTable.hdivider
    self.ReticleTable.h = iScreenHeight / self.ReticleTable.hdivider
end

----------------------------------------------------
-- Secondary Attack - Does nothing (scope handled by Think/IronSight)
-- This prevents the toggle behavior
----------------------------------------------------
function SWEP:SecondaryAttack()
    -- Scope is handled by IronSight() in Think hook
    -- Do nothing here to prevent interference
end

----------------------------------------------------
-- IronSight - Called from Think hook (M9K pattern)
-- Handles HOLD-TO-SCOPE behavior
----------------------------------------------------
function SWEP:IronSight()
    if not IsValid(self) then return end
    if not IsValid(self.Owner) then return end
    if not self.UseScope then return end
    
    local isReloading = self:GetNWBool("Reloading", false)
    local sec = self.Secondary or {}
    local scopeZoom = sec.ScopeZoom or self.ScopeZooms[1] or 4
    
    -- Handle scope entry (press right-click while not using)
    if self.Owner:KeyPressed(IN_ATTACK2) and not self.Owner:KeyDown(IN_USE) and not isReloading then
        self.Owner:SetFOV(75 / scopeZoom, 0.15)
        self:SetNWBool("Scope", true)
        self.DrawCrosshair = false
        self:EmitSound("weapons/zoom.wav", 50, 100)
    end
    
    -- Handle scope exit (release right-click only)
    if self.Owner:KeyReleased(IN_ATTACK2) then
        if self:GetNWBool("Scope", false) then
            self.Owner:SetFOV(0, 0.2)
            self:SetNWBool("Scope", false)
            self.DrawCrosshair = self.XHair
        end
    end
    
    -- Reduce sway when scoped (works while sprinting too)
    if self.Owner:KeyDown(IN_ATTACK2) and not self.Owner:KeyDown(IN_USE) then
        self.SwayScale = 0.05
        self.BobScale = 0.05
    else
        self.SwayScale = 1.0
        self.BobScale = 1.0
    end
end

----------------------------------------------------
-- Think hook - Calls IronSight for hold-to-scope
----------------------------------------------------
function SWEP:Think()
    -- Handle scope behavior
    self:IronSight()
end

----------------------------------------------------
-- Reset scope on holster
----------------------------------------------------
function SWEP:Holster(wep)
    if IsValid(self.Owner) then
        self.Owner:SetFOV(0, 0)
    end
    self:SetNWBool("Scope", false)
    self.DrawCrosshair = self.XHair
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
    self.DrawCrosshair = self.XHair
end

----------------------------------------------------
-- Draw scope overlay on client (M9K pattern)
-- Only draws when HOLDING right-click
----------------------------------------------------
if CLIENT then
    
    function SWEP:DrawHUD()
        if not self.UseScope then return end
        if not IsValid(self.Owner) then return end
        
        -- Ensure scope tables are initialized
        if not self.LensTable or not self.ReticleTable then
            self:InitScopeTables()
        end
        
        -- ONLY draw scope when holding right-click (allow sprinting while scoped)
        local isScoped = self.Owner:KeyDown(IN_ATTACK2) 
                         and not self.Owner:KeyDown(IN_USE)
        
        if not isScoped then return end
        
        -- Get Secondary table (may be set by child weapon)
        local sec = self.Secondary or {}
        
        -- ACOG Scope (for AUG, SG552)
        if sec.UseACOG then
            -- Draw the ACOG lens
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)

            -- Draw the CHEVRON reticle
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_acogchevron"))
            surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)

            -- Draw the ACOG crosshair lines
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_acogcross"))
            surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)
        end

        -- MilDot Scope (for AWP, Scout - sniper rifles)
        if sec.UseMilDot then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_scopesight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
        end

        -- SVD Scope
        if sec.UseSVD then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_svdsight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
        end

        -- Parabolic Scope
        if sec.UseParabolic then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_parabolicsight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
        end

        -- Elcan Scope
        if sec.UseElcan then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_elcanreticle"))
            surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)
            
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_elcansight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
        end

        -- Green Duplex (night vision style)
        if sec.UseGreenDuplex then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_nvgilluminatedduplex"))
            surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)

            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
        end
        
        -- Aimpoint (red dot)
        if sec.UseAimpoint then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/aimpoint"))
            surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)

            surface.SetDrawColor(0, 0, 0, 255)
            surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
            surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
        end
        
        -- NOTE: Black border quads removed - scope textures handle their own borders
    end
    
    -- Hide viewmodel when scoped (holding right-click, works while sprinting)
    function SWEP:PreDrawViewModel(vm, wep, ply)
        if IsValid(self.Owner) and self.Owner:KeyDown(IN_ATTACK2) 
           and not self.Owner:KeyDown(IN_USE) then
            return true  -- Don't draw viewmodel when scoped
        end
        return false
    end
    
    -- Adjust mouse sensitivity when scoped
    function SWEP:AdjustMouseSensitivity()
        if IsValid(self.Owner) and self.Owner:KeyDown(IN_ATTACK2) then
            local sec = self.Secondary or {}
            local zoom = sec.ScopeZoom or self.ScopeZooms[1] or 4
            return 1 / (zoom / 2)
        end
        return 1
    end
end
