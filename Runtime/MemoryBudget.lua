local _, KWR = ...

local MemoryBudget = {
    softCapMB = 25,
    warningCapMB = 28,
    hardCapMB = 32,
    checkEveryRevisions = 20,
    lastTrimRevision = 0,
    lastTrimAt = 0,
    lastMeasuredMB = 0,
    lastPressure = "NONE",
    boundContracts = {},
    retention = {
        aarHistory = 8,
        aarCommands = 18,
        aarEvents = 32,
        aarObjectiveTimeline = 48,
        aarDecisionReviews = 12,
        aarPlayerLocations = 8,
        aarPlayerNotes = 6,
        encounterPlayers = 240,
        opponentProfiles = 240,
        opponentProcessedMatches = 120,
        enemyNotes = 320,
        learningBuckets = 120,
        verificationLedger = 60,
        commandHistory = 16,
        objectiveEvents = 24,
        runtimeDurationSamples = 120,
        reporterPoints = 8,
        reporterEvents = 20,
        reporterExportPoints = 4,
    },
    contracts = {
        persistent = {
            {
                key = "AAR",
                label = "AAR review history",
                priority = "P1 Review Truth",
                purpose = "Keep reviewed battleground evidence and compact command history.",
                caps = {
                    maxHistory = "aarHistory",
                    maxCommands = "aarCommands",
                    maxEvents = "aarEvents",
                    maxObjectiveTimeline = "aarObjectiveTimeline",
                    maxDecisionReviews = "aarDecisionReviews",
                    maxPlayerLocations = "aarPlayerLocations",
                    maxPlayerNotes = "aarPlayerNotes",
                },
                prune = {
                    { module = "AAR", method = "TrimHistory" },
                },
            },
            {
                key = "EncounterHistory",
                label = "Encounter history",
                priority = "P2 Player Memory",
                purpose = "Keep lightweight per-player encounter context.",
                caps = {
                    maxPlayers = "encounterPlayers",
                },
                prune = {
                    { module = "EncounterHistory", method = "Prune" },
                },
            },
            {
                key = "OpponentModels",
                label = "Opponent models",
                priority = "P2 Player Memory",
                purpose = "Keep bounded opponent tendencies and processed-match tokens.",
                caps = {
                    maxProfiles = "opponentProfiles",
                    maxProcessedMatches = "opponentProcessedMatches",
                },
                prune = {
                    { module = "OpponentModels", method = "Prune" },
                    { module = "OpponentModels", method = "PruneProcessedMatches" },
                },
            },
            {
                key = "EnemyIntel",
                label = "Enemy notes",
                priority = "P2 Tactical Memory",
                purpose = "Keep bounded enemy field notes with direct tactical value.",
                caps = {
                    maxNotes = "enemyNotes",
                },
                prune = {
                    { module = "EnemyIntel", method = "PruneNotes" },
                },
            },
            {
                key = "Learning",
                label = "Learning buckets",
                priority = "P3 Doctrine Learning",
                purpose = "Keep bounded plan-learning outcomes for reviewed matches.",
                caps = {
                    maxBuckets = "learningBuckets",
                },
                prune = {
                    { module = "Learning", method = "Prune" },
                },
            },
            {
                key = "Verification",
                label = "Verification ledger",
                priority = "P1 Review Truth",
                purpose = "Keep bounded live verification evidence for field debugging.",
                caps = {
                    maxEntries = "verificationLedger",
                },
                prune = {},
            },
        },
        live = {
            {
                key = "CommanderHistory",
                label = "Commander history",
                priority = "L1 Live Explainability",
                purpose = "Keep short recent command transitions for UI and review context.",
                caps = {
                    maxHistory = "commandHistory",
                },
            },
            {
                key = "ObjectiveIntel",
                label = "Objective events",
                priority = "L1 Live Objective Truth",
                purpose = "Keep recent battleground system objective events.",
                caps = {
                    maxEvents = "objectiveEvents",
                },
            },
            {
                key = "Reporter",
                label = "Reporter movement cache",
                priority = "L1 Live Battlefield Awareness",
                purpose = "Keep short path traces and event bursts for the reporter.",
                caps = {
                    maxPoints = "reporterPoints",
                    maxEvents = "reporterEvents",
                    exportPoints = "reporterExportPoints",
                },
            },
            {
                key = "RuntimeDiagnostics",
                label = "Runtime duration samples",
                priority = "L2 Runtime Telemetry",
                purpose = "Keep bounded refresh timing samples for performance tracking.",
                caps = {
                    maxDurationSamples = "runtimeDurationSamples",
                },
            },
        },
    },
}
KWR.MemoryBudget = MemoryBudget

