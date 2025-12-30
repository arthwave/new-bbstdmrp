----------------------------------------------------
-- TDMRP Spawn Menu Debug Tool
-- Run these commands in console to diagnose spawn menu issues
----------------------------------------------------

if SERVER then return end

-- Debug command to check spawn menu state
concommand.Add("tdmrp_debug_spawnmenu", function()
    print("[TDMRP Debug] ========== SPAWN MENU DIAGNOSTICS ==========")
    
    -- Check gamemode
    local gm = gmod.GetGamemode()
    print("[TDMRP Debug] Current gamemode: " .. tostring(gm and gm.Name or "nil"))
    print("[TDMRP Debug] Gamemode folder: " .. tostring(gm and gm.FolderName or "nil"))
    
    -- Check if GM functions exist
    print("\n[TDMRP Debug] === Checking GM functions ===")
    print("[TDMRP Debug] GM:SpawnMenuEnabled exists: " .. tostring(gm and gm.SpawnMenuEnabled ~= nil))
    print("[TDMRP Debug] GM:SpawnMenuOpen exists: " .. tostring(gm and gm.SpawnMenuOpen ~= nil))
    print("[TDMRP Debug] GM:ContextMenuEnabled exists: " .. tostring(gm and gm.ContextMenuEnabled ~= nil))
    print("[TDMRP Debug] GM:ContextMenuOpen exists: " .. tostring(gm and gm.ContextMenuOpen ~= nil))
    print("[TDMRP Debug] GM:OnSpawnMenuOpen exists: " .. tostring(gm and gm.OnSpawnMenuOpen ~= nil))
    
    -- Check sandbox base
    print("\n[TDMRP Debug] === Checking Sandbox inheritance ===")
    print("[TDMRP Debug] GM.Sandbox exists: " .. tostring(gm and gm.Sandbox ~= nil))
    if gm and gm.Sandbox then
        print("[TDMRP Debug] GM.Sandbox.SpawnMenuEnabled exists: " .. tostring(gm.Sandbox.SpawnMenuEnabled ~= nil))
        print("[TDMRP Debug] GM.Sandbox.OnSpawnMenuOpen exists: " .. tostring(gm.Sandbox.OnSpawnMenuOpen ~= nil))
    end
    
    -- Check if spawnmenu module loaded
    print("\n[TDMRP Debug] === Checking spawnmenu module ===")
    print("[TDMRP Debug] spawnmenu table exists: " .. tostring(spawnmenu ~= nil))
    if spawnmenu then
        print("[TDMRP Debug] spawnmenu.GetToolMenu exists: " .. tostring(spawnmenu.GetToolMenu ~= nil))
        print("[TDMRP Debug] spawnmenu.AddCreationTab exists: " .. tostring(spawnmenu.AddCreationTab ~= nil))
    end
    
    -- Check if spawn menu exists
    local spawnMenu = g_SpawnMenu
    print("\n[TDMRP Debug] === Spawn menu state ===")
    print("[TDMRP Debug] g_SpawnMenu exists: " .. tostring(IsValid(spawnMenu)))
    
    -- Check SpawnMenuEnabled hook results
    local enabled = hook.Run("SpawnMenuEnabled")
    print("[TDMRP Debug] SpawnMenuEnabled result: " .. tostring(enabled))
    
    -- Check SpawnMenuOpen hook results
    local canOpen = hook.Run("SpawnMenuOpen")
    print("[TDMRP Debug] SpawnMenuOpen result: " .. tostring(canOpen))
    
    -- Check ContextMenuEnabled hook results
    local contextEnabled = hook.Run("ContextMenuEnabled")
    print("[TDMRP Debug] ContextMenuEnabled result: " .. tostring(contextEnabled))
    
    -- Check ContextMenuOpen hook results
    local contextCanOpen = hook.Run("ContextMenuOpen")
    print("[TDMRP Debug] ContextMenuOpen result: " .. tostring(contextCanOpen))
    
    -- List all hooks on these events
    print("\n[TDMRP Debug] === Hooks on SpawnMenuEnabled ===")
    local spawnEnabledHooks = hook.GetTable()["SpawnMenuEnabled"]
    if spawnEnabledHooks then
        for name, func in pairs(spawnEnabledHooks) do
            print("  - " .. tostring(name))
        end
    else
        print("  (No hooks)")
    end
    
    print("\n[TDMRP Debug] === Hooks on SpawnMenuOpen ===")
    local spawnOpenHooks = hook.GetTable()["SpawnMenuOpen"]
    if spawnOpenHooks then
        for name, func in pairs(spawnOpenHooks) do
            print("  - " .. tostring(name))
        end
    else
        print("  (No hooks)")
    end
    
    print("\n[TDMRP Debug] === Hooks on ContextMenuEnabled ===")
    local contextEnabledHooks = hook.GetTable()["ContextMenuEnabled"]
    if contextEnabledHooks then
        for name, func in pairs(contextEnabledHooks) do
            print("  - " .. tostring(name))
        end
    else
        print("  (No hooks)")
    end
    
    print("\n[TDMRP Debug] === Hooks on ContextMenuOpen ===")
    local contextOpenHooks = hook.GetTable()["ContextMenuOpen"]
    if contextOpenHooks then
        for name, func in pairs(contextOpenHooks) do
            print("  - " .. tostring(name))
        end
    else
        print("  (No hooks)")
    end
    
    print("\n[TDMRP Debug] === Hooks on PlayerBindPress ===")
    local bindHooks = hook.GetTable()["PlayerBindPress"]
    if bindHooks then
        for name, func in pairs(bindHooks) do
            print("  - " .. tostring(name))
        end
    else
        print("  (No hooks)")
    end
    
    -- Check for APAnti blocking hook
    print("\n[TDMRP Debug] === Checking for known blockers ===")
    local apantiHook = hook.GetTable()["PlayerBindPress"] and hook.GetTable()["PlayerBindPress"]["_sBlockGMSpawn"]
    print("[TDMRP Debug] APAnti _sBlockGMSpawn hook exists: " .. tostring(apantiHook ~= nil))
    
    print("\n[TDMRP Debug] ========== END DIAGNOSTICS ==========")
end)

