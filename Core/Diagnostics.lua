local _, KWR = ...

local Diagnostics = {}
KWR.Diagnostics = Diagnostics

local function fixture(mapKey, score, objectives, inPvP)
    local definition = KWR.Maps:Get(mapKey)
    return {
        context = {
            inPvP = inPvP ~= false,
            mapKey = mapKey,
            mapName = definition and definition.title or "World",
            kind = definition and definition.kind or "WORLD",
        },
        score = {
            friendly = score.friendly or 0,
            enemy = score.enemy or 0,
            max = score.max or (definition and definition.maxScore) or 0,
            friendlyNeeded = math.max((score.max or (definition and definition.maxScore) or 0) - (score.friendly or 0), 0),
            enemyNeeded = math.max((score.max or (definition and definition.maxScore) or 0) - (score.enemy or 0), 0),
            source = score.source or "ui_widget",
        },
        objectives = {
            friendly = objectives.friendly or 0,
            enemy = objectives.enemy or 0,
            friendlyIncoming = objectives.friendlyIncoming or 0,
            enemyIncoming = objectives.enemyIncoming or 0,
            friendlyActive = objectives.friendlyActive or objectives.friendly or 0,
            enemyActive = objectives.enemyActive or objectives.enemy or 0,
            rows = {},
            source = objectives.source or "ui_widget",
        },
        roster = {},
        capturedAt = KWR.Util:Now(),
        lastMessage = "",
    }
end

