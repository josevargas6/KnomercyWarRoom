return function(KWR)
    local objective = { label = "Farm", owner = "FRIENDLY", state = "CONTROLLED",
        confidence = "CONFIRMED", x = 0.7, y = 0.4 }
    local wrapped = { source = "ui_widget", rows = { objective } }
    local board = KWR.BoardStateBuilder:Build({ objectives = wrapped })
    assert(#board.objectives == 1 and board.summary.objectiveCount == 1
        and board.objectives[1].label == "Farm" and board.objectives[1].owner == "FRIENDLY"
        and board.objectives[1].x == 0.7, "Canonical objective rows were lost or changed")
    assert(#KWR.BoardStateBuilder:Build({ objectives = { objective } }).objectives == 1,
        "Legacy objective array compatibility was lost")
    local many = {}
    for index = 1, 20 do many[index] = { label = "Objective" .. index } end
    assert(#KWR.BoardStateBuilder:Build({ objectives = { rows = many } }).objectives
        == KWR.BoardStateTypes:Limit("objectives"), "Objective projection exceeded its board cap")
    assert(wrapped.rows[1] == objective and objective.priority == nil,
        "Board projection mutated its source objective")
    local stable = {
        { objectiveID = "ARATHI:FARM", label = "Farm", owner = "FRIENDLY", observedAt = 10 },
        { objectiveID = "ARATHI:BS", label = "Blacksmith", owner = "ENEMY", observedAt = 10 },
    }
    local firstBoard = KWR.BoardStateBuilder:Build({ objectives = { rows = stable } },
        KWR.FactStore:FromSnapshot({ objectives = { rows = stable }, context = { sessionKey = "objective-fixture" } }))
    stable[1], stable[2] = stable[2], stable[1]
    local reorderedBoard = KWR.BoardStateBuilder:Build({ objectives = { rows = stable } },
        KWR.FactStore:FromSnapshot({ objectives = { rows = stable }, context = { sessionKey = "objective-fixture" } }))
    local firstIDs, reorderedIDs = {}, {}
    for _, row in ipairs(firstBoard.objectives) do firstIDs[row.id] = row.evidenceID end
    for _, row in ipairs(reorderedBoard.objectives) do reorderedIDs[row.id] = row.evidenceID end
    assert(firstIDs["ARATHI:FARM"] == reorderedIDs["ARATHI:FARM"]
        and firstIDs["ARATHI:BS"] == reorderedIDs["ARATHI:BS"],
        "Objective reorder changed stable objective evidence identity")

    local intel = KWR.CombatIntel
    local savedGUID, savedName, savedObserved, savedSession = intel.byGUID, intel.byName,
        intel.observed, intel.sessionKey
    intel:Reset()
    local enemy = { name = "BoundaryVictim-Realm", shortName = "BoundaryVictim",
        guid = "Enemy-Boundary", role = "DAMAGER", classFile = "WARRIOR", spec = "Arms",
        visible = true, localRange = true }
    local snapshot = { context = { inPvP = true, mapKey = "WSG", instanceID = 489 },
        roster = {}, enemies = { enemy }, knowledgeStatus = { metaInfluenceAllowed = false } }
    local result = intel:Analyze(snapshot)
    assert(result.localTarget and result.localTarget.guid == enemy.guid
        and result.killTarget == nil and result.targetIntent.kind == "PRESSURE"
        and result.targetIntent.commitEligible == false
        and enemy.localPressureTarget == true and enemy.localKillTarget == false
        and enemy.killable ~= true and enemy.combat.killable ~= true,
        "Preferred target became a kill commit with unknown health and support")
    local facts = KWR.FactStore:FromSnapshot(snapshot)
    local localState = KWR.LocalTeamfightState:Build(facts, snapshot)
    for _, problem in ipairs(KWR.EnemyProblemDetector:Detect(localState)) do
        assert(problem.verb ~= "Kill", "Unknown preferred target generated a coordinated kill problem")
    end
    enemy.healthPercent = 25
    result = intel:Analyze(snapshot)
    assert(enemy.killable == true and enemy.combat.killable == true
        and result.killTarget and result.killTarget.guid == enemy.guid
        and result.targetIntent.kind == "OBSERVED_KILL_WINDOW"
        and result.targetIntent.commitEligible == true
        and enemy.localKillTarget == true,
        "Observed low-health vulnerability did not produce a kill intent")
    facts = KWR.FactStore:FromSnapshot(snapshot)
    localState = KWR.LocalTeamfightState:Build(facts, snapshot)
    local problems = KWR.EnemyProblemDetector:Detect(localState)
    local killProblem
    for _, problem in ipairs(problems) do
        if problem.verb == "Kill" then killProblem = problem end
    end
    assert(killProblem and killProblem.enemy == enemy,
        "Observed kill intent did not produce a local Kill problem")
    local selectedWithoutSupport = KWR.KillTargetSelector:Select(problems, {})
    local selectedWithSupport = KWR.KillTargetSelector:Select(problems, {
        { verb = "Subdue" }, { verb = "Disrupt" }, { verb = "Deny" },
    })
    assert(selectedWithoutSupport and selectedWithSupport
        and selectedWithoutSupport.targetGUID == enemy.guid
        and selectedWithSupport.targetGUID == enemy.guid
        and selectedWithoutSupport.confidence == selectedWithSupport.confidence,
        "Support assignment count upgraded or withdrew observed kill confidence")
    local plan = KWR.TeamfightCommandPlanner:Plan(snapshot)
    assert(plan.killTarget and plan.killTarget.targetGUID == enemy.guid
        and plan.confidence == selectedWithoutSupport.confidence,
        "Teamfight planner did not preserve the observed kill commitment")
    snapshot.teamfight = plan
    local packet = KWR.ExecutionCommandBuilder:Build(snapshot, {}, {}, {})
    assert(packet.primaryTarget and packet.primaryTarget.targetGUID == enemy.guid
        and packet.localFight and packet.localFight.kill
        and packet.localFight.kill.mode == "KILL",
        "Execution packet did not preserve the observed team kill")
    intel:ObserveSpell(enemy.guid, enemy.name, 33206, "SPELL_AURA_APPLIED")
    result = intel:Analyze(snapshot)
    facts = KWR.FactStore:FromSnapshot(snapshot)
    localState = KWR.LocalTeamfightState:Build(facts, snapshot)
    problems = KWR.EnemyProblemDetector:Detect(localState)
    assert(enemy.killable == false and enemy.combat.killable == false
        and result.killTarget == nil and result.targetIntent.commitEligible == false
        and KWR.KillTargetSelector:Select(problems, {}) == nil,
        "An active observed defensive did not withdraw the team kill commitment")
    local carrier = { name = "Carrier-Realm", shortName = "Carrier", guid = "Enemy-Carrier",
        role = "DAMAGER", classFile = "WARRIOR", spec = "Arms", visible = true,
        localRange = true, carrier = true, killable = false }
    local carrierState = KWR.LocalTeamfightState:Build(KWR.FactStore:FromSnapshot({
        context = snapshot.context, enemies = { carrier }, roster = {},
    }), { context = snapshot.context, enemies = { carrier }, roster = {} })
    local carrierProblems = KWR.EnemyProblemDetector:Detect(carrierState)
    assert(#carrierProblems > 0 and KWR.KillTargetSelector:Select(carrierProblems, {}) == nil,
        "Carrier/objective pressure bypassed the observed-kill selector gate")
    local legacy = KWR.KillTargetSelector:Select({ {
        verb = "Kill", severity = 90, confidence = "CONFIRMED",
        enemy = { name = "Legacy-Realm", guid = "Enemy-Legacy", killable = true },
    } }, {})
    assert(legacy and legacy.targetGUID == "Enemy-Legacy",
        "Explicit legacy killable input lost compatible observed-window support")
    intel:Reset()
    local supportEnemy = { name = "SupportWindow-Realm", shortName = "SupportWindow",
        guid = "Enemy-Support", role = "DAMAGER", classFile = "WARRIOR", spec = "Arms",
        visible = true, localRange = true, dead = false, x = 0.50, y = 0.50 }
    local supportSnapshot = { context = { inPvP = true, mapKey = "WSG", instanceID = 489 },
        enemies = { supportEnemy }, roster = {
            { name = "Unknown-Realm", guid = "Friendly-Unknown", x = 0.51, y = 0.50 },
        }, knowledgeStatus = { metaInfluenceAllowed = false } }
    result = intel:Analyze(supportSnapshot)
    assert(supportEnemy.killable == false and result.killTarget == nil
        and result.targetIntent.kind == "PRESSURE"
        and supportEnemy.combat.localSupport.known == false,
        "Unknown nearby friendly created a support-derived kill window")
    supportSnapshot.roster[1].dead, supportSnapshot.roster[1].connected = true, true
    result = intel:Analyze(supportSnapshot)
    assert(supportEnemy.killable == false and result.killTarget == nil,
        "Dead nearby friendly created a support-derived kill window")
    supportSnapshot.roster[1].dead, supportSnapshot.roster[1].connected = false, false
    result = intel:Analyze(supportSnapshot)
    assert(supportEnemy.killable == false and result.killTarget == nil,
        "Disconnected nearby friendly created a support-derived kill window")
    supportSnapshot.roster[1].connected = true
    result = intel:Analyze(supportSnapshot)
    assert(supportEnemy.killable == true and result.killTarget
        and result.targetIntent.kind == "OBSERVED_KILL_WINDOW"
        and supportEnemy.combat.localSupport.known == true,
        "Known nearby friendly did not restore the support-derived kill window")
    supportSnapshot.roster = {}
    supportEnemy.healthPercent = 25
    result = intel:Analyze(supportSnapshot)
    assert(supportEnemy.killable == true and result.killTarget,
        "Direct observed low health incorrectly required friendly support")
    intel:Reset()
    enemy.healthPercent = nil
    local other = KWR.Util:Copy(enemy)
    other.guid, other.name, other.shortName, other.priority = "Enemy-Other", "Other-Realm", "Other", 100
    snapshot.enemies = { enemy, other }
    intel:Analyze(snapshot)
    assert(other.localPressureTarget == true and other.localKillTarget == false
        and enemy.localPressureTarget == false and enemy.localKillTarget == false,
        "Preferred pressure marker was not replaced without manufacturing a kill marker")
    other.dead = true
    intel:Analyze(snapshot)
    assert(other.localKillTarget == false and other.localPressureTarget == false
        and other.killable == false,
        "Dead winner retained selection or vulnerability flags")
    snapshot.context.inPvP = false
    intel:Analyze(snapshot)
    assert(enemy.localKillTarget == false and enemy.localPressureTarget == false
        and other.localKillTarget == false and other.localPressureTarget == false,
        "World transition retained the local target marker")
    intel.byGUID, intel.byName, intel.observed, intel.sessionKey = savedGUID, savedName,
        savedObserved, savedSession

    local problem = { type = "FREE_CASTING_HEALER", verb = "Subdue", severity = 1000000,
        confidence = "CONFIRMED", locality = "LOCAL", objectiveValue = 1000000,
        enemy = { name = "Healer-Realm", guid = "Enemy-Healer", role = "HEALER" } }
    local score = KWR.AssignmentScorer:Score({ available = false, name = "Knomercy",
        profile = { singleTargetSubdue = 1000000 } }, problem, {})
    assert(score == -math.huge, "Unavailable actor still has a finite competitive score")
    local players = {}
    for index = 1, 6 do
        players[index] = { name = "Knomercy-Realm" .. index, guid = "Unavailable" .. index,
            role = "DAMAGER", dead = index % 2 == 0, connected = index % 2 == 0 }
    end
    assert(#KWR.AssignmentOptimizer:Optimize({ friendlies = players }, { problem }, {}) == 0,
        "Dead or offline actors received control assignments")
    players[#players + 1] = { name = "Available-Realm", guid = "Available", role = "DAMAGER",
        dead = false, connected = true }
    local assignments = KWR.AssignmentOptimizer:Optimize({ friendlies = players }, { problem }, {})
    assert(#assignments == 1 and assignments[1].actorGUID == "Available",
        "Unavailable actors crowded a feasible actor out of the bounded candidate set")

    local baseline = KWR.PlayerControlProfiles:Resolve({ name = "Ordinary-Realm", role = "DAMAGER",
        classFile = "ROGUE", spec = "Subtlety" })
    for _, name in ipairs({ "Knomercy-Realm", "Stan-Realm", "Ordinary-OtherRealm" }) do
        local renamed = KWR.PlayerControlProfiles:Resolve({ name = name, role = "DAMAGER",
            classFile = "ROGUE", spec = "Subtlety" })
        for key, value in pairs(renamed) do
            if key ~= "player" then
                assert(baseline[key] == value, "Renaming a player changed their capability profile")
            end
        end
        for key, value in pairs(baseline) do
            if key ~= "player" then assert(renamed[key] == value, "Renaming removed a capability") end
        end
    end
end
