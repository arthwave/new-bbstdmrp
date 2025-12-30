----------------------------------------------------
-- TDMRP Spawn Menu Fix
-- Fixes spawn menu not working due to key bind interception
-- 
-- Root cause: Something is preventing the +menu/+menu_context
-- binds from reaching GM:OnSpawnMenuOpen/OnContextMenuOpen
-- 
-- Solution: Hook PlayerBindPress at high priority to handle
-- spawn menu and context menu binds directly
----------------------------------------------------

if SERVER then return end

local function ApplySpawnMenuFix()
    print("[TDMRP SpawnFix] Applying spawn menu hooks...")
    
    -- These hooks ensure spawn menu functions return true
    hook.Add("SpawnMenuEnabled", "TDMRP_EnableSpawnMenu", function()
        return true
    end)
    
    hook.Add("SpawnMenuOpen", "TDMRP_AllowSpawnMenuOpen", function()
        return true
    end)
    
    hook.Add("ContextMenuEnabled", "TDMRP_EnableContextMenu", function()
        return true
    end)
    
    hook.Add("ContextMenuOpen", "TDMRP_AllowContextMenuOpen", function()
        return true
    end)
end

-- Apply immediately
ApplySpawnMenuFix()

----------------------------------------------------
-- KEY BIND FIX: Manually handle Q and C keys
----------------------------------------------------

-- Track menu state for toggle behavior
local spawnMenuOpen = false
local contextMenuOpen = false

-- Handle spawn menu (Q key / +menu bind)
local function OpenSpawnMenu()
    if not IsValid(g_SpawnMenu) then 
        RunConsoleCommand("spawnmenu_reload")
        return 
    end
    
    spawnMenuOpen = true
    g_SpawnMenu:Open()
    if menubar then menubar.ParentTo(g_SpawnMenu) end
    hook.Run("SpawnMenuOpened")
end

local function CloseSpawnMenu()
    if not IsValid(g_SpawnMenu) then return end
    
    spawnMenuOpen = false
    g_SpawnMenu:Close()
    hook.Run("SpawnMenuClosed")
end

-- Handle context menu (C key / +menu_context bind)
local function OpenContextMenu()
    if not IsValid(g_ContextMenu) then return end
    
    contextMenuOpen = true
    g_ContextMenu:Open()
    hook.Run("ContextMenuOpened")
end

local function CloseContextMenu()
    if not IsValid(g_ContextMenu) then return end
    
    contextMenuOpen = false
    g_ContextMenu:Close()
    hook.Run("ContextMenuClosed")
end

-- Hook into PlayerBindPress with high priority to catch menu binds
hook.Add("PlayerBindPress", "TDMRP_SpawnMenuKeyFix", function(ply, bind, pressed)
    local bindLower = string.lower(bind)
    
    -- Handle spawn menu (+menu is the Q key bind)
    if string.find(bindLower, "+menu") and not string.find(bindLower, "context") then
        if pressed then
            -- Check if we should open
            if not hook.Run("SpawnMenuOpen") then return true end
            
            if spawnMenuOpen and IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
                -- Already open, close it (toggle behavior)
                CloseSpawnMenu()
            else
                OpenSpawnMenu()
            end
        else
            -- Key released - close menu (hold behavior)
            -- Only close if spawnmenu_toggle cvar is off
            local toggle = GetConVar("spawnmenu_toggle")
            if not toggle or not toggle:GetBool() then
                CloseSpawnMenu()
            end
        end
        return true -- Block default handling since we handled it
    end
    
    -- Handle context menu (+menu_context is the C key bind)
    if string.find(bindLower, "+menu_context") or string.find(bindLower, "menu_context") then
        if pressed then
            -- Check if we should open
            if not hook.Run("ContextMenuOpen") then return true end
            
            if contextMenuOpen and IsValid(g_ContextMenu) and g_ContextMenu:IsVisible() then
                -- Already open, close it (toggle behavior)
                CloseContextMenu()
            else
                OpenContextMenu()
            end
        else
            -- Key released - close menu
            local toggle = GetConVar("context_menu_toggle")
            if not toggle or not toggle:GetBool() then
                CloseContextMenu()
            end
        end
        return true -- Block default handling since we handled it
    end
end)

