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

local function newRecord()
    return {
        defensives = {},
        abilities = {},
        trinket = nil,
        lastObservedAt = 0,
    }
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
    return self:ObserveSpell(guid, name, spellID, "SPELL_CAST_SUCCESS")
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

function CombatIntel:Score(enemy, evidence)
    if enemy.dead or not enemy.visible or not enemy.localEngaged then return nil end
    local score, reasons = 20, { "local fight", "in combat" }
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
    score = score + ((enemy.priority or 0) * 15)
    if evidence.trinketState == "ON_COOLDOWN" then
        score = score + 24
        reasons[#reasons + 1] = "trinket used"
    end
    if #evidence.defensivesActive > 0 then
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
    if meta then
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
    local sessionKey = tostring(snapshot.context.mapID or snapshot.context.mapKey)
        .. (snapshot.context.preview and ":preview" or ":live")
    if self.sessionKey ~= sessionKey then
        self:Reset()
        self.sessionKey = sessionKey
        if snapshot.context.preview and snapshot.enemies and snapshot.enemies[2] then
            self:ObserveSpell(snapshot.enemies[2].guid, snapshot.enemies[2].name, 42292, "SPELL_CAST_SUCCESS")
            self:ObserveSpell(snapshot.enemies[2].guid, snapshot.enemies[2].name, 33206, "SPELL_AURA_REMOVED")
        end
    end
    local best, localCount = nil, 0
    local resource = {
        observed = 0,
        activeDefensives = 0,
        defensivesUsed = 0,
        trinketsUsed = 0,
        deadHealers = 0,
        isolatedCarriers = 0,
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
        enemy.threatScore = evidence.threatScore
        enemy.trinketState = evidence.trinketState
        enemy.trinketRemaining = evidence.trinketRemaining
        if evidence.observed then resource.observed = resource.observed + 1 end
        resource.activeDefensives = resource.activeDefensives + #evidence.defensivesActive
        resource.defensivesUsed = resource.defensivesUsed + #evidence.defensivesOnCooldown
        if evidence.trinketState == "ON_COOLDOWN" then
            resource.trinketsUsed = resource.trinketsUsed + 1
        end
        if enemy.dead and enemy.role == "HEALER" then
            resource.deadHealers = resource.deadHealers + 1
        end
        if enemy.carrier and enemy.visible and enemy.localEngaged then
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
        local score, reasons, role = self:Score(enemy, evidence)
        enemy.killScore = score
        enemy.role = role or enemy.role
        if score then
            localCount = localCount + 1
            if not best or score > best.score or (score == best.score and enemy.name < best.enemy.name) then
                best = { enemy = enemy, score = score, reasons = reasons }
            end
        end
    end
    if best then best.enemy.localKillTarget = true end
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
        killTarget = best and KWR.Util:Copy(best.enemy) or nil,
        killScore = best and math.floor(best.score + 0.5) or nil,
        killReason = best and table.concat(best.reasons, ", ") or "No safely observed enemy in local fight range.",
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
