local _, KWR = ...

local ObjectiveIntel = {
    events = {},
    carriers = {},
    timers = {},
    auraCache = {},
    maxEvents = 24,
}
KWR.ObjectiveIntel = ObjectiveIntel

local MESSAGE_GRAMMARS = {
    enUS = {
        orbPickup = {
            "^(.+) has taken the Green orb!$",
            "^(.+) has taken the Blue orb!$",
            "^(.+) has taken the Orange orb!$",
            "^(.+) has taken the Purple orb!$",
        },
        orbReturn = {
            "^The Green orb has been returned!$",
            "^The Blue orb has been returned!$",
            "^The Orange orb has been returned!$",
            "^The Purple orb has been returned!$",
        },
        flagPickup = {
            "^(.+) has picked up the Alliance flag!$",
            "^(.+) has picked up the Horde flag!$",
            "^(.+) picked up the Alliance flag!$",
            "^(.+) picked up the Horde flag!$",
        },
        flagReturn = {
            "^The Alliance flag was returned to its base!$",
            "^The Horde flag was returned to its base!$",
        },
        flagCapture = {
            "^(.+) captured the Alliance flag!$",
            "^(.+) captured the Horde flag!$",
        },
        globalFlagReset = {
            "^The flags are now placed at their bases%.?$",
            "^Both flags returned%.?$",
        },
        assault = {
            "^(.+) has assaulted the (.+)!$",
        },
        teamMap = {
            Alliance = "Alliance",
            Horde = "Horde",
        },
        colorMap = {
            Green = "Green",
            Blue = "Blue",
            Orange = "Orange",
            Purple = "Purple",
        },
    },
    deDE = {
        orbPickup = {
            "^(.+) hat die Gruene Kugel genommen!$",
            "^(.+) hat die Blaue Kugel genommen!$",
            "^(.+) hat die Orangefarbene Kugel genommen!$",
            "^(.+) hat die Violette Kugel genommen!$",
        },
        orbReturn = {
            "^Die Gruene Kugel wurde zurueckgebracht!$",
            "^Die Blaue Kugel wurde zurueckgebracht!$",
            "^Die Orangefarbene Kugel wurde zurueckgebracht!$",
            "^Die Violette Kugel wurde zurueckgebracht!$",
        },
        flagPickup = {
            "^(.+) hat die Flagge der Allianz aufgenommen!$",
            "^(.+) hat die Flagge der Horde aufgenommen!$",
        },
        flagReturn = {
            "^Die Flagge der Allianz wurde zu ihrem Stuetzpunkt zurueckgebracht!$",
            "^Die Flagge der Horde wurde zu ihrem Stuetzpunkt zurueckgebracht!$",
        },
        flagCapture = {
            "^(.+) hat die Flagge der Allianz erobert!$",
            "^(.+) hat die Flagge der Horde erobert!$",
        },
        globalFlagReset = {
            "^Die Flaggen befinden sich wieder an ihren Basen%.?$",
        },
        assault = {
            "^(.+) hat (.+) angegriffen!$",
        },
        teamMap = {
            Allianz = "Alliance",
            Horde = "Horde",
        },
        colorMap = {
            Gruene = "Green",
            Blaue = "Blue",
            Orangefarbene = "Orange",
            Violette = "Purple",
        },
        normalize = true,
    },
}

local function normalizeName(name)
    return KWR.Util:ShortName(KWR.Util:Text(name, "", 80)):lower()
end

local function sessionMapKey(sessionKey)
    return KWR.Util:Text(sessionKey, "", 96):match("^([^:]+)")
end

local function sessionPhase(sessionKey)
    local normalized = KWR.Util:Upper(sessionKey, "", 96)
    if normalized:find(":PVP:", 1, true) then return "PVP" end
    if normalized:find(":WORLD:", 1, true) then return "WORLD" end
    if normalized:find(":TRUE", 1, true) or normalized:find(":LIVE", 1, true) then
        return "PVP"
    end
    if normalized:find(":FALSE", 1, true) then return "WORLD" end
    return nil
end

local function sessionMode(sessionKey)
    local normalized = KWR.Util:Upper(sessionKey, "", 96)
    if normalized:find(":PREVIEW", 1, true) then return "PREVIEW" end
    if normalized ~= "" then return "LIVE" end
    return nil
end