-- Force open spawn menu command
concommand.Add("tdmrp_force_spawnmenu", function()
    print("[TDMRP Debug] Attempting to force open spawn menu...")
    if IsValid(g_SpawnMenu) then
        g_SpawnMenu:Open()
        print("[TDMRP Debug] Spawn menu opened successfully!")
    else
        print("[TDMRP Debug] ERROR: g_SpawnMenu is not valid!")
        print("[TDMRP Debug] Attempting to reload spawn menu...")
        RunConsoleCommand("spawnmenu_reload")
    end
end)

-- Force open context menu command
concommand.Add("tdmrp_force_contextmenu", function()
    print("[TDMRP Debug] Attempting to force open context menu...")
    if IsValid(g_ContextMenu) then
        g_ContextMenu:Open()
        print("[TDMRP Debug] Context menu opened successfully!")
    else
        print("[TDMRP Debug] ERROR: g_ContextMenu is not valid!")
    end
end)

-- FIX COMMAND: Force-create spawn menu by injecting missing GM functions
concommand.Add("tdmrp_fix_spawnmenu", function()
    print("[TDMRP Fix] Attempting to fix spawn menu...")
    
    local gm = gmod.GetGamemode()
    if not gm then
        print("[TDMRP Fix] ERROR: No gamemode found!")
        return
    end
    
    -- Test what the functions actually return when called directly
    print("[TDMRP Fix] Testing direct function calls...")
    if gm.SpawnMenuEnabled then
        local result = gm:SpawnMenuEnabled()
        print("[TDMRP Fix] GM:SpawnMenuEnabled() returned: " .. tostring(result) .. " (type: " .. type(result) .. ")")
    end
    
    if gm.ContextMenuEnabled then
        local result = gm:ContextMenuEnabled()
        print("[TDMRP Fix] GM:ContextMenuEnabled() returned: " .. tostring(result) .. " (type: " .. type(result) .. ")")
    end
    
    -- Check if GAMEMODE is set
    print("[TDMRP Fix] GAMEMODE exists: " .. tostring(GAMEMODE ~= nil))
    if GAMEMODE and GAMEMODE.SpawnMenuEnabled then
        local result = GAMEMODE:SpawnMenuEnabled()
        print("[TDMRP Fix] GAMEMODE:SpawnMenuEnabled() returned: " .. tostring(result) .. " (type: " .. type(result) .. ")")
    end
    
    -- Force the functions to return true
    print("[TDMRP Fix] Overriding spawn menu functions to return true...")
    
    local oldSpawnMenuEnabled = gm.SpawnMenuEnabled
    function gm:SpawnMenuEnabled()
        return true
    end
    
    local oldSpawnMenuOpen = gm.SpawnMenuOpen  
    function gm:SpawnMenuOpen()
        return true
    end
    
    local oldContextMenuEnabled = gm.ContextMenuEnabled
    function gm:ContextMenuEnabled()
        return true
    end
    
    local oldContextMenuOpen = gm.ContextMenuOpen
    function gm:ContextMenuOpen()
        return true
    end
    
    -- Also set on GAMEMODE if it's different
    if GAMEMODE and GAMEMODE ~= gm then
        GAMEMODE.SpawnMenuEnabled = gm.SpawnMenuEnabled
        GAMEMODE.SpawnMenuOpen = gm.SpawnMenuOpen
        GAMEMODE.ContextMenuEnabled = gm.ContextMenuEnabled
        GAMEMODE.ContextMenuOpen = gm.ContextMenuOpen
    end
    
    print("[TDMRP Fix] Reloading spawn menu...")
    RunConsoleCommand("spawnmenu_reload")
    
    timer.Simple(0.5, function()
        if IsValid(g_SpawnMenu) then
            print("[TDMRP Fix] SUCCESS! Spawn menu created! Press Q to open.")
        else
            print("[TDMRP Fix] Spawn menu still not created. Trying manual creation...")
            
            -- Try to manually trigger the creation
            hook.Run("OnGamemodeLoaded")
            
            timer.Simple(0.5, function()
                if IsValid(g_SpawnMenu) then
                    print("[TDMRP Fix] SUCCESS after OnGamemodeLoaded! Press Q to open.")
                else
                    print("[TDMRP Fix] FAILED. Manual intervention needed.")
                end
            end)
        end
    end)
end)

