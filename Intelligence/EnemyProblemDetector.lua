local _, KWR = ...

local Detector = {}
KWR.EnemyProblemDetector = Detector

local function roleOf(enemy)
    return KWR.CombatSpells:Role(enemy and enemy.spec, enemy and enemy.role)
end

local function enemyLabel(enemy)
    return KWR.Util:Text(enemy and (enemy.shortName or enemy.name), "Enemy", 64)
end

local function sourceEnemy(row)
    return row and (row.source or row) or nil
end

local function problemID(prefix, enemy)
    return prefix .. ":" .. enemyLabel(enemy)
end

local function addProblem(problems, row)
    problems[#problems + 1] = KWR.EnemyProblemState:New(row)
end

local function mapKind(localState)
    return KWR.Util:Text(localState and localState.context and localState.context.kind, "WORLD", 32)
end

function Detector:Detect(localState)
    local problems = {}
    local castingHealerProblems = 0
    local currentHealerProblems = 0
    local recentHealerProblems = 0
    local boardEnemies = KWR.BoardState and KWR.BoardState:Enemies(localState and localState.board) or {}
    if #boardEnemies == 0 then
        for _, enemy in ipairs(localState and localState.enemies or {}) do
            boardEnemies[#boardEnemies + 1] = {
                source = enemy,
                role = roleOf(enemy),
                visible = enemy.visible == true,
                localRange = enemy.localRange == true or enemy.localEngaged == true,
                freeCasting = enemy.freeCasting == true
                    or (enemy.currentCast and enemy.currentCast.freeCasting == true)
                    or (enemy.combat and enemy.combat.priorityCast ~= nil),
                killable = enemy.killable == true,
                overextended = enemy.overextended == true,
                healthPercent = KWR.Util:Number(enemy.healthPercent, nil),
                confidence = enemy.visible and "CONFIRMED" or "INFERRED",
            }
        end
    end

    for _, boardEnemy in ipairs(boardEnemies) do
        local enemy = sourceEnemy(boardEnemy)
        local role = roleOf(enemy)
        local visible = boardEnemy.visible == true or boardEnemy.localRange == true
            or boardEnemy.localEngaged == true
        local currentLocal = boardEnemy.localRange == true
            or boardEnemy.localEngaged == true
        local recentLocal = not currentLocal and enemy
            and (enemy.recentLocalRange == true or enemy.recentLocalEngaged == true)
        local localObserved = currentLocal or recentLocal
        local casting = currentLocal and boardEnemy.freeCasting == true
        local alive = not enemy or enemy.dead ~= true
        local health = KWR.Util:Number(boardEnemy.healthPercent, nil)
        local evidenceID = boardEnemy.evidenceID
        if role == "HEALER" and localObserved and alive then
            local problemType
            local severity
            if casting then
                castingHealerProblems = castingHealerProblems + 1
                problemType = castingHealerProblems == 1
                    and "FREE_CASTING_HEALER" or "CASTER_HEALER_SUPPORT"
                severity = castingHealerProblems == 1 and 94 or 88
            elseif currentLocal then
                currentHealerProblems = currentHealerProblems + 1
                problemType = "LOCAL_HEALER_CONTROL"
                severity = currentHealerProblems == 1 and 82 or 78
            else
                recentHealerProblems = recentHealerProblems + 1
                problemType = "LOCAL_HEALER_CONTROL"
                severity = recentHealerProblems == 1 and 70 or 66
            end
            addProblem(problems, {
                id = problemID(casting and "FREE_CAST" or "LOCAL_HEALER", enemy),
                type = problemType,
                enemy = enemy,
                verb = "Subdue",
                severity = severity,
                confidence = currentLocal and "CONFIRMED" or "INFERRED",
                objectiveValue = currentLocal and 70 or 58,
                locality = "LOCAL",
                localState = currentLocal and "ACTIVE" or "RECENT",
                requiredJobs = { "Subdue", "Disrupt" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                drState = KWR.DRTracker and KWR.DRTracker:StateFor(enemy, "subdue"),
                reasons = {
                    currentLocal and (enemyLabel(enemy) .. " is local")
                        or (enemyLabel(enemy) .. " was recently local"),
                    enemyLabel(enemy) .. " is healer",
                    casting and (enemyLabel(enemy) .. " is free casting")
                        or (enemyLabel(enemy) .. " requires control during the kill window"),
                },
            })
        end
        if role ~= "HEALER" and currentLocal and alive
            and (boardEnemy.overextended == true or boardEnemy.killable == true
            or (health and health <= 45)) then
            local inferred = boardEnemy.killable ~= true and not (health and health <= 35)
            addProblem(problems, {
                id = problemID("KILL", enemy),
                type = "KILL_TARGET_AVAILABLE",
                enemy = enemy,
                verb = "Kill",
                severity = inferred and 82 or 90,
                confidence = inferred and "INFERRED" or "CONFIRMED",
                objectiveValue = 65,
                locality = "LOCAL",
                requiredJobs = { "Kill", "Pressure" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                reasons = {
                    enemyLabel(enemy) .. " is local",
                    enemyLabel(enemy) .. " is overextended or killable",
                },
            })
        end
        if boardEnemy.carrier == true and visible then
            addProblem(problems, {
                id = problemID("CARRIER", enemy),
                type = mapKind(localState) == "FLAG" and "FLAG_CARRIER_ESCAPING"
                    or "OBJECTIVE_CARRIER_EXPOSED",
                enemy = enemy,
                severity = 94,
                confidence = boardEnemy.confidence or "INFERRED",
                objectiveValue = 95,
                locality = visible and "LOCAL" or "MAP",
                requiredJobs = { "Collapse", "Deny", "Kill" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                drState = KWR.DRTracker and KWR.DRTracker:StateFor(enemy, "subdue"),
                reasons = {
                    enemyLabel(enemy) .. " is carrying objective value",
                    "carrier state changes the kill and denial priority",
                },
            })
        end
        if boardEnemy.objectiveThreat == true then
            addProblem(problems, {
                id = problemID("OBJECTIVE", enemy),
                type = mapKind(localState) == "NODE" and "BASE_UNDER_THREAT"
                    or "OBJECTIVE_CARRIER_EXPOSED",
                enemy = enemy,
                severity = visible and 88 or 74,
                confidence = boardEnemy.confidence or "INFERRED",
                objectiveValue = 90,
                locality = visible and "LOCAL" or "MAP",
                requiredJobs = { "Deny", "Spin", "Hold" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                drState = KWR.DRTracker and KWR.DRTracker:StateFor(enemy, "subdue"),
                reasons = {
                    enemyLabel(enemy) .. " has objective pressure",
                },
            })
        end
        if boardEnemy.stealthThreat == true then
            addProblem(problems, {
                id = problemID("STEALTH", enemy),
                type = "STEALTH_THREAT_MISSING",
                enemy = enemy,
                severity = 74,
                confidence = "INFERRED",
                objectiveValue = 76,
                locality = "MAP",
                requiredJobs = { "Deny", "Spin", "Hold" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                reasons = {
                    enemyLabel(enemy) .. " is a missing stealth threat",
                },
            })
        end
        if boardEnemy.healerPressure == true then
            addProblem(problems, {
                id = problemID("PEEL", enemy),
                type = "FRIENDLY_HEALER_UNDER_PRESSURE",
                enemy = enemy,
                severity = 86,
                confidence = boardEnemy.confidence or "INFERRED",
                objectiveValue = 70,
                locality = visible and "LOCAL" or "MAP",
                requiredJobs = { "Peel", "Disrupt" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                drState = KWR.DRTracker and KWR.DRTracker:StateFor(enemy, "subdue"),
                reasons = {
                    enemyLabel(enemy) .. " is pressuring friendly support",
                },
            })
        end
        if boardEnemy.cooldownWindow == true then
            addProblem(problems, {
                id = problemID("COOLDOWN", enemy),
                type = "ENEMY_COOLDOWN_WINDOW",
                enemy = enemy,
                severity = 80,
                confidence = boardEnemy.confidence or "INFERRED",
                objectiveValue = 62,
                locality = visible and "LOCAL" or "MAP",
                requiredJobs = { "Pressure", "Kill" },
                evidenceIDs = evidenceID and { evidenceID } or {},
                reasons = {
                    enemyLabel(enemy) .. " has a pressure window",
                },
            })
        end
    end
    table.sort(problems, function(a, b)
        if (a.severity or 0) == (b.severity or 0) then
            return enemyLabel(a.enemy) < enemyLabel(b.enemy)
        end
        return (a.severity or 0) > (b.severity or 0)
    end)
    return problems
end

KWR:RegisterModule("EnemyProblemDetector", Detector)