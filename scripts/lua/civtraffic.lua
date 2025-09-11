CIVTRAFFIC = {}
CIVTRAFFIC.maxActive = 30
CIVTRAFFIC.active = {}
CIVTRAFFIC.activeByName = {}
CIVTRAFFIC.spawnIndex = 0
CIVTRAFFIC.usedCallsigns = {}
CIVTRAFFIC.aircraftTypes = {"A_320","A_330","A_380","B_727","B_737","B_747","B_757","DC_10"}
CIVTRAFFIC.airlineCodes = {"AAL","DAL","UAL","SWA","JBU","ASA","FFT","NKS","BAW","AFR","KLM","DLH","SAS","FIN","IBE","SIA","QTR","UAE","ETD","THY","RYR","EZY","WZZ","JAL","ANA","CPA","QFA","ACA"}
CIVTRAFFIC.routes = {}
CIVTRAFFIC.routeUseCounts = {}
CIVTRAFFIC.monitorInterval = 5
CIVTRAFFIC.endThreshold = 5000
CIVTRAFFIC.minInterval = 240
CIVTRAFFIC.maxInterval = 720
CIVTRAFFIC.initialSpawns = 3
CIVTRAFFIC.oddFL = {29000,31000,33000,35000,37000,39000}
CIVTRAFFIC.evenFL = {30000,32000,34000,36000,38000,40000}
CIVTRAFFIC.speedMin = 280
CIVTRAFFIC.speedMax = 320
CIVTRAFFIC.country = country.id.UN_PEACEKEEPERS

local function _log(msg)
  if env and env.info then env.info("[CIVTRAFFIC] "..tostring(msg)) end
end

-- Airline-code to livery mapping per aircraft type.
-- Keys are ICAO airline codes; values are livery folder names as installed in CAM.
-- Only codes listed for a given type will be considered for that type.
CIVTRAFFIC.liveriesByType = {
  ["A_320"] = {
    AAL = "American Airlines",
    DAL = "Delta Airlines",
    UAL = "United",
    JBU = "JetBlue",
    FFT = "Frontier",
    BAW = "British Airways",
    AFR = "Air France",
    DLH = "Lufthansa",
    SAS = "SAS",
    IBE = "Iberia",
    QTR = "Qatar",
    UAE = "Emirates",
    ETD = "Etihad",
    THY = "Turkish Airlines",
    EZY = "Easy Jet",
    WZZ = "WiZZ",
  },
  ["A_330"] = {
    ACA = "Air Canada",
    AFR = "Air France",
    KLM = "KLM",
    DLH = "Lufthansa",
    FIN = "FinnAir",
    IBE = "Iberia",
    SIA = "Singapore",
    QTR = "Qatar",
    UAE = "Emirates",
    ETD = "ETIHAD",
    THY = "Turkish Airlines",
    QFA = "Qantas",
    CPA = "Cathay Pacific",
  },
  ["A_380"] = {
    AFR = "Air France",
    BAW = "BA",
    QTR = "QTR",
    UAE = "Emirates",
    QFA = "Qantas Airways",
    DLH = "LH",
  },
  ["B_727"] = {
    AAL = "American Airlines",
    DAL = "Delta Airlines",
    UAL = "UNITED",
    SWA = "Southwest",
    AFR = "Air France",
    DLH = "Lufthansa",
    ASA = "Alaska",
    SIA = "Singapore Airlines",
  },
  ["B_737"] = {
    AAL = "American_Airlines",
    BAW = "British Airways",
    AFR = "Air France",
    DLH = "Lufthansa",
    RYR = "RYANAIR",
    QFA = "QANTAS",
    EZY = "easyJet",
    SWA = "SouthWest Lone Star",
  },
  ["B_747"] = {
    AFR = "AF",
    KLM = "KLM",
    DLH = "LH",
    QFA = "QA",
  },
  ["B_757"] = {
    AAL = "AA",
    BAW = "BA",
    DAL = "Delta",
    EZY = "easyJet",
  },
  -- ["DC_10"] intentionally left mostly unmapped to avoid mismatched codes
}

