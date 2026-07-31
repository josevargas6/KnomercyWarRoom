local _, KWR = ...

local Store = {
    listeners = {},
    state = nil,
    notifyScheduled = false,
    notifyQueue = nil,
    notifyIndex = 1,
    notifyPrevious = nil,
    notifyState = nil,
    notifyGeneration = 0,
    notifyPassGeneration = 0,
    notifyFlushing = false,
}
KWR.Store = Store

local NOTIFY_BATCH_SIZE = 8
local NOTIFY_BUDGET_MS = 1.5

local function reconcileBranch(previousValue, nextValue)
    if previousValue ~= nil and KWR.Util:DeepEqual(previousValue, nextValue) then
        return previousValue
    end
    return nextValue
end

local function reconcileSnapshot(previousSnapshot, nextSnapshot)
    if type(nextSnapshot) ~= "table" then
        return nextSnapshot
    end
    previousSnapshot = type(previousSnapshot) == "table" and previousSnapshot or {}
    local keys = {}
    for key in pairs(previousSnapshot) do keys[key] = true end
    for key in pairs(nextSnapshot) do keys[key] = true end
    for key in pairs(keys) do
        nextSnapshot[key] = reconcileBranch(previousSnapshot[key], nextSnapshot[key])
    end
    return nextSnapshot
end

local function defaults()
    return {
        revision = 0,
        capturedAt = 0,
        snapshot = {
            context = {
                inPvP = false,
                mapKey = "WORLD",
                mapName = "World",
                mapID = nil,
                kind = "WORLD",
                phase = "WORLD",
            },
            score = { friendly = 0, enemy = 0, max = 0, source = "none" },
            objectives = { source = "none", rows = {} },
            roster = {},
            enemies = {},
            formation = {
                targetSize = 10,
                players = 0,
                openSlots = 10,
                needText = "1 tank + 3 healers + 6 damage",
                recommendations = {},
                positioning = {},
            },
            reporter = {
                active = false,
                friendly = {},
                enemy = {},
                pressure = {},
                etas = {},
                enemyIntent = {
                    target = nil,
                    confidence = "NONE",
                    confidenceScore = 0,
                    eta = nil,
                    evidence = {},
                },
                momentum = {
                    value = 0,
                    state = "EVEN",
                    evidence = {},
                },
                matchMemory = {
                    rotations = {},
                    routes = {},
                    revision = 0,
                },
                events = {},
                risk = 0,
                summary = "Reporter standing by.",
            },
            combat = {
                observedSpells = 0,
                localEnemies = 0,
                localTarget = nil,
                localTargetScore = nil,
                localTargetReason = "No safely observed enemy in local fight range.",
                killTarget = nil,
                killReason = "No safely observed enemy in local fight range.",
                resourceEconomy = {
                    coverage = 0,
                    advantage = 0,
                    confidence = "NONE",
                    friendly = {
                        offensives = "UNKNOWN",
                        defensives = "UNKNOWN",
                        trinkets = "UNKNOWN",
                        mana = "UNKNOWN",
                        battleReadiness = "UNKNOWN",
                    },
                    enemy = {
                        activeDefensives = 0,
                        defensivesUsed = 0,
                        trinketsUsed = 0,
                        deadHealers = 0,
                        isolatedCarriers = 0,
                    },
                },
            },
            teamfight = {
                active = false,
                title = "LOCAL TEAMFIGHT CALL",
                assignments = {},
                killTarget = nil,
                countdown = { seconds = 0, ticks = {}, state = "UNKNOWN" },
                problems = {},
                confidence = "UNKNOWN",
                generatedAt = 0,
                compliance = {
                    apiMode = "Retail_Current",
                    targetAssist = "DISPLAY_ONLY",
                    automation = "FORBIDDEN",
                },
                summary = "No local teamfight call.",
            },
            executionCommand = {
                source = "SYNCHRONIZED_EXECUTION",
                active = false,
                authoritative = false,
                controls = {},
                personalByKey = {},
                lines = {},
                spokenText = "",
                confidence = "UNKNOWN",
                audible = false,
                localFight = {
                    phase = "CLEAR",
                    kill = nil,
                    controls = {},
                    updatedAt = 0,
                },
            },
            truth = {
                generatedAt = 0,
                facts = {},
                summary = {
                    verified = 0,
                    observed = 0,
                    stale = 0,
                    unknown = 0,
                    usable = 0,
                    total = 0,
                    coverage = 0,
                },
                coreFresh = false,
                aggressiveCommitAllowed = false,
            },
            strategy = {
                planID = nil,
                confidence = "NONE",
                reason = "Strategy engine standing by.",
                confidenceBudget = {
                    score = 0,
                    evidence = {},
                    risk = "HIGH",
                },
                opportunity = {
                    open = false,
                    duration = 0,
                    evidence = {},
                },
                executionAssessment = {
                    active = false,
                    confidence = "NONE",
                    confidenceScore = 0,
                    actionOpportunity = {
                        action = "NONE",
                        score = 0,
                    },
                },
                simulations = {},
                selectedAction = nil,
                decisionScore = nil,
                projection = "UNKNOWN",
                responseContract = nil,
            },
            assignmentIntegrity = {
                onStation = 0,
                verified = 0,
                moving = 0,
                completed = 0,
                abandoned = 0,
                impossible = 0,
                unverified = 0,
                unknown = 0,
                uncovered = 0,
                overcommitted = 0,
                coverageLedger = {},
                reassignmentRequired = false,
                reassignments = {},
            },
            responsePackage = {
                active = false,
                qualified = false,
                actionID = "HOLD_PLAN",
                action = "HOLD CURRENT PLAN",
                movers = {},
                stayers = {},
                confidence = "NONE",
                score = 0,
            },
        },
        prediction = {
            status = "WAITING",
            urgency = 0,
            condition = "Enter a battleground to begin.",
            action = "Queue or join your team.",
            source = "none",
        },
        assignments = {},
        activePlay = {
            id = nil,
            family = "WORLD",
            phase = "EXPIRED",
            issuedAt = 0,
            reviewAt = 0,
            minimumCommitUntil = 0,
            expectedArrivalAt = 0,
            expectedResolutionAt = 0,
            hardDeadlineAt = 0,
            confidence = 0,
            remainingValue = 0,
            sourceEvidence = {},
            successRules = {},
            abortRules = {},
            invalidationRules = {},
        },
        command = {
            status = "WAITING",
            line1 = "WORLD | KWR READY",
            line2 = "NEXT: QUEUE BATTLEGROUND",
            line3 = "WHO: TEAM | WHEN: READY",
            action = "Queue battleground",
            who = "Team",
            when = "Ready",
            reason = "Not in a battleground.",
            confidence = "NONE",
            confidenceScore = 0,
            evidence = {},
            risk = "HIGH",
            expectedOutcome = "No battlefield outcome projected.",
            projectedWinProbability = nil,
            recommendationMode = "WAIT",
            simulations = {},
            signature = "initial",
        },
        diagnostics = {
            refreshes = 0,
            lastReason = "startup",
            lastDurationMs = 0,
            errors = 0,
        },
        mode = "LIVE",
    }
