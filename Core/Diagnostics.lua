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
                    KWR.CombatRoster.frame.targetSpotlight), 0) == 70
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
    check("Tick math: zero rate is unavailable", KWR.Predictor:TimeToWin(1500, 1000, 0, 2) == 999999)
    check("Tick math: completed score is zero", KWR.Predictor:TimeToWin(1500, 1500, 2, 2) == 0)

    local abWin = KWR.Predictor:Evaluate(fixture(
        "ARATHI",
        { friendly = 1000, enemy = 900, max = 1500 },
        { friendly = 3, enemy = 2 }
    ))
    check("Arathi 3-2 projects WIN", abWin.status == "WIN", "Got " .. tostring(abWin.status))
    check("Arathi friendly clock is 4:10", abWin.friendlyTime == 250, "Got " .. tostring(abWin.friendlyTime))
    check("Arathi enemy clock is 6:40", abWin.enemyTime == 400, "Got " .. tostring(abWin.enemyTime))
    local abBlitzSnapshot = fixture(
        "ARATHI",
        { friendly = 1000, enemy = 900, max = 1500 },
        { friendly = 3, enemy = 2 }
    )
    abBlitzSnapshot.context.isBlitz = true
    local abBlitz = KWR.Predictor:Evaluate(abBlitzSnapshot)
    check("Arathi Blitz uses accelerated scoring and capture timing",
        abBlitz.friendlyTime == 68 and abBlitz.captureDeadline == 90,
        "Clock " .. tostring(abBlitz.friendlyTime) .. " deadline " .. tostring(abBlitz.captureDeadline))

    local abLose = KWR.Predictor:Evaluate(fixture(
        "ARATHI",
        { friendly = 900, enemy = 1200, max = 1500 },
        { friendly = 2, enemy = 3 }
    ))
    check("Arathi 2-3 deficit projects LOSE", abLose.status == "LOSE", "Got " .. tostring(abLose.status))
    check("Arathi recovery requires more objectives", (abLose.neededObjectives or 0) > 0, "Got " .. tostring(abLose.neededObjectives))
    local incomingLoss = KWR.Predictor:Evaluate(fixture(
        "ARATHI",
        { friendly = 1000, enemy = 1000, max = 1500 },
        { friendly = 2, enemy = 2, enemyIncoming = 1 }
    ))
    check("Enemy incoming node capture triggers clock-flip warning",
        incomingLoss.incomingStatus == "LOSE"
            and incomingLoss.action:find("flips the projected clock", 1, true) ~= nil)
    local incomingWin = KWR.Predictor:Evaluate(fixture(
        "ARATHI",
        { friendly = 1000, enemy = 1000, max = 1500 },
        { friendly = 2, enemy = 2, friendlyIncoming = 1 }
    ))
    check("Friendly incoming node capture triggers protection call",
        incomingWin.incomingStatus == "WIN"
            and incomingWin.action:find("Protect the friendly incoming", 1, true) ~= nil)

    local gilneas = KWR.Predictor:Evaluate(fixture(
        "GILNEAS",
        { friendly = 1000, enemy = 900, max = 1500 },
        { friendly = 2, enemy = 1 }
    ))
    check("Gilneas two-base control projects WIN",
        gilneas.status == "WIN" and gilneas.friendlyObjectives == 2)
    local bfgRecoverySnapshot = fixture("GILNEAS",
        { friendly = 450, enemy = 1200, max = 1500 },
        { friendly = 2, enemy = 1 })
    bfgRecoverySnapshot.context.team = { faction = "Alliance", side = "left" }
    bfgRecoverySnapshot.roster = KWR.Util:Copy(assignmentRoster)
    bfgRecoverySnapshot.objectives.rows = {
        { label = "Lighthouse", owner = "FRIENDLY", state = "CONTROLLED" },
        { label = "Waterworks", owner = "FRIENDLY", state = "CONTROLLED" },
        { label = "Mine", owner = "ENEMY", state = "CONTROLLED" },
    }
    bfgRecoverySnapshot.strategy = { state = "RECOVERY" }
    local bfgRecoveryAssignments = KWR.Assignments:Build(bfgRecoverySnapshot)
    local bfgRecoveryCommand = KWR.Commander:Compose(
        bfgRecoverySnapshot,
        KWR.Predictor:Evaluate(bfgRecoverySnapshot),
        bfgRecoveryAssignments)
    local defenders, mineStrike = 0, 0
    for _, assignment in ipairs(bfgRecoveryAssignments) do
        if assignment.role:find("Defender", 1, true)
            and (assignment.location == "Lighthouse" or assignment.location == "Waterworks") then
            defenders = defenders + 1
        elseif assignment.role == "Strike Team" and assignment.location == "Mine" then
            mineStrike = mineStrike + 1
        end
    end
    check("Gilneas recovery names defenders for two held bases and assaults the missing third",
        defenders == 2 and mineStrike >= 6
            and bfgRecoveryCommand.action:find("TAKE M", 1, true) ~= nil
            and bfgRecoveryCommand.action:find("HOLD", 1, true) ~= nil,
        bfgRecoveryCommand.action)

    local deepwind = KWR.Predictor:Evaluate(fixture(
        "DEEPWIND",
        { friendly = 1000, enemy = 900, max = 1500 },
        { friendly = 3, enemy = 2 }
    ))
    check("Deepwind uses its verified score widget and three-base clock",
        KWR.Maps:Get("DEEPWIND").scoreWidget == 2074
            and deepwind.status == "WIN" and deepwind.friendlyObjectives == 3)

    local eotsSnapshot = fixture(
        "EOTS",
        { friendly = 700, enemy = 900, max = 1500 },
        { friendly = 1, enemy = 3 }
    )
    eotsSnapshot.objectives.friendlyFlagActive = 1
    local eots = KWR.Predictor:Evaluate(eotsSnapshot)
    check("Eye of the Storm values towers before the flag",
        eots.kind == "HYBRID" and eots.flagValue == 75
            and eots.action:find("tower control", 1, true) ~= nil)
    eotsSnapshot.context.isBlitz = true
    local eotsBlitz = KWR.Predictor:Evaluate(eotsSnapshot)
    check("Midnight Eye of the Storm Blitz uses the restored standard scoring model",
        eotsBlitz.flagValue == eots.flagValue
            and eotsBlitz.friendlyTime == eots.friendlyTime)

    local flag = KWR.Predictor:Evaluate(fixture(
        "WSG",
        { friendly = 1, enemy = 2, max = 3 },
        { friendlyActive = 1, enemyActive = 1 }
    ))
    check("WSG 1-2 projects LOSE", flag.status == "LOSE", "Got " .. tostring(flag.status))
    check("WSG detects both carriers", flag.friendlyCarrying and flag.enemyCarrying)
    local friendlyTiebreakSnapshot = fixture(
        "WSG",
        { friendly = 1, enemy = 1, max = 3 },
        {}
    )
    friendlyTiebreakSnapshot.score.lastCapture = "FRIENDLY"
    local friendlyTiebreak = KWR.Predictor:Evaluate(friendlyTiebreakSnapshot)
    check("WSG friendly last capture owns a tied score",
        friendlyTiebreak.status == "WIN" and friendlyTiebreak.tiedByLastCapture == true)
    friendlyTiebreakSnapshot.score.lastCapture = "ENEMY"
    local enemyTiebreak = KWR.Predictor:Evaluate(friendlyTiebreakSnapshot)
    check("WSG enemy last capture makes a tied timeout a loss",
        enemyTiebreak.status == "LOSE"
            and enemyTiebreak.action:find("timeout is a loss", 1, true) ~= nil)

    local twinPeaks = KWR.Predictor:Evaluate(fixture(
        "TWINPEAKS",
        { friendly = 1, enemy = 2, max = 3 },
        { friendlyActive = 0, enemyActive = 1 }
    ))
    check("Twin Peaks uses return-and-cap flag logic",
        twinPeaks.kind == "FLAG" and twinPeaks.status == "LOSE"
            and twinPeaks.action:find("EFC", 1, true) ~= nil)

    local orb = KWR.Predictor:Evaluate(fixture(
        "TEMPLE",
        { friendly = 700, enemy = 900, max = 1500 },
        { friendlyActive = 1, enemyActive = 3 }
    ))
    check("Temple deficit raises urgency", (orb.urgency or 0) >= 85, "Got " .. tostring(orb.urgency))
    local orbWithoutTelemetry = fixture(
        "TEMPLE",
        { friendly = 700, enemy = 900, max = 1500 },
        { source = "none" }
    )
    orbWithoutTelemetry.objectives.source = "none"
    orbWithoutTelemetry = KWR.Predictor:Evaluate(orbWithoutTelemetry)
    check("Temple never fabricates missing orb ownership",
        orbWithoutTelemetry.objectiveTelemetry == false
            and orbWithoutTelemetry.condition:find("telemetry unavailable", 1, true) ~= nil)

    local silvershard = KWR.Predictor:Evaluate(fixture(
        "SILVERSHARD",
        { friendly = 700, enemy = 900, max = 1500 },
        { friendlyActive = 1, enemyActive = 2 }
    ))
    check("Silvershard prioritizes cart delay and recovery",
        silvershard.kind == "CART"
            and silvershard.action:find("Delay the enemy scoring route", 1, true) ~= nil)

    local deephaul = KWR.Predictor:Evaluate(fixture(
        "DEEPHAUL",
        { friendly = 700, enemy = 900, max = 1500 },
        { friendlyActive = 1, enemyActive = 2 }
    ))
    check("Deephaul prioritizes turning the enemy cart",
        deephaul.kind == "CART"
            and deephaul.action:find("Turn the enemy cart", 1, true) ~= nil)
    local cartWithoutTelemetry = fixture(
        "DEEPHAUL",
        { friendly = 700, enemy = 900, max = 1500 },
        { source = "none" }
    )
    cartWithoutTelemetry.objectives.source = "none"
    cartWithoutTelemetry = KWR.Predictor:Evaluate(cartWithoutTelemetry)
    check("Deephaul never fabricates missing cart ownership",
        cartWithoutTelemetry.objectiveTelemetry == false
            and cartWithoutTelemetry.condition:find("telemetry unavailable", 1, true) ~= nil)

    local seething = KWR.Predictor:Evaluate(fixture(
        "SEETHING",
        { friendly = 700, enemy = 900, max = 1500 },
        {}
    ))
    check("Seething Shore prioritizes the next resource spawn",
        seething.kind == "RESOURCE"
            and seething.action:find("next node", 1, true) ~= nil)

    local world = KWR.Predictor:Evaluate(fixture(
        "WORLD",
        { friendly = 0, enemy = 0, max = 0, source = "none" },
        { source = "none" },
        false
    ))
    check("World mode does not invent battlefield truth", world.status == "WORLD", "Got " .. tostring(world.status))
    local waitingSnapshot = fixture(
        "ARATHI",
        { friendly = 0, enemy = 0, max = 1500, source = "team_unresolved" },
        { friendly = 0, enemy = 0, source = "ui_widget" }
    )
    waitingSnapshot.roster = KWR.Util:Copy(assignmentRoster)
    local waitingPrediction = KWR.Predictor:Evaluate(waitingSnapshot)
    local waitingStrategy = KWR.Strategist:Evaluate(waitingSnapshot, waitingPrediction)
    local reviewedOpeningSnapshot = fixture(
        "ARATHI",
        { friendly = 0, enemy = 0, max = 1500, source = "ui_widget" },
        { friendly = 0, enemy = 0, source = "ui_widget" }
    )
    reviewedOpeningSnapshot.roster = KWR.Util:Copy(assignmentRoster)
    local reviewedOpeningPrediction = KWR.Predictor:Evaluate(reviewedOpeningSnapshot)
    local reviewedOpeningStrategy = KWR.Strategist:Evaluate(
        reviewedOpeningSnapshot, reviewedOpeningPrediction)
    check("Pregame truth selects only the reviewed opening doctrine",
        waitingPrediction.status == "WAITING" and waitingStrategy.state == "OPENING"
            and waitingStrategy.planID ~= nil
            and waitingStrategy.planID == reviewedOpeningStrategy.planID,
        tostring(waitingStrategy.planID))

    local preview = KWR.Preview:Build()
    check("Preview is explicitly labeled", preview.context.preview == true and preview.context.phase == "PREVIEW")
    check("Preview contains commander roster", #preview.roster == 10, "Found " .. tostring(#preview.roster))
    check("Preview contains enemy tracker rows", #preview.enemies == 10, "Found " .. tostring(#preview.enemies))
    check("Preview includes map coordinates", preview.objectives.rows[1].x ~= nil and preview.objectives.rows[1].y ~= nil)
    check("Preview exercises friendly health bars",
        preview.roster[1].healthPercent == 100 and preview.roster[10].healthPercent == 34)
    check("Reporter distance math", KWR.Reporter:Distance(0, 0, 0.3, 0.4) == 0.5)
    local previewReporter = KWR.Reporter:Observe(preview)
    check("Reporter preserves marker role and health context",
        previewReporter.friendly[1] and previewReporter.friendly[1].role ~= "NONE"
            and previewReporter.friendly[1].healthPercent ~= nil)

    local liveState = KWR.Store:Get()
    check("Store carries Reporter knowledge", type(liveState.snapshot.reporter) == "table")
    check("Reporter publishes movement coverage",
        type(liveState.snapshot.reporter.coverage) == "table")
    check("Defensive catalog resolves Divine Shield",
        KWR.CombatSpells:Get(642) and KWR.CombatSpells:Get(642).kind == "DEFENSIVE")
    check("Combat role model recognizes Discipline",
        KWR.CombatSpells:Role("Discipline", nil) == "HEALER")
    local disciplineMeta = KWR.MetaSnapshot:Lookup("PRIEST", "Discipline")
    check("RBG meta snapshot has forty specializations", KWR.MetaSnapshot:Count() == 40)
    check("RBG meta snapshot resolves Discipline",
        disciplineMeta and disciplineMeta.role == "HEALER" and disciplineMeta.rank == 1)
    check("Reviewed tier composition library contains at least twenty team shells",
        #KWR.Compositions:TierAll() >= 20)
    local tierRoster = {}
    for _, token in ipairs(KWR.Compositions:TierAll()[1].specs) do
        local classFile, spec = token:match("^([^:]+):(.+)$")
        tierRoster[#tierRoster + 1] = {
            name = "Tier" .. tostring(#tierRoster + 1),
            shortName = "Tier" .. tostring(#tierRoster + 1),
            classFile = classFile,
            spec = spec,
            role = spec == "Protection" and "TANK"
                or ((spec == "Discipline" or spec == "Mistweaver"
                    or spec == "Preservation") and "HEALER" or "DAMAGER"),
        }
    end
    local exactTier = KWR.Compositions:MatchTier(tierRoster, "ARATHI")
    check("Full verified roster resolves an exact tier composition",
        exactTier and exactTier.exact and exactTier.qualified
            and exactTier.id == "CONTROL_CLEAVE"
            and exactTier.win ~= "" and exactTier.counter ~= "")
    local tierEnemyRoster = {}
    for _, token in ipairs(KWR.Compositions:TierAll()[2].specs) do
        local classFile, spec = token:match("^([^:]+):(.+)$")
        tierEnemyRoster[#tierEnemyRoster + 1] = {
            name = "EnemyTier" .. tostring(#tierEnemyRoster + 1),
            shortName = "EnemyTier" .. tostring(#tierEnemyRoster + 1),
            classFile = classFile,
            spec = spec,
            role = spec == "Guardian" and "TANK"
                or ((spec == "Discipline" or spec == "Mistweaver"
                    or spec == "Preservation") and "HEALER" or "DAMAGER"),
        }
    end
    local tierStrategySnapshot = fixture("ARATHI",
        { friendly = 700, enemy = 900, max = 1500 },
        { friendly = 2, enemy = 3 })
    tierStrategySnapshot.roster = tierRoster
    tierStrategySnapshot.enemies = tierEnemyRoster
    local tierPrediction = KWR.Predictor:Evaluate(tierStrategySnapshot)
    local tierStrategy = KWR.Strategist:Evaluate(tierStrategySnapshot, tierPrediction)
    check("Qualified enemy tier composition supplies its reviewed counterplan",
        tierStrategy.enemyTier and tierStrategy.enemyTier.id == "NODE_LOCKDOWN"
            and tierStrategy.counter and tierStrategy.counter.source == "USER_REVIEWED_2026_06_29"
            and tierStrategy.counter.emphasis == tierStrategy.enemyTier.counter)
    check("Capability repository covers forty specializations", KWR.Capabilities:Count() == 40)
    local ratingNames = {
        "burst", "pressure", "mobility", "survivability", "peel", "teamfight",
        "nodeDefense", "flagCarry", "splitPush", "objectiveUtility", "recovery",
        "manaEndurance", "killConfirm", "ccPotential",
    }
    local jobNames = {
        "ANCHOR", "FLOATER", "ESCORT", "DEFENDER", "ASSASSIN",
        "CARRIER", "ROAMER", "SUPPORT", "HARASSER",
    }
    local capabilitySchemaOK = true
    for _, classSpec in ipairs({
        { "DEATHKNIGHT", "Blood" }, { "DEATHKNIGHT", "Frost" },
        { "DEATHKNIGHT", "Unholy" }, { "DEMONHUNTER", "Havoc" },
        { "DEMONHUNTER", "Devourer" }, { "DEMONHUNTER", "Vengeance" },
        { "DRUID", "Balance" }, { "DRUID", "Feral" }, { "DRUID", "Guardian" },
        { "DRUID", "Restoration" }, { "EVOKER", "Devastation" },
        { "EVOKER", "Preservation" }, { "EVOKER", "Augmentation" },
        { "HUNTER", "Beast Mastery" }, { "HUNTER", "Marksmanship" },
        { "HUNTER", "Survival" }, { "MAGE", "Arcane" }, { "MAGE", "Fire" },
        { "MAGE", "Frost" }, { "MONK", "Brewmaster" }, { "MONK", "Mistweaver" },
        { "MONK", "Windwalker" }, { "PALADIN", "Holy" },
        { "PALADIN", "Protection" }, { "PALADIN", "Retribution" },
        { "PRIEST", "Discipline" }, { "PRIEST", "Holy" }, { "PRIEST", "Shadow" },
        { "ROGUE", "Assassination" }, { "ROGUE", "Outlaw" },
        { "ROGUE", "Subtlety" }, { "SHAMAN", "Elemental" },
        { "SHAMAN", "Enhancement" }, { "SHAMAN", "Restoration" },
        { "WARLOCK", "Affliction" }, { "WARLOCK", "Demonology" },
        { "WARLOCK", "Destruction" }, { "WARRIOR", "Arms" },
        { "WARRIOR", "Fury" }, { "WARRIOR", "Protection" },
    }) do
        local capability = KWR.Capabilities:Get(classSpec[1], classSpec[2])
        for _, rating in ipairs(ratingNames) do
            local score = capability and capability.ratings and capability.ratings[rating]
            capabilitySchemaOK = capabilitySchemaOK
                and type(score) == "number" and score >= 1 and score <= 5
        end
        for _, job in ipairs(jobNames) do
            local score = capability and capability.jobs and capability.jobs[job]
            capabilitySchemaOK = capabilitySchemaOK
                and type(score) == "number" and score >= 0 and score <= 100
        end
    end
    check("All forty specializations expose bounded capability and battlefield-job ratings",
        capabilitySchemaOK == true)
    local categoryAudit = KWR.Capabilities:CategoryAudit()
    local focusCategories = KWR.Strategist:FocusCategories()
    local categoryCoverageOK = true
    for _, rating in ipairs(ratingNames) do
        local audit = categoryAudit[rating] or {}
        categoryCoverageOK = categoryCoverageOK
            and (audit.signals or 0) >= 3
            and (audit.effects or 0) >= 3
            and focusCategories[rating] == true
    end
    check("Every weighted category has three signals, three battlefield effects, and objective-plan influence",
        categoryCoverageOK == true)
    local baseUnholy = KWR.Capabilities:Get("DEATHKNIGHT", "Unholy")
    local deathbringer = KWR.Capabilities:Get(
        "DEATHKNIGHT", "Unholy", "Deathbringer")
    check("Hero talent modifiers refine a copy without mutating base capability truth",
        baseUnholy and deathbringer
            and deathbringer.ratings.burst == math.min(5, baseUnholy.ratings.burst + 1)
            and deathbringer.jobs.ASSASSIN == math.min(100, baseUnholy.jobs.ASSASSIN + 10)
            and KWR.Capabilities:Get("DEATHKNIGHT", "Unholy").heroTalent == nil)
    local marksmanship = KWR.Capabilities:Get("HUNTER", "Marksmanship")
    check("Retail 12.1 compatibility rejects stale capability overlays",
        marksmanship
            and KWR.PatchData:Capability("HUNTER:marksmanship") == nil
            and KWR.PatchData:Validate(120100) == false)
    local cachedA = KWR.Capabilities:Resolve("DRUID", "Guardian")
    local cachedB = KWR.Capabilities:Resolve("DRUID", "Guardian")
    local copiedCapability = KWR.Capabilities:Get("DRUID", "Guardian")
    check("Capability hot-path cache reuses immutable results while public reads remain isolated",
        cachedA == cachedB and copiedCapability ~= cachedA
            and KWR.Capabilities:CacheStats().hits > 0)
    local smokeBomb = KWR.CombatSpells:Get(212182)
    local cyclone = KWR.CombatSpells:Get(33786)
    check("Battlefield ability catalog distinguishes objective threats from defensives",
        smokeBomb and smokeBomb.kind == "ABILITY"
            and smokeBomb.tags.objectiveThreat == true
            and cyclone and cyclone.tags.captureDenial == true)
    local priorityCyclone = KWR.CombatSpells:GetCast(33786)
    check("Priority-cast catalog accents reviewed control without claiming interruptibility",
        priorityCyclone and priorityCyclone.priority == "MUST_STOP"
            and priorityCyclone.response == "STOP")
    check("Defensive catalog publishes an advisory response for verified immunities",
        KWR.CombatSpells:Get(642).defensiveClass == "IMMUNITY"
            and KWR.CombatSpells:Get(642).response == "SWAP")
    KWR.CombatIntel:Reset()
    KWR.CombatIntel:ObserveSpell(
        "Creature-Test", "Threat-Realm", 212182, "SPELL_CAST_SUCCESS")
    local threatEvidence = KWR.CombatIntel:EvidenceFor({
        guid = "Creature-Test", name = "Threat-Realm",
    })
    check("Observed battlefield abilities publish a bounded tactical threat window",
        threatEvidence.recentAbilities[1]
            and threatEvidence.recentAbilities[1].name == "Smoke Bomb"
            and threatEvidence.threatScore == 36)
    local castRecord = KWR.CombatIntel:GetRecord(
        "Player-Caster", "Caster-Realm", true)
    castRecord.currentCast = {
        spellID = 33786, name = "Cyclone", priority = "MUST_STOP",
        response = "STOP", observedAt = KWR.Util:Now(),
        expiresAt = KWR.Util:Now() + 3,
    }
    local castEvidence = KWR.CombatIntel:EvidenceFor({
        guid = "Player-Caster", name = "Caster-Realm",
    })
    check("Observed priority casts expire through the existing combat evidence record",
        castEvidence.priorityCast
            and castEvidence.priorityCast.name == "Cyclone"
            and castEvidence.priorityCast.remaining > 0)
    local protectedScore = KWR.CombatIntel:Score({
        guid = "Protected-1", name = "Protected-Realm",
        classFile = "PALADIN", spec = "Retribution", role = "DAMAGER",
        visible = true, localEngaged = true, dead = false,
    }, {
        defensivesActive = {
            { name = "Divine Shield", response = "SWAP" },
        },
        defensivesOnCooldown = {},
        recentAbilities = {},
        trinketState = "UNKNOWN",
        threatScore = 0,
    })
    check("Verified immunity removes a protected enemy from automatic kill-candidate ranking",
        protectedScore == nil)
    KWR.CombatIntel:Reset()
    check("Capability preferences refine assignment value without replacing role safety",
        KWR.Assignments:BattleValue({
            name = "Guardian", classFile = "DRUID", spec = "Guardian", role = "TANK",
        }, "defend") > KWR.Assignments:BattleValue({
            name = "Arms", classFile = "WARRIOR", spec = "Arms", role = "DAMAGER",
        }, "defend"))
    local confidenceSummary = KWR.Capabilities:Summarize({
        { classFile = "PRIEST", spec = "Discipline", role = "HEALER",
            specSource = "inspect" },
        { classFile = "WARLOCK", spec = "Affliction", role = "DAMAGER",
            specSource = "historical" },
    })
    check("Capability summary labels mixed live and historical knowledge as likely",
        confidenceSummary.confidence == "LIKELY"
            and confidenceSummary.confirmedSpecs == 1
            and confidenceSummary.likelySpecs == 1)
    check("Capability summary publishes team-level ratings and battlefield-job fit",
        confidenceSummary.ratings.recovery > 0
            and confidenceSummary.jobs.SUPPORT > 0)
    local counterSequencesOK = true
    for _, archetype in ipairs({
        "BALANCED", "STEALTH", "ROT", "MELEE", "RANGED", "ROTATION", "BUNKER",
    }) do
        local counter = KWR.Counters:Get(archetype)
        counterSequencesOK = counterSequencesOK and counter
            and #(counter.sequence or {}) >= 3 and counter.success ~= nil
    end
    check("Every composition counter contains a three-step conversion sequence",
        counterSequencesOK == true)
    local oldReporterSession = KWR.Reporter.sessionKey
    local oldReporterTracks = KWR.Reporter.tracks
    local oldReporterEvents = KWR.Reporter.events
    KWR.Reporter:Reset("diagnostic-location")
    local evidenceTrack = KWR.Reporter:Track("enemy", {
        key = "ENEMY-LOCATION", name = "ObservedEnemy",
        visible = true, location = "Blacksmith", locationSource = "Team Engagement",
    }, KWR.Util:Now(), KWR.Util:Now())
    check("Reporter retains visible and last-seen location evidence without fabricating coordinates",
        evidenceTrack and evidenceTrack.location == "Blacksmith"
            and evidenceTrack.locationSource == "Team Engagement"
            and evidenceTrack.located == false)
    KWR.Reporter.sessionKey = oldReporterSession
    KWR.Reporter.tracks = oldReporterTracks
    KWR.Reporter.events = oldReporterEvents
    local oldEnemyRecords = KWR.EnemyIntel.records
    local oldEnemySession = KWR.EnemyIntel.sessionKey
    local oldEnemyTokens = KWR.EnemyIntel.observedTokens
    local oldEnemyFriendlyScoreFaction = KWR.EnemyIntel.friendlyScoreFaction
    KWR.EnemyIntel.records = {}
    KWR.EnemyIntel.observedTokens = {}
    KWR.EnemyIntel.sessionKey = "diagnostic-location"
    KWR.EnemyIntel.friendlyScoreFaction = nil
    KWR.EnemyIntel:Upsert({
        name = "LastSeen-Realm", guid = "Player-LastSeen",
        class = "Rogue", classFile = "ROGUE", spec = "Subtlety",
        source = "Team Engagement", location = "Blacksmith",
        locationSource = "Team Engagement", x = 0.5, y = 0.5,
    }, true)
    KWR.EnemyIntel.records["Player-LastSeen"].visible = false
    local lastSeenRows = KWR.EnemyIntel:Rows()
    check("Enemy intelligence preserves where and how a no-longer-visible enemy was last seen",
        lastSeenRows[1] and lastSeenRows[1].locationState == "LAST SEEN"
            and lastSeenRows[1].location == "Blacksmith"
            and lastSeenRows[1].locationSource == "Team Engagement")
    KWR.EnemyIntel:Upsert({
        name = "RecentLocal-Realm", guid = "Player-RecentLocal",
        class = "Warrior", classFile = "WARRIOR", spec = "Arms",
        source = "Target", location = "Lumber Mill",
        locationSource = "Target", x = 0.5, y = 0.5,
        localRange = true, localEngaged = true,
    }, true)
    KWR.EnemyIntel.records["Player-RecentLocal"].visible = false
    KWR.EnemyIntel.records["Player-RecentLocal"].localRange = false
    KWR.EnemyIntel.records["Player-RecentLocal"].localEngaged = false
    local recentLocalRow
    for _, row in ipairs(KWR.EnemyIntel:Rows()) do
        if row.guid == "Player-RecentLocal" then
            recentLocalRow = row
            break
        end
    end
    check("Enemy intelligence keeps recent local truth through visibility churn without pretending the enemy is still visible",
        recentLocalRow
            and recentLocalRow.locationState == "LAST SEEN"
            and recentLocalRow.visible ~= true
            and recentLocalRow.recentLocalRange == true
            and recentLocalRow.recentLocalEngaged == true)
    local engagementText = KWR.EnemyIntel:DescribeLocation({
        age = 4,
        location = "Lumber Mill",
        locationSource = "Team Assignment",
        locationInferred = true,
        engagementRole = "Strike Team",
    }, "ARATHI", true)
    check("Team engagement evidence uses assignment terminology and a compact objective",
        engagementText == "LAST 4s WITH STRIKE -> LM", engagementText)
    check("Compact team assignment labels share command terminology",
        KWR.Assignments:CompactLabel({
            role = "Strike Team", location = "Blacksmith",
        }, "ARATHI") == "STRIKE -> BS")
    local scoreboardEnemyRows = KWR.EnemyIntel:Capture({
        inPvP = true,
        mapID = 529,
        mapKey = "ARATHI",
        sessionKey = "ARATHI:529:3:PVP:LIVE",
    }, {
        { unit = "player", guid = "Friendly-1", name = "Friendly-Realm" },
    }, {
        scoreFaction = 1,
    }, {
        {
            guid = "Enemy-1",
            name = "Enemy-Realm",
            classFile = "MAGE",
            class = "Mage",
            spec = "Frost",
            faction = 0,
            role = "DAMAGER",
        },
    })
    check("Scoreboard enemy ingestion preserves battleground-side faction for downstream filtering",
        scoreboardEnemyRows[1]
            and scoreboardEnemyRows[1].faction == 0,
        scoreboardEnemyRows[1] and tostring(scoreboardEnemyRows[1].faction) or "missing")
    KWR.EnemyIntel.records = oldEnemyRecords
    KWR.EnemyIntel.sessionKey = oldEnemySession
    KWR.EnemyIntel.observedTokens = oldEnemyTokens
    KWR.EnemyIntel.friendlyScoreFaction = oldEnemyFriendlyScoreFaction

    local oldReporterState = {
        sessionKey = KWR.Reporter.sessionKey,
        tracks = KWR.Reporter.tracks,
        events = KWR.Reporter.events,
        memory = KWR.Reporter.memory,
        sequence = KWR.Reporter.sequence,
        lastScore = KWR.Reporter.lastScore,
        hotspotKey = KWR.Reporter.hotspotKey,
    }
    KWR.Reporter:Reset("diagnostic-decision")
    local movementNow = KWR.Util:Now()
    KWR.Reporter:Track("friendly", {
        key = "FriendlyMover", name = "FriendlyMover", classFile = "DRUID",
        spec = "Feral", x = 0.20, y = 0.50, visible = true,
        location = "Farm", locationSource = "Friendly Map Position",
    }, movementNow - 5, movementNow - 5)
    KWR.Reporter:Track("friendly", {
        key = "FriendlyMover", name = "FriendlyMover", classFile = "DRUID",
        spec = "Feral", x = 0.35, y = 0.50, visible = true,
        location = "Blacksmith", locationSource = "Friendly Map Position",
    }, movementNow, movementNow)
    KWR.Reporter:Track("enemy", {
        key = "EnemyMover", name = "EnemyMover", classFile = "ROGUE",
        spec = "Subtlety", x = 0.22, y = 0.50, visible = true,
        location = "Farm", locationSource = "Nameplate",
    }, movementNow - 5, movementNow - 5)
    KWR.Reporter:Track("enemy", {
        key = "EnemyMover", name = "EnemyMover", classFile = "ROGUE",
        spec = "Subtlety", x = 0.40, y = 0.50, visible = true,
        location = "Blacksmith", locationSource = "Nameplate",
    }, movementNow, movementNow)
    local decisionSnapshot = fixture("ARATHI",
        { friendly = 800, enemy = 900, max = 1500 },
        { friendly = 2, enemy = 3 })
    decisionSnapshot.context.team = { faction = "Alliance", side = "left" }
    decisionSnapshot.roster = KWR.Util:Copy(assignmentRoster)
    decisionSnapshot.enemies = KWR.Util:Copy(KWR.Preview:Build().enemies)
    decisionSnapshot.objectives.rows = {
        { label = "Farm", owner = "FRIENDLY", state = "CONTROLLED", x = 0.20, y = 0.50 },
        { label = "Blacksmith", owner = "ENEMY", state = "CONTROLLED", x = 0.80, y = 0.50 },
    }
    local diagnosticETAs = KWR.Reporter:ObjectiveETAs(decisionSnapshot)
    local diagnosticIntent = KWR.Reporter:PredictIntent(decisionSnapshot, diagnosticETAs)
    local diagnosticMomentum = KWR.Reporter:Momentum(decisionSnapshot,
        KWR.Reporter:ObjectivePressure(decisionSnapshot))
    check("Reporter estimates bounded friendly and enemy objective arrival times",
        diagnosticETAs[1] ~= nil
            and (diagnosticETAs[1].friendlyETA ~= nil
                or diagnosticETAs[1].enemyETA ~= nil),
        "Objectives with ETA: " .. tostring(#diagnosticETAs))
    check("Enemy intent prediction names a likely objective with evidence-bounded confidence",
        diagnosticIntent.target ~= nil
            and diagnosticIntent.confidenceScore >= 0
            and diagnosticIntent.confidenceScore <= 90
            and diagnosticIntent.commitmentScore ~= nil)
    check("Reporter trust distinguishes commitment quality from stale or split movement noise",
        KWR.Reporter:TrustProfile(decisionSnapshot,
            KWR.Reporter:ObjectivePressure(decisionSnapshot),
            diagnosticETAs, diagnosticIntent).score >= 0)
    check("Momentum remains independent from score and bounded to its declared range",
        diagnosticMomentum.value >= -100 and diagnosticMomentum.value <= 100
            and diagnosticMomentum.state ~= nil)
    check("Match-only movement memory records observed routes without permanent profiling",
        (KWR.Reporter.memory.routes["Farm -> Blacksmith"] or 0) >= 1
            and KWR.Reporter.memory.revision >= 1)

    decisionSnapshot.combat = {
        localEnemies = 1,
        observedSpells = 3,
        resourceEconomy = {
            coverage = 3,
            advantage = 44,
            confidence = "MEDIUM",
            enemy = {
                deadHealers = 1,
                trinketsUsed = 2,
                defensivesUsed = 2,
                activeDefensives = 0,
                isolatedCarriers = 0,
            },
        },
    }
    decisionSnapshot.reporter = KWR.Reporter:Snapshot(decisionSnapshot)
    decisionSnapshot.formation = KWR.FormationAdvisor:Evaluate(decisionSnapshot)
    local decisionPrediction = KWR.Predictor:Evaluate(decisionSnapshot)
    KWR.Strategist.cache = nil
    local decisionStrategy = KWR.Strategist:Evaluate(
        decisionSnapshot, decisionPrediction)
    local freshEvidence = KWR.Util:Evidence(
        "known", "diagnostic", KWR.Util:Now(), 5, "HIGH", true)
    local staleEvidence = KWR.Util:Evidence(
        "known", "diagnostic", KWR.Util:Now() - 20, 5, "HIGH", true)
    check("Evidence contract distinguishes fresh verified truth from stale observations",
        freshEvidence.state == "VERIFIED"
            and KWR.Util:EvidenceUsable(freshEvidence, "HIGH")
            and staleEvidence.state == "STALE"
            and not KWR.Util:EvidenceUsable(staleEvidence, "LOW"))
    local truthSnapshot = KWR.Util:Copy(decisionSnapshot)
    truthSnapshot.context.capturedAt = KWR.Util:Now()
    truthSnapshot.context.team = {
        faction = "Alliance", side = "left", source = "scoreboard",
    }
    truthSnapshot.score.observedAt = KWR.Util:Now()
    truthSnapshot.objectives.observedAt = KWR.Util:Now()
    truthSnapshot.reporter.updatedAt = KWR.Util:Now()
    local truthContract = KWR.Verification:Contract(truthSnapshot)
    check("Battlefield truth contract qualifies fresh match, faction, score, and objective evidence",
        truthContract.coreFresh == true
            and truthContract.aggressiveCommitAllowed == true
            and truthContract.summary.coverage >= 65)
    local routeEstimate = KWR.Maps:TravelEstimate(
        "ARATHI", "Farm", "Blacksmith", {
            mobility = 3, inCombat = false,
        })
    check("Static map route model produces a bounded tactical travel band without coordinates",
        routeEstimate and routeEstimate.seconds > 0
            and routeEstimate.band ~= nil
            and routeEstimate.source == "MAP_ROUTE_ESTIMATE")
    check("Recommendation confidence budget is bounded and cites multiple evidence sources",
        decisionStrategy.confidenceBudget
            and decisionStrategy.confidenceBudget.score >= 0
            and decisionStrategy.confidenceBudget.score <= 100
            and #decisionStrategy.confidenceBudget.evidence >= 8)
    check("Opportunity detector opens a short-lived window from verified temporary advantages",
        decisionStrategy.opportunity and decisionStrategy.opportunity.open
            and decisionStrategy.opportunity.duration > 0
            and #decisionStrategy.opportunity.evidence >= 1)
    local simulationsValid = #(decisionStrategy.simulations or {}) == 5
    for index, candidate in ipairs(decisionStrategy.simulations or {}) do
        simulationsValid = simulationsValid
            and candidate.probability >= 5 and candidate.probability <= 95
            and (index == 1 or candidate.probability
                <= decisionStrategy.simulations[index - 1].probability)
    end
    check("Lightweight win-path simulation ranks five bounded candidate actions",
        simulationsValid == true
            and decisionStrategy.projectedWinProbability
                == decisionStrategy.simulations[1].probability)
    check("Candidate actions include objective, opportunity cost, reversibility, success, and abort semantics",
        decisionStrategy.selectedAction
            and decisionStrategy.selectedAction.target ~= nil
            and decisionStrategy.selectedAction.decisionScore
                == decisionStrategy.selectedAction.probability
            and decisionStrategy.selectedAction.opportunityCost ~= nil
            and type(decisionStrategy.selectedAction.reversible) == "boolean"
            and decisionStrategy.selectedAction.success ~= nil
            and decisionStrategy.selectedAction.abort ~= nil)
    check("Map scenario supplies an execution contract with counter and recovery behavior",
        decisionStrategy.responseContract
            and decisionStrategy.responseContract.playersNeeded >= 2
            and #decisionStrategy.responseContract.requiredEvidence >= 3
            and decisionStrategy.responseContract.likelyCounter ~= nil
            and decisionStrategy.responseContract.counterResponse ~= nil)
    local cacheHitsBefore = KWR.Strategist:CacheStats().hits
    KWR.Strategist:Evaluate(decisionSnapshot, decisionPrediction)
    check("Decision engine reuses an unchanged bounded evaluation",
        KWR.Strategist:CacheStats().hits > cacheHitsBefore)

    local executionSnapshot = KWR.Util:Copy(decisionSnapshot)
    executionSnapshot.strategy = KWR.Util:Copy(decisionStrategy)
    executionSnapshot.reporter = {
        pressure = {
            {
                label = "Farm", owner = "FRIENDLY",
                friendly = 1, enemy = 4, delta = 3, risk = 92,
            },
        },
        hotspot = {
            label = "Farm", owner = "FRIENDLY",
            friendly = 1, enemy = 4, delta = 3, risk = 92,
        },
        etas = {
            {
                label = "Farm", friendlyETA = 14, enemyETA = 5,
                advantage = -9, confidence = "MEDIUM",
            },
        },
        enemyIntent = {
            target = "Farm", confidence = "HIGH", confidenceScore = 78,
        },
        momentum = {
            value = -46, state = "ENEMY", confidence = "MEDIUM",
            friendlyDead = 3, enemyDead = 0, friendlyHealers = 0,
        },
    }
    executionSnapshot.assignmentIntegrity = {
        rows = {
            { name = "Defender", status = "ABANDONED" },
            { name = "Floater", status = "MOVING" },
        },
        onStation = 0,
        moving = 1,
        unverified = 0,
        abandoned = 1,
        impossible = 0,
    }
    executionSnapshot.combat.resourceEconomy.advantage = -35
    local executionAssignments = {
        { name = "Defender", role = "Node Defender", location = "Farm" },
        { name = "Floater", role = "Floater", location = "Blacksmith" },
    }
    local executionAssessment = KWR.Strategist:AssessExecution(
        executionSnapshot, { urgency = 72 }, executionAssignments)
    check("Execution assessment detects an underdefended friendly objective",
        executionAssessment.commitment.state == "UNDERDEFENDED"
            and executionAssessment.commitment.objective == "Farm")
    check("Execution assessment forecasts enemy reinforcement advantage without inventing coordinates",
        executionAssessment.reinforcement.side == "ENEMY"
            and executionAssessment.reinforcement.advantage == -9
            and executionAssessment.pressureForecast.state == "RISING")
    check("Rotation economy rejects a rotation whose leaving cost exceeds its arrival value",
        executionAssessment.rotationEconomy.state == "NOT_WORTH_IT"
            and executionAssessment.rotationEconomy.leavingCost == "HIGH")
    check("Collapse assessment promotes a bounded disengage or stall response",
        executionAssessment.collapse.state == "CRITICAL"
            and (executionAssessment.collapse.response == "DISENGAGE_RESET"
                or executionAssessment.collapse.response == "STALL_OR_TRADE"))
    check("Organization assessment exposes assignment breakdown as bounded entropy",
        executionAssessment.organization.entropy >= 20
            and executionAssessment.organization.entropy <= 100
            and executionAssessment.organization.state ~= "ORDERED")
    check("Action opportunity selects one highest-value execution response",
        executionAssessment.actionOpportunity.action == "DISENGAGE_RESET"
            or executionAssessment.actionOpportunity.action == "STALL_OR_TRADE")
    check("Prediction exposes immediate, engagement, and strategic decision horizons",
        executionAssessment.horizons
            and executionAssessment.horizons.immediate.seconds == 5
            and executionAssessment.horizons.engagement.seconds == 15
            and executionAssessment.horizons.strategic.seconds == 30)
    executionSnapshot.strategy.executionAssessment = executionAssessment
    executionSnapshot.strategy.objectiveDecision = {
        target = "Farm",
        success = "Farm stabilizes.",
        abort = "Farm is unrecoverable.",
    }
    local responseAssignments = {
        {
            guid = "Mover-1", name = "Mover-Realm", shortName = "Mover",
            role = "Strike Team", location = "Blacksmith",
            connected = true, dead = false,
        },
        {
            guid = "Mover-2", name = "Max-Realm", shortName = "Max",
            role = "Strike Team", location = "Blacksmith",
            connected = true, dead = false,
        },
        {
            guid = "Mover-3", name = "Steve-Realm", shortName = "Steve",
            role = "Strike Team", location = "Blacksmith",
            connected = true, dead = false,
        },
        {
            guid = "Mover-4", name = "Bob-Realm", shortName = "Bob",
            role = "Strike Team", location = "Blacksmith",
            connected = true, dead = false,
        },
        {
            guid = "Stay-1", name = "Stay-Realm", shortName = "Stay",
            role = "Node Defender", location = "Farm",
            connected = true, dead = false,
        },
    }
    local responsePackage = KWR.Assignments:ResponsePackage(
        executionSnapshot, responseAssignments)
    check("Response package converts a qualified assessment into movers, stayers, success, and abort",
        responsePackage.qualified == true
            and responsePackage.moverText == "Mover, Max, Steve, Bob"
            and responsePackage.stayerText == "FARM: Stay"
            and responsePackage.success == "Farm stabilizes."
            and responsePackage.abort == "Farm is unrecoverable.")
    executionSnapshot.responsePackage = responsePackage
    local responseCommand = KWR.Commander:Compose(
        executionSnapshot, { status = "LOSE", urgency = 72,
            condition = "Diagnostic pressure.", confidence = "HIGH" },
        responseAssignments)
    check("Commander arbitration publishes a qualified response package through the one command path",
        responseCommand.responsePackage.qualified == true
            and responseCommand.who == "Mover, Max, Steve, Bob"
            and responseCommand.action:find(responsePackage.action, 1, true) ~= nil)
    local spokenCommand = KWR.CommandView:SpokenCall(responseCommand,
        executionSnapshot.context)
    check("Spoken command publishes every named mover without numeric shorthand",
        spokenCommand
            and spokenCommand:find("Mover, Max, Steve, Bob", 1, true) ~= nil
            and spokenCommand:find("+", 1, true) == nil,
        spokenCommand)
    local changeSummary = KWR.Assignments:SummarizeChanges({
        {
            name = "Mover", toRole = "Strike Team",
            toLocation = "Blacksmith",
        },
    }, "ARATHI")
    check("Reassessment summary abbreviates one complete changed assignment",
        changeSummary:find("Mover", 1, true) ~= nil
            and changeSummary:find("STRIKE@BS", 1, true) ~= nil)
    local executionHitsBefore =
        KWR.Strategist:CacheStats().executionHits
    KWR.Strategist:AssessExecution(
        executionSnapshot, { urgency = 72 }, executionAssignments)
    check("Execution assessment reuses unchanged bounded evidence",
        KWR.Strategist:CacheStats().executionHits > executionHitsBefore)

    local recoverySnapshot = KWR.Util:Copy(executionSnapshot)
    recoverySnapshot.reporter.pressure = {
        {
            label = "Blacksmith", owner = "FRIENDLY",
            friendly = 6, enemy = 0, delta = -6, risk = 5,
        },
    }
    recoverySnapshot.reporter.hotspot =
        recoverySnapshot.reporter.pressure[1]
    recoverySnapshot.reporter.etas = {}
    recoverySnapshot.reporter.enemyIntent = {}
    recoverySnapshot.reporter.momentum = {
        value = 55, state = "FRIENDLY", confidence = "MEDIUM",
        friendlyDead = 0, enemyDead = 3, friendlyHealers = 2,
    }
    recoverySnapshot.assignmentIntegrity = {
        rows = { { name = "Defender", status = "ON_STATION" } },
        onStation = 1, moving = 0, unverified = 0,
        abandoned = 0, impossible = 0,
    }
    recoverySnapshot.combat.resourceEconomy.advantage = 40
    local recoveryAssessment = KWR.Strategist:AssessExecution(
        recoverySnapshot, { urgency = 20 }, executionAssignments)
    check("Recovery window opens only from a stable verified advantage",
        recoveryAssessment.recovery.open == true
            and recoveryAssessment.collapse.state == "STABLE")

    KWR.Reporter.sessionKey = oldReporterState.sessionKey
    KWR.Reporter.tracks = oldReporterState.tracks
    KWR.Reporter.events = oldReporterState.events
    KWR.Reporter.memory = oldReporterState.memory
    KWR.Reporter.sequence = oldReporterState.sequence
    KWR.Reporter.lastScore = oldReporterState.lastScore
    KWR.Reporter.hotspotKey = oldReporterState.hotspotKey

    local oldIntegrity = KWR.Assignments.integrity
    local integritySnapshot = fixture("ARATHI",
        { friendly = 500, enemy = 500, max = 1500 },
        { friendly = 2, enemy = 2 })
    integritySnapshot.context.mapID = 529
    integritySnapshot.roster = {
        { guid = "Assigned-1", name = "Assigned-Realm", shortName = "Assigned",
            classFile = "HUNTER", spec = "Marksmanship", role = "DAMAGER",
            location = "Farm", connected = true },
        { guid = "Replacement-1", name = "Replacement-Realm", shortName = "Replacement",
            classFile = "DRUID", spec = "Guardian", role = "TANK",
            location = "Blacksmith", connected = true },
    }
    integritySnapshot.objectives.rows = {
        { label = "Farm", owner = "FRIENDLY", state = "CONTROLLED",
            x = 0.68, y = 0.72 },
        { label = "Blacksmith", owner = "ENEMY", state = "CONTROLLED",
            x = 0.50, y = 0.50 },
    }
    local integrityAssignments = {
        { guid = "Assigned-1", name = "Assigned-Realm", shortName = "Assigned",
            classFile = "HUNTER", spec = "Marksmanship", groupRole = "DAMAGER",
            role = "Node Defender", location = "Blacksmith" },
    }
    KWR.Assignments.integrity = { sessionKey = nil, records = {} }
    KWR.Assignments:Integrity(integritySnapshot, integrityAssignments)
    KWR.Assignments.integrity.records["Assigned-1"].issuedAt =
        KWR.Util:Now() - 25
    local integrityResult = KWR.Assignments:Integrity(
        integritySnapshot, integrityAssignments)
    check("Assignment integrity detects abandonment and recommends a viable replacement",
        integrityResult.abandoned == 1
            and integrityResult.reassignmentRequired == true
            and integrityResult.reassignments[1].replacement == "Replacement")
    check("Assignment contract records timing, evidence, success, and abort conditions",
        integrityResult.rows[1].issuedAt ~= nil
            and integrityResult.rows[1].expectedBy
                > integrityResult.rows[1].issuedAt
            and integrityResult.rows[1].evidenceSource ~= nil
            and integrityResult.rows[1].successCondition ~= nil
            and integrityResult.rows[1].abortCondition ~= nil)
    check("Coverage ledger detects a friendly objective without a named defender",
        integrityResult.uncovered == 1
            and integrityResult.coverageLedger[1].location == "Farm"
            and integrityResult.coverageLedger[1].state == "UNCOVERED")
    KWR.Assignments.integrity = oldIntegrity

    KWR.CombatIntel:Reset()
    KWR.CombatIntel.sessionKey = "ARATHI:live"
    KWR.CombatIntel:ObserveSpell(
        "ResourceEnemy", "ResourceEnemy-Realm", 42292, "SPELL_CAST_SUCCESS")
    local resourceSnapshot = fixture("ARATHI",
        { friendly = 500, enemy = 500, max = 1500 },
        { friendly = 2, enemy = 2 })
    resourceSnapshot.enemies = {
        { guid = "ResourceEnemy", name = "ResourceEnemy-Realm",
            shortName = "ResourceEnemy", classFile = "PRIEST",
            spec = "Discipline", role = "HEALER", visible = true,
            localEngaged = true, healthPercent = 80 },
    }
    local resourceAnalysis = KWR.CombatIntel:Analyze(resourceSnapshot)
    check("Resource economy reports observed enemy exhaustion while leaving friendly unknowns unknown",
        resourceAnalysis.resourceEconomy.coverage == 1
            and resourceAnalysis.resourceEconomy.enemy.trinketsUsed == 1
            and resourceAnalysis.resourceEconomy.friendly.mana == "UNKNOWN")
    KWR.CombatIntel:Reset()
    local localRangeSnapshot = fixture("ARATHI",
        { friendly = 500, enemy = 500, max = 1500 },
        { friendly = 2, enemy = 2 })
    localRangeSnapshot.context.mapID = 529
    localRangeSnapshot.context.instanceID = 3
    localRangeSnapshot.enemies = {
        {
            guid = "RangeEnemy-1", name = "RangeEnemyOne",
            shortName = "RangeEnemyOne", classFile = "PRIEST",
            spec = "Holy", role = "HEALER", visible = true,
            localRange = true, localEngaged = false, healthPercent = 62,
            unit = "target",
        },
        {
            guid = "RangeEnemy-2", name = "RangeEnemyTwo",
            shortName = "RangeEnemyTwo", classFile = "MAGE",
            spec = "Frost", role = "DAMAGER", visible = true,
            localRange = true, localEngaged = false, healthPercent = 88,
            unit = "focus",
        },
    }
    KWR.CombatIntel:ObserveSpell(
        "RangeEnemy-1", "RangeEnemyOne", 42292, "SPELL_CAST_SUCCESS")
    local localRangeAnalysis = KWR.CombatIntel:Analyze(localRangeSnapshot)
    check("Combat intelligence can promote a safely observed local-range target before combat flags appear",
        localRangeAnalysis.killTarget
            and localRangeAnalysis.killTarget.guid == "RangeEnemy-1"
            and localRangeAnalysis.localEnemies == 2,
        localRangeAnalysis.killReason)
    localRangeSnapshot.roster = {
        { guid = "Friendly-1", name = "FriendlyOne", shortName = "FriendlyOne",
            classFile = "WARRIOR", spec = "Arms", role = "DAMAGER",
            x = 0.10, y = 0.10, dead = false },
        { guid = "Friendly-2", name = "FriendlyTwo", shortName = "FriendlyTwo",
            classFile = "PALADIN", spec = "Holy", role = "HEALER",
            x = 0.11, y = 0.10, dead = false },
    }
    localRangeSnapshot.enemies = {
        {
            guid = "SupportedEnemy", name = "SupportedEnemy",
            shortName = "SupportedEnemy", classFile = "MAGE",
            spec = "Frost", role = "DAMAGER", visible = true,
            localRange = true, localEngaged = true, healthPercent = 42,
            x = 0.50, y = 0.50,
        },
        {
            guid = "SupportedHealer", name = "SupportedHealer",
            shortName = "SupportedHealer", classFile = "PRIEST",
            spec = "Holy", role = "HEALER", visible = true,
            localRange = false, localEngaged = false, healthPercent = 88,
            x = 0.53, y = 0.50,
        },
        {
            guid = "IsolatedEnemy", name = "IsolatedEnemy",
            shortName = "IsolatedEnemy", classFile = "WARLOCK",
            spec = "Affliction", role = "DAMAGER", visible = true,
            localRange = true, localEngaged = true, healthPercent = 52,
            x = 0.10, y = 0.10,
        },
    }
    local isolationAnalysis = KWR.CombatIntel:Analyze(localRangeSnapshot)
    check("Combat intelligence prefers the isolated actionable target over the similarly pressured supported target",
        isolationAnalysis.killTarget
            and isolationAnalysis.killTarget.guid == "IsolatedEnemy",
        isolationAnalysis.killReason)
    localRangeSnapshot.enemies[3].dead = true
    local nextTargetAnalysis = KWR.CombatIntel:Analyze(localRangeSnapshot)
    check("Combat intelligence promotes the next best actionable target when the current kill target dies",
        nextTargetAnalysis.killTarget
            and nextTargetAnalysis.killTarget.guid == "SupportedEnemy",
        nextTargetAnalysis.killReason)
    KWR.CombatIntel:Reset()
    local protectedSnapshot = fixture("ARATHI",
        { friendly = 500, enemy = 500, max = 1500 },
        { friendly = 2, enemy = 2 })
    protectedSnapshot.context.mapID = 529
    protectedSnapshot.context.instanceID = 3
    KWR.CombatIntel.sessionKey =
        KWR.Util:BattlefieldSessionKey(protectedSnapshot.context)
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
    check("Retail 12.1 patch data remains fail-closed pending review",
        KWR.PatchData:Validate(120100) == false)
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
