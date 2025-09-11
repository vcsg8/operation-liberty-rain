local IADS_DEBUG = false

local PVO_EWRS = {
    "pvo.4d.1530zrp.hq",
}

local PVO_SAMS = {
    { site = "pvo.4d.1530zrp.1bn", pd = {  } },
    { site = "pvo.4d.606zrp.1bn", pd = {  } },
    { site = "pvo.4d.1530zrp.3bn", pd = {  } },
}

local HADF_EWRS = {
    "hadf.24d.150regt.1c",
    "hadf.24d.150regt.2c",
    "hadf.24d.305bde.hq",
}

local HADF_SAMS = {
    { site = "hadf.24d.46bde.465bn", pd = {} },
    { site = "hadf.24d.46bde.463bn", pd = {} },
    { site = "hadf.24d.46bde.464bn", pd = {} },
    { site = "hadf.24d.46bde.462bn", pd = {} },
    { site = "hadf.24d.46bde.461bn", pd = {} },
    { site = "hadf.24d.48bde.483bn", pd = {} },
    { site = "hadf.24d.48bde.481bn", pd = {} },
    { site = "hadf.24d.48bde.482bn", pd = {} },
    { site = "hadf.24d.48bde.485bn", pd = {} },
    { site = "hadf.24d.48bde.484bn", pd = {} },
    --{ site = "hadf.24d.159rgt", pd = {} },
    { site = "hadf.26d.157rgt", pd = {} },
    { site = "hadf.24d.158rgt", pd = {} },
    { site = "hadf.26d.37bde.1bn", pd = {} },
    { site = "hadf.26d.37bde.2bn", pd = {} },
    { site = "hadf.26d.37bde.3bn", pd = {} },
    { site = "hadf.26d.37bde.4bn", pd = {} },
    { site = "hadf.26d.37bde.5bn", pd = {} },
    { site = "hadf.26d.41bde.1bn", pd = {} },
    { site = "hadf.26d.41bde.2bn", pd = {} },
    { site = "hadf.26d.41bde.3bn", pd = {} },
    { site = "hadf.26d.41bde.4bn", pd = {} },
    { site = "hadf.26d.41bde.5bn", pd = {} },
    { site = "hadf.26d.41bde.6bn", pd = {} },
    { site = "hadf.26d.71bde.1bn", pd = {} },
    { site = "hadf.26d.71bde.2bn", pd = {} },
    { site = "hadf.26d.71bde.3bn", pd = {} },
    { site = "hadf.26d.71bde.4bn", pd = {} },
    { site = "hadf.26d.71bde.5bn", pd = {} },
    { site = "hadf.26d.103bde.4bn", pd = {} },
    { site = "hadf.26d.103bde.3bn", pd = {} },
    { site = "hadf.26d.103bde.2bn", pd = {} },
    { site = "hadf.26d.103bde.1bn", pd = {} },
    { site = "hadf.26d.103bde.5bn", pd = {} },
    { site = "hadf.26d.156bde.1bn", pd = {} },
    { site = "hadf.26d.156bde.3bn", pd = {} },
    { site = "hadf.26d.156bde.2bn", pd = {} },
    { site = "hadf.26d.156bde.4bn", pd = {} },
    { site = "hadf.24d.11bde.2bn", pd = {} },
    { site = "hadf.24d.11bde.3bn", pd = {} },
    { site = "hadf.24d.11bde.1bn", pd = {} },
    { site = "hadf.24d.11bde.6bn", pd = {} },
    { site = "hadf.24d.11bde.5bn", pd = {} },
    { site = "hadf.24d.11bde.4bn", pd = {} },
    { site = "hadf.24d.305bde.3bn.1c", pd = {} },
}

local HADF_19BDE_EWRS = {
    "hadf.24d.19bde.2bn.hq-1",
}

local HADF_19BDE_COMMAND_POST_UNITS = {
    "hadf.24d.19bde.2bn.hq-6",
    "hadf.24d.19bde.2bn.hq-7",
}