-- Also handle -menu and -menu_context for key release
hook.Add("PlayerBindPress", "TDMRP_SpawnMenuKeyRelease", function(ply, bind, pressed)
    local bindLower = string.lower(bind)
    
    if string.find(bindLower, "-menu") and not string.find(bindLower, "context") then
        local toggle = GetConVar("spawnmenu_toggle")
        if not toggle or not toggle:GetBool() then
            CloseSpawnMenu()
        end
        return true
    end
    
    if string.find(bindLower, "-menu_context") then
        local toggle = GetConVar("context_menu_toggle")
        if not toggle or not toggle:GetBool() then
            CloseContextMenu()
        end
        return true
    end
end)

-- Sync our state with actual menu visibility
hook.Add("Think", "TDMRP_SpawnMenuStateSync", function()
    if IsValid(g_SpawnMenu) then
        spawnMenuOpen = g_SpawnMenu:IsVisible()
    end
    if IsValid(g_ContextMenu) then
        contextMenuOpen = g_ContextMenu:IsVisible()
    end
end)

----------------------------------------------------
-- INITIALIZATION
----------------------------------------------------

hook.Add("InitPostEntity", "TDMRP_SpawnMenuFix_Init", function()
    print("[TDMRP SpawnFix] InitPostEntity - ensuring spawn menu exists...")
    ApplySpawnMenuFix()
    
    -- Force reload spawn menu if it wasn't created
    timer.Simple(1, function()
        if not IsValid(g_SpawnMenu) then
            print("[TDMRP SpawnFix] Spawn menu not found, creating...")
            RunConsoleCommand("spawnmenu_reload")
        else
            print("[TDMRP SpawnFix] Spawn menu ready!")
        end
    end)
end)

----------------------------------------------------
-- DEBUG COMMANDS
----------------------------------------------------

concommand.Add("tdmrp_spawnfix_status", function()
    print("[TDMRP SpawnFix] ========== STATUS ==========")
    print("[TDMRP SpawnFix] g_SpawnMenu valid: " .. tostring(IsValid(g_SpawnMenu)))
    print("[TDMRP SpawnFix] g_ContextMenu valid: " .. tostring(IsValid(g_ContextMenu)))
    print("[TDMRP SpawnFix] spawnMenuOpen state: " .. tostring(spawnMenuOpen))
    print("[TDMRP SpawnFix] contextMenuOpen state: " .. tostring(contextMenuOpen))
    print("[TDMRP SpawnFix] hook.Run('SpawnMenuEnabled') = " .. tostring(hook.Run("SpawnMenuEnabled")))
    print("[TDMRP SpawnFix] hook.Run('SpawnMenuOpen') = " .. tostring(hook.Run("SpawnMenuOpen")))
    
    -- Check our bind hook exists
    local hookTable = hook.GetTable()
    print("[TDMRP SpawnFix] TDMRP_SpawnMenuKeyFix hook exists: " .. tostring(hookTable["PlayerBindPress"] and hookTable["PlayerBindPress"]["TDMRP_SpawnMenuKeyFix"] ~= nil))
    
    print("[TDMRP SpawnFix] ========== END ==========")
end)

concommand.Add("tdmrp_open_spawnmenu", function()
    OpenSpawnMenu()
end)

concommand.Add("tdmrp_close_spawnmenu", function()
    CloseSpawnMenu()
end)

concommand.Add("tdmrp_open_contextmenu", function()
    OpenContextMenu()
end)

concommand.Add("tdmrp_close_contextmenu", function()
    CloseContextMenu()
end)

print("[TDMRP SpawnFix] Spawn menu fix loaded - Q/C keys should now work!")