-- Deep diagnostic command
concommand.Add("tdmrp_deep_debug", function()
    print("[TDMRP Deep] ========== DEEP DIAGNOSTICS ==========")
    
    local gm = gmod.GetGamemode()
    
    -- Check the actual function source
    print("\n[TDMRP Deep] === Function inspection ===")
    if gm.SpawnMenuEnabled then
        print("[TDMRP Deep] GM.SpawnMenuEnabled type: " .. type(gm.SpawnMenuEnabled))
        local info = debug.getinfo(gm.SpawnMenuEnabled, "S")
        if info then
            print("[TDMRP Deep] Defined in: " .. tostring(info.source) .. " line " .. tostring(info.linedefined))
        end
        
        -- Try calling it
        local success, result = pcall(function() return gm:SpawnMenuEnabled() end)
        print("[TDMRP Deep] Call success: " .. tostring(success) .. ", result: " .. tostring(result))
    end
    
    -- Check OnGamemodeLoaded hooks
    print("\n[TDMRP Deep] === OnGamemodeLoaded hooks ===")
    local hooks = hook.GetTable()["OnGamemodeLoaded"]
    if hooks then
        for name, func in pairs(hooks) do
            print("  - " .. tostring(name))
        end
    else
        print("  (No hooks)")
    end
    
    -- Check if CreateSpawnMenu exists
    print("\n[TDMRP Deep] === CreateSpawnMenu check ===")
    local createHook = hooks and hooks["CreateSpawnMenu"]
    print("[TDMRP Deep] CreateSpawnMenu hook exists: " .. tostring(createHook ~= nil))
    
    -- List all sandbox includes
    print("\n[TDMRP Deep] === Checking sandbox files ===")
    local sandboxPath = "gamemodes/sandbox/gamemode/"
    print("[TDMRP Deep] cl_spawnmenu.lua exists: " .. tostring(file.Exists(sandboxPath .. "cl_spawnmenu.lua", "GAME")))
    print("[TDMRP Deep] spawnmenu/spawnmenu.lua exists: " .. tostring(file.Exists(sandboxPath .. "spawnmenu/spawnmenu.lua", "GAME")))
    print("[TDMRP Deep] spawnmenu/contextmenu.lua exists: " .. tostring(file.Exists(sandboxPath .. "spawnmenu/contextmenu.lua", "GAME")))
    
    print("\n[TDMRP Deep] ========== END DEEP DIAGNOSTICS ==========")
end)