local HADF_19BDE_SAMS = {
    { site = "hadf.24d.19bde.2bn.batt-3", pd = {} },
    { site = "hadf.24d.19bde.2bn.batt-1", pd = {} },
    { site = "hadf.24d.19bde.2bn.batt-2", pd = {} },
    --{ site = "hadf.24d.19bde.1bn.batt-1", pd = {} },
    { site = "hadf.24d.19bde.1bn.batt-2", pd = {} },
    { site = "hadf.24d.19bde.1bn.batt-3", pd = {} },
}

local _global = _G or {}
local env = rawget(_global, "env") or { info = function(...) end, warning = function(...) end }
local SkynetIADSRef = rawget(_global, "SkynetIADS")
local SkynetIADSJammerRef = rawget(_global, "SkynetIADSJammer")
local landRef = rawget(_global, "land")
local triggerRef = rawget(_global, "trigger")
local GroupRef = rawget(_global, "Group")
local UnitRef = rawget(_global, "Unit")
local worldRef = rawget(_global, "world")
local ObjectRef = rawget(_global, "Object")

local function logInfo(tag, message)
    if env and env.info then env.info("[OLR][" .. tostring(tag) .. "] " .. tostring(message)) end
end

local function logWarn(tag, message)
    if env and env.warning then env.warning("[OLR][" .. tostring(tag) .. "] " .. tostring(message)) end
end

if not SkynetIADSRef then
    logWarn("IADS", "SkynetIADS not found. Ensure Skynet is loaded before this script.")
    return
end

local hasUnitGetByName = UnitRef and type(UnitRef.getByName) == "function"
local hasGroupGetByName = GroupRef and type(GroupRef.getByName) == "function"
local hasLandGetHeight = landRef and type(landRef.getHeight) == "function"
local hasTriggerMisc = triggerRef and triggerRef.misc

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

local function getFormationKey(siteName)
    local key = siteName:match("^(.-%d+bde)") or siteName:match("^(.-%d+rgt)") or siteName
    return key
end

local function isSpecialRegimentKey(key)
    return (key:find("157rgt", 1, true) ~= nil)
        or (key:find("158rgt", 1, true) ~= nil)
        or (key:find("159rgt", 1, true) ~= nil)
end

local function addEWRs(iads, ewrNames, tag)
    for _, name in ipairs(ewrNames or {}) do
        local addedUnitNames = {}
        if hasUnitGetByName and type(iads.addEarlyWarningRadar) == "function" then
            local unit = UnitRef.getByName(name)
            if unit then
                pcall(function() iads:addEarlyWarningRadar(name) end)
                table.insert(addedUnitNames, name)
                logInfo(tag, "EWR unit added: " .. tostring(name))
            end
        end
        if #addedUnitNames == 0 and hasGroupGetByName and type(iads.addEarlyWarningRadar) == "function" then
            local grp = GroupRef.getByName(name)
            if grp and type(grp.getUnits) == "function" then
                local units = grp:getUnits()
                if type(units) == "table" then
                    for _, u in ipairs(units) do
                        if u and type(u.getDesc) == "function" and type(u.getName) == "function" then
                            local desc = u:getDesc()
                            local isEWR = desc and desc.attributes and (desc.attributes.EWR == true)
                            if isEWR then
                                local uname = u:getName()
                                pcall(function() iads:addEarlyWarningRadar(uname) end)
                                table.insert(addedUnitNames, uname)
                            end
                        end
                    end
                    if #addedUnitNames > 0 then
                        logInfo(tag, "EWR added via group scan: " .. name .. " (units: " .. table.concat(addedUnitNames, ", ") .. ")")
                    else
                        logWarn(tag, "No EWR-tagged units found in group: " .. tostring(name))
                    end
                end
            else
                logWarn(tag, "EWR group not found: " .. tostring(name))
            end
        end
    end
end

local function addEWRUnits(iads, unitNames, tag)
    for _, uname in ipairs(unitNames or {}) do
        pcall(function() iads:addEarlyWarningRadar(uname) end)
        logInfo(tag, "EWR unit added: " .. tostring(uname))
    end
end

