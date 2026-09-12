local _, KWR = ...

local Builder = {}
KWR.BoardStateBuilder = Builder

local function keyFor(row)
    return KWR.Util:Text(row and (row.objectiveID or row.id or row.nodeID
        or row.guid or row.name or row.label), "unknown", 80)
end

local function shortLabel(row, fallback)
    return KWR.Util:Text(row and (row.shortName or row.name or row.label), fallback, 64)
end

local function roleOf(row)
    return KWR.CombatSpells:Role(row and row.spec, row and row.role)
end

local function confidenceFor(row, fallback)
    if not row then return "UNKNOWN" end
    if row.confidence then return KWR.BoardStateTypes:Confidence(row.confidence) end
    if row.visible == true or row.localRange == true or row.localEngaged == true then
        return "CONFIRMED"
    end
    return fallback or "INFERRED"
end

function Builder:Build(snapshot, factStore)
    snapshot = snapshot or {}
    local facts = factStore and factStore.facts or {}
    local board = {
        revision = snapshot.revision or snapshot.capturedAt or KWR.Util:Now(),
        generatedAt = KWR.Util:Now(),
        context = KWR.Util:Copy(snapshot.context or {}),
        score = KWR.Util:Copy(snapshot.score or {}),
        objectives = {},
        enemies = {},
        friendlies = {},
        facts = {},
        summary = {},
    }

    for index, fact in ipairs(facts) do
        KWR.BoardStateTypes:AddBounded(board.facts, {
            id = fact.id or KWR.BoardStateTypes:EvidenceID(fact.type, fact.subject),
            type = fact.type,
            subject = fact.subject,
            confidence = KWR.BoardStateTypes:Confidence(fact.confidence),
            observedAt = fact.observedAt,
            source = fact.source,
        }, "facts")
    end

    local objectiveRows = snapshot.objectives and (snapshot.objectives.rows or snapshot.objectives) or {}
    local objectiveFacts = {}
    local enemyFacts, friendlyFacts = {}, {}
    for _, fact in ipairs(facts) do
        if fact.type == "OBJECTIVE" and fact.subject then objectiveFacts[fact.subject] = fact end
        if fact.type == "ENEMY" and fact.subject then enemyFacts[fact.subject] = fact end
        if fact.type == "FRIENDLY" and fact.subject then friendlyFacts[fact.subject] = fact end
    end
    for index, objective in ipairs(objectiveRows) do
        local objectiveID = keyFor(objective)
        local objectiveFact = objectiveFacts[objectiveID]
        KWR.BoardStateTypes:AddBounded(board.objectives, {
            id = objectiveID,
            label = shortLabel(objective, "Objective"),
            owner = KWR.Util:Text(objective.owner, "UNKNOWN", 24),
            state = KWR.Util:Text(objective.state, "UNKNOWN", 32),
            kind = KWR.Util:Text(objective.kind, board.context.kind or "OBJECTIVE", 32),
            priority = KWR.Util:Number(objective.priority, index) or index,
            confidence = confidenceFor(objective, "UNKNOWN"),
            evidenceID = objectiveFact and objectiveFact.id
                or KWR.BoardStateTypes:EvidenceID("objective", objectiveID),
            observedAt = objectiveFact and objectiveFact.observedAt,
            expiresAt = objectiveFact and objectiveFact.expiresAt,
            source = objectiveFact and objectiveFact.source or KWR.Util:Text(objective.source, "unknown", 32),
            x = KWR.Util:Number(objective.x, nil),
            y = KWR.Util:Number(objective.y, nil),
        }, "objectives")
    end

    for index, enemy in ipairs(snapshot.enemies or {}) do
        local enemyID = keyFor(enemy)
        local enemyFact = enemyFacts[KWR.Util:CanonicalPlayerKey(enemy.name, enemy.guid) or enemyID]
        KWR.BoardStateTypes:AddBounded(board.enemies, {
            source = enemy,
            id = enemyID,
            guid = enemy.guid,
            name = enemy.name,
            shortName = shortLabel(enemy, "Enemy"),
            role = roleOf(enemy),
            spec = enemy.spec,
            classFile = enemy.classFile,
            visible = enemy.visible == true,
            localRange = enemy.localRange == true or enemy.localEngaged == true,
            localEngaged = enemy.localEngaged == true,
            healthPercent = KWR.Util:Number(enemy.healthPercent, nil),
            freeCasting = enemy.freeCasting == true
                or (enemy.currentCast and enemy.currentCast.freeCasting == true)
                or enemy.priorityCast ~= nil
                or (enemy.combat and enemy.combat.priorityCast ~= nil),
            killable = enemy.killable == true
                or (enemy.combat and enemy.combat.killable == true),
            targetIntent = KWR.Util:Text(enemy.targetIntent
                or (enemy.combat and enemy.combat.targetIntent), "NONE", 32),
            commitEligible = enemy.combat and enemy.combat.commitEligible == true,
            overextended = enemy.overextended == true
                or (enemy.combat and enemy.combat.overextended == true),
            carrier = enemy.carrier == true,
            objectiveThreat = enemy.objectiveThreat == true or enemy.nearObjective == true,
            stealthThreat = enemy.stealthThreat == true or enemy.missingStealth == true,
            healerPressure = enemy.healerPressure == true,
            cooldownWindow = enemy.cooldownWindow == true,
            confidence = confidenceFor(enemy, "INFERRED"),
            evidenceID = enemyFact and enemyFact.id
                or KWR.BoardStateTypes:EvidenceID("enemy", enemyID),
        }, "enemies")
    end

    for index, player in ipairs(snapshot.roster or {}) do
        local playerID = keyFor(player)
        local friendlyFact = friendlyFacts[KWR.Util:CanonicalPlayerKey(player.name, player.guid) or playerID]
        KWR.BoardStateTypes:AddBounded(board.friendlies, {
            source = player,
            id = playerID,
            guid = player.guid,
            name = player.name,
            shortName = shortLabel(player, "Player"),
            role = roleOf(player),
            spec = player.spec,
            classFile = player.classFile,
            dead = KWR.Util:OptionalBoolean(player.dead),
            connected = KWR.Util:OptionalBoolean(player.connected),
            visible = KWR.Util:OptionalBoolean(player.visible),
            assignment = player.assignment,
            location = player.location,
            currentTargetGUID = player.currentTargetGUID,
            confidence = confidenceFor(player, "UNKNOWN"),
            evidenceID = friendlyFact and friendlyFact.id
                or KWR.BoardStateTypes:EvidenceID("friendly", playerID),
        }, "friendlies")
    end

    board.summary = {
        enemyCount = #board.enemies,
        friendlyCount = #board.friendlies,
        objectiveCount = #board.objectives,
        mapKey = board.context.mapKey or "UNKNOWN",
        mapKind = board.context.kind or "UNKNOWN",
    }
    return board
end

KWR:RegisterModule("BoardStateBuilder", Builder)
