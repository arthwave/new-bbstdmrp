----------------------------------------------------
-- TDMRP Weapon Mixin
-- Shared logic for all tdmrp_m9k_* derived weapons
-- This file provides the Setup() function and stat scaling
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}
TDMRP_WeaponMixin = TDMRP_WeaponMixin or {}

-- Hit number debounce per attacker-target combo
local hitNumberDebounce = {}

----------------------------------------------------
-- Pending Instance System
-- Stores instances to apply during Initialize/Equip
-- Prevents tier reset from Give() -> Initialize() -> Equip() sequence
----------------------------------------------------

if SERVER then
    TDMRP.PendingInstances = TDMRP.PendingInstances or {}
    
    -- Network strings for slug mode
    util.AddNetworkString("TDMRP_RequestSlugToggle")
    util.AddNetworkString("TDMRP_ShotgunModeChanged")
    util.AddNetworkString("TDMRP_ChainLightningVis")
    util.AddNetworkString("TDMRP_ChainBeam")
    
    -- Network handler for slug toggle requests
    net.Receive("TDMRP_RequestSlugToggle", function(len, ply)
        if not IsValid(ply) then return end
        
        local wep = ply:GetActiveWeapon()
        local isSlugEnabled = wep.IsSlugEnabled and wep:IsSlugEnabled() or TDMRP_WeaponMixin.IsSlugEnabled(wep)
        if not IsValid(wep) or not isSlugEnabled then return end
        
        -- Attempt toggle
        TDMRP_WeaponMixin.ToggleSlugMode(wep, ply)
    end)
end

-- Set a pending instance before calling ply:Give()
function TDMRP.SetPendingInstance(ply, class, inst)
    if not SERVER then return end
    if not IsValid(ply) or not class or not inst then return end
    
    local key = ply:SteamID64() .. "_" .. class
    TDMRP.PendingInstances[key] = inst
    
    -- Auto-expire after 5 seconds (extended from 2s for slow connections)
    timer.Simple(5, function()
        if TDMRP.PendingInstances[key] then
            print(string.format("[TDMRP] PendingInstance EXPIRED (never consumed): %s tier=%d", key, inst.tier or 1))
            TDMRP.PendingInstances[key] = nil
        end
    end)
    
    print(string.format("[TDMRP] SetPendingInstance: %s tier=%d", key, inst.tier or 1))
end

-- Get and consume pending instance during Initialize/Equip
function TDMRP.GetPendingInstance(ply, class)
    if not SERVER then return nil end
    if not IsValid(ply) or not class then return nil end
    
    local key = ply:SteamID64() .. "_" .. class
    local inst = TDMRP.PendingInstances[key]
    
    if inst then
        TDMRP.PendingInstances[key] = nil  -- Consume it
        print(string.format("[TDMRP] GetPendingInstance: CONSUMED %s tier=%d", key, inst.tier or 1))
    end
    
    return inst
end

----------------------------------------------------
-- Tier Stat Multipliers (1-4 normal, 5 = unique/hand-coded)
----------------------------------------------------

TDMRP_WeaponMixin.TierScaling = {
    [1] = { damage = 1.00, rpm = 1.00, spread = 1.00, recoil = 1.00, handling = 1.00, reload = 1.00 },
    [2] = { damage = 1.15, rpm = 1.05, spread = 0.90, recoil = 0.90, handling = 1.05, reload = 0.95 },
    [3] = { damage = 1.30, rpm = 1.10, spread = 0.80, recoil = 0.80, handling = 1.10, reload = 0.90 },
    [4] = { damage = 1.50, rpm = 1.15, spread = 0.65, recoil = 0.65, handling = 1.20, reload = 0.85 },
    -- Tier 5 is reserved for uniques - those weapons override stats manually
}

----------------------------------------------------
-- Hook Injection System
-- Wraps M9K base functions to allow modifier interception
----------------------------------------------------