local function addCommandPosts(iads, unitNames, tag)
    if type(iads.addCommandCenter) == "function" then
        for _, uname in ipairs(unitNames or {}) do
            pcall(function() iads:addCommandCenter(uname) end)
            logInfo(tag, "Command post added: " .. tostring(uname))
        end
    else
        logWarn(tag, "Skynet IADS addCommandCenter API missing; cannot add command posts")
    end
end

local function ensureSAMAdded(iads, groupName, tag)
    local shouldSkip = false
    if hasGroupGetByName then
        local grp = GroupRef.getByName(groupName)
        if grp then
            local exists
            if type(grp.isExist) == "function" then
                local ok, res = pcall(function() return grp:isExist() end)
                exists = ok and res or nil
            end
            if exists == false then
                shouldSkip = true
            else
                if type(grp.getUnits) == "function" then
                    local units = grp:getUnits()
                    local anyUnitExists = false
                    if type(units) == "table" then
                        for _, u in ipairs(units) do
                            if u and type(u.isExist) == "function" then
                                local ok2, ex = pcall(function() return u:isExist() end)
                                if ok2 and ex then anyUnitExists = true break end
                            end
                        end
                        if not anyUnitExists then shouldSkip = true end
                    end
                end
            end
        end
    end
    if shouldSkip then
        logInfo(tag, "Skipping late-activated SAM group: " .. tostring(groupName))
        return nil
    end
    if type(iads.addSAMSite) == "function" then
        iads:addSAMSite(groupName)
    elseif type(iads.addSAMSitesByPrefix) == "function" then
        iads:addSAMSitesByPrefix(groupName)
    else
        logWarn(tag, "SAM add API missing: " .. tostring(groupName))
        return nil
    end
    return iads:getSAMSiteByGroupName(groupName)
end

