local _, KWR = ...

local ObjectiveIntel = {
    events = {},
    carriers = {},
    timers = {},
    maxEvents = 50,
}
KWR.ObjectiveIntel = ObjectiveIntel

local ORB_COLORS = {
    Green = true, Blue = true, Orange = true, Purple = true,
}

local function normalizeName(name)
    return KWR.Util:ShortName(KWR.Util:Text(name, "", 80)):lower()
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

function ObjectiveIntel:Reset(sessionKey)
    self.sessionKey = sessionKey
    self.events = {}
    self.carriers = {}
    self.timers = {}
end

function ObjectiveIntel:ObserveMessage(message, mapKey)
    message = KWR.Util:Text(message, "", 160)
    if message == "" then return end
    if mapKey and mapKey ~= "WORLD" and mapKey ~= "UNKNOWN" then
        local desired = tostring(mapKey) .. ":true"
        if self.sessionKey ~= desired then self:Reset(desired) end
    end
    local player, color = message:match("^(.+) has taken the (Green|Blue|Orange|Purple) orb!$")
    if not player then
        for candidate in pairs(ORB_COLORS) do
            local pattern = "^(.+) has taken the " .. candidate .. " orb!$"
            player = message:match(pattern)
            if player then color = candidate break end
        end
    end
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
    for candidate in pairs(ORB_COLORS) do
        if message:find("The " .. candidate .. " orb has been returned!", 1, true) then
            local objective = candidate .. " Orb"
            self.carriers[objective] = nil
            addEvent(self, "RETURN", message, objective)
            return
        end
    end

    local flagPlayer, flagTeam
    for _, candidate in ipairs({ "Alliance", "Horde" }) do
        flagPlayer = message:match("^(.+) has picked up the " .. candidate .. " flag!$")
            or message:match("^(.+) picked up the " .. candidate .. " flag!$")
        if flagPlayer then flagTeam = candidate break end
    end
    if flagPlayer and flagTeam then
        local objective = flagTeam .. " Flag"
        self.carriers[objective] = {
            objective = objective,
            kind = "FLAG",
            color = flagTeam,
            player = flagPlayer,
            playerKey = normalizeName(flagPlayer),
            observedAt = KWR.Util:Now(),
            source = "BG_SYSTEM",
        }
        addEvent(self, "PICKUP", message, objective, flagPlayer)
        return
    end
    if message:lower():find("flag", 1, true)
        and (message:lower():find("returned", 1, true)
            or message:lower():find("captured", 1, true)) then
        for objective, carrier in pairs(self.carriers) do
            if carrier.kind == "FLAG" then self.carriers[objective] = nil end
        end
        addEvent(self, "FLAG_STATE", message)
        return
    end

    local assaulter, node = message:match("^(.+) has assaulted the (.+)!$")
    if assaulter and node then
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

local function findEntity(snapshot, playerKey)
    for _, entity in ipairs(snapshot.roster or {}) do
        if normalizeName(entity.name) == playerKey then return entity, "FRIENDLY" end
    end
    for _, entity in ipairs(snapshot.enemies or {}) do
        if normalizeName(entity.name) == playerKey then return entity, "ENEMY" end
    end
end

local function observeCarrierAuras(carrier, unit)
    if not unit or not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then return end
    local bestStacks = 0
    local observed = {}
    for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
        for index = 1, 40 do
            local aura = KWR.Util:Call(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
            if type(aura) ~= "table" or KWR.Util:IsSecret(aura) then break end
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
end

function ObjectiveIntel:Apply(snapshot)
    local sessionKey = tostring(snapshot.context.mapKey or "WORLD") .. ":"
        .. tostring(snapshot.context.inPvP == true)
    if self.sessionKey ~= sessionKey then self:Reset(sessionKey) end

    local carriers = {}
    for objective, stored in pairs(self.carriers) do
        local carrier = KWR.Util:Copy(stored)
        local entity, owner = findEntity(snapshot, carrier.playerKey)
        carrier.owner = owner or "UNKNOWN"
        if entity then
            carrier.unit = entity.unit
            carrier.healthPercent = entity.healthPercent
            carrier.x, carrier.y = entity.x, entity.y
            carrier.dead = entity.dead
            carrier.visible = entity.visible == true or owner == "FRIENDLY"
            observeCarrierAuras(carrier, entity.unit)
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
                if carrier.x and carrier.y then
                    row.x, row.y = carrier.x, carrier.y
                    row.mapSource = "carrier"
                end
            end
        end
    end
    table.sort(carriers, function(a, b) return a.objective < b.objective end)
    snapshot.objectives.carriers = carriers
    snapshot.objectives.events = KWR.Util:Copy(self.events)
    snapshot.objectives.timers = {}
    local now = KWR.Util:Now()
    for node, timer in pairs(self.timers) do
        local copy = KWR.Util:Copy(timer)
        copy.remaining = math.max(0, (copy.endsAt or now) - now)
        if copy.remaining > 0 then
            snapshot.objectives.timers[#snapshot.objectives.timers + 1] = copy
        else
            self.timers[node] = nil
        end
    end
    return snapshot
end

function ObjectiveIntel:CarrierCount()
    local count = 0
    for _ in pairs(self.carriers) do count = count + 1 end
    return count
end

KWR:RegisterModule("ObjectiveIntel", ObjectiveIntel)
