local _, KWR = ...

local CombatIntel = {
    byGUID = {},
    byName = {},
    observed = 0,
}
KWR.CombatIntel = CombatIntel

local function normalizedName(name)
    return KWR.Util:ShortName(KWR.Util:Text(name, "", 64)):lower()
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

local function newRecord()
    return {
        defensives = {},
        abilities = {},
        trinket = nil,
        currentCast = nil,
        lastObservedAt = 0,
    }
end

local function isLocalActionable(enemy)
    return enemy
        and enemy.dead ~= true
        and enemy.visible == true
        and (enemy.localEngaged == true or enemy.localRange == true)
end

local function swapGuidanceText(enemy, defensive)
    local shortName = KWR.Util:Text(enemy and (enemy.shortName or enemy.name), "target", 32)
    local spellName = KWR.Util:Text(defensive and defensive.name, "defensive", 40)
    local response = KWR.Util:Text(defensive and defensive.response, "SWAP", 24)
    if response == "SWAP_OR_MAGIC" then
        return "Swap or commit magic into " .. shortName .. ": " .. spellName .. " active."
    end
    if response == "SWAP_OR_PHYSICAL" then
        return "Swap or commit physical into " .. shortName .. ": " .. spellName .. " active."
    end
    return "Swap off " .. shortName .. ": " .. spellName .. " active."
end

local function swapGuidanceWeight(enemy)
    local role = KWR.CombatSpells:Role(enemy and enemy.spec, enemy and enemy.role)
    local health = KWR.Util:Number(enemy and enemy.healthPercent, 100) or 100
    local weight = (enemy and enemy.priority or 0) * 15
    if role == "HEALER" then
        weight = weight + 60
    elseif role ~= "TANK" then
        weight = weight + 20
    end
    return weight + math.max(0, 100 - health)
end

local function coordinateDistance(x1, y1, x2, y2)
    x1, y1 = KWR.Util:Number(x1, nil), KWR.Util:Number(y1, nil)
    x2, y2 = KWR.Util:Number(x2, nil), KWR.Util:Number(y2, nil)
    if not x1 or not y1 or not x2 or not y2 then return nil end
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt((dx * dx) + (dy * dy))
end

local function localSupportState(snapshot, enemy)
    local x, y = KWR.Util:Number(enemy and enemy.x, nil), KWR.Util:Number(enemy and enemy.y, nil)
    if not x or not y then
        return { known = false, friendly = 0, enemy = 0, healerSupport = 0 }
    end
    local nearby = { known = true, friendly = 0, enemy = 0, healerSupport = 0 }
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        if player ~= enemy and not player.dead then
            local range = coordinateDistance(x, y, player.x, player.y)
            if range and range <= 0.09 then
                nearby.friendly = nearby.friendly + 1
            end
        end
    end
    for _, other in ipairs(snapshot and snapshot.enemies or {}) do
        if other ~= enemy and not other.dead and (other.visible == true
            or (other.lastSeenAge or 999) <= 6) then
            local range = coordinateDistance(x, y, other.x, other.y)
            if range and range <= 0.09 then
                nearby.enemy = nearby.enemy + 1
                if KWR.CombatSpells:Role(other.spec, other.role) == "HEALER" then
                    nearby.healerSupport = nearby.healerSupport + 1
                end
            end
        end
    end
    return nearby
end

local function supportsKillWindow(enemy, evidence, support)
    if not isLocalActionable(enemy) then return false end
    if type(evidence) == "table" and #(evidence.defensivesActive or {}) > 0 then
        return false
    end
    local health = KWR.Util:Number(enemy and enemy.healthPercent, nil)
    if health and health <= 35 then
        return true
    end
    if type(evidence) == "table"
        and evidence.trinketState == "ON_COOLDOWN"
        and health and health <= 55 then
        return true
    end
    return support and support.known == true
        and support.friendly >= (support.enemy + 1)
        and KWR.CombatSpells:Role(enemy and enemy.spec, enemy and enemy.role) ~= "TANK"
end

