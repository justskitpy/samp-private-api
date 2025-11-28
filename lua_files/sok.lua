-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz

script_author('@justluaarz')
script_name('Lesopilka-Helper')

local imgui = require('mimgui')
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local sampev = require("lib.samp.events")
local effil = require('effil')
local ffi = require('ffi')
local inicfg = require('inicfg')

local botikstate = imgui.new.bool(false)
local menules = imgui.new.bool(false)
local les_state = "IDLE"
local successCut = false
local les_last_fix_zabor_id = 1
local les_last_jump = 0
local les_last_alt = false
local les_set_wait_alt = 0
local lastEatCheck = 0
local eatInterval = 18*10000
local eatp = 20
local findeat = nil
local les_state_before_eat = nil

local les_fix_zabors_random = {
{-526.053, -168.167, 78.206},
{-497.337, -166.059, 77.169}
}

local les_fix_zabors_cut = {
{-523.053, -168.167, 78.206},
{-497.337, -166.059, 77.169}
}

local les_ignore_trees = {
{-562, -135, 72}
}

local les_center_coords = {
{-511.055786132, -169.019500732, 75.8674774},
{-512.460205078, -148.792236328, 73.2221069},
{-513.005432128, -135.199645996, 70.3452224},
{-513.298828125, -123.202331548, 66.9921875},
{-512.765991210, -104.848159790, 63.5846252},
{-511.860595703, -86.7380676269, 62.1677665},
{-511.542388912, -147.507537841, 73.0059661},
{-512.583374024, -190.684219365, 78.2473602}
}

local les_road_points = {
{x = -512.693359375, y = -190.7613067627, z = 78.250762939453},
{x = -506.49435424805, y = -14.57945728302, z = 56.492931365967}
}

local function les_cMsg(text)
sampAddChatMessage('{99cc66}[Lesopilka-Helper]: {FFFFFF}' .. text, -1)
end

local function les_lineVec(point1, point2, distance)
local dx = point2.x - point1.x
local dy = point2.y - point1.y

local length = math.sqrt(dx * dx + dy * dy)
if length == 0 then return {x = point1.x, y = point1.y} end
    local normalized_dx = dx / length
    local normalized_dy = dy / length
    local new_x = point1.x - normalized_dx * distance
    local new_y = point1.y - normalized_dy * distance
    return {x = new_x, y = new_y}

end

local function les_distPoint(x, y, z)
local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
if not mX then return 1e6 end
    local distance = getDistanceBetweenCoords3d(mX, mY, mZ, x, y, z)
    return distance
end

local function les_coordsIn(el, _table)
for _, v in pairs(_table) do
    local dist = getDistanceBetweenCoords2d(el[1], el[2], v[1], v[2])
    if dist < 1 then
        return true
    end
end
return false
end

local function les_noPlayersAround(point, radius)
local radius = radius or 3
for _, player in ipairs(getAllChars()) do
    if select(1, sampGetPlayerIdByCharHandle(player)) and player ~= PLAYER_PED then
        local plX, plY, plZ = getCharCoordinates(player)
        if plX then
            local dist = getDistanceBetweenCoords3d(plX, plY, plZ, point[1], point[2], point[3])
            if dist < radius then return false end
            end
        end
    end
    return true
end

local function les_set_camera_direction(point)
local c_pos_x, c_pos_y, c_pos_z = getActiveCameraCoordinates()
if not c_pos_x then return end
    local vect = {x = point[1] - c_pos_x, y = point[2] - c_pos_y}
    local ax = math.atan2(vect.y, -vect.x)
    setCameraPositionUnfixed(0.0, -ax)
end

local function les_isBuildingInFront()
local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
if not pX then return false end
    local ped_angle = math.rad(getCharHeading(PLAYER_PED)) + math.pi / 2
    local ppX, ppY, ppZ = 5 * math.cos(ped_angle) + pX, 5 * math.sin(ped_angle) + pY, pZ + 0.8
    local result, colPoint = processLineOfSight(pX, pY, pZ, ppX, ppY, ppZ, true, false, true, false, false, false, false, false)
    if not result or not colPoint then return false end
        return colPoint.entityType == 1
    end

    local function les_runToPoint(x, y, z)
    les_set_camera_direction({x, y, z})
    if not les_last_jump then les_last_jump = 0 end
        local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
        if not mX then return end
            local distance = getDistanceBetweenCoords3d(mX, mY, mZ, x, y, z)
            setGameKeyState(1, -255)
            if distance > 15 and os.clock() - les_last_jump > 1 and (les_state == "SEARCH_TREE" or les_state == "RUN_FIX_ZABOR") then
                setGameKeyState(14, 255)
                les_last_jump = os.clock()
            else
            setGameKeyState(16, distance > 8 and 255 or 0)
        end
        local random_left_right = math.random(1, 10000)
        if random_left_right > 9500 then
            setGameKeyState(0, 255)
        elseif random_left_right < 500 then
            setGameKeyState(0, -255)
        else
        setGameKeyState(0, 0)
    end
    if les_isBuildingInFront() then
        setGameKeyState(0, -255)
    end