end

function Store:OnInitialize()
    self.state = defaults()
end

function Store:Get()
    if not self.state then
        self.state = defaults()
    end
    return self.state
end

function Store:Subscribe(owner, callback)
    if type(owner) ~= "table" or type(callback) ~= "function" then
        return
    end
    self.listeners[owner] = {
        callback = callback,
        selector = nil,
        lastToken = nil,
        lastGeneration = 0,
    }
end

function Store:SubscribeFiltered(owner, callback, selector)
    if type(owner) ~= "table" or type(callback) ~= "function" then
        return
    end
    self.listeners[owner] = {
        callback = callback,
        selector = type(selector) == "function" and selector or nil,
        lastToken = nil,
        lastGeneration = 0,
    }
end

function Store:Unsubscribe(owner)
    self.listeners[owner] = nil
end

local function storeErrorHandler(err)
    local message = tostring(err or "unknown store listener error")
    if type(geterrorhandler) == "function" then
        local ok, handler = pcall(geterrorhandler)
        if ok and type(handler) == "function" then
            pcall(handler, message)
        end
    end
    return message
end

function Store:QueueNotifications(previous, nextState)
    self.notifyGeneration = (self.notifyGeneration or 0) + 1
    if type(self.notifyQueue) ~= "table" then
        local queue = {}
        for owner, listener in pairs(self.listeners) do
            queue[#queue + 1] = {
                owner = owner,
                listener = listener,
            }
        end
        self.notifyQueue = queue
        self.notifyIndex = 1
        self.notifyPassGeneration = self.notifyGeneration
    end
    self.notifyPrevious = previous
    self.notifyState = nextState
    if self.notifyScheduled == true or self.notifyFlushing == true then
        return
    end
    self.notifyScheduled = true
    self:FlushNotifications()