function TDMRP_WeaponMixin.InstallHooks(wep)
    if not IsValid(wep) then return end
    if wep.TDMRP_HooksInstalled then return end
    wep.TDMRP_HooksInstalled = true
    
    -- Store original functions
    wep.TDMRP_Orig_PrimaryAttack = wep.PrimaryAttack
    wep.TDMRP_Orig_ShootBullet = wep.ShootBullet
    wep.TDMRP_Orig_RicochetCallback = wep.RicochetCallback
    wep.TDMRP_Orig_Deploy = wep.Deploy
    wep.TDMRP_Orig_Reload = wep.Reload
    wep.TDMRP_Orig_Think = wep.Think  -- Store original Think
    
    -------------------------------------------------
    -- Wrap Think to reapply material each frame
    -- (M9K custom rendering resets material)
    -------------------------------------------------
    
    wep.Think = function(self)
        -- Call original Think first
        if self.TDMRP_Orig_Think then
            self:TDMRP_Orig_Think()
        end
        
        -- Reapply material every frame if suffix is present (M9K rendering overwrites it)
        -- PRIORITY: 1) NWString (network synced) 2) Entity property (fallback) 3) Instance (last resort)
        local suffixMaterial = self:GetNWString("TDMRP_Material", "") or self.TDMRP_StoredMaterial or ""
        
        -- DEBUG: Log material state on respawn (only once per weapon)
        if not self.TDMRP_Material_DebugLogged and (suffixMaterial ~= "" or self.TDMRP_Instance) then
            print(string.format("[TDMRP Material DEBUG] Weapon Think - Material from NWString: '%s' | Entity prop: '%s' | Instance: '%s'", 
                self:GetNWString("TDMRP_Material", ""),
                self.TDMRP_StoredMaterial or "NONE",
                (self.TDMRP_Instance and self.TDMRP_Instance.craft and self.TDMRP_Instance.craft.material) or "NO_INSTANCE"))
            self.TDMRP_Material_DebugLogged = true
        end
        
        if suffixMaterial ~= "" then
            self:SetMaterial(suffixMaterial)
            for i = 0, 31 do
                self:SetSubMaterial(i, suffixMaterial)
            end
        elseif self.TDMRP_Instance and self.TDMRP_Instance.craft and self.TDMRP_Instance.craft.material and self.TDMRP_Instance.craft.material ~= "" then
            -- FINAL FALLBACK: If nothing else worked, use instance material
            local materialFallback = self.TDMRP_Instance.craft.material
            self:SetMaterial(materialFallback)
            for i = 0, 31 do
                self:SetSubMaterial(i, materialFallback)
            end
        end
    end
    
    -------------------------------------------------
    -- Wrap Think (disable sprint animation)
    -- M9K's Think calls IronSight() which handles sprint
    -------------------------------------------------
    
    -- Store original IronSight function
    wep.TDMRP_Orig_IronSight = wep.IronSight
    
    -- Override IronSight to skip sprint handling (TDMRP disables sprint)
    -- This is a cleaned up version of bobs_gun_base's IronSight without sprint code
    wep.IronSight = function(self)
        if not IsValid(self) then return end
        
        local owner = self.Owner
        if not IsValid(owner) then return end
        
        -- NPCs use original function
        if owner:IsNPC() then
            if self.TDMRP_Orig_IronSight then
                return self:TDMRP_Orig_IronSight()
            end
            return
        end
        
        -- Reset sights after reload animation (from original bobs_gun_base)
        if self.ResetSights and CurTime() >= self.ResetSights then
            self.ResetSights = nil
            if self.Silenced then
                self:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
            else
                self:SendWeaponAnim(ACT_VM_IDLE)
            end
        end
        
        -- Handle silencer toggle (USE + right click)
        if self.CanBeSilenced and (self.NextSilence or 0) < CurTime() then
            if owner:KeyDown(IN_USE) and owner:KeyPressed(IN_ATTACK2) then
                self:Silencer()
            end
        end
        
        -- Handle selective fire (USE + reload)
        if self.SelectiveFire and (self.NextFireSelect or 0) < CurTime() and not self:GetNWBool("Reloading") then
            if owner:KeyDown(IN_USE) and owner:KeyPressed(IN_RELOAD) then
                self:SelectFireMode()
            end
        end
        
        -- SKIP SPRINT CODE - TDMRP disables sprint globally
        -- (original bobs_gun_base lines 820-833 handled IN_SPEED)
        
        -- Handle ADS toggle (only if not pressing USE)
        if not owner:KeyDown(IN_USE) then
            if owner:KeyPressed(IN_ATTACK2) and not self:GetNWBool("Reloading") then
                local ironFOV = (self.Secondary and self.Secondary.IronFOV) or 55
                owner:SetFOV(ironFOV, 0.3)
                self.IronSightsPos = self.SightsPos
                self.IronSightsAng = self.SightsAng
                self:SetIronsights(true, owner)
                self.DrawCrosshair = false
                if CLIENT then return end
            end
        end
        
        -- Handle ADS release (only if not pressing USE)
        if owner:KeyReleased(IN_ATTACK2) and not owner:KeyDown(IN_USE) then
            owner:SetFOV(0, 0.3)
            self.DrawCrosshair = self.OrigCrossHair or true
            self:SetIronsights(false, owner)
            if CLIENT then return end
        end
        
        -- Handle sway/bob reduction during ADS
        if owner:KeyDown(IN_ATTACK2) and not owner:KeyDown(IN_USE) then
            self.SwayScale = 0.05
            self.BobScale = 0.05
        else
            self.SwayScale = 1.0
            self.BobScale = 1.0
        end
    end
    
    -------------------------------------------------
    -- Wrap ViewModelDrawn to reapply material
    -- (M9K's custom rendering can override SetMaterial)
    -------------------------------------------------
    if CLIENT then
        wep.TDMRP_Orig_ViewModelDrawn = wep.ViewModelDrawn
        
        wep.ViewModelDrawn = function(self)
            -- Reapply material before M9K rendering
            local suffixMaterial = self:GetNWString("TDMRP_Material", "")
            if suffixMaterial ~= "" then
                self:SetMaterial(suffixMaterial)
                for i = 0, 31 do
                    self:SetSubMaterial(i, suffixMaterial)
                end
            end
            
            -- Call original ViewModelDrawn
            if self.TDMRP_Orig_ViewModelDrawn then
                return self:TDMRP_Orig_ViewModelDrawn()
            end
        end
        
        -- Store hands original material once
        local handsOriginalMaterial = nil
        
        -- Also add a render hook to apply material to viewmodel weapon parts every frame
        -- We save/restore hands material to prevent them from being affected
        hook.Add("PreDrawViewModel", "TDMRP_MaterialRender", function(vm, ply, wep)
            if not IsValid(wep) or not IsValid(vm) then return end
            
            -- Capture hands material once (only if not already captured)
            if handsOriginalMaterial == nil then
                local hands = ply:GetHands()
                if IsValid(hands) then
                    handsOriginalMaterial = hands:GetMaterial()
                end
            end
            
            -- PRIORITY: 1) NWString 2) Entity property 3) Instance
            local suffixMaterial = wep:GetNWString("TDMRP_Material", "") or wep.TDMRP_StoredMaterial or ""
            
            -- DEBUG: Log viewmodel material on respawn
            if not wep.TDMRP_VM_DebugLogged and (suffixMaterial ~= "" or wep.TDMRP_Instance) then
                print(string.format("[TDMRP Material DEBUG PreDrawVM] VM Material from NWString: '%s' | Entity prop: '%s' | Instance: '%s'", 
                    wep:GetNWString("TDMRP_Material", ""),
                    wep.TDMRP_StoredMaterial or "NONE",
                    (wep.TDMRP_Instance and wep.TDMRP_Instance.craft and wep.TDMRP_Instance.craft.material) or "NO_INSTANCE"))
                wep.TDMRP_VM_DebugLogged = true
            end
            
            if suffixMaterial ~= "" then
                -- Apply material to all viewmodel submaterials
                for i = 0, 31 do
                    vm:SetSubMaterial(i, suffixMaterial)
                end
                
                -- Restore hands material
                local hands = ply:GetHands()
                if IsValid(hands) and handsOriginalMaterial and handsOriginalMaterial ~= "" then
                    hands:SetMaterial(handsOriginalMaterial)
                end
            elseif wep.TDMRP_Instance and wep.TDMRP_Instance.craft and wep.TDMRP_Instance.craft.material and wep.TDMRP_Instance.craft.material ~= "" then
                -- FINAL FALLBACK: If nothing else worked, use instance material
                local materialFallback = wep.TDMRP_Instance.craft.material
                for i = 0, 31 do
                    vm:SetSubMaterial(i, materialFallback)
                end
                
                -- Restore hands material
                local hands = ply:GetHands()
                if IsValid(hands) and handsOriginalMaterial and handsOriginalMaterial ~= "" then
                    hands:SetMaterial(handsOriginalMaterial)
                end
            end
        end)
    end
    
    -------------------------------------------------
    -- ChainLightning Beam Rendering
    -- Renders electrical beam arcs for of_ChainLightning suffix
    -------------------------------------------------
    if CLIENT then
        local activeBeams = {}
        
        -- Receive beam data from server
        net.Receive("TDMRP_ChainBeam", function()
            local startPos = net.ReadVector()
            local endPos = net.ReadVector()
            local lifespan = net.ReadFloat()
            
            table.insert(activeBeams, {
                startPos = startPos,
                endPos = endPos,
                dieTime = CurTime() + lifespan,
                createdAt = CurTime(),
                lifespan = lifespan
            })
        end)
        
        -- Render beams each frame
        hook.Add("PostDrawTranslucentRenderables", "TDMRP_ChainBeamRender", function()
            if #activeBeams == 0 then return end
            
            local currentTime = CurTime()
            
            for i = #activeBeams, 1, -1 do
                local beam = activeBeams[i]
                
                -- Remove expired beams
                if currentTime > beam.dieTime then
                    table.remove(activeBeams, i)
                    continue
                end
                
                -- Calculate fade (alpha based on remaining life)
                local elapsed = currentTime - beam.createdAt
                local frac = elapsed / beam.lifespan
                local alpha = 1 - frac
                
                -- Draw electrical beam
                render.SetMaterial(Material("cable/blue_elec"))
                render.DrawBeam(
                    beam.startPos,
                    beam.endPos,
                    6,  -- Width
                    0,  -- Texture start
                    1,  -- Texture end
                    Color(100, 200, 255, 255 * alpha)
                )
            end
        end)
    end
    
    -------------------------------------------------
    -- Wrap PrimaryAttack (fire sound, muzzle, RPM)
    -- Also bypasses M9K's sprint check
    -------------------------------------------------
    wep.PrimaryAttack = function(self)
        if not IsValid(self) then return end
        
        -- Pre-fire hook - modifiers can cancel the shot
        local canFire = TDMRP_WeaponMixin.RunModifierHook(self, "OnPreFire")
        if canFire == false then return end
        
        -- Sound override with layering for slug mode
        local origSound = self.Primary.Sound
        local origSilencedSound = self.Primary.SilencedSound
        local newSound = TDMRP_WeaponMixin.GetModifiedFireSound(self)
        local isSlugMode = TDMRP_WeaponMixin.IsSlugEnabled(self) and self:GetSlugMode() == 1
        
        -- Slug mode: play additional slug sound without replacing original
        if isSlugMode then
            -- Override EmitSound to add slug sound when original plays
            local origEmitSound = self.EmitSound
            self.EmitSound = function(self, soundName, ...)
                -- Call original EmitSound first
                origEmitSound(self, soundName, ...)
            end
            
            -- Also try overriding Weapon:EmitSound if that's what M9K uses
            if self.Weapon and self.Weapon.EmitSound and self.Weapon ~= self then
                self.Weapon.TDMRP_OrigEmitSound = self.Weapon.EmitSound
                self.Weapon.EmitSound = self.EmitSound
            end
        elseif newSound then
            -- Regular sound replacement (for other modifiers)
            self.Primary.Sound = newSound
            self.Primary.SilencedSound = newSound
        end
        
        -- RPM override (applied in ApplyTierScaling, but modifiers can further adjust)
        local origDelay = self.Primary.Delay
        local rpmMult = TDMRP_WeaponMixin.GetRPMMultiplier(self)
        if rpmMult and rpmMult ~= 1 then
            self.Primary.Delay = origDelay / rpmMult
        end
        
        -- TDMRP: Bypass M9K's sprint check by directly calling ShootBulletInformation
        -- instead of letting the original PrimaryAttack block us
        -- For CSS weapons (no ShootBulletInformation), use original PrimaryAttack
        local owner = self:GetOwner()
        local hasM9KBase = self.ShootBulletInformation ~= nil
        
        if IsValid(owner) and owner:IsPlayer() and owner:KeyDown(IN_SPEED) and hasM9KBase then
            -- We're sprinting with M9K weapon - bypass M9K's check and fire directly
                if self:CanPrimaryAttack() and not owner:KeyDown(IN_RELOAD) then
                self:ShootBulletInformation()
                local preClip = self:Clip1()
                self:TakePrimaryAmmo(1)
                
                -- Consume additional ammo for suffix effects (forward compatible)
                local suffixId = self:GetNWString("TDMRP_SuffixID", "")
                if suffixId ~= "" and TDMRP and TDMRP.Gems and TDMRP.Gems.Suffixes then
                    local suffix = TDMRP.Gems.Suffixes[suffixId]
                    if suffix and suffix.ammoCost and suffix.ammoCost > 1 then
                        local extraAmmo = suffix.ammoCost - 1
                        self:TakePrimaryAmmo(extraAmmo)
                        if SERVER then
                            print(string.format("[TDMRP] Suffix %s consumed %d extra ammo (ammoCost=%d total)", 
                                suffixId, extraAmmo, suffix.ammoCost))
                        end
                    end
                end
                
                -- Play fire sound
                local soundToPlay = self.Silenced and self.Primary.SilencedSound or self.Primary.Sound
                if soundToPlay then
                    self:EmitSound(soundToPlay)
                end
                
                -- Add slug sound layer if in slug mode and we had ammo to fire
                if isSlugMode and preClip and preClip > 0 then
                    local slugSound = TDMRP_WeaponMixin.GetModifiedFireSound(self)
                    if slugSound then
                        self:EmitSound(slugSound, 75, 100, 2.0)  -- 100% louder (2x volume)
                    end
                end
                
                -- Add suffix sound layer if suffix has custom sound effect
                if suffixId ~= "" and TDMRP and TDMRP.Gems and TDMRP.Gems.Suffixes and preClip and preClip > 0 then
                    local suffix = TDMRP.Gems.Suffixes[suffixId]
                    if suffix and suffix.soundEffect then
                        local wepEnt = self
                        local soundPath = suffix.soundEffect
                        -- Delay suffix sound by 0.05s to prevent sound stacking on high RPM weapons
                        -- This runs AFTER the normal shot has fired
                        timer.Simple(0.05, function()
                            if IsValid(wepEnt) then
                                wepEnt:EmitSound(soundPath, 75, 100, 1.5)
                            end
                        end)
                        if SERVER then
                            print(string.format("[TDMRP] Suffix %s sound effect scheduled (0.05s delay): %s", suffixId, suffix.soundEffect))
                        end
                    end
                end
                
                if self.Silenced then
                    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_SILENCED)
                else
                    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
                end
                
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
            end
        else
            -- Not sprinting - use original
            if self.TDMRP_Orig_PrimaryAttack then
                local preClip = self:Clip1()
                self:TDMRP_Orig_PrimaryAttack()
                
                -- Consume additional ammo for suffix effects (forward compatible)
                local suffixId = self:GetNWString("TDMRP_SuffixID", "")
                if suffixId ~= "" and TDMRP and TDMRP.Gems and TDMRP.Gems.Suffixes then
                    local suffix = TDMRP.Gems.Suffixes[suffixId]
                    if suffix and suffix.ammoCost and suffix.ammoCost > 1 then
                        local extraAmmo = suffix.ammoCost - 1
                        self:TakePrimaryAmmo(extraAmmo)
                        if SERVER then
                            print(string.format("[TDMRP] Suffix %s consumed %d extra ammo (ammoCost=%d total)", 
                                suffixId, extraAmmo, suffix.ammoCost))
                        end
                    end
                end

                -- Add slug sound layer if in slug mode and we had ammo to fire
                if isSlugMode and preClip and preClip > 0 then
                    local slugSound = TDMRP_WeaponMixin.GetModifiedFireSound(self)
                    if slugSound then
                        self:EmitSound(slugSound, 75, 100, 2.0)  -- 100% louder (2x volume)
                    end
                end
                
                -- Add suffix sound layer if suffix has custom sound effect
                if suffixId ~= "" and TDMRP and TDMRP.Gems and TDMRP.Gems.Suffixes and preClip and preClip > 0 then
                    local suffix = TDMRP.Gems.Suffixes[suffixId]
                    if suffix and suffix.soundEffect then
                        local wepEnt = self
                        local soundPath = suffix.soundEffect
                        -- Delay suffix sound by 0.05s to prevent sound stacking on high RPM weapons
                        -- This runs AFTER the normal shot has fired
                        timer.Simple(0.05, function()
                            if IsValid(wepEnt) then
                                wepEnt:EmitSound(soundPath, 75, 100, 1.5)
                            end
                        end)
                        if SERVER then
                            print(string.format("[TDMRP] Suffix %s sound effect scheduled (0.05s delay): %s", suffixId, suffix.soundEffect))
                        end
                    end
                end
            end
        end
        
        -- Restore originals
        self.Primary.Sound = origSound
        self.Primary.SilencedSound = origSilencedSound
        self.Primary.Delay = origDelay
        if origEmitSound then
            self.EmitSound = origEmitSound
            if self.Weapon and self.Weapon.TDMRP_OrigEmitSound then
                self.Weapon.EmitSound = self.Weapon.TDMRP_OrigEmitSound
                self.Weapon.TDMRP_OrigEmitSound = nil
            end
        end
        
        -- Post-fire hook
        TDMRP_WeaponMixin.RunModifierHook(self, "OnPostFire")
    end
    
    -------------------------------------------------
    -- Wrap ShootBullet (damage, tracer)
    -- M9K uses: ShootBullet(damage, recoil, num_bullets, aimcone)
    -- CSS uses: ShootBullet(damage, numbullets, aimcone)
    -------------------------------------------------
    wep.ShootBullet = function(self, damage, arg2, arg3, arg4)
        if not IsValid(self) then return end
        
        -- Detect signature: CSS passes 3 args, M9K passes 4
        -- CSS: (damage, numbullets, aimcone) - arg4 is nil
        -- M9K: (damage, recoil, num_bullets, aimcone) - arg4 is aimcone
        local isCSS = (arg4 == nil)
        local recoil, num_bullets, aimcone
        
        if isCSS then
            -- CSS format: (damage, numbullets, aimcone)
            recoil = self.Primary and self.Primary.Recoil or 0.5  -- Get recoil from weapon stats
            num_bullets = arg2 or 1
            aimcone = arg3 or 0.02
        else
            -- M9K format: (damage, recoil, num_bullets, aimcone)
            recoil = arg2 or 0.5
            num_bullets = arg3 or 1
            aimcone = arg4 or 0.02
        end
        
        -- Increment shot counter for recoil patterns
        self.TDMRP_ShotsFired = (self.TDMRP_ShotsFired or 0) + 1
        
        -- Check for slug mode on shotguns
        local isSlugEnabled = self.IsSlugEnabled and self:IsSlugEnabled() or TDMRP_WeaponMixin.IsSlugEnabled(self)
        local isSlugMode = isSlugEnabled and self:GetSlugMode() == 1
        
        if isSlugMode then
            -- Slug mode: derive slug damage from the weapon's buckshot stats
            -- Use per-pellet * pellet count as baseline, then apply a multiplier
            local perPellet = (self.Primary and self.Primary.Damage) or damage
            local pelletCount = (self.Primary and self.Primary.NumShots) or num_bullets or 1
            local totalBuckDamage = perPellet * pelletCount
            local slugMultiplier = 0.9 -- 90% of total buckshot damage by default
            local slugDamage = math.max(1, math.floor(totalBuckDamage * slugMultiplier))

            damage = slugDamage
            num_bullets = 1
            aimcone = 0.02  -- Tight spread for slug
            recoil = recoil * 1.25  -- Slightly higher recoil for slug
        end
        
        -- Check for Doubleshot suffix - fire twice instead of once
        local isDoubleshot = self:GetNWString("TDMRP_SuffixID", "") == "of_Doubleshot"
        if isDoubleshot then
            -- Apply modifiers first
            local modifiedDamage = TDMRP_WeaponMixin.GetModifiedDamage(self, damage)
            local modifiedRecoil = TDMRP_WeaponMixin.GetModifiedRecoil(self, recoil)
            local modifiedSpread = TDMRP_WeaponMixin.GetModifiedSpread(self, aimcone)
            
            -- Fire first shot with tighter spread (50% of modified spread)
            local firstSpread = modifiedSpread * 0.5
            if self.TDMRP_Orig_ShootBullet then
                if isCSS then
                    self:TDMRP_Orig_ShootBullet(modifiedDamage, num_bullets, firstSpread)
                else
                    self:TDMRP_Orig_ShootBullet(modifiedDamage, modifiedRecoil, num_bullets, firstSpread)
                end
            end
            
            -- Fire second shot with wider spread and directional variance
            -- Add random offset to each shot's direction (doubled variance)
            local secondSpread = modifiedSpread * (1.2 + math.Rand(-0.30, 0.70))  -- Random spread between 0.9-1.9x
            if self.TDMRP_Orig_ShootBullet then
                if isCSS then
                    self:TDMRP_Orig_ShootBullet(modifiedDamage, num_bullets, secondSpread)
                else
                    self:TDMRP_Orig_ShootBullet(modifiedDamage, modifiedRecoil * 0.8, num_bullets, secondSpread)
                end
            end
            
            print(string.format("[TDMRP] Doubleshot fired: 2x shot, damage=%.1f each, spread1=%.3f spread2=%.3f", 
                modifiedDamage or damage, firstSpread, secondSpread))
        else
            -- Normal single shot path
            -- Damage modification from modifiers
            local modifiedDamage = TDMRP_WeaponMixin.GetModifiedDamage(self, damage)
            
            -- Recoil modification from modifiers  
            local modifiedRecoil = TDMRP_WeaponMixin.GetModifiedRecoil(self, recoil)
            
            -- Spread modification from modifiers (applies movement penalty)
            local modifiedSpread = TDMRP_WeaponMixin.GetModifiedSpread(self, aimcone)
            
            -- Store for callback access
            self.TDMRP_CurrentShotDamage = modifiedDamage
            
            -- Call original with modified values - use correct signature for weapon type
            if self.TDMRP_Orig_ShootBullet then
                if isCSS then
                    -- CSS format: (damage, numbullets, aimcone)
                    self:TDMRP_Orig_ShootBullet(modifiedDamage, num_bullets, modifiedSpread)
                else
                    -- M9K format: (damage, recoil, num_bullets, aimcone)
                    self:TDMRP_Orig_ShootBullet(modifiedDamage, modifiedRecoil, num_bullets, modifiedSpread)
                end
            end
        end
        
        -- Bullet fired hook
        TDMRP_WeaponMixin.RunModifierHook(self, "OnBulletFired")
    end
    
    -------------------------------------------------
    -- Wrap RicochetCallback (bullet hit effects)
    -------------------------------------------------
    wep.RicochetCallback = function(self, bouncenum, attacker, tr, dmginfo)
        if not IsValid(self) then return end
        
        -- If we hit a player with invincibility active, override default hit effects (prevent blood)
        if tr and tr.Entity and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            local ent = tr.Entity
            local buff = TDMRP.ActiveSkills and TDMRP.ActiveSkills.ActiveBuffs and TDMRP.ActiveSkills.ActiveBuffs[ent]
            if buff and buff.skill == "invincibility" and CurTime() < buff.endTime then
                -- Create sparks effect at impact position
                local effectData = EffectData()
                local hitPos = tr.HitPos or ent:GetPos() + ent:OBBCenter()
                local normal = tr.HitNormal or tr.Normal
                if not normal then
                    if IsValid(attacker) and attacker.GetForward then
                        normal = attacker:GetForward()
                    else
                        normal = Vector(0, 0, 1)
                    end
                end
                effectData:SetOrigin(hitPos)
                effectData:SetNormal(normal)
                util.Effect("Sparks", effectData)

                -- Play metal clank at impact
                local clankSounds = {
                    "physics/metal/metal_box_impact_bullet1.wav",
                    "physics/metal/metal_box_impact_bullet2.wav",
                    "physics/metal/metal_box_impact_bullet3.wav"
                }
                local randomClank = clankSounds[math.random(1, #clankSounds)]
                sound.Play(randomClank, hitPos, 75, 100)

                -- Skip original callback to avoid blood effects
                return
            end
        end
        
        -- Bullet hit hook - modifiers can add effects
        TDMRP_WeaponMixin.RunModifierHook(self, "OnBulletHit", tr, dmginfo)
        
        -- Send hit number to attacker (damage feedback)
        if SERVER and IsValid(attacker) and attacker:IsPlayer() then
            local target = tr.Entity
            if IsValid(target) and (target:IsPlayer() or target:IsNPC()) and target ~= attacker then
                local dmg = dmginfo:GetDamage()
                if dmg > 0 then
                    -- Debounce: only send one hit number per 0.1s per attacker-target combo
                    local key = attacker:SteamID64() .. "_" .. target:EntIndex()
                    local now = CurTime()
                    local lastTime = hitNumberDebounce[key] or 0
                    
                    print("[TDMRP] RicochetCallback:", "key=" .. key, "dmg=" .. dmg, "last=" .. (now - lastTime) .. "s ago")
                    
                    if now - lastTime > 0.1 then
                        hitNumberDebounce[key] = now
                        
                        local hitPos = tr.HitPos or target:GetPos() + target:OBBCenter()
                        
                        -- Check if headshot using hitgroup (more reliable than bone distance)
                        local isHeadshot = false
                        if tr.HitGroup == HITGROUP_HEAD then
                            isHeadshot = true
                        end
                        
                        -- Fallback to bone distance if hitgroup not available (for NPCs or edge cases)
                        if not isHeadshot and hitPos then
                            local headPos = target:GetBonePosition(target:LookupBone("ValveBiped.Bip01_Head1") or 0)
                            if headPos then
                                isHeadshot = (headPos:Distance(hitPos) < 8.5)
                            end
                        end
                        
                        -- Check if killing blow
                        local willKill = (target:Health() - dmg) <= 0
                        
                        -- Check if attacker has quad damage active
                        local isQuadDamage = false
                        local displayDamage = dmg
                        if SERVER and TDMRP.ActiveSkills and TDMRP.ActiveSkills.ActiveBuffs then
                            local buff = TDMRP.ActiveSkills.ActiveBuffs[attacker]
                            if buff and buff.skill == "quaddamage" and CurTime() < buff.endTime then
                                isQuadDamage = true
                                displayDamage = math.ceil(dmg * 4)  -- Show quad-scaled damage
                            end
                        end
                        
                        print("[TDMRP] SENT hit number:", displayDamage)
                        
                        -- Send hit number
                        net.Start("TDMRP_HitNumber")
                            net.WriteVector(hitPos)
                            net.WriteUInt(math.min(math.Round(displayDamage), 65535), 16)
                            net.WriteBool(isHeadshot)
                            net.WriteBool(willKill)
                            net.WriteBool(isQuadDamage)
                        net.Send(attacker)
                    else
                        print("[TDMRP] BLOCKED (debounce)")
                    end
                end
            end
        end
        
        -- Call original
        -- NOTE: M9K's RicochetCallback also sends hit numbers, so we skip it to avoid duplicates
        -- if self.TDMRP_Orig_RicochetCallback then
        --     return self:TDMRP_Orig_RicochetCallback(bouncenum, attacker, tr, dmginfo)
        -- end
    end
    
    -------------------------------------------------
    -- Wrap Deploy (handling - draw speed)
    -------------------------------------------------
    wep.Deploy = function(self)
        if not IsValid(self) then return true end
        
        -- Call original first
        local ret = true
        if self.TDMRP_Orig_Deploy then
            ret = self:TDMRP_Orig_Deploy()
        end
        
        -- Apply handling modifier to draw speed
        local handling = self.TDMRP_Handling or 100
        local handlingMult = handling / 100
        
        -- Faster handling = shorter delay before can fire
        -- Base draw delay is typically ~0.5s, reduce it with good handling
        if handlingMult > 1 then
            local currentDelay = self:GetNextPrimaryFire() - CurTime()
            if currentDelay > 0 then
                local newDelay = currentDelay / handlingMult
                self:SetNextPrimaryFire(CurTime() + newDelay)
            end
        end
        
        -- Deploy hook
        TDMRP_WeaponMixin.RunModifierHook(self, "OnDeploy")
        
        return ret
    end
    
    -------------------------------------------------
    -- Wrap Reload (reload speed)
    -------------------------------------------------
    wep.Reload = function(self)
        if not IsValid(self) then return end
        
        -- Get reload speed multiplier
        local reloadMult = TDMRP_WeaponMixin.GetReloadMultiplier(self)
        
        -- Pre-reload hook
        TDMRP_WeaponMixin.RunModifierHook(self, "OnReload")
        
        -- Call original
        if self.TDMRP_Orig_Reload then
            self:TDMRP_Orig_Reload()
        end
        
        -- Adjust reload timing if modifier changes it
        -- Note: M9K uses animation duration, so we adjust NextPrimaryFire
        if reloadMult and reloadMult ~= 1 and SERVER then
            local currentDelay = self:GetNextPrimaryFire() - CurTime()
            if currentDelay > 0 then
                local newDelay = currentDelay / reloadMult
                self:SetNextPrimaryFire(CurTime() + newDelay)
            end
        end
    end
    
    -------------------------------------------------
    -- Add utility methods to weapon
    -------------------------------------------------
    wep.IsSlugEnabled = function(self) return TDMRP_WeaponMixin.IsSlugEnabled(self) end
    wep.GetSlugMode = function(self) return TDMRP_WeaponMixin.GetSlugMode(self) end
    wep.SetSlugMode = function(self, mode) return TDMRP_WeaponMixin.SetSlugMode(self, mode) end
    
    if SERVER then
        print(string.format("[TDMRP] Hooks installed for %s", wep:GetClass()))
    end
end

----------------------------------------------------
-- Modifier Hook Runner
-- Calls hook function on active prefix/suffix
----------------------------------------------------

function TDMRP_WeaponMixin.RunModifierHook(wep, hookName, ...)
    if not IsValid(wep) then return end
    if not TDMRP or not TDMRP.Gems then return end
    
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Check prefix hooks first
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix[hookName] then
            local result = prefix[hookName](wep, ...)
            if result == false then return false end
        end
    end
    
    -- Then suffix hooks
    if suffixId ~= "" and TDMRP.Gems.Suffixes then
        local suffix = TDMRP.Gems.Suffixes[suffixId]
        if suffix and suffix[hookName] then
            local result = suffix[hookName](wep, ...)
            if result == false then return false end
        end
    end
    
    return true
end

----------------------------------------------------
-- Stat Modification Helpers
-- Used by hooks to get prefix/suffix-adjusted values
----------------------------------------------------

function TDMRP_WeaponMixin.GetModifiedFireSound(wep)
    if not IsValid(wep) then return nil end
    if not TDMRP or not TDMRP.Gems then return nil end
    
    -- Check slug mode first (highest priority)
    local isSlugEnabled = wep.IsSlugEnabled and wep:IsSlugEnabled() or TDMRP_WeaponMixin.IsSlugEnabled(wep)
    if isSlugEnabled and wep:GetSlugMode() == 1 then
        local slugSounds = {
            "tdmrp/slugsounds/slugshotnew1.wav",
            "tdmrp/slugsounds/slugshotnew2.wav", 
            "tdmrp/slugsounds/slugshotnew3.wav"
        }
        return slugSounds[math.random(#slugSounds)]
    end
    
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Check prefix for sound override
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix.GetFireSound then
            local sound = prefix.GetFireSound(wep)
            if sound then return sound end
        end
    end
    
    -- Check suffix for sound override
    if suffixId ~= "" and TDMRP.Gems.Suffixes then
        local suffix = TDMRP.Gems.Suffixes[suffixId]
        if suffix and suffix.GetFireSound then
            local sound = suffix.GetFireSound(wep)
            if sound then return sound end
        end
    end
    
    return nil
end

function TDMRP_WeaponMixin.GetModifiedDamage(wep, baseDamage)
    if not IsValid(wep) then return baseDamage end
    if not TDMRP or not TDMRP.Gems then return baseDamage end
    
    local damage = baseDamage
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Apply prefix damage modifier
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix.ModifyDamage then
            damage = prefix.ModifyDamage(wep, damage)
        end
    end
    
    -- Apply suffix damage modifier
    if suffixId ~= "" and TDMRP.Gems.Suffixes then
        local suffix = TDMRP.Gems.Suffixes[suffixId]
        if suffix and suffix.ModifyDamage then
            damage = suffix.ModifyDamage(wep, damage)
        end
    end
    
    return damage
end

function TDMRP_WeaponMixin.GetModifiedRecoil(wep, baseRecoil)
    if not IsValid(wep) then return baseRecoil end
    if not TDMRP or not TDMRP.Gems then return baseRecoil end
    
    local recoil = baseRecoil
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    
    -- Only prefixes modify recoil
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix.ModifyRecoil then
            recoil = prefix.ModifyRecoil(wep, recoil)
        end
    end
    
    return recoil
end

function TDMRP_WeaponMixin.GetModifiedSpread(wep, baseSpread)
    if not IsValid(wep) then return baseSpread or 0 end
    
    local spread = baseSpread or 0  -- Default to 0 if nil
    local movementPenaltyMult = 1  -- Modifiers can reduce movement penalty
    
    -- Apply prefix modifiers
    if TDMRP and TDMRP.Gems then
        local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
        local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
        
        -- Prefix spread modification
        if prefixId ~= "" and TDMRP.Gems.Prefixes then
            local prefix = TDMRP.Gems.Prefixes[prefixId]
            if prefix then
                if prefix.ModifySpread then
                    spread = prefix.ModifySpread(wep, spread)
                end
                -- Check for stability stat (reduces movement penalty)
                if prefix.stats and prefix.stats.stability then
                    movementPenaltyMult = movementPenaltyMult * (1 - prefix.stats.stability)
                end
            end
        end
        
        -- Suffix spread modification
        if suffixId ~= "" and TDMRP.Gems.Suffixes then
            local suffix = TDMRP.Gems.Suffixes[suffixId]
            if suffix then
                if suffix.ModifySpread then
                    spread = suffix.ModifySpread(wep, spread)
                end
                -- Check for stability stat (reduces movement penalty)
                if suffix.stats and suffix.stats.stability then
                    movementPenaltyMult = movementPenaltyMult * (1 - suffix.stats.stability)
                end
            end
        end
    end
    
    -- Apply accuracy system movement penalty
    if TDMRP and TDMRP.Accuracy and TDMRP.Accuracy.GetWeaponType and TDMRP.Accuracy.GetMovementMultiplier then
        local owner = wep:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            local weaponType = TDMRP.Accuracy.GetWeaponType(wep)
            local multiplier = TDMRP.Accuracy.GetMovementMultiplier(owner, weaponType, wep)
            
            -- Apply stability reduction to movement penalty
            -- If multiplier is 5x and stability reduces by 50%, effective is 1 + (5-1)*0.5 = 3x
            if multiplier > 1 then
                local penalty = multiplier - 1  -- The penalty portion above 1x
                penalty = penalty * math.max(0, movementPenaltyMult)  -- Reduce penalty by stability
                multiplier = 1 + penalty
            end
            
            spread = spread * multiplier
        end
    end
    
    return spread
end

function TDMRP_WeaponMixin.GetRPMMultiplier(wep)
    if not IsValid(wep) then return 1 end
    if not TDMRP or not TDMRP.Gems then return 1 end
    
    local mult = 1
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    
    -- Only prefixes modify RPM
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix.GetRPMMultiplier then
            mult = mult * prefix.GetRPMMultiplier(wep)
        end
    end
    
    return mult
end

function TDMRP_WeaponMixin.GetReloadMultiplier(wep)
    if not IsValid(wep) then return 1 end
    if not TDMRP or not TDMRP.Gems then return 1 end
    
    local mult = 1
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    
    -- Only prefixes modify reload
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix.GetReloadMultiplier then
            mult = mult * prefix.GetReloadMultiplier(wep)
        end
    end
    
    -- Also factor in tier-based reload scaling
    local tier = wep.Tier or 1
    local scale = TDMRP_WeaponMixin.TierScaling[tier]
    if scale and scale.reload then
        mult = mult * (1 / scale.reload)  -- Invert because lower reload = faster
    end
    
    return mult
end

function TDMRP_WeaponMixin.GetCustomTracerName(wep)
    if not IsValid(wep) then return nil end
    if not TDMRP or not TDMRP.Gems then return nil end
    
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Check suffix first (suffix effects have priority over prefix)
    if suffixId ~= "" and TDMRP.Gems.Suffixes then
        local suffix = TDMRP.Gems.Suffixes[suffixId]
        if suffix and suffix.TracerName then
            return suffix.TracerName
        end
    end
    
    -- Then check prefix
    if prefixId ~= "" and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix and prefix.TracerName then
            return prefix.TracerName
        end
    end
    
    return nil
end

----------------------------------------------------
-- Setup: Called from weapon:Initialize()
-- Applies TDMRP tier scaling to the weapon's base stats
----------------------------------------------------

function TDMRP_WeaponMixin.Setup(wep, skipTierReset)
    if not IsValid(wep) then return end

    -- Ensure Primary table exists
    wep.Primary = wep.Primary or {}
    
    -- Check for pending instance (set before Give() call)
    local owner = wep:GetOwner()
    if SERVER and IsValid(owner) and owner:IsPlayer() and not wep.TDMRP_TierLocked then
        local pendingInst = TDMRP.GetPendingInstance(owner, wep:GetClass())
        if pendingInst then
            -- Apply pending instance immediately
            wep.Tier = pendingInst.tier or 1
            wep.TDMRP_TierLocked = true
            wep.TDMRP_PendingFullApply = pendingInst  -- Store for full apply after Setup
            
            -- Apply bind timer from the pending instance if present
            if pendingInst.bound_until and pendingInst.bound_until > 0 then
                local bindExpireTime = CurTime() + pendingInst.bound_until
                wep:SetNWFloat("TDMRP_BindExpire", bindExpireTime)
                wep:SetNWFloat("TDMRP_BindRemaining", pendingInst.bound_until)
                print(string.format("[TDMRP] Setup: applied bind timer from instance - %.1f seconds remaining", pendingInst.bound_until))
            end
            
            print(string.format("[TDMRP] Setup: applied pending instance tier=%d for %s", wep.Tier, wep:GetClass()))
        end
    end

    -- Determine tier - if TDMRP_TierLocked is set, ALWAYS preserve existing tier
    -- This flag is set by ApplyInstanceToSWEP to prevent Equip() from resetting
    local tier = wep.Tier or 1
    
    if wep.TDMRP_TierLocked then
        -- Tier was explicitly set by instance system - preserve it
        tier = wep.Tier or 1
        if SERVER then
            print(string.format("[TDMRP] Setup: tier locked at %d for %s", tier, wep:GetClass()))
        end
    elseif skipTierReset and wep.TDMRP_BaseDamage then
        -- Called with skipTierReset flag and base stats exist - preserve tier
        tier = wep.Tier or 1
    elseif wep.TDMRP_BaseDamage then
        -- Base stats exist from previous Setup - preserve existing tier
        tier = wep.Tier or tier
    else
        -- First Setup call - use SWEP default tier
        wep.Tier = tier
    end
    
    tier = math.Clamp(tier, 1, 4)  -- Enforce 1-4 for normal weapons
    wep.Tier = tier

    -- Try to get base stats from registry first (most reliable)
    local class = wep:GetClass()
    local baseClass = wep.TDMRP_BaseClass or string.gsub(class, "^tdmrp_", "")
    local meta = TDMRP.M9KRegistry and TDMRP.M9KRegistry[baseClass]
    
    -- Store base stats (ONLY use registry or parent SWEP defaults, never use Primary table that might be scaled)
    if not wep.TDMRP_BaseDamage then
        if meta and meta.baseDamage then
            wep.TDMRP_BaseDamage = meta.baseDamage
        else
            -- Fallback to Primary if not in registry
            wep.TDMRP_BaseDamage = wep.Primary.Damage or 25
        end
    end
    
    if not wep.TDMRP_BaseRPM then
        if meta and meta.baseRPM then
            wep.TDMRP_BaseRPM = meta.baseRPM
        else
            -- Fallback to Primary RPM (most weapons not in registry)
            wep.TDMRP_BaseRPM = wep.Primary.RPM or 600
        end
    end
    
    -- If TDMRP_BaseDamage already exists, don't overwrite it (preserves base stats across multiple Setup calls)
    
    if not wep.TDMRP_BaseSpread then
        wep.TDMRP_BaseSpread   = wep.Primary.Spread or 0.03
        wep.TDMRP_BaseKickUp   = wep.Primary.KickUp or 0.5
        wep.TDMRP_BaseKickDown = wep.Primary.KickDown or 0.3
        wep.TDMRP_BaseKickHoriz = wep.Primary.KickHorizontal or 0.2
    end
    
    -- Apply RPM overrides BEFORE scaling (nerf high-RPM weapons)
    if TDMRP and TDMRP.RPMOverrides then
        local overrideRPM = TDMRP.RPMOverrides[wep:GetClass()]
        if overrideRPM then
            wep.TDMRP_BaseRPM = overrideRPM
            if SERVER then
                print(string.format("[TDMRP] RPM override applied to %s: %d RPM", wep:GetClass(), overrideRPM))
            end
        end
    end

    -- Apply tier scaling
    TDMRP_WeaponMixin.ApplyTierScaling(wep, tier)
    
    -- CRITICAL: After tier scaling, reapply craft modifiers if this weapon has been crafted
    -- This ensures prefix/suffix bonuses aren't lost when Setup is called again
    if SERVER then
        local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
        local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
        if prefixId ~= "" or suffixId ~= "" then
            -- Call the gem craft's ApplyAllCraftModifiers to reapply bonuses
            if TDMRP and TDMRP.Gems and TDMRP.Gems.ApplyAllCraftModifiers then
                TDMRP.Gems.ApplyAllCraftModifiers(wep)
            end
        end
    end

    -- Set networked values for HUD display
    TDMRP_WeaponMixin.SetNetworkedStats(wep)

    -- Mark as TDMRP weapon
    wep.IsTDMRPWeapon = true
    
    -- Install modifier hooks
    TDMRP_WeaponMixin.InstallHooks(wep)
    
    -- Initialize slug mode for shotguns (default to buckshot)
    if TDMRP_WeaponMixin.IsSlugEnabled(wep) then
        wep:SetSlugMode(0)  -- 0 = buckshot mode
    end
    
    -- Set Gun class for shotgun reload compatibility
    -- Shotgun base code checks if curwep:GetClass() != self.Gun to prevent timer destruction
    wep.Gun = wep:GetClass()
    
    -- Initialize shot counter for recoil patterns
    wep.TDMRP_ShotsFired = 0

    -- Apply suffix material if present (must be done after all other setup)
    local suffixMaterial = wep:GetNWString("TDMRP_Material", "")
    if suffixMaterial ~= "" then
        wep:SetMaterial(suffixMaterial)
        
        -- Also apply to all submaterials (like active skills does)
        for i = 0, 31 do
            wep:SetSubMaterial(i, suffixMaterial)
        end
        
        -- If weapon has a viewmodel, apply there too
        local owner = wep:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            local vm = owner:GetViewModel()
            if IsValid(vm) then
                vm:SetMaterial(suffixMaterial)
                for i = 0, 31 do
                    vm:SetSubMaterial(i, suffixMaterial)
                end
            end
        end
        
        if SERVER then
            print(string.format("[TDMRP] Applied suffix material to %s: %s", wep:GetClass(), suffixMaterial))
        end
    end

    if SERVER then
        print(string.format("[TDMRP] Initialized %s (Tier %d) - Dmg: %d, RPM: %d, Handling: %d", 
            wep:GetClass(), tier, wep.Primary.Damage or 0, wep.Primary.RPM or 0, wep.TDMRP_Handling or 100))
    end
end

----------------------------------------------------
-- Apply tier scaling to weapon stats
----------------------------------------------------

function TDMRP_WeaponMixin.ApplyTierScaling(wep, tier)
    local scale = TDMRP_WeaponMixin.TierScaling[tier]
    if not scale then
        scale = TDMRP_WeaponMixin.TierScaling[1]
    end

    -- Ensure Primary table exists
    wep.Primary = wep.Primary or {}

    -- Scale damage (round to integer)
    wep.Primary.Damage = math.Round((wep.TDMRP_BaseDamage or 25) * scale.damage)

    -- Scale RPM (round to integer)
    wep.Primary.RPM = math.Round((wep.TDMRP_BaseRPM or 600) * scale.rpm)
    
    -- Recalculate fire delay from RPM
    wep.Primary.Delay = 60 / wep.Primary.RPM

    -- Scale spread (lower = more accurate, so multiply by < 1 for better tiers)
    wep.Primary.Spread = (wep.TDMRP_BaseSpread or 0.03) * scale.spread

    -- Scale recoil (lower = less kick)
    wep.Primary.KickUp = (wep.TDMRP_BaseKickUp or 0.5) * scale.recoil
    wep.Primary.KickDown = (wep.TDMRP_BaseKickDown or 0.3) * scale.recoil
    wep.Primary.KickHorizontal = (wep.TDMRP_BaseKickHoriz or 0.2) * scale.recoil
    
    -- Scale handling (higher = faster draw/ADS)
    wep.TDMRP_Handling = math.Round(100 * (scale.handling or 1))
end

----------------------------------------------------
-- Set networked stats for HUD display
----------------------------------------------------

function TDMRP_WeaponMixin.SetNetworkedStats(wep)
    if not SERVER then return end
    if not IsValid(wep) then return end

    wep:SetNWInt("TDMRP_Tier", wep.Tier or 1)
    wep:SetNWInt("TDMRP_Damage", wep.Primary.Damage or 20)
    wep:SetNWInt("TDMRP_RPM", wep.Primary.RPM or 600)
    
    -- Debug: print what we're setting
    if wep.Primary.RPM then
        print(string.format("[TDMRP] SetNetworkedStats for %s: BaseRPM=%d, Scaled RPM=%d, Tier=%d", 
            wep:GetClass(), wep.TDMRP_BaseRPM or 0, wep.Primary.RPM, wep.Tier or 1))
    end
    
    -- Convert spread to accuracy percentage (0.01 spread = ~97% accuracy)
    local accuracy = math.Clamp(100 - (wep.Primary.Spread or 0.03) * 1000, 0, 100)
    wep:SetNWInt("TDMRP_Accuracy", math.Round(accuracy))
    
    -- Convert recoil to a 0-100 scale (higher = more recoil)
    local recoilScore = math.Clamp((wep.Primary.KickUp or 0.5) * 50, 0, 100)
    wep:SetNWInt("TDMRP_Recoil", math.Round(recoilScore))
    
    -- Handling scaled by tier (100 = base, higher = faster)
    wep:SetNWInt("TDMRP_Handling", wep.TDMRP_Handling or 100)
end

----------------------------------------------------
-- Gem Application (called when gems are socketed)
----------------------------------------------------

function TDMRP_WeaponMixin.ApplyGems(wep, gems)
    if not IsValid(wep) or not gems then return end
    
    -- Sapphire: +15% damage per gem
    local sapphireCount = gems.sapphire or 0
    if sapphireCount > 0 then
        local dmgBonus = 1 + (sapphireCount * 0.15)
        wep.Primary.Damage = math.Round(wep.Primary.Damage * dmgBonus)
    end
    
    -- Emerald: +10% RPM per gem
    local emeraldCount = gems.emerald or 0
    if emeraldCount > 0 then
        local rpmBonus = 1 + (emeraldCount * 0.10)
        wep.Primary.RPM = math.Round(wep.Primary.RPM * rpmBonus)
        wep.Primary.Delay = 60 / wep.Primary.RPM
    end
    
    -- Ruby: -15% recoil per gem
    local rubyCount = gems.ruby or 0
    if rubyCount > 0 then
        local recoilMult = 1 - (rubyCount * 0.15)
        recoilMult = math.max(recoilMult, 0.25)  -- Cap at 75% reduction
        wep.Primary.KickUp = wep.Primary.KickUp * recoilMult
        wep.Primary.KickDown = wep.Primary.KickDown * recoilMult
        wep.Primary.KickHorizontal = wep.Primary.KickHorizontal * recoilMult
    end
    
    -- Diamond: +10% accuracy per gem (reduce spread)
    local diamondCount = gems.diamond or 0
    if diamondCount > 0 then
        local spreadMult = 1 - (diamondCount * 0.10)
        spreadMult = math.max(spreadMult, 0.30)  -- Cap at 70% reduction
        wep.Primary.Spread = wep.Primary.Spread * spreadMult
    end
    
    -- Update networked stats after gem application
    TDMRP_WeaponMixin.SetNetworkedStats(wep)
    
    -- Store gem info
    wep.TDMRP_Gems = gems
end

----------------------------------------------------
-- Binding System Integration
----------------------------------------------------

function TDMRP_WeaponMixin.SetBindTime(wep, bindUntil)
    if not SERVER then return end
    if not IsValid(wep) then return end
    
    wep:SetNWFloat("TDMRP_BindUntil", bindUntil or 0)
    wep.TDMRP_BindUntil = bindUntil
end

function TDMRP_WeaponMixin.GetBindTime(wep)
    if not IsValid(wep) then return 0 end
    return wep:GetNWFloat("TDMRP_BindUntil", 0)
end

function TDMRP_WeaponMixin.IsBound(wep)
    local bindUntil = TDMRP_WeaponMixin.GetBindTime(wep)
    return bindUntil > CurTime()
end

----------------------------------------------------
-- Crafting System Integration
----------------------------------------------------

function TDMRP_WeaponMixin.SetCrafted(wep, crafted, prefixId, suffixId)
    if not SERVER then return end
    if not IsValid(wep) then return end
    
    wep:SetNWBool("TDMRP_Crafted", crafted or false)
    wep:SetNWString("TDMRP_PrefixID", prefixId or "")
    wep:SetNWString("TDMRP_SuffixID", suffixId or "")
end

----------------------------------------------------
-- TDMRP Weapon Detection Helper
----------------------------------------------------

function TDMRP_IsTDMRPWeapon(wepOrClass)
    if not wepOrClass then return false end
    
    local className = nil
    if type(wepOrClass) == "string" then
        className = wepOrClass
    elseif IsEntity(wepOrClass) and wepOrClass.GetClass then
        className = wepOrClass:GetClass()
    end
    
    if not className then return false end
    
    -- Check if it's a tdmrp_m9k_* weapon
    return string.StartWith(className, "tdmrp_m9k_")
end

----------------------------------------------------
-- Get the base M9K class for a TDMRP weapon
----------------------------------------------------

function TDMRP_GetBaseM9KClass(tdmrpClass)
    if not tdmrpClass then return nil end
    
    -- tdmrp_m9k_glock -> m9k_glock
    if string.StartWith(tdmrpClass, "tdmrp_") then
        return string.sub(tdmrpClass, 7)  -- Remove "tdmrp_" prefix
    end
    
    return nil
end

----------------------------------------------------
-- Get the TDMRP class for a base M9K weapon
----------------------------------------------------

function TDMRP_GetTDMRPClass(m9kClass)
    if not m9kClass then return nil end
    
    -- m9k_glock -> tdmrp_m9k_glock
    if string.StartWith(m9kClass, "m9k_") then
        return "tdmrp_" .. m9kClass
    end
    
    return nil
end

----------------------------------------------------
-- EntityFireBullets Hook - Override tracer for TDMRP weapons
-- CLIENT ONLY: Tracers are visual effects
----------------------------------------------------

if CLIENT then
    hook.Add("EntityFireBullets", "TDMRP_CustomTracers", function(entity, data)
        -- Check if entity is a player with a weapon
        if not IsValid(entity) or not entity:IsPlayer() then return end
        
        -- BUGFIX: Disable the broken M9K ricochet tracer effect
        -- The effect has a bug where it doesn't properly set up Start/End positions,
        -- causing perpendicular tracer lines to render
        if data.TracerName == "m9k_effect_mad_ricochet_trace" then
            data.Tracer = 0
            data.TracerName = ""
            return true
        end
        
        local wep = entity:GetActiveWeapon()
        if not IsValid(wep) then return end
        
        -- Check if weapon has a custom tracer set (networked via NWString)
        local customTracer = wep:GetNWString("TDMRP_TracerName", "")
        if customTracer ~= "" then
            data.TracerName = customTracer
            data.Tracer = 1 -- Show tracer on EVERY bullet (instead of every 3rd)
            return true -- Modify bullet data
        end
    end)
end

----------------------------------------------------
-- Slug Mode System for Shotguns
----------------------------------------------------

-- Check if weapon supports slug mode
function TDMRP_WeaponMixin.IsSlugEnabled(wep)
    if not IsValid(wep) then return false end
    
    -- Get base M9K class
    local baseClass = string.gsub(wep:GetClass(), "^tdmrp_", "")
    local meta = TDMRP.M9KRegistry and TDMRP.M9KRegistry[baseClass]
    
    return meta and meta.slugEnabled == true
end

-- Get current slug mode (0=buckshot, 1=slug)
function TDMRP_WeaponMixin.GetSlugMode(wep)
    if not IsValid(wep) then return 0 end
    return wep:GetNWInt("TDMRP_ShotgunMode", 0)
end

-- Set slug mode
function TDMRP_WeaponMixin.SetSlugMode(wep, mode)
    if not IsValid(wep) then return end
    wep:SetNWInt("TDMRP_ShotgunMode", mode)
end

-- Toggle slug mode (server-side with validation)
if SERVER then
    function TDMRP_WeaponMixin.ToggleSlugMode(wep, ply)
        if not IsValid(wep) or not IsValid(ply) then return false end
        local isSlugEnabled = wep.IsSlugEnabled and wep:IsSlugEnabled() or TDMRP_WeaponMixin.IsSlugEnabled(wep)
        if not isSlugEnabled then return false end
        
        -- Check ammo availability
        local ammoType = wep:GetPrimaryAmmoType()
        if ply:GetAmmoCount(ammoType) < 1 then
            ply:ChatPrint("[TDMRP] Need at least 1 shell to switch modes.")
            return false
        end
        
        -- Force reload animation/sound
        wep:SendWeaponAnim(ACT_VM_RELOAD)
        ply:EmitSound("weapons/shotgun/shotgun_reload" .. math.random(1,3) .. ".wav")
        
        -- Consume ammo
        ply:RemoveAmmo(1, ammoType)
        
        -- Toggle mode
        local newMode = wep:GetSlugMode() == 0 and 1 or 0
        wep:SetSlugMode(newMode)
        
        -- Network to client for HUD
        net.Start("TDMRP_ShotgunModeChanged")
            net.WriteEntity(wep)
            net.WriteInt(newMode, 4)
        net.Send(ply)
        
        return true
    end
end

-- Override fire sound based on mode
function TDMRP_WeaponMixin.GetFireSound(wep)
    if not IsValid(wep) then return "weapons/shotgun/shotgun_fire.wav" end
    
    if wep:GetSlugMode() == 1 then
        -- Slug mode: random from 3 sounds
        local slugSounds = {
            "tdmrp/slugsounds/slugshot.wav",
            "tdmrp/slugsounds/slugshot2.wav", 
            "tdmrp/slugsounds/slugshot3.wav"
        }
        return slugSounds[math.random(#slugSounds)]
    else
        -- Buckshot mode: use original sound
        if wep.TDMRP_Orig_GetFireSound then
            return wep:TDMRP_Orig_GetFireSound()
        end
        return "weapons/shotgun/shotgun_fire.wav"
    end
end

print("[TDMRP] sh_tdmrp_weapon_mixin.lua loaded")