end

local function perpendicularToLineThroughPoint(a, b, p)
local denom = ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
if denom == 0 then return {p.x, p.y} end
    local ix = (a.x * a.x * p.x - 2 * a.x * b.x * p.x + b.x * b.x * p.x + b.x *
    (a.y - b.y) * (a.y - p.y) - a.x * (a.y - b.y) * (b.y - p.y)) / denom
    local iy = (b.x * b.x * a.y + a.x * a.x * b.y + b.x * p.x * (b.y - a.y) - a.x *
    (p.x * (b.y - a.y) + b.x * (a.y + b.y)) + (a.y - b.y) * (a.y - b.y) * p.y) / denom
    return {ix, iy}
end

local function getPerpendicularToCenter_les(offset)
offset = offset or 10.0
local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
if not mX then return nil end
    local base = perpendicularToLineThroughPoint(les_road_points[1], les_road_points[2], {x = mX, y = mY})
    local dx = les_road_points[2].x - les_road_points[1].x
    local dy = les_road_points[2].y - les_road_points[1].y
    local len = math.sqrt(dxdx + dydy)
    if len == 0 then return {base[1], base[2], mZ} end

        dx, dy = dx/len, dy/len
        local px, py = -dy, dx
        return {base[1] + px * offset, base[2] + py * offset, mZ}

    end

    local function getNearestTree_les()
    if not isSampfuncsLoaded() or not isSampLoaded() or not isSampAvailable() then return false, {0,0,0} end
        local nearest_dist = 2 ^ 10
        local nearest_tree = {0, 0, 0}
        local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
        if not mX then return false, nearest_tree end
            local find = false
            for id = 0, 2048 do
                if sampIs3dTextDefined(id) then
                    local text, color, posX, posY, posZ, distance, ignore_walls, player, veh = sampGet3dTextInfoById(id)
                    if text then
                        local distance = getDistanceBetweenCoords3d(posX, posY, posZ, mX, mY, mZ)
                        if text:find("Срубить дерево") then
                            if distance < nearest_dist and les_noPlayersAround({posX, posY, posZ}) and not les_coordsIn({posX, posY, posZ}, les_ignore_trees) then
                                find = true
                                nearest_dist = distance
                                nearest_tree = {posX, posY, posZ}
                            end
                        end
                    end
                end
            end
            return find, nearest_tree
        end

        local active = false

        function sendFrontendClick(interfaceid, id, subid, json_str)
            local bs = raknetNewBitStream()
            raknetBitStreamWriteInt8(bs, 220)
            raknetBitStreamWriteInt8(bs, 63)
            raknetBitStreamWriteInt8(bs, interfaceid)
            raknetBitStreamWriteInt32(bs, id)
            raknetBitStreamWriteInt32(bs, subid)
            raknetBitStreamWriteInt32(bs, #json_str)
            raknetBitStreamWriteString(bs, json_str)
            raknetSendBitStreamEx(bs, 1, 10, 1)
            raknetDeleteBitStream(bs)
        end

            imgui.OnInitialize(function()
            themeexam()
            imgui.GetIO().IniFilename = nil
        end)

-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz

        function themeexam()
            imgui.SwitchContext()
    local style = imgui.GetStyle()
  
    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 20.0
    style.ChildRounding = 20.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 20.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 30.0
    style.ScrollbarRounding = 20.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 20
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.93, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.18, 0.20, 0.22, 0.30)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.80, 0.80, 0.90, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.60, 0.60, 0.65, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.12, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.18, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
        end

        function SendAltPacket()
            local bs = raknetNewBitStream()
            raknetBitStreamWriteInt8(bs, 220)
            raknetBitStreamWriteInt8(bs, 63)
            raknetBitStreamWriteInt8(bs, 8)
            raknetBitStreamWriteInt32(bs, 7)
            raknetBitStreamWriteInt32(bs, -1)
            raknetBitStreamWriteInt32(bs, 0)
            raknetBitStreamWriteString(bs, "")
            raknetSendBitStreamEx(bs, 1, 7, 1)
            raknetDeleteBitStream(bs)
        end

        function Search3Dtext(x, y, z, radius, pattern)
            for id = 0, 2048 do
                if sampIs3dTextDefined(id) then
                    local text, _, tx, ty, tz = sampGet3dTextInfoById(id)
                    if getDistanceBetweenCoords3d(x, y, z, tx, ty, tz) < radius then
                        if string.match(text, pattern) then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local les_move_target = nil
        local _last_cam_angle = 0.0

        function les_startMoveTo(x, y, z, threshold)
            threshold = threshold or 2.5
            les_move_target = {x = x, y = y, z = z, threshold = threshold}
        end

        local function normalizeAngle(rad)
        while rad > math.pi do rad = rad - 2 * math.pi end
            while rad < -math.pi do rad = rad + 2 * math.pi end
                return rad
            end

            function les_updateMovement()
                if not les_move_target then return false end

                    local tx, ty, tz = les_move_target.x, les_move_target.y, les_move_target.z
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    if not px then return false end

                        local dist = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)

                        if dist <= (les_move_target.threshold or 0.5) then
                            setGameKeyState(1, 0)
                            setGameKeyState(16, 0)
                            setGameKeyState(0, 0)
                            les_move_target = nil
                            return true
                        end

                        local move_angle = getHeadingFromVector2d(tx - px, ty - py)
                        local target_rad = math.rad(move_angle - 90)

                        local diff = normalizeAngle(target_rad - _last_cam_angle)

                        _last_cam_angle = _last_cam_angle + diff * 0.04
                        setCameraPositionUnfixed(0, _last_cam_angle)

                        setGameKeyState(1, -255)

                        if getDistanceBetweenCoords2d(px, py, tx, ty) > 8 then
                            setGameKeyState(16, 255)
                        else
                        setGameKeyState(16, 0)
                    end

                    if les_isBuildingInFront() then
                        setGameKeyState(0, -255)
                    end

                    return false

                end

                local create_thread = nil
                if type(lua_thread) == "table" and type(lua_thread.create) == "function" then
                    create_thread = lua_thread.create
                elseif effil and type(effil.thread) == "function" then
                    create_thread = function(f) effil.thread(f)() end
                else
                create_thread = function(f) coroutine.wrap(f)() end
            end

            function main()
    while not isSampAvailable() do wait(0) end
    wait(200)
    les_cMsg('Лесоруб бот активен! Команда /lesopilka для включения.')

    sampRegisterChatCommand('lesopilka', function()
        menules[0] = not menules[0]
        if botikstate[0] then
            les_cMsg('Бот включен!')
            les_state = "RUN_FIX_ZABOR"
        else
            les_cMsg('Бот выключен!')
            setGameKeyState(1, 0)
            setGameKeyState(16, 0)
            setGameKeyState(0, 0)
            les_move_target = nil
        end
    end)

    while true do
        wait(0)

        if not botikstate[0] then goto continue end

        if les_updateMovement() then end

        local found, tree = getNearestTree_les()

        if les_state == "IDLE" then
            les_state = "RUN_FIX_ZABOR"

        elseif les_state == "RUN_FIX_ZABOR" then
            local point = les_fix_zabors_random[les_last_fix_zabor_id] or les_fix_zabors_random[1]
            if not les_move_target then
                les_startMoveTo(point[1], point[2], point[3], 3)
            end
            local dist = les_distPoint(point[1], point[2], point[3])
            if dist < 4 then
                les_last_fix_zabor_id = math.random(1, #les_fix_zabors_random)
                les_cMsg("Подошёл к фикс-забору — ищу дерево.")
                les_state = "SEARCH_TREE"
            end

        elseif les_state == "SEARCH_TREE" then
            if found then
                les_startMoveTo(tree[1], tree[2], tree[3], 1.5)
                local dist = les_distPoint(tree[1], tree[2], tree[3])
                if dist < 1.5 then
                    les_state = "START_CUT"
                    les_cMsg("Подошёл к дереву — начинаю рубку.")
                end
            else
                les_cMsg("Дерево не найдено — иду фиксить.")
                les_state = "RUN_FIX_ZABOR"
            end

        elseif les_state == "START_CUT" then
            les_state = "WAIT_ALT"
            successCut = false
            les_set_wait_alt = os.clock()

            create_thread(function()
                for i = 1, 8 do
                    SendAltPacket()
                    wait(500)
                end
                successCut = true
                les_cMsg("Рубка завершена — дерево срублено!")
            end)

        elseif les_state == "WAIT_ALT" then
            local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
            if not mX then
                les_state = "SEARCH_TREE"
                goto continue
            end

            local dist = getDistanceBetweenCoords2d(mX, mY, tree[1], tree[2])

            if os.clock() - les_set_wait_alt > 15 then
                table.insert(les_ignore_trees, {tree[1], tree[2], tree[3]})
                les_cMsg("Дерево не ответило — баню точку.")
                les_state = "SEARCH_TREE"
                successCut = false
                goto continue
            end

            if dist > 3.0 then
                if successCut then
                    les_cMsg("Дерево срублено! Еду сдавать.")
                    les_state = "RUN_FIX_AFTER_CUT"
                else
                    les_cMsg("Потерял дерево — ищу новое.")
                    les_state = "SEARCH_TREE"
                end
                goto continue
            end

            if les_last_alt then
                SendAltPacket()
                successCut = true
            end
            les_last_alt = not les_last_alt

        elseif les_state == "RUN_FIX_AFTER_CUT" then
            local px, py, pz = getCharCoordinates(PLAYER_PED)
            if not px then goto continue end

            local nearest_id = 1
            local nearest_d = 1e9
            for i, pt in ipairs(les_fix_zabors_cut) do
                local d = getDistanceBetweenCoords2d(px, py, pt[1], pt[2])
                if d < nearest_d then
                    nearest_d = d
                    nearest_id = i
                end
            end

            local point = les_fix_zabors_cut[nearest_id]
            if not les_move_target then
                les_startMoveTo(point[1], point[2], point[3], 3)
            end

            local dist = les_distPoint(point[1], point[2], point[3])
            if dist < 4 then
                les_cMsg("Подошёл к ближайшему фикс-забору после сруба — теперь к складу.")
                local sx, sy, sz = -512.553, -191.403, 78.284
                les_startMoveTo(sx, sy, sz, 3)
                les_state = "RUN_SDACHA"
            end

        elseif les_state == "RUN_SDACHA" then
            local sx, sy, sz = -512.553, -191.403, 78.284
            if not les_move_target then
                les_startMoveTo(sx, sy, sz, 0.5)
            end

            local px, py, pz = getCharCoordinates(PLAYER_PED)
            if not px then goto continue end
            local dist = getDistanceBetweenCoords3d(px, py, pz, sx, sy, sz)

            if dist <= 0.5 then
                create_thread(function()
                    for i = 1, 3 do
                        SendAltPacket()
                        wait(400)
                    end
                    les_state = "RUN_FIX_ZABOR"
                end)
                goto continue
            end
        end

        ::continue::
    end
end

    function sampev.onServerMessage(color, text)
        if botikstate[0] then
            if text:match('Ваш уровень сытости ниже') then
                sampSendChat('/cheeps')
            end
            if text:find("{ffffff}Вы слишком далеко от дерева!") then
                les_state = "SEARCH_TREE"
                les_cMsg("Дерево далеко — ищу следующее.")
            elseif text:find("{ffffff}Для срубки дерева Вам необходимо начать") then
                botikstate[0] = false
                sampAddChatMessage('{cc66ff}[auto-mine]: {FFFFFF}Вы не работаете на лесопилке — бот выключен.', -1)
            elseif color == -1347440641 and text:find("Вы сломали тележку, отправляйтесь и срубите дерево по новой!") then
                les_state = "SEARCH_TREE"
                les_cMsg("Тележка сломалась — ищу дерево заново.")
            elseif text:find("Всего спилено дерева:") then
                les_state = "RUN_FIX_ZABOR"
                les_last_jump = os.clock() + 3
                les_cMsg("Срублено — фиксирую забор/идём дальше.")
            end
        end
    end

imgui.OnFrame(function() return menules[0] end,
function()

	local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(500, 350))
    local flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize
    imgui.Begin("Lesopilka-Helper", menules, flags)
    	
    local btnColor = botikstate[0] and imgui.ImVec4(0.8, 0.1, 0.1, 1.0) or imgui.ImVec4(0.1, 0.8, 0.1, 1.0)
	local btnLabel = botikstate[0] and u8"STOP BOT" or u8"START BOT"
	
	imgui.PushStyleColor(imgui.Col.Button, btnColor)
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(btnColor.x + 0.1, btnColor.y + 0.1, btnColor.z + 0.1, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonActive, btnColor)

	if imgui.Button(btnLabel, imgui.ImVec2(-1, 60)) then
    botikstate[0] = not botikstate[0]

    if botikstate[0] then
                        les_cMsg('Бот включен!')
                        les_state = "RUN_FIX_ZABOR"
                    else
                    les_cMsg('Бот выключен!')
                    setGameKeyState(1, 0)
                    setGameKeyState(16, 0)
                    setGameKeyState(0, 0)
                    les_move_target = nil
                end
end
imgui.PopStyleColor(3)

	imgui.End()
end)

-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz

-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz

-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz

-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
-- скрипт создан @justluaarz