local function overextendedState(enemy, support)
    if not isLocalActionable(enemy) or not support or support.known ~= true then
        return false
    end
    if support.enemy == 0 and support.friendly >= 1 then
        return true
    end
    return support.friendly >= (support.enemy + 2)
end

function CombatIntel:Reset()
    self.byGUID = {}
    self.byName = {}
    self.observed = 0
    self.sessionKey = nil
end

function CombatIntel:GetRecord(guid, name, create)
    guid = KWR.Util:Text(guid, "", 80)
    local short = normalizedName(name)
    local record = guid ~= "" and self.byGUID[guid] or nil
    if not record and short ~= "" then record = self.byName[short] end
    if not record and create then record = newRecord() end
    if record then
        if guid ~= "" then self.byGUID[guid] = record end
        if short ~= "" and short ~= "unknown" then self.byName[short] = record end
    end
    return record
end

function CombatIntel:ObserveSpell(sourceGUID, sourceName, spellID, eventType)
    local spell = KWR.CombatSpells:Get(spellID)
    if not spell then return false end
    local record = self:GetRecord(sourceGUID, sourceName, true)
    local now = KWR.Util:Now()
    record.lastObservedAt = now
    record.name = KWR.Util:Text(sourceName, record.name or "Unknown", 64)
    record.guid = KWR.Util:Text(sourceGUID, record.guid or "", 80)
    if spell.kind == "TRINKET" then
        record.trinket = {
            spellID = spell.spellID,
            name = spell.name,
            usedAt = now,
            readyAt = now + spell.cooldown,
        }
    elseif spell.kind == "ABILITY" then
        record.abilities[spell.spellID] = {
            spellID = spell.spellID,
            name = spell.name,
            observedAt = now,
            expiresAt = now + spell.window,
            importance = spell.importance,
            tags = KWR.Util:Copy(spell.tags or {}),
        }
    else
        local entry = record.defensives[spell.spellID] or {}
        entry.spellID = spell.spellID
        entry.name = spell.name
        entry.usedAt = entry.usedAt or now
        entry.readyAt = entry.readyAt or (now + spell.cooldown)
        entry.weight = spell.weight
        entry.response = spell.response
        entry.defensiveClass = spell.defensiveClass
        if eventType == "SPELL_AURA_REMOVED" then
            entry.activeUntil = now
        else
            entry.usedAt = now
            entry.readyAt = now + spell.cooldown
            entry.activeUntil = now + spell.active
        end
        record.defensives[spell.spellID] = entry
    end
    self.observed = self.observed + 1
    return true
end

function CombatIntel:ObserveUnitSpell(unit, spellID)
    if not unit or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false)
        or not KWR.Util:Boolean(KWR.Util:Call(UnitIsPlayer, unit), false)
        or not KWR.Util:Boolean(KWR.Util:Call(UnitCanAttack, "player", unit), false) then
        return false
    end
    local name = KWR.Util:UnitName(unit)
    local guid = KWR.Util:Text(KWR.Util:Call(UnitGUID, unit), "", 80)
    local record = self:GetRecord(guid, name, false)
    if record and record.currentCast
        and record.currentCast.spellID == KWR.Util:Number(spellID, nil) then
        record.currentCast = nil
    end
    return self:ObserveSpell(guid, name, spellID, "SPELL_CAST_SUCCESS")
end