local function addSAMsWithPointDefence(iads, samDefs, tag, outAddedGroupNames)
    for _, def in ipairs(samDefs or {}) do
        local site = ensureSAMAdded(iads, def.site, tag)
        if not site then
            logWarn(tag, "SAM site not found after add: " .. tostring(def.site))
        else
            if outAddedGroupNames then outAddedGroupNames[#outAddedGroupNames + 1] = def.site end
            for _, pdName in ipairs(def.pd or {}) do
                local pdSite = ensureSAMAdded(iads, pdName, tag)
                if pdSite and type(site.addPointDefence) == "function" then
                    site:addPointDefence(pdSite)
                    logInfo(tag, "Point defence '" .. pdName .. "' added to '" .. def.site .. "'")
                else
                    logWarn(tag, "Point defence SAM not found: " .. tostring(pdName))
                end
            end
            logInfo(tag, "SAM added: " .. def.site)
        end
    end
end

local function buildMinAGLConstraint(minFeetAGL)
    local minMeters = (tonumber(minFeetAGL) or 0) * 0.3048
    local constraint
    constraint = {
        shouldGoLive = function(selfRef, abstractRadar, contact)
            local ok, res = pcall(function()
                local altMSL
                if contact and type(contact.getAltitude) == "function" then altMSL = contact:getAltitude() end
                local pos
                if not altMSL and contact and type(contact.getPosition) == "function" then
                    local p = contact:getPosition()
                    pos = p and (p.p or p.point or p)
                    altMSL = pos and pos.y or nil
                end
                if not altMSL then return true end
                local aglMeters = altMSL
                local posForLand = pos
                if not posForLand and contact and type(contact.getPosition) == "function" then
                    local p2 = contact:getPosition()
                    posForLand = p2 and (p2.p or p2.point or p2)
                end
                if posForLand and hasLandGetHeight then
                    aglMeters = altMSL - landRef.getHeight({ x = posForLand.x, y = posForLand.z })
                end
                return aglMeters >= minMeters
            end)
            return ok and res or true
        end,
        canGoLive = function(selfRef, abstractRadar, contact)
            return selfRef:shouldGoLive(abstractRadar, contact)
        end,
    }
    return constraint
end

local function buildNFZConstraint(zoneNames, userFlagName)
    local zones = {}
    if hasTriggerMisc and type(triggerRef.misc.getZone) == "function" then
        for _, zn in ipairs(zoneNames or {}) do
            local z = triggerRef.misc.getZone(zn)
            if z and z.point and z.radius then
                zones[#zones + 1] = { x = z.point.x, z = z.point.z, r2 = z.radius * z.radius }
            end
        end
    end
    local constraint
    constraint = {
        shouldGoLive = function(selfRef, abstractRadar, contact)
            local ok, res = pcall(function()
                if hasTriggerMisc and type(triggerRef.misc.getUserFlag) == "function" and userFlagName then
                    local flagVal = triggerRef.misc.getUserFlag(userFlagName)
                    if tonumber(flagVal) == 1 then return true end
                end
                local pos
                if contact and type(contact.getPosition) == "function" then
                    local p = contact:getPosition()
                    pos = p and (p.p or p.point or p)
                end
                if not pos then return false end
                for i = 1, #zones do
                    local z = zones[i]
                    local dx = pos.x - z.x
                    local dz = pos.z - z.z
                    if (dx * dx + dz * dz) <= z.r2 then
                                return true
                    end
                end
                return false
            end)
            return ok and res or false
        end,
        canGoLive = function(selfRef, abstractRadar, contact)
            return selfRef:shouldGoLive(abstractRadar, contact)
        end,
    }
    return constraint
end

local function attachConstraintToSite(site, constraint)
    if site and type(site.addGoLiveConstraint) == "function" then
        pcall(function() site:addGoLiveConstraint(constraint) end)
    end
end

local function addConstraintToGroups(iads, groupNames, constraint, tag)
    for _, name in ipairs(groupNames or {}) do
        attachConstraintToSite(iads:getSAMSiteByGroupName(name), constraint)
    end
    if groupNames and #groupNames > 0 then
        logInfo(tag, "Attached go-live constraint to groups: " .. table.concat(groupNames, ", "))
    end
end

local function addConstraintToNatoType(iads, natoName, constraint, tag)
    local collection = iads:getSAMSitesByNatoName(natoName)
    if type(collection) == "table" then
        for _, site in pairs(collection) do attachConstraintToSite(site, constraint) end
        logInfo(tag, "Applied constraint to type: " .. tostring(natoName))
    elseif collection and type(collection.addGoLiveConstraint) == "function" and type(collection.iterator) == "function" then
        for site in collection:iterator() do attachConstraintToSite(site, constraint) end
        logInfo(tag, "Applied constraint to type: " .. tostring(natoName))
    else
        logWarn(tag, "Could not enumerate SAM sites for type: " .. tostring(natoName))
    end
end

local function setCanEngageHARMForNatoType(iads, natoName, canEngage, tag)
    local collection = iads:getSAMSitesByNatoName(natoName)
    if type(collection) == "table" then
        for _, site in pairs(collection) do
            if site and type(site.setCanEngageHARM) == "function" then
                site:setCanEngageHARM(canEngage and true or false)
            end
        end
        logInfo(tag, "Set HARM engagement for " .. tostring(natoName) .. ": " .. tostring(canEngage))
    elseif collection and type(collection.iterator) == "function" then
        for site in collection:iterator() do
            if site and type(site.setCanEngageHARM) == "function" then
                site:setCanEngageHARM(canEngage and true or false)
            end
        end
        logInfo(tag, "Set HARM engagement for " .. tostring(natoName) .. ": " .. tostring(canEngage))
    else
        logWarn(tag, "Could not enumerate SAM sites for type: " .. tostring(natoName))
    end
end

local function setGoLivePercentForNatoType(iads, natoName, percent, tag)
    local collection = iads:getSAMSitesByNatoName(natoName)
    if collection and type(collection.setGoLiveRangeInPercent) == "function" then
        collection:setGoLiveRangeInPercent(percent)
        logInfo(tag, "Set go-live % for " .. tostring(natoName) .. ": " .. tostring(percent))
    elseif type(collection) == "table" then
        for _, site in pairs(collection) do
            if site and type(site.setGoLiveRangeInPercent) == "function" then
                site:setGoLiveRangeInPercent(percent)
            end
        end
        logInfo(tag, "Applied go-live % per-site for " .. tostring(natoName))
    else
        logWarn(tag, "Could not enumerate SAM sites for type: " .. tostring(natoName))
    end
end

local function applyIADSDefaultDebug(iads)
    iads:addRadioMenu()
    local debugOutputConsole = rawget(_global, "SkynetIADSDebugOutputConsole")
    if type(iads.setDebugOutput) == "function" and debugOutputConsole then
        iads:setDebugOutput(debugOutputConsole)
    end
    local dbg = iads:getDebugSettings()
    dbg.IADSStatus = true
    dbg.contacts = false
    dbg.samWentLive = true
    dbg.ewRadarWentLive = true
    dbg.samWentDark = false
    dbg.ewRadarWentDark = false
    dbg.noWorkingCommmandCenter = false
    dbg.ewRadarNoConnection = true
    dbg.samNoConnection = true
    dbg.warnings = true
end

local function disableGroupByName(groupName, tag)
    local ok, err = pcall(function()
        if hasGroupGetByName then
            local grp = GroupRef.getByName(groupName)
            if grp and type(grp.getController) == "function" then
                local ctrl = grp:getController()
                if ctrl and type(ctrl.setOnOff) == "function" then
                    ctrl:setOnOff(false)
                end
            end
        end
    end)
    if not ok then
        logWarn(tag, "Failed to disable group '" .. tostring(groupName) .. "': " .. tostring(err))
    else
        logInfo(tag, "Disabled group (controller off): " .. tostring(groupName))
    end
end

local function selectActiveHADFSAMs(allSamDefs)
    local present = {}
    for _, def in ipairs(allSamDefs or {}) do
        local site = def.site
        if hasGroupGetByName then
            local grp = GroupRef.getByName(site)
            if grp then table.insert(present, def) end
        end
    end
    local totalPresent = #present
    if totalPresent == 0 then return {}, {} end
    local keyToDefs = {}
    for _, def in ipairs(present) do
        local key = getFormationKey(def.site)
        keyToDefs[key] = keyToDefs[key] or {}
        table.insert(keyToDefs[key], def)
    end
    local targetActive = math.floor(totalPresent * (2/3) + 0.5)
    local deactCapByKey = {}
    local candidatesByKey = {}
    local totalDeactCap = 0
    for key, defs in pairs(keyToDefs) do
        local n = #defs
        local requiredActive
        if isSpecialRegimentKey(key) then
            requiredActive = math.ceil(n * (2/3))
        else
            requiredActive = 1
        end
        local maxDeactAllowed = math.max(0, n - requiredActive)
        local cap = math.min(2, maxDeactAllowed)
        deactCapByKey[key] = cap
        totalDeactCap = totalDeactCap + cap
        candidatesByKey[key] = {}
        for _, d in ipairs(defs) do
            candidatesByKey[key][#candidatesByKey[key] + 1] = d.site
        end
        shuffle(candidatesByKey[key])
    end
    local deactivationsNeeded = math.max(0, totalPresent - targetActive)
    deactivationsNeeded = math.min(deactivationsNeeded, totalDeactCap)
    local keys = {}
    for k, _ in pairs(keyToDefs) do keys[#keys + 1] = k end
    shuffle(keys)
    local usedByKey = {}
    local toDeactivate = {}
    local keyIndex = 1
    while deactivationsNeeded > 0 and #keys > 0 do
        local progressed = false
        for _ = 1, #keys do
            local k = keys[keyIndex]
            keyIndex = keyIndex + 1
            if keyIndex > #keys then keyIndex = 1 end
            local used = usedByKey[k] or 0
            local cap = deactCapByKey[k] or 0
            local candList = candidatesByKey[k] or {}
            if used < cap and #candList > 0 then
                local site = table.remove(candList)
                toDeactivate[#toDeactivate + 1] = site
                usedByKey[k] = used + 1
                deactivationsNeeded = deactivationsNeeded - 1
                progressed = true
                if deactivationsNeeded == 0 then break end
            end
        end
        if not progressed then break end
    end
    local toDeactivateSet = {}
    for _, s in ipairs(toDeactivate) do toDeactivateSet[s] = true end
    local actives = {}
    for _, def in ipairs(present) do
        if not toDeactivateSet[def.site] then actives[#actives + 1] = def end
    end
    return actives, toDeactivate
end

local function createIADS(name, cfg, tag)
    local iads = SkynetIADSRef:create(name)
    if cfg.ewr_mode == "units" then
        addEWRUnits(iads, cfg.ewrs or {}, tag)
    else
        addEWRs(iads, cfg.ewrs or {}, tag)
    end
    if cfg.command_posts_units and #cfg.command_posts_units > 0 then
        addCommandPosts(iads, cfg.command_posts_units, tag)
    end
    if cfg.selective_activation then
        local activeSAMDefs, toDeactivateSites = selectActiveHADFSAMs(cfg.sams or {})
        addSAMsWithPointDefence(iads, activeSAMDefs, tag)
        for _, siteName in ipairs(toDeactivateSites or {}) do
            disableGroupByName(siteName, tag)
        end
    else
        addSAMsWithPointDefence(iads, cfg.sams or {}, tag)
    end
    if cfg.min_agl_by_type then
        for natoName, feet in pairs(cfg.min_agl_by_type) do
            local c = buildMinAGLConstraint(feet)
            addConstraintToNatoType(iads, natoName, c, tag)
        end
    end
    if cfg.nfz and cfg.nfz.zones and cfg.nfz.groups and cfg.nfz.flag then
        local nfzConstraint = buildNFZConstraint(cfg.nfz.zones, cfg.nfz.flag)
        addConstraintToGroups(iads, cfg.nfz.groups, nfzConstraint, tag)
    end
    if cfg.go_live_percent_by_type then
        for natoName, pct in pairs(cfg.go_live_percent_by_type) do
            setGoLivePercentForNatoType(iads, natoName, pct, tag)
        end
    end
    if cfg.harm_types then
        for _, t in ipairs(cfg.harm_types) do
            setCanEngageHARMForNatoType(iads, t, true, tag)
        end
    end
    if IADS_DEBUG then
    applyIADSDefaultDebug(iads)
    end
    iads:activate()
    logInfo(tag, name .. " activated")
    return iads
end

-- Expose a module-like table for future extensions if needed

-- Base jammer functions (0..100) and generic registrar
local function toInt(x) return math.floor((x or 0) + 0.5) end
local BASE_JAM_FUNCS = {
    ['SA-5'] = function(d)
        local p
        if d >= 30 then p = 95
        elseif d >= 25 then p = 75 + (d - 25) * ((95 - 75) / 5)
        elseif d >= 20 then p = 50 + (d - 20) * ((75 - 50) / 5)
        else p = 50 + (d - 20) * 5
        end
        return toInt(p)
    end,
    ['SA-2'] = function(d) return toInt(50 + (d - 4) * 12.5) end,
    ['SA-3'] = function(d) return toInt(50 + (d - 4) * 12.5) end,
    ['SA-6'] = function(d) return toInt((50 + (d - 4) * 12.5) * 0.75) end,
    ['SA-8'] = function(d) return toInt((50 + (d - 4) * 12.5) * 0.75) end,
    ['SA-10'] = function(d) return toInt((1.4 ^ d) + 80) end,
    ['SA-15'] = function(d) return toInt(20 + d * 2) end,
    ['SA-20'] = function(d) if d < 20 then return 5 else return toInt(5 + (d - 20) * 2) end end,
    ['SA-23'] = function(d) if d < 20 then return 5 else return toInt(5 + (d - 20) * 2) end end,
    ['SA-22'] = function(d) return toInt(10 + d * 2.5 + (math.random() - 0.5) * 20) end,
}

local function setupJammersForIADS(iadsList, unitTypeKeys, maxRangeNm, effScale, rangeScale)
    if not (SkynetIADSJammerRef and worldRef and ObjectRef and type(worldRef.searchObjects) == 'function' and worldRef.VolumeType) then return end
    local function norm(name) return name and (string.gsub(string.upper(name), "[^%w]", '')) or nil end
    local found, vol = {}, { id = worldRef.VolumeType.SPHERE, params = { point = { x = 0, y = 0, z = 0 }, radius = 5e6 } }
    worldRef.searchObjects(ObjectRef.Category.UNIT, vol, function(obj)
        if obj and obj.getTypeName and obj.getName then
            local ok1, t = pcall(obj.getTypeName, obj)
            local ok2, n = pcall(obj.getName, obj)
            if ok1 and ok2 and t and n and unitTypeKeys[norm(t)] then found[#found + 1] = n end
        end
        return true
    end)
    if #found == 0 then return end
    for _, uname in ipairs(found) do
        local u = hasUnitGetByName and UnitRef.getByName(uname) or nil
        if u and iadsList and iadsList[1] then
            local jammer = SkynetIADSJammerRef:create(u, iadsList[1])
            for i = 2, #iadsList do if iadsList[i] and jammer.addIADS then jammer:addIADS(iadsList[i]) end end
            if jammer.setMaximumEffectiveDistance then jammer:setMaximumEffectiveDistance(maxRangeNm) end
            if jammer.masterArmOn then jammer:masterArmOn() end
            if jammer.addRadioMenu then jammer:addRadioMenu() end
            if jammer.addFunction then
                for nato, f in pairs(BASE_JAM_FUNCS) do
                    jammer:addFunction(nato, function(d) return toInt((effScale or 1) * f((d or 0) / (rangeScale or 1))) end)
                end
            end
            if IADS_DEBUG then logInfo('IADS', 'Jammer attached for unit ' .. uname) end
        end
    end
end

-- Expose a module-like table for future extensions if needed
local PVO_CFG = {
    ewrs = PVO_EWRS,
    sams = PVO_SAMS,
    go_live_percent_by_type = { ["SA-10"] = 80, ["SA-5"] = 37, ["SA-2"] = 85 },
    nfz = {
        zones = { "DON-NFZ-TARTUS", "DON-NFZ-LATAKIA" },
        flag = "DON-NFZ-TRESPASS",
        groups = { "pvo.4d.1530zrp.1bn", "pvo.4d.1530zrp.3bn", "pvo.4d.606zrp.1bn" },
    },
    harm_types = { "SA-10", "SA-15" },
}

local HADF_CFG = {
    ewrs = HADF_EWRS,
    sams = HADF_SAMS,
    selective_activation = true,
    min_agl_by_type = { ["SA-2"] = 1200, ["SA-5"] = 1800 },
    go_live_percent_by_type = { ["SA-10"] = 80, ["SA-5"] = 37, ["SA-2"] = 85 },
    harm_types = { "SA-10", "SA-15" },
}

local HADF_19BDE_CFG = {
    ewrs = HADF_19BDE_EWRS,
    ewr_mode = "units",
    command_posts_units = HADF_19BDE_COMMAND_POST_UNITS,
    sams = HADF_19BDE_SAMS,
}

PVO_IADS = PVO_IADS or {}
PVO_IADS.instance = PVO_IADS.instance or createIADS("PVO", PVO_CFG, "PVO IADS")

HADF_IADS = HADF_IADS or {}
HADF_IADS.instance = HADF_IADS.instance or createIADS("HADF", HADF_CFG, "HADF IADS")

HADF_19BDE_IADS = HADF_19BDE_IADS or {}
HADF_19BDE_IADS.instance = HADF_19BDE_IADS.instance or createIADS("HADF-19th Brigade", HADF_19BDE_CFG, "HADF-19BDE IADS")

-- Register EA-6B jammers across all IADS
setupJammersForIADS({ PVO_IADS.instance, HADF_IADS.instance, HADF_19BDE_IADS.instance }, { EA6B = true }, 100, 1.0, 1.0)
-- Register EC-130 jammers across all IADS
setupJammersForIADS({ PVO_IADS.instance, HADF_IADS.instance, HADF_19BDE_IADS.instance }, { EC130 = true }, 150, 1.33, 1.5)