local function now()
    return KWR.Util:Now()
end

local function countKeys(bucket)
    local count = 0
    for _ in pairs(bucket or {}) do count = count + 1 end
    return count
end

local function listCount(rows)
    return #(rows or {})
end

function MemoryBudget:MeasureMB()
    if type(UpdateAddOnMemoryUsage) ~= "function"
        or type(GetAddOnMemoryUsage) ~= "function" then
        return nil
    end
    if not (InCombatLockdown and InCombatLockdown()) then
        KWR.Util:Call(UpdateAddOnMemoryUsage)
    end
    local kb = KWR.Util:Number(KWR.Util:Call(GetAddOnMemoryUsage, KWR.name), nil)
    return kb and (kb / 1024) or nil
end

function MemoryBudget:Retention()
    return self.retention
end

function MemoryBudget:Cap(key, fallback)
    local value = self.retention and self.retention[key]
    if value == nil then
        return fallback
    end
    return value
end

function MemoryBudget:ApplyCaps(owner, mapping)
    if type(owner) ~= "table" or type(mapping) ~= "table" then
        return owner
    end
    for field, key in pairs(mapping) do
        owner[field] = self:Cap(key, owner[field])
    end
    return owner
end

function MemoryBudget:Contract(key)
    for _, group in pairs(self.contracts or {}) do
        for _, contract in ipairs(group or {}) do
            if contract.key == key then
                return contract
            end
        end
    end
end

function MemoryBudget:Bind(owner, contractKey)
    local contract = self:Contract(contractKey)
    if not contract then
        return owner
    end
    self.boundContracts[contractKey] = owner
    return self:ApplyCaps(owner, contract.caps)
end

function MemoryBudget:InvokePrune(contract)
    for _, action in ipairs(contract and contract.prune or {}) do
        local module = KWR[action.module]
        local method = module and action.method and module[action.method]
        if type(method) == "function" then
            method(module)
        end
    end
end

function MemoryBudget:ContractCount(contractKey)
    local db = KWR.db or {}
    if contractKey == "AAR" then
        return listCount(db.journal and db.journal.history)
    elseif contractKey == "EncounterHistory" then
        return countKeys(db.encounters and db.encounters.players)
    elseif contractKey == "OpponentModels" then
        return countKeys(db.opponentModels and db.opponentModels.players)
    elseif contractKey == "EnemyIntel" then
        return countKeys(db.enemyNotes)
    elseif contractKey == "Learning" then
        return countKeys(db.learning and db.learning.plans)
    elseif contractKey == "Verification" then
        return listCount(KWR.Verification and KWR.Verification.ledger)
    elseif contractKey == "CommanderHistory" then
        return listCount(KWR.Commander and KWR.Commander:GetHistory())
    elseif contractKey == "ObjectiveIntel" then
        return listCount(KWR.ObjectiveIntel and KWR.ObjectiveIntel.events)
    elseif contractKey == "Reporter" then
        local coverage = 0
        local reporter = KWR.Reporter
        if reporter then
            coverage = coverage + listCount(reporter.events)
            for _, track in pairs(reporter.tracks or {}) do
                coverage = coverage + listCount(track and track.points)
            end
        end
        return coverage
    elseif contractKey == "RuntimeDiagnostics" then
        return listCount(KWR.MatchRuntime and KWR.MatchRuntime.durationSamples)
    end
    return 0
end

function MemoryBudget:ContractCapSummary(contract)
    local caps = {}
    for field, key in pairs(contract and contract.caps or {}) do
        caps[#caps + 1] = {
            field = field,
            key = key,
            cap = self:Cap(key, nil),
        }
    end
    table.sort(caps, function(a, b) return a.field < b.field end)
    return caps
end