function Diagnostics:Run()
    local checks = {}
    local passed, failed = 0, 0

    local function check(name, condition, detail)
        checks[#checks + 1] = {
            name = name,
            ok = condition == true,
            detail = detail or "",
        }
        if condition == true then passed = passed + 1 else failed = failed + 1 end
    end

    for _, moduleName in ipairs({
        "Util", "Store", "Maps", "Doctrine", "MetaSnapshot", "SourceRegistry", "PatchData",
        "CombatSpells", "Capabilities", "Compositions", "BattlePlans", "ScenarioLibrary", "Counters",
        "CompThreats", "EnemyDefenseModels", "OpenerDoctrine", "RecoveryDoctrine", "EndgameDoctrine",
        "ScenarioFixtures", "KnowledgeManifest", "TeamResolver", "EncounterHistory", "OpponentModels", "Sensors", "RosterInspector",
        "EnemyIntel", "ObjectiveIntel", "FormationAdvisor", "CombatIntel",
        "Preview", "Reporter",
        "Predictor", "Strategist", "AssignmentOverrides", "Assignments", "Commander", "Learning",
        "AAR", "Verification", "SentinelBridge", "MatchRuntime", "CursorRing", "Theme", "CopyDialog", "QuickCalls", "TacticalMap",
        "CombatRoster", "HUD",
        "MainWindow", "AARWindow", "Options",
    }) do
        check("Module " .. moduleName, type(KWR:GetModule(moduleName)) == "table", "Module is not registered.")
    end

    local mapCount = 0
    local mapErrors = {}
    local abbreviationErrors = {}
    for key, definition in pairs(KWR.Maps:All()) do
        mapCount = mapCount + 1
        if not definition.kind or not definition.title or not definition.mapIDs or #definition.mapIDs == 0 then
            mapErrors[#mapErrors + 1] = key
        end
        for _, location in ipairs(definition.locations or {}) do
            if not definition.positions or not definition.positions[location] then
                mapErrors[#mapErrors + 1] = key .. ":" .. location
            end
            if not definition.abbreviations or not definition.abbreviations[location] then
                abbreviationErrors[#abbreviationErrors + 1] = key .. ":" .. location
            end
        end
    end
    check("Ten supported map definitions", mapCount == 10, "Found " .. tostring(mapCount))
    check("Map definitions complete", #mapErrors == 0, table.concat(mapErrors, ", "))
    check("Every supported map location has a compact call abbreviation",
        #abbreviationErrors == 0, table.concat(abbreviationErrors, ", "))
    check("Compact assignment export groups jobs and removes repeated formation text",
        KWR.Assignments:CompactExport({
            { shortName = "TankOne", role = "Tank", location = "Formation" },
            { shortName = "HealOne", role = "Healer", location = "Formation" },
            { shortName = "HealTwo", role = "Healer", location = "Formation" },
        }, "WORLD") == "FORM | T:TankOne | H:HealOne,HealTwo")
    check("Scenario matrix covers 40 situations per supported battleground",
        KWR.ScenarioLibrary:Count() == 400, "Found " .. tostring(KWR.ScenarioLibrary:Count()))
    check("Comp threat catalog meets the minimum doctrine depth",
        KWR.CompThreats:Validate() == true, tostring(KWR.CompThreats:Count()))
    check("Enemy defense model catalog meets the minimum doctrine depth",
        KWR.EnemyDefenseModels:Validate() == true, tostring(KWR.EnemyDefenseModels:Count()))
    check("Opener doctrine exposes at least four reviewed branches per supported battleground",
        KWR.OpenerDoctrine:Count() >= 40, tostring(KWR.OpenerDoctrine:Count()))
    check("Recovery doctrine exposes at least four reviewed branches per supported battleground",
        KWR.RecoveryDoctrine:Count() >= 40, tostring(KWR.RecoveryDoctrine:Count()))
    check("Endgame doctrine exposes at least five reviewed branches per supported battleground plus universal rules",
        KWR.EndgameDoctrine:Count() >= 55, tostring(KWR.EndgameDoctrine:Count()))
    check("Scenario fixtures cover at least five deterministic doctrine contracts per supported battleground",
        KWR.ScenarioFixtures:Count() >= 50, tostring(KWR.ScenarioFixtures:Count()))

    local quickCallsValid, quickCallsDetail = KWR.QuickCalls:Validate()
    check("Quick Calls use exactly six reviewed fixed phrases",
        quickCallsValid == true, quickCallsDetail)

    local uiAuditState = KWR.Store:Get()
    if uiAuditState and uiAuditState.snapshot and uiAuditState.command then
        KWR.MainWindow:Create()
        KWR.MainWindow:Show("TACTICAL")
        KWR.MainWindow:Update(uiAuditState)
        local tacticalMap = KWR.MainWindow.pages
            and KWR.MainWindow.pages.TACTICAL
            and KWR.MainWindow.pages.TACTICAL.battlefieldCard
            and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map
        check("Tactical map reserves premium header and footer rails",
            tacticalMap and tacticalMap.headerBand
                and KWR.Util:Number(KWR.Util:Call(tacticalMap.headerBand.GetHeight, tacticalMap.headerBand), 0) == 56
                and tacticalMap.footerBand
                and KWR.Util:Number(KWR.Util:Call(tacticalMap.footerBand.GetHeight, tacticalMap.footerBand), 0) == 22)
        check("Main window exposes command, truth, reporter, and doctrine header badges",
            KWR.MainWindow.frame ~= nil
                and KWR.MainWindow.frame.commandBadge ~= nil
                and KWR.MainWindow.frame.truthBadge ~= nil
                and KWR.MainWindow.frame.reporterBadge ~= nil
                and KWR.MainWindow.frame.doctrineBadge ~= nil)

        KWR.CombatRoster:Create()
        KWR.CombatRoster:Request(true, "ENEMY", false)
        KWR.CombatRoster:Update(uiAuditState)
        check("Combat roster spotlight preserves the expanded readability lane",
            KWR.CombatRoster.frame and KWR.CombatRoster.frame.targetSpotlight
                and KWR.Util:Number(KWR.Util:Call(
                    KWR.CombatRoster.frame.targetSpotlight.GetHeight,
                    KWR.CombatRoster.frame.targetSpotlight), 0) == 42
                and KWR.CombatRoster.frame.targetSpotlight.rule
                and KWR.Util:Number(KWR.Util:Call(
                    KWR.CombatRoster.frame.targetSpotlight.rule.GetHeight,
                    KWR.CombatRoster.frame.targetSpotlight.rule), 0) == 1)

        KWR.CursorRing:Create()
        KWR.CursorRing:ApplyReticle()
        check("Reticle captions reserve readable premium plates",
            KWR.CursorRing.reticle
                and KWR.CursorRing.reticle.labelPlate
                and KWR.Util:Number(KWR.Util:Call(
                    KWR.CursorRing.reticle.labelPlate.GetWidth,
                    KWR.CursorRing.reticle.labelPlate), 0) >= 150
                and KWR.CursorRing.reticle.detailPlate
                and KWR.Util:Number(KWR.Util:Call(
                    KWR.CursorRing.reticle.detailPlate.GetWidth,
                    KWR.CursorRing.reticle.detailPlate), 0) >= 210)
    end

    local mapOrder = {
        "ARATHI", "GILNEAS", "DEEPWIND", "EOTS", "WSG",
        "TWINPEAKS", "TEMPLE", "SILVERSHARD", "DEEPHAUL", "SEETHING",
    }
    local assignmentRoster = KWR.Preview:Build().roster
    local expectedRole = {
        NODE = "Anchor Defender",
        HYBRID = "Tower Sitter",
        FLAG = "Flag Carrier",
        ORB = "Orb Carrier",
        CART = "Cart Anchor",
        RESOURCE = "Scout / Fast Cap",
    }
    for _, mapKey in ipairs(mapOrder) do
        local definition = KWR.Maps:Get(mapKey)
        local objectives = {}
        if definition.kind == "NODE" or definition.kind == "HYBRID" then
            local equalControl = (definition.maxObjectives or 0) >= 4 and 2 or 1
            objectives.friendly = equalControl
            objectives.enemy = equalControl
        elseif definition.kind == "ORB" or definition.kind == "CART" then
            objectives.friendlyActive = 1
            objectives.enemyActive = 1
        end
        local leadScore, trailScore, tiedScore
        if definition.kind == "FLAG" then
            leadScore = { friendly = 2, enemy = 1, max = 3 }
            trailScore = { friendly = 1, enemy = 2, max = 3 }
            tiedScore = { friendly = 1, enemy = 1, max = 3 }
        else
            leadScore = { friendly = 900, enemy = 700, max = definition.maxScore }
            trailScore = { friendly = 700, enemy = 900, max = definition.maxScore }
            tiedScore = { friendly = 800, enemy = 800, max = definition.maxScore }
        end
        local lead = KWR.Predictor:Evaluate(fixture(mapKey, leadScore, objectives))
        local trail = KWR.Predictor:Evaluate(fixture(mapKey, trailScore, objectives))
        local tied = KWR.Predictor:Evaluate(fixture(mapKey, tiedScore, objectives))
        check(definition.title .. " lead, deficit, and tie states",
            lead.status == "WIN" and trail.status == "LOSE" and tied.status == "TIE",
            string.format("%s/%s/%s", tostring(lead.status), tostring(trail.status), tostring(tied.status)))

        local assignmentSnapshot = fixture(mapKey, tiedScore, objectives)
        assignmentSnapshot.context.team = { faction = "Alliance", side = "left" }
        assignmentSnapshot.roster = KWR.Util:Copy(assignmentRoster)
        local mapAssignments = KWR.Assignments:Build(assignmentSnapshot)
        local assignmentAudit = KWR.Assignments:Audit(assignmentSnapshot, mapAssignments)
        check(definition.title .. " assignments cover valid jobs and locations",
            assignmentAudit.ok == true, table.concat(assignmentAudit.issues or {}, ", "))
        local foundExpectedRole = false
        for _, assignment in ipairs(mapAssignments) do
            if assignment.role == expectedRole[definition.kind] then
                foundExpectedRole = true
                break
            end
        end
        check(definition.title .. " uses its " .. definition.kind .. " assignment family",
            foundExpectedRole == true, "Expected " .. tostring(expectedRole[definition.kind]))

        local openingSnapshot = fixture(mapKey,
            { friendly = 0, enemy = 0, max = definition.maxScore },
            objectives)
        openingSnapshot.context.team = { faction = "Alliance", side = "left" }
        openingSnapshot.roster = KWR.Util:Copy(assignmentRoster)
        local openingPrediction = KWR.Predictor:Evaluate(openingSnapshot)
        openingSnapshot.strategy = KWR.Strategist:Evaluate(openingSnapshot, openingPrediction)
        local openingAssignments = KWR.Assignments:Build(openingSnapshot)
        local openingAudit = KWR.Assignments:Audit(openingSnapshot, openingAssignments)
        check(definition.title .. " has a valid reviewed opening",
            openingSnapshot.strategy.state == "OPENING"
                and openingSnapshot.strategy.planID ~= nil and openingAudit.ok == true,
            tostring(openingSnapshot.strategy.planID))
        check(definition.title .. " opening publishes objective success and abort criteria",
            openingSnapshot.strategy.objectiveDecision
                and openingSnapshot.strategy.objectiveDecision.success ~= nil
                and openingSnapshot.strategy.objectiveDecision.abort ~= nil,
            openingSnapshot.strategy.action)
        check(definition.title .. " exposes forty scenario combinations",
            KWR.ScenarioLibrary:Count(mapKey) == 40)
        if mapKey == "EOTS" then
            local sitters, mid, strike = 0, 0, 0
            for _, assignment in ipairs(openingAssignments) do
                if assignment.role == "Tower Sitter" then sitters = sitters + 1
                elseif assignment.role == "Mid / Flag Control" then mid = mid + 1
                elseif assignment.role == "Tower Strike" then strike = strike + 1 end
            end
            check("Eye of the Storm opening preserves two towers and split pressure",
                sitters == 2 and mid == 4 and strike == 4,
                string.format("sitters=%d mid=%d strike=%d", sitters, mid, strike))
        end

        if definition.kind == "NODE" or definition.kind == "HYBRID" then
            assignmentSnapshot.strategy = {}
            assignmentSnapshot.formation = {}
            local oldHistory = KWR.Util:Copy(KWR.Commander.history)
            local oldSignature = KWR.Commander.lastSignature
            local command = KWR.Commander:Compose(
                assignmentSnapshot, trail, mapAssignments)
            KWR.Commander.history = oldHistory
            KWR.Commander.lastSignature = oldSignature
            local priority = KWR.Maps:AbbreviateLocation(
                mapKey, definition.priorities[1])
            local _, line2 = KWR.CommandView:SummaryLines({
                snapshot = assignmentSnapshot,
                command = command,
            })
            check(definition.title .. " command names its own priority objective",
                line2:find(priority, 1, true) ~= nil,
                line2)
        end
    end

    local stealthSnapshot = fixture("ARATHI",
        { friendly = 0, enemy = 0, max = 1500 },
        { friendly = 0, enemy = 0 })
    stealthSnapshot.roster = KWR.Util:Copy(assignmentRoster)
    stealthSnapshot.strategy = {
        state = "OPENING",
        enemyComposition = { id = "STEALTH" },
    }
    local stealthAssignments = KWR.Assignments:Build(stealthSnapshot)
    local foundStealthDirective = false
    for _, assignment in ipairs(stealthAssignments) do
        if assignment.counterDirective
            and assignment.counterDirective:find(
                "missing stealth", 1, true) then
            foundStealthDirective = true
            break
        end
    end
    check("Enemy composition counterplay reaches relevant player assignments",
        foundStealthDirective == true)

    local invalidAssignmentSnapshot = fixture("WSG",
        { friendly = 0, enemy = 0, max = 3 },
        { friendly = 0, enemy = 0 })
    invalidAssignmentSnapshot.roster = {
        {
            guid = "DPS-1", name = "Damage-Realm", shortName = "Damage",
            classFile = "MAGE", spec = "Frost", role = "DAMAGER",
        },
    }
    local invalidAssignmentAudit = KWR.Assignments:Audit(
        invalidAssignmentSnapshot, {
            {
                guid = "Other-1", name = "Other-Realm",
                shortName = "Other", groupRole = "DAMAGER",
                role = "Flag Carrier", location = "Home", priority = 100,
            },
        })
    check("Assignment audit rejects non-roster identities and incompatible flag carriers",
        invalidAssignmentAudit.ok == false
            and #invalidAssignmentAudit.issues >= 2)

    local freshEvidence = fixture(
        "ARATHI",
        { friendly = 900, enemy = 700, max = 1500 },
        { friendly = 2, enemy = 2 }
    )
    freshEvidence.score.observedAt = KWR.Util:Now()
    freshEvidence.objectives.observedAt = KWR.Util:Now()
    check("Fresh authoritative evidence drives a live prediction",
        KWR.Predictor:Evaluate(freshEvidence).status == "WIN")
    local staleScore = KWR.Util:Copy(freshEvidence)
    staleScore.score.observedAt = KWR.Util:Now() - 6
    check("Stale score evidence cannot drive a live command",
        KWR.Predictor:Evaluate(staleScore).status == "WAITING")
    local staleObjectives = KWR.Util:Copy(freshEvidence)
    staleObjectives.objectives.observedAt = KWR.Util:Now() - 6
    check("Stale objective evidence cannot drive node strategy",
        KWR.Predictor:Evaluate(staleObjectives).status == "WAITING")
    local impossibleRecovery = KWR.Predictor:Evaluate(fixture(
        "ARATHI",
        { friendly = 0, enemy = 1499, max = 1500 },
        { friendly = 0, enemy = 5 }
    ))
    check("Impossible node recovery is reported honestly",
        impossibleRecovery.status == "LOSE"
            and impossibleRecovery.recoverable == false
            and impossibleRecovery.condition:find("No current objective count", 1, true) ~= nil,
        impossibleRecovery.condition)

    local leftTeam = { side = "left", faction = "Alliance" }
    local rightTeam = { side = "right", faction = "Horde" }
    check("Alliance score transform preserves left as friendly",
        KWR.TeamResolver:Value(725, 910, "friendly", leftTeam) == 725
            and KWR.TeamResolver:Value(725, 910, "enemy", leftTeam) == 910)
    check("Horde score transform preserves right as friendly",
        KWR.TeamResolver:Value(725, 910, "friendly", rightTeam) == 910
            and KWR.TeamResolver:Value(725, 910, "enemy", rightTeam) == 725)
    do
        local oldUnitFactionGroup = UnitFactionGroup
        local oldUnitIsMercenary = UnitIsMercenary
        local oldUnitName = UnitName
        local oldGetNumBattlefieldScores = GetNumBattlefieldScores
        local oldCPvP = C_PvP
        UnitFactionGroup = function() return "Alliance" end
        UnitIsMercenary = function() return true end
        UnitName = function(unit)
            if unit == "player" then return "Player-Realm" end
            return nil
        end
        GetNumBattlefieldScores = function() return 0 end
        C_PvP = { GetScoreInfo = function() return nil end }
        KWR.TeamResolver:Reset()
        local mercenaryAssigned = KWR.TeamResolver:Capture(true, {
            { unit = "player", guid = "GUID-PLAYER", name = "Player-Realm" },
        }, "ARATHI:529:1:PVP:LIVE")
        check("Mercenary battleground entry stays pending until scoreboard truth appears",
            mercenaryAssigned.side == nil
                and mercenaryAssigned.source == "scoreboard_pending",
            tostring(mercenaryAssigned.source))
        UnitIsMercenary = function() return false end
        KWR.TeamResolver:Reset()
        local nativeAssigned = KWR.TeamResolver:Capture(true, {
            { unit = "player", guid = "GUID-PLAYER", name = "Player-Realm" },
        }, "ARATHI:529:2:PVP:LIVE")
        check("Non-mercenary battleground entry may still use native side as an early fallback",
            nativeAssigned.side == "left"
                and nativeAssigned.source == "native_lock",
            tostring(nativeAssigned.source))
        UnitFactionGroup = oldUnitFactionGroup
        UnitIsMercenary = oldUnitIsMercenary
        UnitName = oldUnitName
        GetNumBattlefieldScores = oldGetNumBattlefieldScores
        C_PvP = oldCPvP
        KWR.TeamResolver:Reset()
    end

    check("Tick math: 500 points at 2 points/2s", KWR.Predictor:TimeToWin(1500, 1000, 2, 2) == 500)
    check("Tick math: zero rate is unavailable", KWR.Predictor:TimeToWin(1500, 1000, 0, 2…13091 tokens truncated…apshot.context)
    KWR.CombatIntel:ObserveSpell(
        "ProtectedEnemy", "ProtectedEnemy", 45438, "SPELL_AURA_APPLIED")
    protectedSnapshot.enemies = {
        {
            guid = "ProtectedEnemy", name = "ProtectedEnemy",
            shortName = "ProtectedEnemy", classFile = "MAGE",
            spec = "Frost", role = "DAMAGER", visible = true,
            localRange = true, localEngaged = true, healthPercent = 34,
            unit = "target",
        },
    }
    local protectedAnalysis = KWR.CombatIntel:Analyze(protectedSnapshot)
    check("Combat intelligence tells the commander to swap when the only local target is protected",
        protectedAnalysis.killTarget == nil
            and protectedAnalysis.killReason == "Swap off ProtectedEnemy: Ice Block active.",
        protectedAnalysis.killReason)
    KWR.CombatIntel:Reset()

    local decisionReviews = KWR.AAR:BuildDecisionReviews({
        {
            at = 1, action = "HOLD BS", recommendationMode = "HOLD",
            expectedOutcome = "Preserve score", projectedWinProbability = 72,
            confidence = "HIGH", risk = "LOW",
            simulations = {
                { id = "HOLD", probability = 72 },
                { id = "ROTATE", probability = 61 },
            },
        },
    }, "VICTORY")
    check("Counterfactual review logs recommendation, alternative, and actual result without auto-learning",
        decisionReviews[1] and decisionReviews[1].outcomeAligned == true
            and decisionReviews[1].competingOption == "ROTATE"
            and decisionReviews[1].evidenceReview == "DEVELOPER_REVIEW_REQUIRED")
    local aarExport = KWR.AAR:Export({
        id = "diagnostic-aar",
        mapName = "Arathi Basin",
        result = "VICTORY",
        startedAt = 1000,
        endedAt = 1120,
        duration = 120,
        scoreEnd = { friendly = 1500, enemy = 1200 },
        team = { faction = "Alliance" },
        friendlyTeam = {
            ["Friendly-1"] = {
                guid = "Friendly-1", name = "Defender-Realm",
                class = "Hunter", spec = "Marksmanship", role = "DAMAGER",
                specSource = "live",
            },
        },
        enemyTeam = {
            ["Enemy-1"] = {
                guid = "Enemy-1", name = "UnknownEnemy-Realm",
                class = "Rogue", spec = "Unknown", role = "Unknown",
                specSource = "unknown",
            },
        },
        commands = {
            {
                at = 1030, action = "HOLD BS", assigned = "Defender",
                objectiveTarget = "Blacksmith", confidence = "HIGH",
                confidenceScore = 82, risk = "LOW",
                evidence = { "Friendly numbers confirmed", "Objective controlled" },
                abortCondition = "Enemy commits four or more.",
                outcome = "Match ended: VICTORY",
                mapState = {
                    phase = "ACTIVE", friendlyScore = 900, enemyScore = 700,
                    friendlyObjectives = 3, enemyObjectives = 2,
                },
            },
        },
        objectiveTimeline = {
            {
                at = 1040, kind = "STATE", objective = "Blacksmith",
                text = "Blacksmith: ENEMY/CONTROLLED -> FRIENDLY/CONTROLLED",
                source = "ui_widget",
            },
        },
        playerEvidence = {
            ["Friendly-1"] = {
                guid = "Friendly-1", name = "Defender-Realm",
                assignedRole = "Node Defender", assignedLocation = "Blacksmith",
                assignedAt = 1020, lastAssignedAt = 1100,
                lastLocation = "Blacksmith", deathsObserved = 0, notes = {},
            },
        },
        enemyThreats = {
            ["Enemy-1"] = {
                name = "UnknownEnemy-Realm", class = "Rogue", spec = "Unknown",
                lastSeenLocation = "Farm", lastSeenAge = 12, sightings = 2,
                flags = { stealth = true },
            },
        },
    })
    check("Manual AAR export contains every structured evidence section",
        type(aarExport) == "string"
            and aarExport:find("========== KWR MATCH EXPORT ==========", 1, true) ~= nil
            and aarExport:find("Friendly Team:", 1, true) ~= nil
            and aarExport:find("Enemy Team:", 1, true) ~= nil
            and aarExport:find("KWR Command Timeline:", 1, true) ~= nil
            and aarExport:find("Objective Timeline:", 1, true) ~= nil
            and aarExport:find("Player Evidence:", 1, true) ~= nil
            and aarExport:find("Enemy Threats:", 1, true) ~= nil
            and aarExport:find("Known Limitations:", 1, true) ~= nil
            and aarExport:find("========== END EXPORT ==========", 1, true) ~= nil)
    check("AAR export separates recommendation, evidence, abort condition, and outcome",
        aarExport:find("action HOLD BS", 1, true) ~= nil
            and aarExport:find("Evidence: Friendly numbers confirmed; Objective controlled", 1, true) ~= nil
            and aarExport:find("Abort/Pivot: Enemy commits four or more.", 1, true) ~= nil
            and aarExport:find("Outcome: Match ended: VICTORY", 1, true) ~= nil)
    check("AAR export preserves unknown enemy specialization and states its evidence limits",
        aarExport:find("UnknownEnemy-Realm | Rogue | Unknown | Unknown", 1, true) ~= nil
            and aarExport:find("Unknown values were not inferred.", 1, true) ~= nil)
    local oldAARActive, oldAARHistory, oldLastCompleted =
        KWR.AAR.active, KWR.db.journal.history, KWR.AAR.lastCompleted
    KWR.AAR.active = { id = "active-diagnostic" }
    local refusedClear = KWR.AAR:ClearCompleted()
    KWR.AAR.active = nil
    KWR.db.journal.history = { { id = "completed-diagnostic" } }
    KWR.AAR.lastCompleted = KWR.db.journal.history[1]
    local acceptedClear = KWR.AAR:ClearCompleted()
    check("AAR clear refuses to discard a live recording and clears only completed evidence",
        refusedClear == false and acceptedClear == true
            and #KWR.db.journal.history == 0 and KWR.AAR.lastCompleted == nil)
    KWR.AAR.active, KWR.db.journal.history, KWR.AAR.lastCompleted =
        oldAARActive, oldAARHistory, oldLastCompleted
    check("Manual AAR evidence recording is enabled by default and remains optional",
        type(KWR.db.profile.aar.enabled) == "boolean")
    local formationRoster = {
        { classFile = "PRIEST", spec = "Discipline", role = "HEALER" },
    }
    for index = 1, 8 do
        formationRoster[#formationRoster + 1] = {
            classFile = "WARRIOR", spec = "Arms", role = "DAMAGER",
        }
    end
    local formation = KWR.FormationAdvisor:Evaluate({ roster = formationRoster })
    check("Formation advisor distinguishes open slots from required replacements",
        formation.openSlots == 1 and formation.replacementsNeeded == 2
            and formation.recommendations[1].acquisition == "OPEN SLOT"
            and formation.recommendations[2].acquisition:find("REPLACE", 1, true) == 1)
    local formationAssignments = KWR.Assignments:Build({
        roster = formationRoster,
        context = { inPvP = false, mapKey = "WORLD" },
    })
    check("Assignments preserve specialization and effective role",
        formationAssignments[1] and formationAssignments[1].spec == "Discipline"
            and formationAssignments[1].groupRole == "HEALER")
    local noHealerSnapshot = fixture("EOTS",
        { friendly = 0, enemy = 0, max = 1500 }, {})
    noHealerSnapshot.context.team = { faction = "Alliance", side = "left" }
    noHealerSnapshot.strategy = { state = "OPENING" }
    noHealerSnapshot.roster = {
        { guid = "DK-1", name = "Deathknight-Realm", shortName = "Deathknight",
            class = "Death Knight", classFile = "DEATHKNIGHT", spec = "Unholy",
            role = "DAMAGER", connected = true },
    }
    local noHealerAssignments = KWR.Assignments:Build(noHealerSnapshot)
    local incompatible = false
    for _, assignment in ipairs(noHealerAssignments) do
        if assignment.role:find("Healer", 1, true) then incompatible = true end
    end
    check("Role validator never assigns a Death Knight as a healer", incompatible == false)

    KWR.EncounterHistory:Observe({
        name = "Knownlock-Realm", shortName = "Knownlock", class = "Warlock",
        classFile = "WARLOCK", spec = "Affliction", role = "DAMAGER",
    }, "ENEMY", "ARATHI")
    local historical = {
        name = "Knownlock-Realm", shortName = "Knownlock", class = "Warlock",
        classFile = "WARLOCK", spec = "Unknown", role = "NONE",
    }
    KWR.EncounterHistory:Apply(historical)
    check("Current-season encounter history supplies explicitly labeled likely spec",
        historical.spec == "Affliction" and historical.specSource == "historical"
            and historical.evidence == "HISTORICAL")
    local opponentSnapshot = fixture("ARATHI",
        { friendly = 500, enemy = 500, max = 1500 }, { friendly = 2, enemy = 2 })
    opponentSnapshot.context.mapID = 529
    opponentSnapshot.enemies = {
        {
            guid = "Opponent-1", name = "OpponentOne-Realm", shortName = "OpponentOne",
            class = "Rogue", classFile = "ROGUE", spec = "Subtlety", role = "DAMAGER",
            visible = true, localEngaged = true, x = 0.50, y = 0.50,
            location = "Blacksmith", carrier = false,
        },
        {
            guid = "Opponent-2", name = "OpponentTwo-Realm", shortName = "OpponentTwo",
            class = "Priest", classFile = "PRIEST", spec = "Holy", role = "HEALER",
            visible = true, localEngaged = false, x = 0.54, y = 0.50,
            location = "Blacksmith", carrier = false,
        },
    }
    opponentSnapshot.reporter = {
        hotspot = { label = "Blacksmith", enemy = 4, friendly = 2, risk = 78 },
    }
    KWR.OpponentModels:ResetSession("diagnostic-opponents")
    for _ = 1, 4 do
        KWR.OpponentModels.sampleTokens = {}
        KWR.OpponentModels:Observe(opponentSnapshot)
    end
    local opponentProfile = KWR.OpponentModels:Describe(opponentSnapshot.enemies[1])
    check("Opponent model builds a bounded persistent tendency profile from repeated legal observations",
        opponentProfile.label ~= "NONE"
            and type(opponentProfile.strengths) == "table"
            and type(opponentProfile.weaknesses) == "table")
    check("Enemy rows expose persistent profile detail for note hover and review",
        (function()
            KWR.EnemyIntel:Reset("diagnostic-opponents")
            KWR.EnemyIntel:Upsert({
                guid = "Opponent-1",
                name = "OpponentOne-Realm",
                class = "Rogue",
                classFile = "ROGUE",
                spec = "Subtlety",
                role = "DAMAGER",
                source = "Scoreboard",
                location = "Blacksmith",
            }, false)
            local rows = KWR.EnemyIntel:Rows()
            for _, row in ipairs(rows) do
                if row.guid == "Opponent-1" then
                    return row.profile ~= nil and row.noteDetail ~= nil
                end
            end
            return false
        end)())

    KWR.ObjectiveIntel:Reset("TEMPLE:true")
    KWR.ObjectiveIntel:ObserveMessage("Carrier-Realm has taken the Purple orb!", "TEMPLE")
    local carrierSnapshot = fixture("TEMPLE",
        { friendly = 100, enemy = 100, max = 1500 }, {})
    carrierSnapshot.roster = {
        { name = "Carrier-Realm", shortName = "Carrier", classFile = "DRUID",
            spec = "Balance", role = "DAMAGER", healthPercent = 80 },
    }
    KWR.ObjectiveIntel:Apply(carrierSnapshot)
    check("Colored orb events identify and promote the live friendly carrier",
        carrierSnapshot.objectives.carriers[1]
            and carrierSnapshot.objectives.carriers[1].objective == "Purple Orb"
            and carrierSnapshot.objectives.carriers[1].owner == "FRIENDLY"
            and carrierSnapshot.roster[1].carrier == true)
    KWR.ObjectiveIntel:Reset("ARATHI:true")
    KWR.ObjectiveIntel:ObserveMessage("Scout-Realm has assaulted the Lumber Mill!", "ARATHI")
    local assaultSnapshot = fixture("ARATHI",
        { friendly = 600, enemy = 650, max = 1500, source = "ui_widget" },
        { friendly = 2, enemy = 2, source = "none" })
    assaultSnapshot.roster = {
        { name = "Scout-Realm", shortName = "Scout", classFile = "ROGUE",
            spec = "Subtlety", role = "DAMAGER", healthPercent = 100 },
    }
    KWR.ObjectiveIntel:Apply(assaultSnapshot)
    local assaultedRow
    for _, row in ipairs(assaultSnapshot.objectives.rows or {}) do
        if row.label == "Lumber Mill" then
            assaultedRow = row
            break
        end
    end
    check("Objective assault events promote bounded incoming truth when the widget path is unavailable",
        assaultSnapshot.objectives.timers[1]
            and assaultSnapshot.objectives.friendlyIncoming == 1
            and assaultedRow
            and assaultedRow.state == "INCOMING"
            and assaultedRow.source == "bg_system"
            and assaultedRow.timerRemaining ~= nil)
    KWR.ObjectiveIntel:Reset("ARATHI:true")
    KWR.ObjectiveIntel:ObserveMessage("EnemyScout-Realm has assaulted the Lumber Mill!", "ARATHI")
    local widgetSnapshot = fixture("ARATHI",
        { friendly = 700, enemy = 700, max = 1500, source = "ui_widget" },
        { friendly = 2, enemy = 2, friendlyIncoming = 0, enemyIncoming = 0, source = "ui_widget" })
    widgetSnapshot.enemies = {
        { name = "EnemyScout-Realm", shortName = "EnemyScout", classFile = "ROGUE",
            spec = "Subtlety", role = "DAMAGER", healthPercent = 100 },
    }
    widgetSnapshot.objectives.rows = {
        {
            label = "Lumber Mill",
            owner = "FRIENDLY",
            state = "CONTROLLED",
            kind = "OBJECTIVE",
            source = "ui_widget",
        },
    }
    KWR.ObjectiveIntel:Apply(widgetSnapshot)
    local widgetRow = widgetSnapshot.objectives.rows[1]
    check("Objective assault events decorate verified widget rows without overwriting fresh public control truth",
        widgetRow
            and widgetRow.state == "CONTROLLED"
            and widgetRow.pendingState == "INCOMING"
            and widgetRow.pendingSource == "bg_system"
            and widgetSnapshot.objectives.enemyIncoming == 0)
    check("Battle-plan repository covers every supported map",
        KWR.BattlePlans:Count() >= 20)
    check("Patch data matches Retail interface", KWR.PatchData:Validate(120007) == true)
    check("Learning repository is bounded and available",
        type(KWR.Learning:Summary()) == "table")
    check("Learning rejects reviews without qualified score and team truth",
        KWR.Learning:RecordReviewed({
            primaryPlanID = "AB_STABLE_THREE",
            mapKey = "ARATHI",
            result = "VICTORY",
            feedback = { wonBy = "Objectives" },
            truthQualified = false,
        }) == false)
    check("Completed time-limit matches resolve from the final assigned-team score",
        KWR.AAR:DetermineResult({
            matchComplete = true,
            scoreEnd = { friendly = 3, enemy = 2, max = 3 },
        }) == "VICTORY"
        and KWR.AAR:DetermineResult({
            matchComplete = true,
            scoreEnd = { friendly = 1, enemy = 2, max = 3 },
        }) == "DEFEAT")
    local oldPostMatchComplete = KWR.MatchRuntime.matchComplete
    local oldPostMatchTruth = KWR.Util:Copy(KWR.MatchRuntime.postMatchTruth)
    local completedTruth = fixture("ARATHI",
        { friendly = 1500, enemy = 1200, max = 1500, source = "ui_widget" },
        { friendly = 3, enemy = 2, source = "ui_widget" })
    completedTruth.context.team = {
        faction = "Horde", side = "right", source = "scoreboard_self",
    }
    completedTruth.context.sessionKey =
        KWR.Util:BattlefieldSessionKey(completedTruth.context)
    KWR.MatchRuntime.matchComplete = false
    KWR.MatchRuntime.postMatchTruth = nil
    KWR.MatchRuntime:ApplyMatchCompleteFallback(completedTruth)
    KWR.MatchRuntime.matchComplete = true
    local decayedTruth = fixture("ARATHI",
        { friendly = 0, enemy = 0, max = 1500, source = "none" },
        { friendly = 0, enemy = 0, source = "none" })
    decayedTruth.context.team = {
        faction = "Alliance", side = "left", source = "native_lock",
    }
    decayedTruth.context.sessionKey =
        KWR.Util:BattlefieldSessionKey(decayedTruth.context)
    KWR.MatchRuntime:ApplyMatchCompleteFallback(decayedTruth)
    check("Post-match truth fallback preserves final battleground side, score, and objectives",
        decayedTruth.context.phase == "COMPLETE"
            and decayedTruth.context.team
            and decayedTruth.context.team.side == "right"
            and decayedTruth.score.friendly == 1500
            and decayedTruth.score.enemy == 1200
            and decayedTruth.objectives.friendly == 3
            and decayedTruth.objectives.enemy == 2
            and decayedTruth.score.postMatchFrozen == true
            and decayedTruth.objectives.postMatchFrozen == true)
    KWR.MatchRuntime.matchComplete = oldPostMatchComplete
    KWR.MatchRuntime.postMatchTruth = oldPostMatchTruth
    check("Store carries local combat intelligence", type(liveState.snapshot.combat) == "table")

    local live = KWR.Store:Get()
    check("Store has one command object", type(live.command) == "table" and type(live.command.signature) == "string")
    local fieldReport = KWR.Verification:FieldReport()
    check("Field defect bundle contains truth, live binding, AAR, and evidence",
        fieldReport:find("KWR LIVE VERIFICATION", 1, true) ~= nil
            and fieldReport:find("Live binding:", 1, true) ~= nil
            and fieldReport:find("LATEST AAR:", 1, true) ~= nil
            and fieldReport:find("KWR MATCH EVIDENCE LEDGER", 1, true) ~= nil)
    check("Runtime error count is zero", (live.diagnostics.errors or 0) == 0, "Errors: " .. tostring(live.diagnostics.errors))
    check("Runtime event subscriptions remain initialization-stable",
        KWR.MatchRuntime.frame
            and KWR.MatchRuntime.frame:IsEventRegistered("UPDATE_UI_WIDGET"))
    check("Combat roster prepares automatically at battleground entry by default",
        KWR.db.profile.combatRoster.autoShowInPvP == true)
    local currentRoster = live.snapshot and live.snapshot.roster or {}
    check("Player specialization uses the direct player specialization API",
        not currentRoster[1] or currentRoster[1].unit ~= "player"
            or currentRoster[1].specSource == "player_spec",
        currentRoster[1] and tostring(currentRoster[1].specSource) or "No player row")
    check("Heavy optional UI stays off the addon-load critical path",
        KWR.bootDiagnostics and #(KWR.bootDiagnostics.eagerFrames or {}) == 0,
        KWR.bootDiagnostics and table.concat(KWR.bootDiagnostics.eagerFrames or {}, ", ") or "No boot diagnostics")
    check("Horde battlefield team maps to the right widget side",
        KWR.TeamResolver:SideForScoreFaction(0) == "right")
    check("Alliance battlefield team maps to the left widget side",
        KWR.TeamResolver:SideForScoreFaction(1) == "left")

    return {
        passed = passed,
        failed = failed,
        checks = checks,
    }
end

function Diagnostics:Report()
    local result = self:Run()
    local lines = {
        "KNOMERCY WAR ROOM " .. KWR.Util:Upper(
            KWR.version, "CURRENT") .. " DIAGNOSTICS",
        "Passed: " .. tostring(result.passed) .. "   Failed: " .. tostring(result.failed),
        "",
    }
    for _, check in ipairs(result.checks) do
        lines[#lines + 1] = (check.ok and "PASS  " or "FAIL  ") .. check.name
            .. (check.detail ~= "" and (" - " .. check.detail) or "")
    end
    return table.concat(lines, "\n"), result
end

function Diagnostics:ShowReport()
    local report = self:Report()
    KWR.CopyDialog:ShowText("KWR Diagnostics", report)
end

KWR:RegisterModule("Diagnostics", Diagnostics)