local function sameSession(stored, desired)
    if stored == desired then return true end
    local storedMap = sessionMapKey(stored)
    local desiredMap = sessionMapKey(desired)
    if not storedMap or not desiredMap or storedMap ~= desiredMap then
        return false
    end
    local storedPhase = sessionPhase(stored)
    local desiredPhase = sessionPhase(desired)
    local storedMode = sessionMode(stored)
    local desiredMode = sessionMode(desired)
    return (storedPhase == nil or desiredPhase == nil or storedPhase == desiredPhase)
        and (storedMode == nil or desiredMode == nil or storedMode == desiredMode)
end

local function addEvent(self, kind, text, objective, player)
    self.events[#self.events + 1] = {
        at = KWR.Util:Now(),
        kind = kind,
        text = KWR.Util:Text(text, "", 160),
        objective = objective,
        player = player,
    }
    while #self.events > self.maxEvents do table.remove(self.events, 1) end
end

local function clearCarrier(self, objective)
    objective = KWR.Util:Text(objective, "", 48)
    if objective == "" then
        return false
    end
    if self.carriers[objective] ~= nil then
        self.carriers[objective] = nil
        return true
    end
    return false
end

local function clearFlagCarriers(self, objective)
    if objective then
        return clearCarrier(self, objective)
    end
    local cleared = false
    for key, carrier in pairs(self.carriers) do
        if carrier.kind == "FLAG" then
            self.carriers[key] = nil
            cleared = true
        end
    end
    return cleared
end

local function flagObjectiveFromMessage(message)
    for _, team in ipairs({ "Alliance", "Horde" }) do
        if message:find(team .. " flag", 1, true) then
            return team .. " Flag"
        end
    end
end

local function activeGrammar()
    local locale = type(GetLocale) == "function" and tostring(GetLocale() or "") or "enUS"
    if locale == "enGB" then locale = "enUS" end
    return MESSAGE_GRAMMARS[locale] or MESSAGE_GRAMMARS.enUS
end

local function normalizeLocaleMessage(message)
    return tostring(message or "")
        :gsub("\195\188", "ue")
        :gsub("\195\156", "Ue")
        :gsub("\195\164", "ae")
        :gsub("\195\132", "Ae")
        :gsub("\195\182", "oe")
        :gsub("\195\150", "Oe")
        :gsub("\195\159", "ss")
end

local function matchFirst(message, patterns)
    for _, pattern in ipairs(patterns or {}) do
        local first, second = message:match(pattern)
        if first ~= nil then
            return first, second
        end
    end
end

local function localizedFlagObjective(grammar, teamToken)
    local teamMap = grammar and grammar.teamMap or nil
    local team = teamMap and teamMap[teamToken] or nil
    if team then
        return team .. " Flag"
    end
end

local function localizedOrbColor(grammar, colorToken)
    local colorMap = grammar and grammar.colorMap or nil
    return colorMap and colorMap[colorToken] or nil
end

local function localizedToken(message, tokenMap)
    for token in pairs(tokenMap or {}) do
        if message:find(token, 1, true) then
            return token
        end
    end
end

local function normalizeObjectiveLabel(label)
    label = KWR.Util:Text(label, "", 80)
    return (label
        :gsub("^the%s+", "")
        :gsub("^den%s+", "")
        :gsub("^die%s+", "")
        :gsub("^das%s+", "")
        :gsub("^der%s+", ""))
end

local function isGlobalFlagReset(message)
    local lower = message:lower()
    return lower:find("flags are now placed at their bases", 1, true) ~= nil
        or lower:find("both flags returned", 1, true) ~= nil
end

function ObjectiveIntel:Reset(sessionKey)
    self.sessionKey = sessionKey
    self.events = {}
    self.carriers = {}
    self.timers = {}
    self.auraCache = {}
end

function ObjectiveIntel:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "ObjectiveIntel")
    end
end

