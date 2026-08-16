local _, Sentinel = ...

local Bridge = {}
Sentinel.Bridge = Bridge

local INTERRUPTS = {
    WARRIOR = { kick = 6552, cc = 5246 },
    PALADIN = { kick = 96231, cc = 853 },
    HUNTER = { kick = 147362, cc = 187650 },
    ROGUE = { kick = 1766, cc = 408 },
    PRIEST = { kick = 15487, cc = 8122 },
    DEATHKNIGHT = { kick = 47528, cc = 108194 },
    SHAMAN = { kick = 57994, cc = 51514 },
    MAGE = { kick = 2139, cc = 118 },
    WARLOCK = { kick = 19647, cc = 5782 },
    MONK = { kick = 116705, cc = 115078 },
    DRUID = { kick = 106839, cc = 33786 },
    DEMONHUNTER = { kick = 183752, cc = 217832 },
    EVOKER = { kick = 351338, cc = 360806 },
}

local function isSecret(value)
    if type(issecretvalue) ~= "function" then return false end
    local ok, result = pcall(issecretvalue, value)
    return ok and result == true
end

local function text(value, fallback, maximum)
    if type(_G.KWR) == "table" and _G.KWR.Util and _G.KWR.Util.Text then
        return _G.KWR.Util:Text(value, fallback or "", maximum or 180)
    end
    local ok, result = pcall(function()
        if value == nil or isSecret(value) then return fallback or "" end
        local output = tostring(value)
        if isSecret(output) or output == "" then return fallback or "" end
        if maximum and #output > maximum then return output:sub(1, maximum) end
        return output
    end)
    return ok and result or (fallback or "")
end

local function shortName(value)
    value = text(value, "", 64)
    local dash = value:find("-", 1, true)
    return dash and value:sub(1, dash - 1) or value
end

local function spellName(spellID)
    if type(C_Spell) == "table" and type(C_Spell.GetSpellName) == "function" then
        return C_Spell.GetSpellName(spellID)
    end
    if type(GetSpellInfo) == "function" then
        return GetSpellInfo(spellID)
    end
    return nil
end

local function spellCooldownSeconds(_)
    -- Retail may return secret cooldown fields. Addons cannot safely do math,
    -- compare, format, or branch on those values after they enter this call
    -- path. Sentinel is advisory, so an explicit unknown is safer than a
    -- tainted countdown or a misleading ready state.
    return nil
end

local function clock(value)
    if value == nil then return "UNKNOWN" end
    value = tonumber(value)
    if value == nil then return "UNKNOWN" end
    if value <= 0 then return "READY" end
    value = math.ceil(value)
    local minutes = math.floor(value / 60)
    local seconds = value % 60
    if minutes > 0 then
        return string.format("%d:%02d", minutes, seconds)
    end
    return tostring(seconds) .. "s"
end

local function playerSpells()
    local _, class = UnitClass("player")
    class = text(class, "", 24)
    local profile = INTERRUPTS[class]
    if not profile then
        return { kickName = nil, ccName = nil }
    end
    return {
        kickName = spellName(profile.kick),
        ccName = spellName(profile.cc),
    }
end

local function inRangeForSpell(spell, unit)
    if not spell or not unit or not UnitExists(unit) or type(IsSpellInRange) ~= "function" then
        return nil
    end
    local result = IsSpellInRange(spell, unit)
    -- Retail may return a protected/secret boolean here. Never compare or
    -- branch on that value directly; treat it as unavailable for display.
    local ok, normalized = pcall(function()
        if result == 1 or result == true then return true end
        if result == 0 or result == false then return false end
        return nil
    end)
    if ok then return normalized end
    return nil
end

local function castInfo(unit)
    local ok, result = pcall(function()
        if not unit or not UnitExists(unit) then return nil end
        local name, _, _, _, endMS, _, _, notInterruptible = UnitCastingInfo(unit)
        local channel = false
        if not name then
            name, _, _, _, endMS, _, notInterruptible = UnitChannelInfo(unit)
            channel = name ~= nil
        end
        if not name or isSecret(name) or isSecret(endMS)
            or isSecret(notInterruptible) then return nil end
        local nowMS = GetTime() * 1000
        local remaining = endMS and math.max(0, (endMS - nowMS) / 1000) or nil
        return {
            name = text(name, "", 64),
            remaining = remaining,
            notInterruptible = notInterruptible == true,
            channel = channel,
        }
    end)
    return ok and result or nil
end