-- Direct spawn menu creation command
concommand.Add("tdmrp_create_spawnmenu", function()
    print("[TDMRP Create] ========== MANUAL SPAWN MENU CREATION ==========")
    
    -- First check if SpawnMenuEnabled returns true via hook.Run
    print("[TDMRP Create] Testing hook.Run('SpawnMenuEnabled')...")
    local enabledResult = hook.Run("SpawnMenuEnabled")
    print("[TDMRP Create] hook.Run('SpawnMenuEnabled') = " .. tostring(enabledResult))
    
    if not enabledResult then
        print("[TDMRP Create] SpawnMenuEnabled returned false/nil - this is the problem!")
        print("[TDMRP Create] Forcing it to work...")
        
        -- Add a hook that returns true
        hook.Add("SpawnMenuEnabled", "TDMRP_ForceEnable", function()
            return true
        end)
        
        enabledResult = hook.Run("SpawnMenuEnabled")
        print("[TDMRP Create] After adding hook, result = " .. tostring(enabledResult))
    end
    
    -- Remove old spawn menu if exists
    if IsValid(g_SpawnMenu) then
        print("[TDMRP Create] Removing old spawn menu...")
        g_SpawnMenu:Remove()
        g_SpawnMenu = nil
    end
    
    -- Try to manually create
    print("[TDMRP Create] Running PreReloadToolsMenu...")
    hook.Run("PreReloadToolsMenu")
    
    print("[TDMRP Create] Clearing tool menus...")
    spawnmenu.ClearToolMenus()
    
    print("[TDMRP Create] Running AddGamemodeToolMenuTabs...")
    hook.Run("AddGamemodeToolMenuTabs")
    
    print("[TDMRP Create] Running AddToolMenuTabs...")
    hook.Run("AddToolMenuTabs")
    
    print("[TDMRP Create] Running AddGamemodeToolMenuCategories...")
    hook.Run("AddGamemodeToolMenuCategories")
    
    print("[TDMRP Create] Running AddToolMenuCategories...")
    hook.Run("AddToolMenuCategories")
    
    print("[TDMRP Create] Running PopulateToolMenu...")
    hook.Run("PopulateToolMenu")
    
    print("[TDMRP Create] Creating SpawnMenu vgui panel...")
    local success, err = pcall(function()
        g_SpawnMenu = vgui.Create("SpawnMenu")
    end)
    
    if not success then
        print("[TDMRP Create] ERROR creating SpawnMenu: " .. tostring(err))
        return
    end
    
    if IsValid(g_SpawnMenu) then
        print("[TDMRP Create] SpawnMenu panel created successfully!")
        g_SpawnMenu:SetVisible(false)
        hook.Run("SpawnMenuCreated", g_SpawnMenu)
        
        -- Also create context menu
        print("[TDMRP Create] Creating context menu...")
        if CreateContextMenu then
            CreateContextMenu()
        end
        
        hook.Run("PostReloadToolsMenu")
        print("[TDMRP Create] SUCCESS! Press Q to open the spawn menu.")
    else
        print("[TDMRP Create] FAILED - g_SpawnMenu is not valid after creation")
    end
    
    print("[TDMRP Create] ========== END ==========")
end)

-- Check for vgui registration
concommand.Add("tdmrp_check_vgui", function()
    print("[TDMRP VGUI] ========== VGUI CHECK ==========")
    
    -- Check if SpawnMenu panel type is registered
    local spawnMenuRegistered = vgui.GetControlTable("SpawnMenu")
    print("[TDMRP VGUI] SpawnMenu registered: " .. tostring(spawnMenuRegistered ~= nil))
    
    local contextMenuRegistered = vgui.GetControlTable("ContextMenu") 
    print("[TDMRP VGUI] ContextMenu registered: " .. tostring(contextMenuRegistered ~= nil))
    
    -- Check DFrame as a baseline
    local dframeRegistered = vgui.GetControlTable("DFrame")
    print("[TDMRP VGUI] DFrame registered: " .. tostring(dframeRegistered ~= nil))
    
    if not spawnMenuRegistered then
        print("[TDMRP VGUI] SpawnMenu panel not registered! This is the problem.")
        print("[TDMRP VGUI] The spawnmenu/spawnmenu.lua file may not have loaded properly.")
    end
    
    print("[TDMRP VGUI] ========== END ==========")
end)

print("[TDMRP] Spawn menu debug tools loaded. Use 'tdmrp_debug_spawnmenu' in console to diagnose issues.")