function ObjectiveIntel:ObserveMessage(message, mapKey)
    message = KWR.Util:Text(message, "", 160)
    if message == "" then return end
    local grammar = activeGrammar()
    local matchMessage = grammar.normalize and normalizeLocaleMessage(message) or message
    if mapKey and mapKey ~= "WORLD" and mapKey ~= "UNKNOWN" then
        local desired = tostring(mapKey) .. ":true"
        if not sameSession(self.sessionKey, desired) then
            self:Reset(desired)
        end
    end

    local player = matchFirst(matchMessage, grammar.orbPickup)
    local color = localizedOrbColor(grammar, localizedToken(matchMessage, grammar.colorMap))
    if player and color then
        local objective = color .. " Orb"
        self.carriers[objective] = {
            objective = objective,
            kind = "ORB",
            color = color,
            player = player,
            playerKey = normalizeName(player),
            observedAt = KWR.Util:Now(),
            source = "BG_SYSTEM",
        }
        addEvent(self, "PICKUP", message, objective, player)
        return
    end

    local returnedColor = localizedOrbColor(grammar, localizedToken(matchMessage, grammar.colorMap))
    if returnedColor then
        local objective = returnedColor .. " Orb"
        self.carriers[objective] = nil
        addEvent(self, "RETURN", message, objective)
        return
    end

    local flagPlayer = matchFirst(matchMessage, grammar.flagPickup)
    local flagTeam = localizedFlagObjective(grammar, localizedToken(matchMessage, grammar.teamMap))
    if flagPlayer and flagTeam then
        local objective = flagTeam
        self.carriers[objective] = {
            objective = objective,
            kind = "FLAG",
            color = objective:gsub(" Flag$", ""),
            player = flagPlayer,
            playerKey = normalizeName(flagPlayer),
            observedAt = KWR.Util:Now(),
            source = "BG_SYSTEM",
        }
        addEvent(self, "PICKUP", message, objective, flagPlayer)
        return
    end

    local returnedFlag = localizedFlagObjective(grammar,
        localizedToken(matchMessage, grammar.teamMap))
    if returnedFlag then
        clearFlagCarriers(self, returnedFlag)
        addEvent(self, "FLAG_STATE", message, returnedFlag)
        return
    end

    local capturedBy = matchFirst(matchMessage, grammar.flagCapture)
    local capturedFlag = capturedBy and localizedFlagObjective(grammar,
        localizedToken(matchMessage, grammar.teamMap)) or nil
    if capturedFlag then
        clearFlagCarriers(self, capturedFlag)
        addEvent(self, "FLAG_STATE", message, capturedFlag)
        return
    end

    if matchFirst(matchMessage, grammar.globalFlagReset) or isGlobalFlagReset(message) then
        clearFlagCarriers(self)
        addEvent(self, "FLAG_STATE", message)
        return
    end

    local lowerMessage = message:lower()
    if lowerMessage:find("flag", 1, true)
        and (lowerMessage:find("returned", 1, true)
            or lowerMessage:find("captured", 1, true)
            or isGlobalFlagReset(message)) then
        local objective = flagObjectiveFromMessage(message)
        if objective then
            clearFlagCarriers(self, objective)
            addEvent(self, "FLAG_STATE", message, objective)
            return
        end
        addEvent(self, "SYSTEM", message)
        return
    end

    local assaulter, node = matchFirst(matchMessage, grammar.assault)
    if assaulter and node then
        node = normalizeObjectiveLabel(node)
        local definition = KWR.Maps:Get(mapKey)
        self.timers[node] = {
            objective = node,
            assaulter = assaulter,
            startedAt = KWR.Util:Now(),
            endsAt = KWR.Util:Now() + (definition and definition.captureSeconds or 60),
            source = "BG_SYSTEM",
        }
        addEvent(self, "ASSAULT", message, node, assaulter)
        return
    end
    addEvent(self, "SYSTEM", message)
end

function ObjectiveIntel:ObserveRemoteCarrier(body, observedAt)
    body = type(body) == "table" and body or {}
    local objective = KWR.Util:Text(body.label, "", 64)
    local player = KWR.Util:Text(body.carrier, "", 64)
    local kind = KWR.Util:Upper(body.kind, "", 16)
    if objective == "" or player == "" or (kind ~= "FLAG" and kind ~= "ORB") then return nil end
    local existing = self.carriers[objective]
    if existing and existing.source == "BG_SYSTEM" then
        return KWR.Util:Copy(existing)
    end
    local carrier = {
        objective = objective,
        kind = kind,
        color = objective:gsub(" Flag$", ""):gsub(" Orb$", ""),
        player = player,
        playerKey = normalizeName(player),
        observedAt = KWR.Util:Number(observedAt, KWR.Util:Now()) or KWR.Util:Now(),
        source = "REMOTE_SENTINEL",
    }
    -- A relay observation is advisory, not an authoritative flag-state event.
    -- It must disappear with the ingress observation when no newer packet arrives.
    carrier.expiresAt = carrier.observedAt + 3
    self.carriers[objective] = carrier
    return KWR.Util:Copy(carrier)