local function _rand(tbl) return tbl[math.random(1,#tbl)] end
local function _bearing(x1,y1,x2,y2) local b=math.deg(math.atan2(x2-x1,y2-y1)) if b<0 then b=b+360 end return b end
local function _ft2m(ft) return ft*0.3048 end
local function _kn2ms(kn) return kn*0.514444 end
local function _iasKtsToGsMs(iasKts, altMeters)
  local altFt = (altMeters or 0) / 0.3048
  if altFt < 0 then altFt = 0 end
  local tasKts = iasKts * (1 + 0.02 * (altFt/1000))
  return _kn2ms(tasKts)
end
local function _dist(x1,y1,x2,y2) local dx=x2-x1 local dy=y2-y1 return math.sqrt(dx*dx+dy*dy) end
local function _nm2m(nm) return nm*1852 end
local function _offsetFrom(x,y,bearingDeg,dist)
  local r = math.rad(bearingDeg)
  local dx = math.sin(r) * dist
  local dy = math.cos(r) * dist
  return {x = x + dx, y = y + dy}
end
local function _toXY(p)
  if not p then return nil end
  if p.type=="Land" then
    if Airbase and Airbase.getByName then
      local ab = Airbase.getByName(p.airbaseName or "")
      if ab and ab.getPoint then local q=ab:getPoint(); return {x=q.x,y=q.z} end
    end
    if p.x and p.y then return {x=p.x, y=p.y} end
    return nil
  elseif p.type=="LandXY" then
    return {x=p.x, y=p.y}
  else
    if p.x and p.y then return {x=p.x, y=p.y} end
    return nil
  end
end
local function _pointBackAlong(x1,y1,x2,y2,backDist)
  local dx=x2-x1; local dy=y2-y1; local d=math.sqrt(dx*dx+dy*dy)
  if d<=0 then return {x=x2,y=y2} end
  local t = math.max(0, 1 - (backDist/d))
  return {x = x1 + dx*t, y = y1 + dy*t}
end
local function _nextInterval() return math.random(CIVTRAFFIC.minInterval,CIVTRAFFIC.maxInterval) end
local function _now() if timer and timer.getTime then return timer.getTime() end return 0 end

FIXES = {
  ["ANKARA"] = {lat=39.934, lon=32.859},
  ["URMIA"] = {lat=37.555, lon=45.080},
  ["GAZIANTEP"] = {lat=37.066, lon=37.378},
  ["DIYARBAKIR"] = {lat=37.914, lon=40.229},
  ["ADANA SAKIRPASA"] = {lat=36.982, lon=35.280},
  ["AQABA"] = {lat=29.532, lon=35.007},
  ["AMMAN"] = {lat=31.953, lon=35.910},
  ["QAA VOR"] = {lat=30.322, lon=36.155},
  ["KIRRK"] = {lat=33.200, lon=36.400},
}

function CIVTRAFFIC.loadFixZones(prefix)
  local pre = string.upper(prefix or "FIX_")
  if not env or not env.mission or not env.mission.triggers or not env.mission.triggers.zones then return end
  local zones = env.mission.triggers.zones
  for i=1,#zones do
    local z = zones[i]
    if z and z.name then
      local zn = string.upper(z.name)
      if string.sub(zn, 1, #pre) == pre then
        local fixName = string.sub(zn, #pre+1)
        if fixName and #fixName > 0 then
          local x, y
          if z.point then
            x = z.point.x
            y = z.point.z or z.point.y
          else
            x = z.x
            y = z.y
          end
          if x and y then
            FIXES[fixName] = {x=x, y=y}
            _log("Loaded fix from zone: "..fixName.." @ ("..math.floor(x)..","..math.floor(y)..")")
          end
        end
      end
    end
  end
end

local function _ll(name_or_obj)
  if type(name_or_obj)=="table" and name_or_obj.lat and name_or_obj.lon then
    if coord and coord.LLtoLO then
      local p = coord.LLtoLO(name_or_obj.lat, name_or_obj.lon)
      return {x=p.x, y=p.z}
    end
    return nil
  end
  if type(name_or_obj)=="string" then
    if Airbase and Airbase.getByName then
      local ab = Airbase.getByName(name_or_obj)
      if ab and ab.getPoint then
        local p = ab:getPoint()
        return {x=p.x, y=p.z}
      end
    end
    local fix = FIXES[string.upper(name_or_obj)]
    if fix then
      if fix.lat and fix.lon then
        if coord and coord.LLtoLO then
          local p = coord.LLtoLO(fix.lat, fix.lon)
          return {x=p.x, y=p.z}
        end
        return nil
      elseif fix.x and fix.y then
        return {x=fix.x, y=fix.y}
      end
    end
  end
  return nil
end

local function WP(name_or_obj) return _ll(name_or_obj) end
local function LAND_AT(airbaseName) return {landAt=airbaseName} end

local function _resolvePoints(seq)
  local pts = {}
  for _,w in ipairs(seq) do
    if type(w)=="table" and w.landAt then
      local ab = (Airbase and Airbase.getByName) and Airbase.getByName(w.landAt) or nil
      if ab and ab.getID then
        pts[#pts+1] = {type="Land", airdromeId=ab:getID(), airbaseName=w.landAt}
      else
        local p = _ll(w.landAt)
        if p then
          pts[#pts+1] = {type="LandXY", x=p.x, y=p.y}
        end
      end
    else
      local p = WP(w)
      if p then pts[#pts+1] = {x=p.x, y=p.y} end
    end
  end
  return pts
end

-- Safety helpers for DCS API calls
local function _unitExists(u)
  if not u then return false end
  if Unit and Unit.isExist then
    local ok, res = pcall(Unit.isExist, u)
    if ok then return res end
  end
  if u.isExist then
    local ok, res = pcall(u.isExist, u)
    if ok then return res end
  end
  return true
end

local function _groupExists(g)
  if not g then return false end
  if g.isExist then
    local ok, res = pcall(g.isExist, g)
    if ok then return res end
  end
  if Group and Group.isExist then
    local ok, res = pcall(Group.isExist, g)
    if ok then return res end
  end
  return true
end

local function _safeGroupGetByName(name)
  if not (Group and Group.getByName) then return nil end
  local ok, res = pcall(Group.getByName, name)
  if ok then return res end
  return nil
end

local function _safeCoalitionAddGroup(countryId, category, data)
  if not (coalition and coalition.addGroup) then return nil end
  local ok, res = pcall(coalition.addGroup, countryId, category, data)
  if ok then return res end
  _log("coalition.addGroup failed: "..tostring(res))
  return nil
end

local function _chooseRouteWithDir()
  if #CIVTRAFFIC.routes == 0 then return nil end
  local minCount = nil
  local candidates = {}
  for idx=1,#CIVTRAFFIC.routes do
    local c = CIVTRAFFIC.routeUseCounts[idx] or 0
    if minCount == nil or c < minCount then
      minCount = c
      candidates = {idx}
    elseif c == minCount then
      candidates[#candidates+1] = idx
    end
  end
  local pickIdx = candidates[math.random(1,#candidates)]
  CIVTRAFFIC.routeUseCounts[pickIdx] = (CIVTRAFFIC.routeUseCounts[pickIdx] or 0) + 1
  local r = CIVTRAFFIC.routes[pickIdx]
  local forward = math.random(1,2)==1
  local pts = {}
  if forward then
    for i=1,#r.points do pts[i]=r.points[i] end
  else
    local k=1
    for i=#r.points,1,-1 do pts[k]=r.points[i]; k=k+1 end
  end
  return {points=pts, speed=r.speed, altOdd=r.altOdd, altEven=r.altEven}
end

local function _chooseAltitude(routePts, altOdd, altEven)
  local p1 = _toXY(routePts[1])
  local p2 = _toXY(routePts[#routePts])
  if not p1 or not p2 then return _ft2m(32000) end
  local b = _bearing(p1.x,p1.y,p2.x,p2.y)
  local odd = altOdd or CIVTRAFFIC.oddFL
  local even = altEven or CIVTRAFFIC.evenFL
  if b>=0 and b<180 then return _ft2m(_rand(odd)) else return _ft2m(_rand(even)) end
end

local function _chooseSpeed(speedKts, altMeters)
  local ias = speedKts or (CIVTRAFFIC.speedMin + math.random()*(CIVTRAFFIC.speedMax - CIVTRAFFIC.speedMin))
  return _iasKtsToGsMs(ias, altMeters)
end

local function _bearingHeading(routePts)
  local p1 = _toXY(routePts[1])
  local p2 = _toXY(routePts[2]) or _toXY(routePts[#routePts]) or p1
  if not p1 or not p2 then return 0 end
  local b = _bearing(p1.x,p1.y,p2.x,p2.y)
  return math.rad(90 - b)
end

local function _callsign()
  local code = _rand(CIVTRAFFIC.airlineCodes)
  local num = tostring(math.random(101,9999))
  return code..num
end

local function _buildCallsign(code)
  local num = tostring(math.random(101,9999))
  if code and #code > 0 then return code..num end
  return "CIV"..num
end

local function _newCallsign(code)
  local prefix = (code and #code>0) and code or "CIV"
  for _=1,200 do
    local num = tostring(math.random(101,9999))
    local cs = prefix..num
    if not CIVTRAFFIC.usedCallsigns[cs] and not CIVTRAFFIC.activeByName[cs] then
      CIVTRAFFIC.usedCallsigns[cs] = true
      return cs
    end
  end
  -- Fallback: time-based unique suffix
  local fallback = prefix..tostring(math.floor((_now() or 0)*1000) % 10000000)
  CIVTRAFFIC.usedCallsigns[fallback] = true
  return fallback
end

local function _chooseAirlineForType(typ)
  local tmap = CIVTRAFFIC.liveriesByType[typ]
  if not tmap then return nil,nil end
  local codes = {}
  for c,_ in pairs(tmap) do codes[#codes+1] = c end
  if #codes == 0 then return nil,nil end
  local code = codes[math.random(1,#codes)]
  return code, tmap[code]
end

local function _wp(x,y,alt,speed,isLand,airdromeId)
  if isLand then
    return {alt=alt, action="Landing", alt_type="BARO", speed=speed, speed_locked=true, task={id="ComboTask",params={tasks={}}}, type="Land", x=x, y=y, airdromeId=airdromeId}
  end
  return {alt=alt, action="Turning Point", alt_type="BARO", speed=speed, speed_locked=true, task={id="ComboTask",params={tasks={}}}, type="Turning Point", x=x, y=y}
end

function CIVTRAFFIC.setRoutes(routes)
  CIVTRAFFIC.routes = {}
  CIVTRAFFIC.routeUseCounts = {}
  for _,r in ipairs(routes or {}) do
    if r and r.points and #r.points>=2 then
      local rr = {points={}, speed=r.speed, altOdd=r.altOdd, altEven=r.altEven}
      for i,p in ipairs(r.points) do rr.points[#rr.points+1]=p end
      CIVTRAFFIC.routes[#CIVTRAFFIC.routes+1] = rr
      CIVTRAFFIC.routeUseCounts[#CIVTRAFFIC.routeUseCounts+1] = 0
    end
  end
  _log("Routes set: "..tostring(#CIVTRAFFIC.routes))
end

function CIVTRAFFIC._activeCount() local n=0 for _ in pairs(CIVTRAFFIC.activeByName) do n=n+1 end return n end

function CIVTRAFFIC._spawnOne()
  if #CIVTRAFFIC.routes == 0 then return end
  if CIVTRAFFIC._activeCount() >= CIVTRAFFIC.maxActive then return end
  local r = _chooseRouteWithDir()
  if not r then return end
  local alt = _chooseAltitude(r.points, r.altOdd, r.altEven)
  local spd = _chooseSpeed(r.speed, alt)
  local typ = _rand(CIVTRAFFIC.aircraftTypes)
  local airlineCode, livery = _chooseAirlineForType(typ)
  local cs = _newCallsign(airlineCode)
  CIVTRAFFIC.spawnIndex = CIVTRAFFIC.spawnIndex + 1
  local gName = cs
  local uName = gName.."_U1"
  local heading = _bearingHeading(r.points)
  local wps = {}
  local endX, endY
  for i,p in ipairs(r.points) do
    if p.type=="Land" then
      local ab = (Airbase and Airbase.getByName) and Airbase.getByName(p.airbaseName or "") or nil
      if ab and ab.getPoint then
        local q=ab:getPoint(); endX=q.x; endY=q.z
        local prevXY = nil
        if #wps>0 then prevXY = {x=wps[#wps].x, y=wps[#wps].y}
        elseif i>1 then prevXY = _toXY(r.points[i-1]) end
        if not prevXY then prevXY = {x=q.x-50000,y=q.z} end
        local inbound = _bearing(prevXY.x, prevXY.y, q.x, q.z)
        local outbound = (inbound + 180) % 360
        local sign = (math.random(1,2)==1) and 1 or -1
        local b70 = (outbound + 30*sign) % 360
        local b20 = (outbound - 30*sign) % 360
        local p70 = _offsetFrom(q.x, q.z, b70, _nm2m(70))
        local p20 = _offsetFrom(q.x, q.z, b20, _nm2m(20))
        local p08 = _offsetFrom(q.x, q.z, outbound, _nm2m(8))
        local alt70 = alt
        local alt20 = math.min(alt, _ft2m(10000))
        local alt08 = math.min(alt, _ft2m(3000))
        wps[#wps+1] = _wp(p70.x, p70.y, alt70, spd, false, nil)
        wps[#wps+1] = _wp(p20.x, p20.y, alt20, _iasKtsToGsMs(250, alt20), false, nil)
        wps[#wps+1] = _wp(p08.x, p08.y, alt08, _iasKtsToGsMs(180, alt08), false, nil)
        wps[#wps+1] = _wp(q.x, q.z, alt08, _iasKtsToGsMs(160, alt08), true, p.airdromeId)
      end
    elseif p.type=="LandXY" then
      local prevXY = nil
      if #wps>0 then prevXY = {x=wps[#wps].x, y=wps[#wps].y}
      elseif i>1 then prevXY = _toXY(r.points[i-1]) end
      endX=p.x; endY=p.y
      if not prevXY then prevXY = {x=p.x-50000,y=p.y} end
      local inbound = _bearing(prevXY.x, prevXY.y, p.x, p.y)
      local outbound = (inbound + 180) % 360
      local sign = (math.random(1,2)==1) and 1 or -1
      local b70 = (outbound + 30*sign) % 360
      local b20 = (outbound - 30*sign) % 360
      local p70 = _offsetFrom(p.x, p.y, b70, _nm2m(70))
      local p20 = _offsetFrom(p.x, p.y, b20, _nm2m(20))
      local p08 = _offsetFrom(p.x, p.y, outbound, _nm2m(8))
      local alt70 = alt
      local alt20 = math.min(alt, _ft2m(10000))
      local alt08 = math.min(alt, _ft2m(3000))
      wps[#wps+1] = _wp(p70.x, p70.y, alt70, spd, false, nil)
      wps[#wps+1] = _wp(p20.x, p20.y, alt20, _iasKtsToGsMs(250, alt20), false, nil)
      wps[#wps+1] = _wp(p08.x, p08.y, alt08, _iasKtsToGsMs(180, alt08), false, nil)
      wps[#wps+1] = _wp(p.x, p.y, alt08, _iasKtsToGsMs(160, alt08), true, nil)
    else
      wps[#wps+1] = _wp(p.x, p.y, alt, spd, false, nil)
      if i==#r.points then endX=p.x; endY=p.y end
    end
  end
  local start = _toXY(r.points[1])
  if not start then _log("Route start invalid; abort spawn") return end
  local groupData = {
    visible=false, lateActivation=false, tasks={}, task="Transport",
    route={points=wps},
    units={ [1]={alt=alt, alt_type="BARO", skill="Excellent", speed=spd, type=typ, name=uName, x=start.x, y=start.y, heading=heading, livery_id=livery}},
    y=start.y, x=start.x, name=gName
  }
  local airplaneCat = (Group and Group.Category and Group.Category.AIRPLANE) or 0
  local grp = _safeCoalitionAddGroup(CIVTRAFFIC.country, airplaneCat, groupData)
  if grp then
    CIVTRAFFIC.active[gName] = {name=gName, endPt={x=endX,y=endY}, spawnedAt=_now()}
    CIVTRAFFIC.activeByName[gName] = true
    _log("Spawned "..typ.." as "..gName.." livery="..tostring(livery))
  end
end

function CIVTRAFFIC._cleanupMissing()
  if not (Group and (Group.getByName or Group.isExist)) then return end
  for name,_ in pairs(CIVTRAFFIC.activeByName) do
    local g = _safeGroupGetByName(name)
    if not _groupExists(g) then
      CIVTRAFFIC.activeByName[name] = nil
      CIVTRAFFIC.active[name] = nil
    end
  end
end

function CIVTRAFFIC._monitor()
  CIVTRAFFIC._cleanupMissing()
  for name,rec in pairs(CIVTRAFFIC.active) do
    local g = _safeGroupGetByName(name)
    if g and _groupExists(g) then
      local u = (g.getUnit and g:getUnit(1)) or nil
      if u and _unitExists(u) and u.getPoint then
        local p = u:getPoint()
        if p and p.x and p.z then
          local d = _dist(p.x,p.z,rec.endPt.x,rec.endPt.y)
          if d <= CIVTRAFFIC.endThreshold then
            if g.destroy then pcall(g.destroy, g) end
            CIVTRAFFIC.activeByName[name] = nil
            CIVTRAFFIC.active[name] = nil
            _log("Despawned at destination: "..name)
          end
        end
      else
        CIVTRAFFIC.activeByName[name] = nil
        CIVTRAFFIC.active[name] = nil
      end
    else
      CIVTRAFFIC.activeByName[name] = nil
      CIVTRAFFIC.active[name] = nil
    end
  end
  return _now() + CIVTRAFFIC.monitorInterval
end

function CIVTRAFFIC._spawner()
  if CIVTRAFFIC._activeCount() < CIVTRAFFIC.maxActive then CIVTRAFFIC._spawnOne() end
  return _now() + _nextInterval()
end

CIVTRAFFIC._eventHandler = {}
function CIVTRAFFIC._eventHandler:onEvent(e)
  local isDeadOrCrash = (world and world.event) and (e and (e.id == world.event.S_EVENT_DEAD or e.id == world.event.S_EVENT_CRASH))
  if isDeadOrCrash and e.initiator then
    local u = e.initiator
    if _unitExists(u) then
      local g = (u.getGroup and u:getGroup()) or nil
      if g and g.getName then
        local gn = g:getName()
        if gn and CIVTRAFFIC.activeByName[gn] then
          CIVTRAFFIC.activeByName[gn] = nil
          CIVTRAFFIC.active[gn] = nil
          _log("Removed due to event "..tostring(e.id)..": "..gn)
        end
      end
    end
  end
end

function CIVTRAFFIC.start(routes)
  if routes then CIVTRAFFIC.setRoutes(routes) end
  if world and world.addEventHandler then
    pcall(world.addEventHandler, CIVTRAFFIC._eventHandler)
  end
  -- Immediate initial spawns
  local toSpawn = math.min(CIVTRAFFIC.initialSpawns or 0, CIVTRAFFIC.maxActive - CIVTRAFFIC._activeCount())
  for i=1,toSpawn do
    CIVTRAFFIC._spawnOne()
  end
  if timer and timer.scheduleFunction then
    timer.scheduleFunction(function() return CIVTRAFFIC._monitor() end, {}, _now() + CIVTRAFFIC.monitorInterval)
    timer.scheduleFunction(function() return CIVTRAFFIC._spawner() end, {}, _now() + _nextInterval())
  end
  _log("Started. monitorInterval="..tostring(CIVTRAFFIC.monitorInterval)..", maxActive="..tostring(CIVTRAFFIC.maxActive))
end

-- Load any trigger zones named with prefix FIX_ into FIXES (center point)
CIVTRAFFIC.loadFixZones("FIX_")

local myRoutes = {
  { points = _resolvePoints({"Ankara","Gaziantep","Diyarbakir","Urmia"}), speed = 250 },
  { points = _resolvePoints({"Urmia","Diyarbakir","Gaziantep","Ankara"}), speed = 250 },
  --{ points = _resolvePoints({"Ankara","Adana Sakirpasa", LAND_AT("Adana Sakirpasa")}), speed = 240 },
  { points = _resolvePoints({"Aqaba","QAA VOR","KIRRK"}), speed = 240 },
  { points = _resolvePoints({"KIRRK","QAA VOR","Aqaba"}), speed = 240 },
}

CIVTRAFFIC.start(myRoutes)