function MemoryBudget:ContractSummary()
    local rows = {}
    for groupName, contracts in pairs(self.contracts or {}) do
        for _, contract in ipairs(contracts or {}) do
            rows[#rows + 1] = {
                key = contract.key,
                group = groupName,
                label = contract.label,
                priority = contract.priority,
                purpose = contract.purpose,
                count = self:ContractCount(contract.key),
                caps = self:ContractCapSummary(contract),
            }
        end
    end
    table.sort(rows, function(a, b)
        if a.group ~= b.group then return a.group < b.group end
        return a.key < b.key
    end)
    return rows
end

function MemoryBudget:TrimPersistent()
    for _, contract in ipairs(self.contracts.persistent or {}) do
        self:InvokePrune(contract)
    end
end

function MemoryBudget:TrimLive(state)
    for _, contract in ipairs(self.contracts.live or {}) do
        self:ApplyCaps(self.boundContracts[contract.key], contract.caps)
        self:InvokePrune(contract)
    end
    local inPvP = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    if not inPvP then
        if KWR.Reporter and KWR.Reporter.Reset then KWR.Reporter:Reset(nil) end
        if KWR.EnemyIntel and KWR.EnemyIntel.Reset then KWR.EnemyIntel:Reset(nil) end
        if KWR.ObjectiveIntel and KWR.ObjectiveIntel.Reset then
            KWR.ObjectiveIntel:Reset(nil)
        end
    elseif KWR.ObjectiveIntel and type(KWR.ObjectiveIntel.auraCache) == "table" then
        KWR.ObjectiveIntel.auraCache = {}
    end
    if KWR.Strategist then
        KWR.Strategist.cache = nil
        KWR.Strategist.executionCache = nil
    end
    if type(collectgarbage) == "function"
        and not (InCombatLockdown and InCombatLockdown()) then
        KWR.Util:Call(collectgarbage, "collect")
    end
end

function MemoryBudget:Trim(state, force)
    local revision = state and state.revision or 0
    local currentNow = now()
    if not force then
        if revision == self.lastTrimRevision then return end
        if (currentNow - (self.lastTrimAt or 0)) < 3 then return end
    end
    self.lastTrimRevision = revision
    self.lastTrimAt = currentNow
    self:TrimPersistent()
    self:TrimLive(state)
end

function MemoryBudget:PressureLevel(mb)
    mb = KWR.Util:Number(mb, nil)
    if not mb then return "NONE" end
    if mb >= (self.hardCapMB or 32) then return "FAIL" end
    if mb >= (self.warningCapMB or 28) then return "WARNING" end
    if mb >= (self.softCapMB or 25) then return "SOFT" end
    return "OK"
end

function MemoryBudget:Summary()
    local db = KWR.db or {}
    local currentMB = self:MeasureMB()
    return {
        softCapMB = self.softCapMB,
        warningCapMB = self.warningCapMB,
        hardCapMB = self.hardCapMB,
        currentMB = currentMB,
        pressure = self:PressureLevel(currentMB),
        history = {
            count = #(db.journal and db.journal.history or {}),
            cap = self:Cap("aarHistory", 8),
        },
        encounters = {
            count = countKeys(db.encounters and db.encounters.players),
            cap = self:Cap("encounterPlayers", 240),
        },
        opponentProfiles = {
            count = countKeys(db.opponentModels and db.opponentModels.players),
            cap = self:Cap("opponentProfiles", 240),
        },
        processedMatches = {
            count = countKeys(db.opponentModels and db.opponentModels.processedMatches),
            cap = self:Cap("opponentProcessedMatches", 120),
        },
        enemyNotes = {
            count = countKeys(db.enemyNotes),
            cap = self:Cap("enemyNotes", 320),
        },
        learningPlans = {
            count = countKeys(db.learning and db.learning.plans),
            cap = self:Cap("learningBuckets", 120),
        },
        verificationLedger = {
            count = #(KWR.Verification and KWR.Verification.ledger or {}),
            cap = self:Cap("verificationLedger", 60),
        },
        commandHistory = {
            count = #(KWR.Commander and KWR.Commander:GetHistory() or {}),
            cap = self:Cap("commandHistory", 16),
        },
        objectiveEvents = {
            count = #(KWR.ObjectiveIntel and KWR.ObjectiveIntel.events or {}),
            cap = self:Cap("objectiveEvents", 24),
        },
        runtimeDurations = {
            count = #(KWR.MatchRuntime and KWR.MatchRuntime.durationSamples or {}),
            cap = self:Cap("runtimeDurationSamples", 120),
        },
        contracts = self:ContractSummary(),
    }