function CombatIntel:ObserveUnitCast(unit, spellID, active, eventType)
    if not unit or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false)
        or not KWR.Util:Boolean(KWR.Util:Call(UnitIsPlayer, unit), false)
        or not KWR.Util:Boolean(KWR.Util:Call(UnitCanAttack, "player", unit), false) then
        return false
    end
    local name = KWR.Util:UnitName(unit)
    local guid = KWR.Util:Text(KWR.Util:Call(UnitGUID, unit), "", 80)
    local numericSpellID = KWR.Util:Number(spellID, nil)
    local record = self:GetRecord(guid, name, active == true)
    if not record then return false end
    if active ~= true then
        if record.currentCast and (not numericSpellID
            or record.currentCast.spellID == numericSpellID) then
            record.currentCast = nil
            return true
        end
        return false
    end
    local cast = KWR.CombatSpells:GetCast(numericSpellID)
    if not cast then return false end
    local now = KWR.Util:Now()
    record.lastObservedAt = now
    record.name = KWR.Util:Text(name, record.name or "Unknown", 64)
    record.guid = guid
    record.currentCast = {
        spellID = cast.spellID,
        name = cast.name,
        priority = cast.priority,
        response = cast.response,
        eventType = KWR.Util:Text(eventType, "CAST", 32),
        observedAt = now,
        expiresAt = now + KWR.Util:Clamp(cast.duration or 2, 0.5, 8) + 1,
    }
    self.observed = self.observed + 1
    return true
end