end

local function findEntity(snapshot, playerKey)
    for _, entity in ipairs(snapshot.roster or {}) do
        if normalizeName(entity.name) == playerKey then return entity, "FRIENDLY" end
    end
    for _, entity in ipairs(snapshot.enemies or {}) do
        if normalizeName(entity.name) == playerKey then return entity, "ENEMY" end
    end
end

local function findObjectiveRow(rows, objective)
    for _, row in ipairs(rows or {}) do
        if row.label == objective then return row end
    end
end

local function decorateTimerRow(snapshot, timer)
    local objectives = snapshot.objectives or {}
    objectives.rows = objectives.rows or {}
    local row = findObjectiveRow(objectives.rows, timer.objective)
    if not row then
        row = {
            label = timer.objective,
            kind = "OBJECTIVE",
            owner = "UNKNOWN",
            state = "INCOMING",
            source = "bg_system",
        }
        objectives.rows[#objectives.rows + 1] = row
    end
    local _, assaulterOwner = findEntity(snapshot,
        normalizeName(KWR.Util:Text(timer.assaulter, "", 80)))
    row.contested = true
    row.pendingState = "INCOMING"
    row.pendingSource = "bg_system"
    row.pendingBy = timer.assaulter
    row.pendingOwner = assaulterOwner
    row.timerRemaining = timer.remaining
    if objectives.source ~= "ui_widget"
        or row.state == nil or row.state == "AVAILABLE" or row.state == "MAP" then
        row.state = "INCOMING"
        row.source = "bg_system"
    end
    if objectives.source ~= "ui_widget" then
        if assaulterOwner == "FRIENDLY" then
            objectives.friendlyIncoming = (objectives.friendlyIncoming or 0) + 1
        elseif assaulterOwner == "ENEMY" then
            objectives.enemyIncoming = (objectives.enemyIncoming or 0) + 1
        end
    end
end

local function observeCarrierAuras(self, carrier, unit)
    if not unit or not KWR.SafeAuraAdapter then return end
    local cacheKey = carrier.playerKey or carrier.player or unit
    local now = KWR.Util:Now()
    local cached = self.auraCache[cacheKey]
    if cached and now - cached.at < 0.5 then
        carrier.stacks = cached.stacks
        carrier.auras = KWR.Util:Copy(cached.auras)
        return
    end
    local bestStacks = 0
    local observed = {}
    for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
        for index = 1, 40 do
            local aura = KWR.SafeAuraAdapter:GetAura(unit, index, filter)
            if type(aura) ~= "table" then break end
            local name = KWR.Util:Text(aura.name, "", 80)
            local lower = name:lower()
            if lower:find("focused assault", 1, true)
                or lower:find("brutal assault", 1, true)
                or lower:find("orb", 1, true) then
                local stacks = KWR.Util:Number(aura.applications, 0) or 0
                observed[#observed + 1] = { name = name, stacks = stacks }
                bestStacks = math.max(bestStacks, stacks)
            end
        end
    end
    carrier.stacks = bestStacks
    carrier.auras = observed
    self.auraCache[cacheKey] = {
        at = now,
        stacks = bestStacks,
        auras = KWR.Util:Copy(observed),
    }
end

function ObjectiveIntel:Apply(snapshot)
    local sessionKey = KWR.Util:BattlefieldSessionKey(snapshot.context)
    if not sameSession(self.sessionKey, sessionKey) then
        self:Reset(sessionKey)
    elseif self.sessionKey ~= sessionKey then
        self.sessionKey = sessionKey
    end

    local carriers = {}
    local now = KWR.Util:Now()
    for objective, stored in pairs(self.carriers) do
        if stored.expiresAt and stored.expiresAt <= now then
            self.carriers[objective] = nil
        else
        local carrier = KWR.Util:Copy(stored)
        local entity, owner = findEntity(snapshot, carrier.playerKey)
        carrier.owner = owner or "UNKNOWN"
        if entity then
            carrier.unit = entity.unit
            carrier.healthPercent = entity.healthPercent
            carrier.x, carrier.y = entity.x, entity.y
            carrier.dead = entity.dead
            carrier.visible = entity.visible == true or owner == "FRIENDLY"
            observeCarrierAuras(self, carrier, entity.unit)
            entity.carrier = true
            entity.carriedObjective = objective
            entity.carrierStacks = carrier.stacks
        end
        if not carrier.x or not carrier.y then
            local wanted = KWR.Util:Text(carrier.color, "", 20):lower()
            for _, flag in ipairs(snapshot.objectives.flags or {}) do
                local texture = KWR.Util:Text(flag.texture, "", 100):lower()
                if wanted ~= "" and texture:find(wanted, 1, true) then
                    carrier.x, carrier.y = flag.x, flag.y
                    carrier.mapSource = "battlefield_flag"
                    break
                end
            end
        end
        carriers[#carriers + 1] = carrier
        for _, row in ipairs(snapshot.objectives.rows or {}) do
            if row.label == objective or (carrier.kind == "FLAG" and row.kind == "FLAG") then
                row.state = "CARRIED"
                row.carrier = carrier.player
                row.owner = carrier.owner
                -- Preserve native widget/map semantics as raw provenance, but
                -- identify the newer accepted carrier observation as the
                -- source of the overlaid live state.
                row.source = KWR.Util:Text(carrier.source, "BG_SYSTEM", 32):lower()
                row.selectedSource = row.source
                row.liveStateSource = row.source
                row.liveObservedAt = carrier.observedAt
                if carrier.x and carrier.y then
                    row.x, row.y = carrier.x, carrier.y
                    row.mapSource = "carrier"
                end
            end
        end
        end
    end
    table.sort(carriers, function(a, b) return a.objective < b.objective end)
    snapshot.objectives.carriers = carriers
    snapshot.objectives.events = KWR.Util:Copy(self.events)
    snapshot.objectives.timers = {}
    for node, timer in pairs(self.timers) do
        local copy = KWR.Util:Copy(timer)
        copy.remaining = math.max(0, (copy.endsAt or now) - now)
        if copy.remaining > 0 then
            snapshot.objectives.timers[#snapshot.objectives.timers + 1] = copy
            decorateTimerRow(snapshot, copy)
        else
            self.timers[node] = nil
        end
    end
    table.sort(snapshot.objectives.timers, function(a, b)
        return KWR.Util:Text(a.objective, "", 48) < KWR.Util:Text(b.objective, "", 48)
    end)
    snapshot.objectives.truthQuality = {
        source = snapshot.objectives.source or "unknown",
        carriers = #carriers,
        timers = #snapshot.objectives.timers,
        observedEvents = #self.events,
        qualified = snapshot.objectives.source == "ui_widget"
            or #carriers > 0 or #snapshot.objectives.timers > 0,
    }
    return snapshot
end

-- Action targets are a stricter contract than event evidence.  Blizzard's
-- localized sentence remains in events, but only a reviewed carrier or map
-- target may cross into a commander action.
function ObjectiveIntel:CanonicalCommandTarget(mapKey, target, context)
    local value = KWR.Util:Text(target, "", 96)
    local upper = value:upper()
    local team = context and context.team and context.team.faction or nil
    if upper == "OUR FC" or upper == "OUR CARRIER" then return "Our FC" end
    if upper == "ENEMY FC" or upper == "ENEMY CARRIER" then return "Enemy FC" end
    if upper == "HOME" then return "Home" end
    if upper == "MID" or upper == "CENTER" then return "Mid" end
    if upper:find("FLAG", 1, true) then
        local flagFaction = upper:find("ALLIANCE", 1, true) and "Alliance"
            or (upper:find("HORDE", 1, true) and "Horde" or nil)
        if flagFaction and team then
            local friendly = flagFaction == team
            if upper:find("PICKED", 1, true)
                or upper:find("CARRIED", 1, true)
                or upper:find("TAKEN", 1, true) then
                return friendly and "Our FC" or "Enemy FC"
            end
            if upper:find("RETURN", 1, true)
                or upper:find("CAPTURE", 1, true)
                or upper:find("DROPPED", 1, true) then
                return friendly and "Home" or "Enemy Flag Room"
            end
        end
    end
    local definition = mapKey and KWR.Maps:Get(mapKey) or nil
    for _, location in ipairs(definition and definition.locations or {}) do
        if KWR.Util:Upper(location, "", 48) == upper then return location end
    end
    return "VERIFY"
end

function ObjectiveIntel:CarrierCount()
    local count = 0
    for _ in pairs(self.carriers) do count = count + 1 end
    return count
end

KWR:RegisterModule("ObjectiveIntel", ObjectiveIntel)