end

function MemoryBudget:Report()
    local summary = self:Summary()
    local lines = {
        string.format("Memory target: %.1f MB", summary.softCapMB or 0),
        string.format("Memory warning: %.1f MB", summary.warningCapMB or 0),
        string.format("Memory fail: %.1f MB", summary.hardCapMB or 0),
        string.format("Measured addon memory: %s",
            summary.currentMB and string.format("%.2f MB", summary.currentMB) or "unavailable"),
        string.format("Pressure state: %s", tostring(summary.pressure or "NONE")),
        string.format("AAR history: %d / %d",
            summary.history.count or 0, summary.history.cap or 0),
        string.format("Encounter history: %d / %d",
            summary.encounters.count or 0, summary.encounters.cap or 0),
        string.format("Opponent profiles: %d / %d",
            summary.opponentProfiles.count or 0, summary.opponentProfiles.cap or 0),
        string.format("Processed matches: %d / %d",
            summary.processedMatches.count or 0, summary.processedMatches.cap or 0),
        string.format("Enemy notes: %d / %d",
            summary.enemyNotes.count or 0, summary.enemyNotes.cap or 0),
        string.format("Learning plans: %d / %d",
            summary.learningPlans.count or 0, summary.learningPlans.cap or 0),
        string.format("Verification ledger: %d / %d",
            summary.verificationLedger.count or 0, summary.verificationLedger.cap or 0),
        string.format("Command history: %d / %d",
            summary.commandHistory.count or 0, summary.commandHistory.cap or 0),
        string.format("Objective events: %d / %d",
            summary.objectiveEvents.count or 0, summary.objectiveEvents.cap or 0),
        string.format("Runtime duration samples: %d / %d",
            summary.runtimeDurations.count or 0, summary.runtimeDurations.cap or 0),
        "",
        "Retention contract:",
    }
    for _, contract in ipairs(summary.contracts or {}) do
        local capText = {}
        for _, cap in ipairs(contract.caps or {}) do
            capText[#capText + 1] = cap.field .. "=" .. tostring(cap.cap or "?")
        end
        lines[#lines + 1] = string.format("%s [%s] %s | count %d | %s",
            tostring(contract.group or "contract"):upper(),
            tostring(contract.priority or "UNRANKED"),
            tostring(contract.label or contract.key or "Unknown"),
            contract.count or 0,
            table.concat(capText, ", "))
    end
    return table.concat(lines, "\n")
end

local function updateToken(_, state)
    local revision = state and state.revision or 0
    local bucket = math.floor(revision / math.max(1, MemoryBudget.checkEveryRevisions or 20))
    local inPvP = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    return tostring(bucket) .. ":" .. tostring(inPvP)
end

function MemoryBudget:Update(state)
    if not state or (state.revision or 0) % self.checkEveryRevisions ~= 0 then
        return
    end
    local mb = self:MeasureMB()
    self.lastMeasuredMB = mb or self.lastMeasuredMB or 0
    local pressure = self:PressureLevel(mb)
    self.lastPressure = pressure
    if pressure == "FAIL" then
        self:Trim(state, true)
    elseif pressure == "WARNING" then
        self:Trim(state, false)
        self:Trim(state, true)
    elseif pressure == "SOFT" then
        self:Trim(state, false)
    elseif state.snapshot and state.snapshot.context and state.snapshot.context.inPvP ~= true then
        self:Trim(state, false)
    end
end

function MemoryBudget:OnInitialize()
    self:TrimPersistent()
end

function MemoryBudget:OnEnable()
    local state = KWR.Store and type(KWR.Store.Get) == "function" and KWR.Store:Get() or nil
    self:Trim(state, true)
    if KWR.Store and KWR.Store.SubscribeFiltered then
        KWR.Store:SubscribeFiltered(self, self.Update, updateToken)
    end
end

function MemoryBudget:OnDisable()
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
end

KWR:RegisterModule("MemoryBudget", MemoryBudget)