local function iterateGroupUnits()
    local units = { "player" }
    if IsInRaid() then
        for index = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. tostring(index)
        end
    elseif IsInGroup() then
        for index = 1, GetNumSubgroupMembers() do
            units[#units + 1] = "party" .. tostring(index)
        end
    end
    return units
end

local function healerStatus()
    local result = {
        name = "Unknown",
        range = "UNKNOWN",
        detail = "No friendly healer unit is available.",
    }
    for _, unit in ipairs(iterateGroupUnits()) do
        if UnitExists(unit)
            and UnitGroupRolesAssigned(unit) == "HEALER"
            and UnitIsConnected(unit)
            and not UnitIsDeadOrGhost(unit) then
            result.name = shortName(UnitName(unit))
            if unit == "player" then
                result.range = "SELF"
                result.detail = "You are a healer."
            else
                result.range = "UNKNOWN"
                result.detail = "Primary healer range is protected by the client."
            end
            return result
        end
    end
    return result
end

local function releaseTimeRemaining()
    -- See spellCooldownSeconds: release timers can also be secret in Retail.
    -- Do not derive a countdown from protected values in addon Lua.
    return nil
end

local function localStatus(view)
    local assignment = view.assignment or {}
    local spells = playerSpells()
    local trinket = spellCooldownSeconds(42292)
        or spellCooldownSeconds(195710)
        or spellCooldownSeconds(208683)
        or spellCooldownSeconds(336126)
    local kick = spellCooldownSeconds((select(2, UnitClass("player")) and INTERRUPTS[select(2, UnitClass("player"))]
        and INTERRUPTS[select(2, UnitClass("player"))].kick) or nil)
    local cc = spellCooldownSeconds((select(2, UnitClass("player")) and INTERRUPTS[select(2, UnitClass("player"))]
        and INTERRUPTS[select(2, UnitClass("player"))].cc) or nil)
    local dead = false
    if UnitIsDeadOrGhost then
        local ok, value = pcall(UnitIsDeadOrGhost, "player")
        dead = ok and not isSecret(value) and value == true
    end
    local stage = assignment.location
    if assignment.movement ~= "FLOAT" and assignment.movement ~= "MOVE"
        and assignment.movement ~= "COLLAPSE" then
        stage = ""
    end
    return {
        dead = dead,
        movement = text(assignment.movement, "STAY", 24),
        stage = text(stage, "", 48),
        rez = dead and clock(releaseTimeRemaining()) or "ALIVE",
        trinket = clock(trinket),
        kick = spells.kickName and (spells.kickName .. " " .. clock(kick)) or "NO KICK",
        cc = spells.ccName and (spells.ccName .. " " .. clock(cc)) or "NO CC",
    }
end

local function locateUnitByName(name)
    name = shortName(name):lower()
    if name == "" then return nil end
    for _, unit in ipairs({ "target", "focus", "mouseover" }) do
        if UnitExists(unit) and shortName(UnitName(unit)):lower() == name then
            return unit
        end
    end
    for index = 1, 40 do
        local unit = "nameplate" .. tostring(index)
        if UnitExists(unit) and shortName(UnitName(unit)):lower() == name then
            return unit
        end
    end
    return nil
end

local function fallbackView()
    local mapName = GetRealZoneText and GetRealZoneText() or "World"
    return {
        source = "STANDALONE",
        revision = 0,
        mode = select(2, IsInInstance()) == "pvp" and "LIVE" or "WORLD",
        mapKey = "WORLD",
        assignment = {
            role = "Standalone",
            shortRole = "SOLO",
            location = "Install KWR for commander assignment relay",
            detail = "Sentinel is running without a local KWR commander state.",
        },
        score = {
            mapKey = "WORLD",
            mapName = mapName,
            mapShort = "WORLD",
            status = select(2, IsInInstance()) == "pvp" and "LIVE" or "WORLD",
            friendly = 0,
            enemy = 0,
            max = 0,
            timeToWin = "unknown",
            friendlyTime = "unknown",
            enemyTime = "unknown",
            commandWhen = "WAIT",
            condition = "Install KWR on the same client for score pace and assignment relay.",
            action = "Use native map and scoreboard while Sentinel watches healer range and your target cast.",
        },
        deathZone = {
            state = "NONE",
            label = "current fight",
            score = 0,
            response = "WATCH",
            detail = "Standalone Sentinel has no commander collapse model.",
        },
        watch = {
            name = "No tracked enemy",
            role = "UNKNOWN",
            healthPercent = nil,
            castName = nil,
            castPriority = nil,
            reason = "Track your current target or run Sentinel beside KWR for local-target relay.",
            cooldownText = nil,
        },
        carriers = {},
        command = {
            line2 = "",
            line3 = "",
            action = "",
        },
        requirement = {
            holdLine = "Hold current assignment.",
            winLine = "Win the next objective exchange.",
        },
        trustState = "NO COMMANDER",
        roster = {
            self = {},
            team = {},
            enemy = {},
        },
    }
end

local function augmentWatch(view)
    view.watch = view.watch or {}
    local spells = playerSpells()
    view.watch.kickSpell = spells.kickName
    view.watch.ccSpell = spells.ccName
    local unit = view.watch.unit
    if (not unit or unit == "") and view.watch.name then
        unit = locateUnitByName(view.watch.name)
    end
    if unit then
        view.watch.unit = unit
        view.watch.liveCast = castInfo(unit)
        view.watch.inKickRange = inRangeForSpell(spells.kickName, unit)
        view.watch.inCCRange = inRangeForSpell(spells.ccName, unit)
        if type(_G.KWR) == "table" and _G.KWR.Util and _G.KWR.Util.IsSecret then
            local healthMax = UnitHealthMax(unit)
            local health = UnitHealth(unit)
            if not _G.KWR.Util:IsSecret(health) and not _G.KWR.Util:IsSecret(healthMax)
                and healthMax and healthMax > 0 then
                view.watch.healthPercent = math.floor((health / healthMax) * 100 + 0.5)
            end
        end
    elseif (not view.watch.name or view.watch.name == "")
        and UnitExists("target") and UnitCanAttack("player", "target") then
        view.watch.name = shortName(UnitName("target"))
        view.watch.localFallbackTarget = true
        view.watch.liveCast = castInfo("target")
        view.watch.inKickRange = inRangeForSpell(spells.kickName, "target")
        view.watch.inCCRange = inRangeForSpell(spells.ccName, "target")
        if type(_G.KWR) == "table" and _G.KWR.Util and _G.KWR.Util.IsSecret then
            local healthMax = UnitHealthMax("target")
            local health = UnitHealth("target")
            if not _G.KWR.Util:IsSecret(health) and not _G.KWR.Util:IsSecret(healthMax)
                and healthMax and healthMax > 0 then
                view.watch.healthPercent = math.floor((health / healthMax) * 100 + 0.5)
            end
        end
    end
    return view
end

function Bridge:BuildView()
    local remote = Sentinel:TransportEnabled() and Sentinel.Relay and Sentinel.Relay:View() or nil
    local kwr = _G.KWR
    -- Remote relays are deliberately partial. Overlay only their received
    -- families onto the complete local/standalone view so a lost packet never
    -- blanks score pace, the local target, or an actionable local command.
    local view = (kwr and kwr.SentinelBridge and kwr.ready
        and kwr.SentinelBridge:BuildView(shortName(UnitName("player")))
        or fallbackView())
    if remote then
        for _, field in ipairs({ "assignment", "watch", "command" }) do
            if remote[field] then view[field] = remote[field] end
        end
        view.trustState, view.source = remote.trustState, remote.source
    end
    view.healer = healerStatus()
    view.playerStatus = localStatus(view)
    local relayStatus = Sentinel.Relay and Sentinel.Relay:Status() or {
        connected = false, state = "NO REMOTE", age = nil, expiresIn = 0,
    }
    local comm = Sentinel.Comm and Sentinel.Comm.diagnostics or {}
    local nexusKnowledge = kwr and kwr.StrategistNexusKnowledge
    local liveEvidence = nexusKnowledge and nexusKnowledge.LiveEvidence
        and nexusKnowledge:LiveEvidence() or {}
    view.proof = {
        bridge = remote and "REMOTE" or (kwr and kwr.ready and "LOCAL" or "STANDALONE"),
        transport = Sentinel:TransportEnabled() and relayStatus.state or "DISABLED",
        packetAge = relayStatus.age,
        expiresIn = relayStatus.expiresIn,
        received = comm.received or 0,
        rejected = comm.rejected or 0,
        throttled = comm.throttled or 0,
        corpus = nexusKnowledge
            and ("NEXUS " .. tostring(nexusKnowledge:Status())
                .. " / REVIEWED " .. tostring(liveEvidence.reviewedLearningSamples or 0))
            or "LOCAL ONLY",
    }
    if Sentinel:TransportEnabled() and relayStatus.state == "REMOTE STALE" then
        view.degraded = true
        view.trustState = "STALE"
        view.command = view.command or {}
        view.command.action = "REMOTE EXPIRED - USE LOCAL GUIDANCE"
        view.command.when = "NOW"
    end
    return augmentWatch(view)
end

Sentinel:RegisterModule("Bridge", Bridge)
