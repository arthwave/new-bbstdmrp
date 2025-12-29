-- cl_tdmrp_hitnumbers.lua
-- Draws floating damage numbers at hit locations (with headshot crits)

if not CLIENT then return end

local hitNums = {}

surface.CreateFont("TDMRP_HitNum", {
    font = "Tahoma",
    size = 32,
    weight = 800,
    antialias = true,
})

surface.CreateFont("TDMRP_HitNumBig", {
    font = "Tahoma",
    size = 64,
    weight = 900,
    antialias = true,
})

surface.CreateFont("TDMRP_ChainDamage", {
    font = "Tahoma",
    size = 24,
    weight = 600,
    antialias = true,
})

net.Receive("TDMRP_HitNumber", function()
    local pos        = net.ReadVector()
    local dmg        = net.ReadUInt(16)
    local isHeadshot = net.ReadBool()
    local isKill     = net.ReadBool()

    table.insert(hitNums, {
        pos        = pos,
        dmg        = dmg,
        headshot   = isHeadshot,
        kill       = isKill,
        born       = CurTime(),
        life       = isHeadshot and 0.9 or 0.6, -- headshots hang around a bit longer
        drift      = VectorRand() * 2 + Vector(0, 0, isHeadshot and 20 or 14),
    })
end)

net.Receive("TDMRP_ChainDamage", function()
    local pos = net.ReadVector()
    local dmg = net.ReadUInt(16)

    table.insert(hitNums, {
        pos        = pos,
        dmg        = dmg,
        headshot   = false,
        kill       = false,
        born       = CurTime(),
        life       = 0.5,  -- Chain damage disappears faster
        drift      = VectorRand() * 1 + Vector(0, 0, 8),  -- Smaller drift
        isChain    = true,  -- Flag to use different color/font
    })
end)

hook.Add("HUDPaint", "TDMRP_DrawHitNumbers", function()
    if #hitNums == 0 then return end

    local now = CurTime()

    for i = #hitNums, 1, -1 do
        local data = hitNums[i]
        local age  = now - data.born
        local frac = age / data.life

        if frac >= 1 then
            table.remove(hitNums, i)
        else
            local worldPos = data.pos + data.drift * frac
            local screen   = worldPos:ToScreen()

            if screen.visible then
                -- Fade out over time
                local alpha = 255 * (1 - frac)

                local txt  = tostring(data.dmg)
                local col
                local fontName

                if data.isChain then
                    -- Pale light blue for chain lightning damage (smaller)
                    fontName = "TDMRP_ChainDamage"
                    col      = Color(150, 200, 255, alpha)  -- Pale light blue
                elseif data.headshot then
                    -- Big dark red for headshots
                    fontName = "TDMRP_HitNumBig"

                    if data.kill then
                        -- Extra dark red for lethal headshots
                        col = Color(200, 10, 10, alpha)
                    else
                        col = Color(220, 20, 20, alpha)
                    end
                else
                    fontName = "TDMRP_HitNum"
                    col      = Color(255, 255, 255, alpha)
                end

                surface.SetFont(fontName)
                local tw, th = surface.GetTextSize(txt)

                draw.SimpleTextOutlined(
                    txt,
                    fontName,
                    screen.x - tw / 2,
                    screen.y - th / 2,
                    col,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_TOP,
                    1,
                    Color(0, 0, 0, alpha)
                )
            end
        end
    end
end)
