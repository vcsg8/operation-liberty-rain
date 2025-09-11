local RADAR_SETS = {
    { names = {"haf.10rgt.1bn-1"}, flag = "TIYAS-ALERT" },
    { names = {"haf.10rgt.2bn-1"}, flag = "SAYQAL-ALERT" },
    { names = {"haf.10rgt.3bn-1"}, flag = "AL-QUSAYR-ALERT" },
    { names = {"haf.10rgt.4bn-1"}, flag = "RUHAYYIL-ALERT" },
    { names = {"haf.10rgt.5bn-1"}, flag = "KHALKHALAH-ALERT" }
}

local POLL = 5

local function existsByName(name)
    if type(name) ~= "string" or name == "" then return false end
    local okU, u = pcall(Unit.getByName, name)
    if okU and u and u.isExist and u:isExist() then return true end
    return false
end

local function getControllerByName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local okU, u = pcall(Unit.getByName, name)
    if okU and u and u.isExist and u:isExist() then
        local g = u.getGroup and u:getGroup()
        if g and g.isExist and g:isExist() then
            local okC, c = pcall(function() return g:getController() end)
            if okC then return c end
        end
    end
    local okG, g2 = pcall(Group.getByName, name)
    if okG and g2 and g2.isExist and g2:isExist() then
        local okC2, c2 = pcall(function() return g2:getController() end)
        if okC2 then return c2 end
    end
    return nil
end

local function normalizeNames(set)
    if type(set.names) == "string" then
        set.names = { set.names }
    elseif type(set.names) ~= "table" then
        set.names = {}
    end
end

local function removeDead(set)
    normalizeNames(set)
    for i = #set.names, 1, -1 do
        local n = set.names[i]
        if type(n) ~= "string" or not existsByName(n) then
            table.remove(set.names, i)
            env.info("Removing dead EWR: " .. n)
        end
    end
end

local function getTargets(controller)
    if not controller then return nil end
    local ok, t = pcall(function() return controller:getDetectedTargets(Controller.Detection and Controller.Detection.RADAR) end)
    if not ok or type(t) ~= "table" then
        ok, t = pcall(function() return controller:getDetectedTargets() end)
        if not ok or type(t) ~= "table" then return nil end
    end
    return t
end

local function isHumanAirUnit(obj)
    if not obj or not obj.getPlayerName then return false end
    local okN, pname = pcall(function() return obj:getPlayerName() end)
    if not okN or type(pname) ~= "string" or pname == "" then return false end
    local okD, desc = pcall(function() return obj:getDesc() end)
    if not okD or type(desc) ~= "table" or not desc.category then return false end
    if desc.category ~= Unit.Category.AIRPLANE and desc.category ~= Unit.Category.HELICOPTER then return false end
    return true
end

local function setHasDetectedPlayers(set)
    normalizeNames(set)
    for i = 1, #set.names do
        local controller = getControllerByName(set.names[i])
        local targets = getTargets(controller)
        if targets then
            for _, t in pairs(targets) do
                local obj = t and t.object
                if isHumanAirUnit(obj) then 
                    env.info("EWR: " .. set.names[i] .. " has detected a player: " .. obj:getPlayerName())
                    return true
                end
            end
        end
    end
    return false
end

local function tick(_, time)
    for i = 1, #RADAR_SETS do
        local set = RADAR_SETS[i]
        removeDead(set)
        local detected = setHasDetectedPlayers(set)
        if type(set.flag) == "string" and set.flag ~= "" then
            trigger.action.setUserFlag(set.flag, detected and 1 or 0)
        end
    end
    return time + POLL
end

timer.scheduleFunction(tick, nil, timer.getTime() + POLL)
