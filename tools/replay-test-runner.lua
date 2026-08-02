-- Deterministic offline replay runner for KWR developer-side replay fixtures.
-- This runner bootstraps the actual addon modules through tests/smoke.lua,
-- loads a sanitized replay JSON fixture, builds production-shaped snapshots,
-- executes the real planner stack, and emits timeline decision summaries.

local function loadSmokeBootstrap()
    _G.KWR_SMOKE_BOOTSTRAP_ONLY = true
    local chunk, message = loadfile("tests/smoke.lua")
    assert(chunk, tostring(message))
    local bootstrap = chunk()
    _G.KWR_SMOKE_BOOTSTRAP_ONLY = nil
    assert(type(bootstrap) == "table" and type(bootstrap.KWR) == "table",
        "Smoke bootstrap did not return a KWR runtime.")
    return bootstrap
end

local function decodeJson(text)
    local index = 1
    local length = #text

    local function fail(message)
        error(string.format("JSON parse error at byte %d: %s", index, message))
    end

    local function peek()
        return text:sub(index, index)
    end

    local function nextChar()
        local ch = text:sub(index, index)
        index = index + 1
        return ch
    end

    local function skipWhitespace()
        while index <= length do
            local ch = peek()
            if ch == " " or ch == "\n" or ch == "\r" or ch == "\t" then
                index = index + 1
            else
                return
            end
        end
    end

    local parseValue

    local function parseString()
        if nextChar() ~= "\"" then fail("expected string") end
        local buffer = {}
        while index <= length do
            local ch = nextChar()
            if ch == "\"" then
                return table.concat(buffer)
            end
            if ch == "\\" then
                local esc = nextChar()
                if esc == "\"" or esc == "\\" or esc == "/" then
                    buffer[#buffer + 1] = esc
                elseif esc == "b" then
                    buffer[#buffer + 1] = "\b"
                elseif esc == "f" then
                    buffer[#buffer + 1] = "\f"
                elseif esc == "n" then
                    buffer[#buffer + 1] = "\n"
                elseif esc == "r" then
                    buffer[#buffer + 1] = "\r"
                elseif esc == "t" then
                    buffer[#buffer + 1] = "\t"
                elseif esc == "u" then
                    local hex = text:sub(index, index + 3)
                    if not hex:match("^[0-9a-fA-F]+$") then
                        fail("invalid unicode escape")
                    end
                    index = index + 4
                    local code = tonumber(hex, 16)
                    if code < 128 then
                        buffer[#buffer + 1] = string.char(code)
                    else
                        buffer[#buffer + 1] = "?"
                    end
                else
                    fail("invalid escape sequence")
                end
            else
                buffer[#buffer + 1] = ch
            end
        end
        fail("unterminated string")
    end

    local function parseNumber()
        local start = index
        if peek() == "-" then index = index + 1 end
        if peek():match("%d") then
            if peek() == "0" then
                index = index + 1
            else
                while index <= length and peek():match("%d") do
                    index = index + 1
                end
            end
        else
            fail("invalid number")
        end
        if peek() == "." then
            index = index + 1
            if not peek():match("%d") then fail("invalid fraction") end
            while index <= length and peek():match("%d") do
                index = index + 1
            end
        end
        local ch = peek()
        if ch == "e" or ch == "E" then
            index = index + 1
            ch = peek()
            if ch == "+" or ch == "-" then index = index + 1 end
            if not peek():match("%d") then fail("invalid exponent") end
            while index <= length and peek():match("%d") do
                index = index + 1
            end
        end
        local value = tonumber(text:sub(start, index - 1))
        if value == nil then fail("invalid numeric token") end
        return value
    end

    local function parseArray()
        if nextChar() ~= "[" then fail("expected array") end
        skipWhitespace()
        local result = {}
        if peek() == "]" then
            index = index + 1
            return result
        end
        while true do
            result[#result + 1] = parseValue()
            skipWhitespace()
            local ch = nextChar()
            if ch == "]" then
                return result
            end
            if ch ~= "," then
                fail("expected ',' or ']' in array")
            end
            skipWhitespace()
        end
    end

    local function parseObject()
        if nextChar() ~= "{" then fail("expected object") end
        skipWhitespace()
        local result = {}
        if peek() == "}" then
            index = index + 1
            return result
        end
        while true do
            if peek() ~= "\"" then fail("expected object key") end
            local key = parseString()
            skipWhitespace()
            if nextChar() ~= ":" then fail("expected ':' after key") end
            skipWhitespace()
            result[key] = parseValue()
            skipWhitespace()
            local ch = nextChar()
            if ch == "}" then
                return result
            end
            if ch ~= "," then
                fail("expected ',' or '}' in object")
            end
            skipWhitespace()
        end
    end

    local function parseLiteral(token, value)
        if text:sub(index, index + #token - 1) ~= token then
            fail("expected " .. token)
        end
        index = index + #token
        return value
    end

    function parseValue()
        skipWhitespace()
        local ch = peek()
        if ch == "\"" then return parseString() end
        if ch == "{" then return parseObject() end
        if ch == "[" then return parseArray() end
        if ch == "-" or ch:match("%d") then return parseNumber() end
        if ch == "t" then return parseLiteral("true", true) end
        if ch == "f" then return parseLiteral("false", false) end
        if ch == "n" then return parseLiteral("null", nil) end
        fail("unexpected token")
    end

    local value = parseValue()
    skipWhitespace()
    if index <= length then
        fail("trailing content")
    end
    return value
end

local function encodeJson(value)
    local valueType = type(value)
    if valueType == "nil" then return "null" end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then return tostring(value) end
    if valueType == "string" then
        local escaped = value
            :gsub("\\", "\\\\")
            :gsub("\"", "\\\"")
            :gsub("\b", "\\b")
            :gsub("\f", "\\f")
            :gsub("\n", "\\n")
            :gsub("\r", "\\r")
            :gsub("\t", "\\t")
        return "\"" .. escaped .. "\""
    end
    if valueType ~= "table" then
        error("Cannot encode JSON type: " .. valueType)
    end
    local isArray = true
    local count = 0
    for key in pairs(value) do
        count = count + 1
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            isArray = false
            break
        end
    end
    if isArray then
        for index = 1, count do
            if value[index] == nil then
                isArray = false
                break
            end
        end
    end
    if isArray then
        local parts = {}
        for index = 1, count do
            parts[#parts + 1] = encodeJson(value[index])
        end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = encodeJson(key) .. ":" .. encodeJson(value[key])
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function writeText(path, text)
    if type(io) == "table" and type(io.open) == "function" then
        local handle, message = io.open(path, "wb")
        assert(handle, tostring(message))
        handle:write(text)
        handle:close()
        return
    end
    local outputPath = type(os) == "table" and type(os.getenv) == "function"
        and os.getenv("KWR_REPLAY_OUTPUT_PATH") or nil
    if outputPath == path then
        print("KWR_REPLAY_JSON_OUT " .. text)
        return
    end
    error("Replay runtime cannot write files and no output bridge was configured.")
end

local function readJson(path)
    local text
    if type(io) == "table" and type(io.open) == "function" then
        local handle, message = io.open(path, "rb")
        assert(handle, tostring(message))
        text = handle:read("*a")
        handle:close()
    elseif type(os) == "table" and type(os.getenv) == "function" then
        if os.getenv("KWR_REPLAY_INPUT_PATH") == path then
            text = os.getenv("KWR_REPLAY_INPUT_JSON")
        elseif os.getenv("KWR_REPLAY_LABEL_PATH") == path then
            text = os.getenv("KWR_REPLAY_LABEL_JSON")
        end
    end
    assert(type(text) == "string" and text ~= "",
        "Replay runtime cannot read " .. tostring(path)
            .. " and no matching input bridge was configured.")
    return decodeJson(text)
end

local function deepMerge(target, patch)
    if type(target) ~= "table" or type(patch) ~= "table" then
        return patch
    end
    for key, value in pairs(patch) do
        if type(value) == "table" and type(target[key]) == "table" then
            target[key] = deepMerge(target[key], value)
        else
            target[key] = value
        end
    end
    return target
end

local function listToSet(values)
    local set = {}
    for _, value in ipairs(values or {}) do
        set[tostring(value)] = true
    end
    return set
end

local function normalizeToken(value)
    value = tostring(value or "UNKNOWN"):upper()
    value = value:gsub("[^A-Z0-9]+", "_")
    value = value:gsub("_+", "_")
    value = value:gsub("^_", ""):gsub("_$", "")
    return value ~= "" and value or "UNKNOWN"
end

local function canonicalFaction(side)
    local upper = normalizeToken(side)
    if upper == "HORDE" then return "Horde", "right", 1 end
    return "Alliance", "left", 0
end

local function replayPlayerRows(rows, prefix)
    local result = {}
    for index, row in ipairs(rows or {}) do
        local slot = tostring(row.slot or (prefix .. "_" .. tostring(index)))
        result[#result + 1] = {
            name = slot,
            shortName = slot,
            guid = prefix .. ":" .. slot,
            class = row.class or "Unknown",
            spec = row.spec or "Unknown",
            role = row.role or "DAMAGER",
            connected = true,
            dead = false,
        }
    end
    return result
end

local function carrierRows(initialState, mapKind)
    local carriers = {}
    local objectives = initialState and initialState.objectives or {}
    if objectives.friendlyCarrier then
        carriers[#carriers + 1] = {
            player = objectives.friendlyCarrier,
            owner = "FRIENDLY",
            kind = mapKind,
            objective = "Friendly Carrier",
            visible = true,
        }
    end
    if objectives.enemyCarrier then
        carriers[#carriers + 1] = {
            player = objectives.enemyCarrier,
            owner = "ENEMY",
            kind = mapKind,
            objective = "Enemy Carrier",
            visible = true,
        }
    end
    return carriers
end

local function mapScoreMax(replay, mapDefinition)
    if replay.initialState and replay.initialState.score
        and replay.initialState.score.max then
        return replay.initialState.score.max
    end
    if replay.map and replay.map.kind == "FLAG" then
        return 3
    end
    return mapDefinition and mapDefinition.maxScore or 1500
end

local function buildBaseSnapshot(KWR, replay, now)
    local mapKey = replay.map and replay.map.key or "UNKNOWN"
    local mapDefinition = KWR.Maps and KWR.Maps:Get(mapKey) or nil
    local faction, side, scoreFaction = canonicalFaction(replay.side)
    local initialState = replay.initialState or {}
    local score = initialState.score or {}
    return {
        capturedAt = now,
        context = {
            inPvP = true,
            preview = false,
            mapKey = mapKey,
            mapName = mapDefinition and mapDefinition.name or mapKey,
            kind = replay.map and replay.map.kind or (mapDefinition and mapDefinition.kind) or "WORLD",
            instanceType = "pvp",
            phase = "LIVE",
            isBlitz = replay.ruleset and replay.ruleset.bracket == "BLITZ",
            team = {
                faction = faction,
                side = side,
                source = "replay_fixture",
                votes = 1,
                scoreFaction = scoreFaction,
            },
            capturedAt = now,
        },
        score = {
            friendly = score.friendly or 0,
            enemy = score.enemy or 0,
            max = mapScoreMax(replay, mapDefinition),
            source = "ui_widget",
            observedAt = now,
            changedAt = now,
            lastCapture = score.lastCapture,
        },
        objectives = {
            carriers = carrierRows(initialState, replay.map and replay.map.kind or "OBJECTIVE"),
            source = "ui_widget",
            observedAt = now,
            friendly = initialState.objectives and initialState.objectives.friendly or 0,
            enemy = initialState.objectives and initialState.objectives.enemy or 0,
            friendlyIncoming = initialState.objectives and initialState.objectives.friendlyIncoming or 0,
            enemyIncoming = initialState.objectives and initialState.objectives.enemyIncoming or 0,
            rows = initialState.objectives and initialState.objectives.rows or {},
        },
        roster = replayPlayerRows(initialState.friendlyRoster, "Friendly"),
        enemies = replayPlayerRows(initialState.enemyRoster, "Enemy"),
        reporter = {
            active = false,
            updatedAt = now,
            coverage = {
                friendly = 0,
                enemy = 0,
                friendlyLocated = 0,
                enemyLocated = 0,
            },
        },
        combat = {},
    }
end

local function setCarrierState(snapshot, owner, active, mapKind)
    local carriers = {}
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.carriers or {}) do
        if row.owner ~= owner then
            carriers[#carriers + 1] = row
        end
    end
    local initial = owner == "FRIENDLY" and "Friendly Carrier" or "Enemy Carrier"
    local slot = owner == "FRIENDLY"
        and "friendly_carrier" or "enemy_carrier"
    if active == true then
        carriers[#carriers + 1] = {
            player = slot,
            owner = owner,
            kind = mapKind,
            objective = initial,
            visible = true,
        }
    end
    snapshot.objectives.carriers = carriers
end

local function applyReplayFacts(snapshot, facts, replay, now, KWR)
    facts = type(facts) == "table" and facts or {}
    snapshot.capturedAt = now
    snapshot.context.capturedAt = now
    snapshot.score.observedAt = now
    snapshot.score.changedAt = now
    snapshot.objectives.observedAt = now

    if facts.snapshotPatch then
        deepMerge(snapshot, facts.snapshotPatch)
    end
    if facts.friendlyScore ~= nil then
        snapshot.score.friendly = facts.friendlyScore
    end
    if facts.enemyScore ~= nil then
        snapshot.score.enemy = facts.enemyScore
    end
    if facts.result then
        snapshot.context.matchComplete = true
        snapshot.context.phase = "COMPLETE"
    end
    if facts.friendlyCarrierActive ~= nil then
        setCarrierState(snapshot, "FRIENDLY", facts.friendlyCarrierActive == true,
            replay.map and replay.map.kind or "OBJECTIVE")
    end
    if facts.enemyCarrierActive ~= nil then
        setCarrierState(snapshot, "ENEMY", facts.enemyCarrierActive == true,
            replay.map and replay.map.kind or "OBJECTIVE")
    end
    if facts.objective then
        snapshot.reporter = snapshot.reporter or {}
        snapshot.reporter.enemyIntent = {
            target = facts.objective,
            confidence = facts.pressure or "MEDIUM",
            eta = facts.etaSeconds or nil,
        }
        snapshot.reporter.updatedAt = now
    end
    if facts.friendlyObjectives ~= nil then
        snapshot.objectives.friendly = facts.friendlyObjectives
    end
    if facts.enemyObjectives ~= nil then
        snapshot.objectives.enemy = facts.enemyObjectives
    end
    if facts.friendlyIncoming ~= nil then
        snapshot.objectives.friendlyIncoming = facts.friendlyIncoming
    end
    if facts.enemyIncoming ~= nil then
        snapshot.objectives.enemyIncoming = facts.enemyIncoming
    end

    if KWR and KWR.Util then
        snapshot = KWR.Util:Copy(snapshot)
    end
    return snapshot
end

local function deriveDecisionTags(KWR, state)
    local tags = {}
    local seen = {}
    local fightNow = KWR.CommandView:FightNow(state)
    local function add(tag)
        tag = normalizeToken(tag)
        if not seen[tag] then
            seen[tag] = true
            tags[#tags + 1] = tag
        end
    end

    add("PLAN:" .. normalizeToken(state.command and state.command.planID or "NONE"))
    add("CALL:" .. normalizeToken(fightNow.current and fightNow.current.what or "NONE"))
    add("WHERE:" .. normalizeToken(fightNow.current and fightNow.current.where or "FIELD"))
    add("NEXT:" .. normalizeToken(fightNow.next and fightNow.next.where or "FIELD"))
    add("WINPATH:" .. normalizeToken(fightNow.winPath or "UNKNOWN"))
    if state.command and state.command.responsePackage and state.command.responsePackage.actionID then
        add("RESPONSE:" .. normalizeToken(state.command.responsePackage.actionID))
    end
    if state.snapshot and state.snapshot.strategy and state.snapshot.strategy.objectiveDecision
        and state.snapshot.strategy.objectiveDecision.target then
        local where = KWR.Maps:AbbreviateLocation(
            state.snapshot.context.mapKey,
            state.snapshot.strategy.objectiveDecision.target)
        add("TARGET:" .. normalizeToken(where))
    end
    for _, problem in ipairs(state.snapshot and state.snapshot.teamfight
        and state.snapshot.teamfight.problems or {}) do
        add("PROBLEM:" .. normalizeToken(problem.type))
    end
    return tags, fightNow
end

local function evaluateSnapshot(KWR, snapshot)
    local working = KWR.Util:Copy(snapshot)
    if KWR.KnowledgeManifest and KWR.KnowledgeManifest.Status then
        working.knowledgeStatus = KWR.KnowledgeManifest:Status(working)
    end
    working.combat = KWR.CombatIntel:Analyze(working)
    working.teamfight = KWR.TeamfightCommandPlanner:Plan(working)
    working.reporter = KWR.Reporter:Observe(working)
    local prediction = KWR.Predictor:Evaluate(working)
    working.strategy = KWR.Strategist:Evaluate(working, prediction)
    local assignments = KWR.Assignments:Build(working, prediction)
    working.assignmentIntegrity = KWR.Assignments:Integrity(working, assignments)
    working.strategy.executionAssessment =
        KWR.Strategist:AssessExecution(working, prediction, assignments)
    working.responsePackage = KWR.Assignments:ResponsePackage(working, assignments)
    local command = KWR.Commander:Compose(working, prediction, assignments)
    working.executionCommand = KWR.ExecutionCommandBuilder:Build(
        working, prediction, assignments, command)
    local state = {
        snapshot = working,
        prediction = prediction,
        assignments = assignments,
        command = command,
        activePlay = command.activePlay,
    }
    local tags, fightNow = deriveDecisionTags(KWR, state)
    return state, {
        tags = tags,
        fightNow = fightNow,
        summary = { KWR.CommandView:SummaryLines(state) },
    }
end

local function evaluateExpected(observedTags, expected)
    expected = expected or {}
    local observed = listToSet(observedTags or {})
    local forbiddenHits = {}
    local primaryMatch = false
    local fallbackMatch = false
    local primaryActions =
        expected.primaryActions or expected.acceptablePrimaryActions or {}
    local fallbackActions =
        expected.fallbackActions or expected.acceptableFallbackActions or {}
    for _, tag in ipairs(primaryActions) do
        if observed[normalizeToken(tag)] then
            primaryMatch = true
        end
    end
    for _, tag in ipairs(fallbackActions) do
        if observed[normalizeToken(tag)] then
            fallbackMatch = true
        end
    end
    for _, tag in ipairs(expected.forbiddenActions or {}) do
        local normalized = normalizeToken(tag)
        if observed[normalized] then
            forbiddenHits[#forbiddenHits + 1] = normalized
        end
    end
    return {
        primaryMatch = primaryMatch,
        fallbackMatch = fallbackMatch,
        forbiddenHits = forbiddenHits,
    }
end

local function parseArgs(argv)
    local config = {
        replayPath = "tests/replays/twin_peaks_recovery_sample.json",
        strict = false,
    }
    local index = 1
    while index <= #(argv or {}) do
        local value = argv[index]
        if value == "--check" or value == "--strict" then
            config.strict = true
        elseif value == "--label" then
            index = index + 1
            config.labelPath = argv[index]
        elseif value == "--json-out" then
            index = index + 1
            config.jsonOutPath = argv[index]
        else
            config.replayPath = value
        end
        index = index + 1
    end
    return config
end

local function printCheckpoint(replayId, eventIndex, eventName, at, state, report)
    print(string.format(
        "KWR_REPLAY_STEP replay=%s step=%d t=%s event=%s plan=%s status=%s action=%s where=%s tags=%s",
        replayId,
        eventIndex,
        tostring(at),
        tostring(eventName),
        tostring(state.command and state.command.planID or "NONE"),
        tostring(state.prediction and state.prediction.status or "WAITING"),
        tostring(report.fightNow and report.fightNow.current and report.fightNow.current.what or "NONE"),
        tostring(report.fightNow and report.fightNow.current and report.fightNow.current.where or "FIELD"),
        table.concat(report.tags, ",")
    ))
end

local function main(argv)
    local config = parseArgs(argv or {})
    local bootstrap = loadSmokeBootstrap()
    local KWR = bootstrap.KWR
    bootstrap.resetCommander()

    local replay = readJson(config.replayPath)
    assert(type(replay) == "table", "Replay fixture did not decode to a table.")
    local label = config.labelPath and readJson(config.labelPath) or nil

    local baseTime = bootstrap.now()
    local snapshot = buildBaseSnapshot(KWR, replay, baseTime)
    local latestState
    local latestReport
    local replayId = replay.replayId or "unknown-replay"
    local checkpoints = {}

    for index, event in ipairs(replay.timeline or {}) do
        local eventTime = baseTime + (tonumber(event.t) or 0)
        bootstrap.setTime(eventTime)
        snapshot = applyReplayFacts(snapshot, event.facts, replay, eventTime, KWR)
        latestState, latestReport = evaluateSnapshot(KWR, snapshot)
        checkpoints[#checkpoints + 1] = {
            step = index,
            at = event.t or 0,
            event = event.event or "unknown",
            planID = latestState.command and latestState.command.planID or "NONE",
            status = latestState.prediction and latestState.prediction.status or "WAITING",
            current = latestReport.fightNow and latestReport.fightNow.current or {},
            next = latestReport.fightNow and latestReport.fightNow.next or {},
            tags = latestReport.tags,
        }
        printCheckpoint(replayId, index, event.event or "unknown", event.t or 0,
            latestState, latestReport)
    end

    assert(latestState ~= nil and latestReport ~= nil,
        "Replay produced no evaluated checkpoints.")

    local expected = label and label.decision or replay.expectedLabels
    local evaluation = evaluateExpected(latestReport.tags, expected)
    print("KWR_REPLAY_FINAL replay=" .. replayId)
    for _, line in ipairs(latestReport.summary or {}) do
        print("  " .. tostring(line))
    end
    print("  TAGS: " .. table.concat(latestReport.tags, ", "))
    print("  PRIMARY_MATCH: " .. tostring(evaluation.primaryMatch))
    print("  FALLBACK_MATCH: " .. tostring(evaluation.fallbackMatch))
    print("  FORBIDDEN_HITS: " .. (#evaluation.forbiddenHits > 0
        and table.concat(evaluation.forbiddenHits, ", ")
        or "NONE"))

    if #evaluation.forbiddenHits > 0 then
        error("Replay emitted forbidden decision tags.")
    end
    if config.strict and not (evaluation.primaryMatch or evaluation.fallbackMatch) then
        error("Replay did not match any acceptable primary or fallback decision tag.")
    end
    if config.jsonOutPath and config.jsonOutPath ~= "" then
        writeText(config.jsonOutPath, encodeJson({
            schema = "kwr-replay-run-result",
            schemaVersion = 1,
            replayId = replayId,
            replayPath = config.replayPath,
            labelPath = config.labelPath,
            strict = config.strict == true,
            final = {
                planID = latestState.command and latestState.command.planID or "NONE",
                status = latestState.prediction and latestState.prediction.status or "WAITING",
                tags = latestReport.tags,
                summary = latestReport.summary,
            },
            evaluation = evaluation,
            checkpoints = checkpoints,
        }))
    end
    print("KWR_REPLAY_RUN_PASS")
end

main(arg or {})