end

function Store:FlushNotifications()
    if self.notifyFlushing == true then return end
    self.notifyScheduled = false
    self.notifyFlushing = true
    local queue = self.notifyQueue
    local nextState = self.notifyState
    if type(queue) ~= "table" or type(nextState) ~= "table" then
        self.notifyQueue = nil
        self.notifyFlushing = false
        return
    end

    local previous = self.notifyPrevious
    local passGeneration = self.notifyPassGeneration or self.notifyGeneration or 0
    local deliveryGeneration = self.notifyGeneration or passGeneration
    local started = type(debugprofilestop) == "function" and debugprofilestop() or nil
    local processed = 0
    local index = self.notifyIndex or 1
    while index <= #queue do
        local entry = queue[index]
        index = index + 1
        local owner = entry and entry.owner
        local currentListener = owner and self.listeners[owner] or nil
        if currentListener and currentListener == entry.listener then
            local listener = entry.listener
            local callback = type(listener) == "table" and listener.callback or listener
            local selector = type(listener) == "table" and listener.selector or nil
            local shouldNotify = (listener.lastGeneration or 0) < passGeneration
            if selector then
                local ok, token = xpcall(function()
                    return selector(owner, nextState, previous)
                end, storeErrorHandler)
                if ok then
                    if listener.lastToken ~= nil and listener.lastToken == token then
                        shouldNotify = false
                    end
                    listener.lastToken = token
                else
                    shouldNotify = false
                    if nextState.diagnostics then
                        nextState.diagnostics.errors = (nextState.diagnostics.errors or 0) + 1
                        nextState.diagnostics.lastStoreError = tostring(token or "store selector failed")
                    end
                end
            end
            if shouldNotify == true and type(callback) == "function" then
                local ok, message = xpcall(function()
                    callback(owner, nextState, previous)
                end, storeErrorHandler)
                if not ok and nextState.diagnostics then
                    nextState.diagnostics.errors = (nextState.diagnostics.errors or 0) + 1
                    nextState.diagnostics.lastStoreError = tostring(message or "store listener failed")
                end
            end
            listener.lastGeneration = deliveryGeneration
        end
        processed = processed + 1
        if C_Timer and C_Timer.After and processed >= NOTIFY_BATCH_SIZE then
            break
        end
        if started and type(debugprofilestop) == "function"
            and (debugprofilestop() - started) >= NOTIFY_BUDGET_MS then
            break
        end
    end

    if index <= #queue then
        self.notifyIndex = index
        self.notifyScheduled = true
        self.notifyFlushing = false
        C_Timer.After(0, function()
            self:FlushNotifications()
        end)
    elseif (self.notifyGeneration or 0) > passGeneration then
        local nextQueue = {}
        for owner, listener in pairs(self.listeners) do
            nextQueue[#nextQueue + 1] = {
                owner = owner,
                listener = listener,
            }
        end
        self.notifyQueue = nextQueue
        self.notifyIndex = 1
        self.notifyPassGeneration = self.notifyGeneration
        self.notifyScheduled = true
        self.notifyFlushing = false
        C_Timer.After(0, function()
            self:FlushNotifications()
        end)
    else
        self.notifyQueue = nil
        self.notifyIndex = 1
        self.notifyPrevious = nil
        self.notifyState = nil
        self.notifyPassGeneration = self.notifyGeneration or 0
        self.notifyFlushing = false
    end
end

function Store:Publish(snapshot, prediction, assignments, command, diagnostics)
    local previous = self:Get()
    snapshot = reconcileSnapshot(previous.snapshot, snapshot)
    local activePlay = type(command) == "table" and command.activePlay or nil
    local nextState = {
        revision = (previous.revision or 0) + 1,
        capturedAt = KWR.Util:Now(),
        snapshot = snapshot,
        prediction = reconcileBranch(previous.prediction, prediction),
        assignments = reconcileBranch(previous.assignments, assignments),
        command = reconcileBranch(previous.command, command),
        activePlay = reconcileBranch(previous.activePlay, activePlay),
        diagnostics = reconcileBranch(previous.diagnostics, diagnostics or previous.diagnostics),
        mode = snapshot and snapshot.context and snapshot.context.preview and "PREVIEW" or "LIVE",
    }
    self.state = nextState
    self:QueueNotifications(previous, nextState)
    return nextState
end

KWR:RegisterModule("Store", Store)