function CombatIntel:EvidenceFor(enemy)
    local record = self:GetRecord(enemy.guid, enemy.name, false)
    local now = KWR.Util:Now()
    local evidence = {
        defensivesActive = {},
        defensivesOnCooldown = {},
        trinketState = "UNKNOWN",
        trinketRemaining = nil,
        recentAbilities = {},
        priorityCast = nil,
        threatScore = 0,
        observed = record ~= nil,
    }
    if not record then return evidence end
    for _, defensive in pairs(record.defensives) do
        local activeRemaining = math.max((defensive.activeUntil or 0) - now, 0)
        local cooldownRemaining = math.max((defensive.readyAt or 0) - now, 0)
        if activeRemaining > 0 then
            local copy = KWR.Util:Copy(defensive)
            copy.remaining = activeRemaining
            evidence.defensivesActive[#evidence.defensivesActive + 1] = copy
        elseif cooldownRemaining > 0 then
            local copy = KWR.Util:Copy(defensive)
            copy.remaining = cooldownRemaining
            evidence.defensivesOnCooldown[#evidence.defensivesOnCooldown + 1] = copy
        end
    end
    for spellID, ability in pairs(record.abilities or {}) do
        local remaining = math.max((ability.expiresAt or 0) - now, 0)
        if remaining > 0 then
            local copy = KWR.Util:Copy(ability)
            copy.remaining = remaining
            evidence.recentAbilities[#evidence.recentAbilities + 1] = copy
            evidence.threatScore = math.max(
                evidence.threatScore, KWR.Util:Number(copy.importance, 0))
        else
            record.abilities[spellID] = nil
        end
    end
    if record.currentCast then
        if (record.currentCast.expiresAt or 0) > now then
            evidence.priorityCast = KWR.Util:Copy(record.currentCast)
            evidence.priorityCast.remaining =
                math.max((record.currentCast.expiresAt or 0) - now, 0)
        else
            record.currentCast = nil
        end
    end
    table.sort(evidence.defensivesActive, function(a, b) return a.remaining < b.remaining end)
    table.sort(evidence.defensivesOnCooldown, function(a, b) return a.remaining > b.remaining end)
    table.sort(evidence.recentAbilities, function(a, b)
        return (a.importance or 0) > (b.importance or 0)
    end)
    if record.trinket then
        evidence.trinketRemaining = math.max((record.trinket.readyAt or 0) - now, 0)
        evidence.trinketState = evidence.trinketRemaining > 0 and "ON_COOLDOWN" or "COOLDOWN_EXPIRED"
        evidence.trinketName = record.trinket.name
    end
    return evidence
end

function CombatIntel:Score(enemy, evidence, metaActive, snapshot)
    if not isLocalActionable(enemy) then return nil end
    local score, reasons = 20, {}
    if enemy.localEngaged == true then
        reasons[#reasons + 1] = "local fight"
        reasons[#reasons + 1] = "in combat"
    else
        score = score - 4
        reasons[#reasons + 1] = "local range"
    end
    local role = KWR.CombatSpells:Role(enemy.spec, enemy.role)
    local meta = KWR.MetaSnapshot:Lookup(enemy.classFile, enemy.spec)
    if role == "HEALER" then score = score + 32; reasons[#reasons + 1] = "healer"
    elseif role == "TANK" then score = score - 18; reasons[#reasons + 1] = "tank penalty"
    else score = score + 8 end
    local health = KWR.Util:Number(enemy.healthPercent, nil)
    if health then
        score = score + ((100 - health) * 0.72)
        if health <= 40 then reasons[#reasons + 1] = "low health" end
    end
    if enemy.carrier then
        score = score + 24
        reasons[#reasons + 1] = "objective carrier"
    end
    score = score + ((enemy.priority or 0) * 15)
    if evidence.trinketState == "ON_COOLDOWN" then
        score = score + 24
        reasons[#reasons + 1] = "trinket used"
    end
    if #evidence.defensivesActive > 0 then
        local response = evidence.defensivesActive[1].response
        if response and response:find("SWAP", 1, true) then
            reasons[#reasons + 1] = "protected target"
            return nil, reasons, role
        end
        score = score - 50
        reasons[#reasons + 1] = "defensive active"
    elseif #evidence.defensivesOnCooldown > 0 then
        score = score + math.min(30, #evidence.defensivesOnCooldown * 10)
        reasons[#reasons + 1] = "defensives used"
    end
    if #evidence.recentAbilities > 0 then
        local ability = evidence.recentAbilities[1]
        local tags = ability.tags or {}
        if tags.killWindow or tags.killSetup then
            score = score + math.min(18, evidence.threatScore * 0.5)
            reasons[#reasons + 1] = "kill window active"
        elseif tags.objectiveThreat or tags.captureDenial then
            score = score + math.min(14, evidence.threatScore * 0.4)
            reasons[#reasons + 1] = "objective threat"
        end
    end
    if evidence.priorityCast then
        local castPriority = KWR.Util:Text(evidence.priorityCast.priority, "", 24)
        if castPriority == "MUST_STOP" then
            score = score + 18
            reasons[#reasons + 1] = "must-stop cast"
        elseif castPriority ~= "" then
            score = score + 10
            reasons[#reasons + 1] = "priority cast"
        end
    end
    local support = localSupportState(snapshot, enemy)
    if support.known then
        if support.enemy == 0 then
            score = score + 12
            reasons[#reasons + 1] = "isolated"
        elseif support.friendly >= support.enemy + 2 then
            score = score + 14
            reasons[#reasons + 1] = "friendly local edge"
        elseif support.enemy >= support.friendly + 2 then
            score = score - 18
            reasons[#reasons + 1] = "enemy local support"
        end
        if support.healerSupport > 0 and role ~= "HEALER" then
            score = score - math.min(12, support.healerSupport * 8)
            reasons[#reasons + 1] = "healer support nearby"
        end
    end
    if meta and metaActive ~= false then
        local metaWeight = role == "HEALER" and math.max(0, 9 - meta.rank)
            or (role == "TANK" and -math.max(0, 7 - meta.rank)
            or math.max(0, 7 - math.floor(meta.rank / 4)))
        score = score + metaWeight
        enemy.metaRank = meta.rank
        enemy.metaRating = meta.rating
        enemy.metaCaptured = meta.captured
        if meta.rank <= 3 then reasons[#reasons + 1] = "RBG meta #" .. tostring(meta.rank) end
    end
    return score, reasons, role
end

function CombatIntel:Analyze(snapshot)
    if not snapshot.context.inPvP then
        if self.sessionKey then self:Reset() end
        return {
            observedSpells = 0,
            localEnemies = 0,
            localTarget = nil,
            localTargetScore = nil,
            localTargetReason = "No safely observed enemy in local fight range.",
            killTarget = nil,
            killReason = "No safely observed enemy in local fight range.",
            updatedAt = KWR.Util:Now(),
            resourceEconomy = {
                confidence = "NONE", advantage = 0,
                friendly = { offensives = "UNKNOWN", defensives = "UNKNOWN",
                    trinkets = "UNKNOWN", mana = "UNKNOWN" },
                enemy = { offensives = "UNKNOWN", defensivesUsed = 0,
                    trinketsUsed = 0, mana = "UNKNOWN" },
            },
        }
    end
    local sessionKey = KWR.Util:BattlefieldSessionKey(snapshot.context)
    if not sameSession(self.sessionKey, sessionKey) then
        self:Reset()
        self.sessionKey = sessionKey
        if snapshot.context.preview and snapshot.enemies and snapshot.enemies[2] then
            self:ObserveSpell(snapshot.enemies[2].guid, snapshot.enemies[2].name, 42292, "SPELL_CAST_SUCCESS")
            self:ObserveSpell(snapshot.enemies[2].guid, snapshot.enemies[2].name, 33206, "SPELL_AURA_REMOVED")
        end
    elseif self.sessionKey ~= sessionKey then
        self.sessionKey = sessionKey
    end
    local best, localCount, topPriorityCast = nil, 0, nil
    local knowledge = snapshot.knowledgeStatus or {}
    local swapGuidance
    local resource = {
        observed = 0,
        activeDefensives = 0,
        defensivesUsed = 0,
        trinketsUsed = 0,
        deadHealers = 0,
        isolatedCarriers = 0,
        priorityCasts = 0,
    }
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local evidence = self:EvidenceFor(enemy)
        enemy.role = KWR.CombatSpells:Role(enemy.spec, enemy.role)
        local meta = KWR.MetaSnapshot:Lookup(enemy.classFile, enemy.spec)
        if meta then
            enemy.metaRank = meta.rank
            enemy.metaRating = meta.rating
            enemy.metaCaptured = meta.captured
        end
        enemy.defensivesActive = evidence.defensivesActive
        enemy.defensivesOnCooldown = evidence.defensivesOnCooldown
        enemy.recentAbilities = evidence.recentAbilities
        enemy.priorityCast = evidence.priorityCast
        enemy.currentCast = evidence.priorityCast and KWR.Util:Copy(evidence.priorityCast) or nil
        if enemy.currentCast then
            enemy.currentCast.freeCasting = enemy.role == "HEALER"
                and isLocalActionable(enemy)
        end
        if evidence.priorityCast and (not topPriorityCast
            or (evidence.priorityCast.priority == "MUST_STOP"
                and topPriorityCast.priority ~= "MUST_STOP")) then
            topPriorityCast = KWR.Util:Copy(evidence.priorityCast)
            topPriorityCast.source = enemy.shortName or enemy.name
        end
        enemy.threatScore = evidence.threatScore
        enemy.trinketState = evidence.trinketState
        enemy.trinketRemaining = evidence.trinketRemaining
        if evidence.observed then resource.observed = resource.observed + 1 end
        resource.activeDefensives = resource.activeDefensives + #evidence.defensivesActive
        if evidence.priorityCast then
            resource.priorityCasts = resource.priorityCasts + 1
        end
        resource.defensivesUsed = resource.defensivesUsed + #evidence.defensivesOnCooldown
        if evidence.trinketState == "ON_COOLDOWN" then
            resource.trinketsUsed = resource.trinketsUsed + 1
        end
        if enemy.dead and enemy.role == "HEALER" then
            resource.deadHealers = resource.deadHealers + 1
        end
        if enemy.carrier and isLocalActionable(enemy) then
            resource.isolatedCarriers = resource.isolatedCarriers + 1
        end
        if evidence.trinketState == "ON_COOLDOWN" then
            enemy.trinket = KWR.Util:Clock(evidence.trinketRemaining)
        elseif evidence.trinketState == "COOLDOWN_EXPIRED" then
            enemy.trinket = "USED (CD?)"
        else
            enemy.trinket = "UNKNOWN"
        end
        if #evidence.defensivesActive > 0 then
            enemy.cooldownText = "ACTIVE: " .. evidence.defensivesActive[1].name
        elseif #evidence.defensivesOnCooldown > 0 then
            enemy.cooldownText = tostring(#evidence.defensivesOnCooldown) .. " DEF USED"
        elseif #evidence.recentAbilities > 0 then
            enemy.cooldownText = "THREAT: " .. evidence.recentAbilities[1].name
        else
            enemy.cooldownText = "UNKNOWN"
        end
        local support = localSupportState(snapshot, enemy)
        enemy.freeCasting = enemy.currentCast and enemy.currentCast.freeCasting == true or false
        enemy.killable = supportsKillWindow(enemy, evidence, support)
        enemy.overextended = overextendedState(enemy, support)
        enemy.combat = enemy.combat or {}
        enemy.combat.priorityCast = enemy.priorityCast and KWR.Util:Copy(enemy.priorityCast) or nil
        enemy.combat.killable = enemy.killable
        enemy.combat.overextended = enemy.overextended
        enemy.combat.localSupport = support
        local score, reasons, role = self:Score(enemy, evidence,
            knowledge.metaInfluenceAllowed ~= false, snapshot)
        enemy.killScore = score
        enemy.role = role or enemy.role
        if isLocalActionable(enemy) then
            localCount = localCount + 1
        end
        if not score and isLocalActionable(enemy) and #evidence.defensivesActive > 0 then
            local defensive = evidence.defensivesActive[1]
            local response = KWR.Util:Text(defensive.response, "", 24)
            if response:find("SWAP", 1, true) then
                local guidance = {
                    enemy = enemy,
                    defensive = defensive,
                    weight = swapGuidanceWeight(enemy),
                    text = swapGuidanceText(enemy, defensive),
                }
                if not swapGuidance or guidance.weight > swapGuidance.weight then
                    swapGuidance = guidance
                end
            end
        end
        if score then
            if not best or score > best.score or (score == best.score and enemy.name < best.enemy.name) then
                best = { enemy = enemy, score = score, reasons = reasons }
            end
        end
    end
    if best then
        best.enemy.localKillTarget = true
        best.enemy.killable = true
        best.enemy.combat = best.enemy.combat or {}
        best.enemy.combat.killable = true
    end
    local enemyCount = #(snapshot.enemies or {})
    local resourceAdvantage = KWR.Util:Clamp(
        resource.trinketsUsed * 8 + resource.defensivesUsed * 4
            + resource.deadHealers * 18 + resource.isolatedCarriers * 10
            - resource.activeDefensives * 10,
        -40, 80)
    local resourceConfidence = resource.observed >= 4 and "HIGH"
        or (resource.observed >= 1 and "MEDIUM" or "LOW")
    return {
        observedSpells = self.observed,
        localEnemies = localCount,
        localTarget = best and KWR.Util:Copy(best.enemy) or nil,
        localTargetScore = best and math.floor(best.score + 0.5) or nil,
        localTargetReason = best and table.concat(best.reasons, ", ")
            or (swapGuidance and swapGuidance.text
                or "No safely observed enemy in local fight range."),
        killTarget = best and KWR.Util:Copy(best.enemy) or nil,
        killScore = best and math.floor(best.score + 0.5) or nil,
        killReason = best and table.concat(best.reasons, ", ")
            or (swapGuidance and swapGuidance.text
                or "No safely observed enemy in local fight range."),
        priorityCast = topPriorityCast,
        updatedAt = KWR.Util:Now(),
        resourceEconomy = {
            confidence = resourceConfidence,
            coverage = resource.observed,
            advantage = resourceAdvantage,
            friendly = {
                offensives = "UNKNOWN",
                defensives = "UNKNOWN",
                trinkets = "UNKNOWN",
                mana = "UNKNOWN",
                battleReadiness = "CAPABILITY ESTIMATE",
            },
            enemy = {
                offensives = "UNKNOWN",
                activeDefensives = resource.activeDefensives,
                defensivesUsed = resource.defensivesUsed,
                trinketsUsed = resource.trinketsUsed,
                deadHealers = resource.deadHealers,
                isolatedCarriers = resource.isolatedCarriers,
                mana = "UNKNOWN",
            },
        },
    }
end

KWR:RegisterModule("CombatIntel", CombatIntel)