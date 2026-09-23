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
    listenerSequence = 0,
}
KWR.Store = Store

local NOTIFY_BATCH_SIZE = 8
local NOTIFY_BUDGET_MS = 1.5

local function shallowCopy(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return result
end

local function reconcileBranch(previousValue, nextValue)
    if previousValue == nextValue then return previousValue end
    if type(nextValue) ~= "table" then return nextValue end
    if type(previousValue) ~= "table" then return KWR.Util:Copy(nextValue) end
    -- Reconcile before allocating, not after copying the entire snapshot.
    -- Only changed paths acquire owned tables; equal immutable branches retain
    -- identity. Never retain a producer's mutable input table on a changed path.
    local target
    for key, value in pairs(nextValue) do
        local owned = reconcileBranch(previousValue[key], value)
        if owned ~= previousValue[key] then
            target = target or shallowCopy(previousValue)
            target[key] = owned
        end
    end
    for key in pairs(previousValue) do
        if nextValue[key] == nil then
            target = target or shallowCopy(previousValue)
            target[key] = nil
        end
    end
    return target or previousValue
end

local function reconcileSnapshot(previousSnapshot, nextSnapshot)
    if type(nextSnapshot) ~= "table" then
        return nextSnapshot
    end
    return reconcileBranch(previousSnapshot, nextSnapshot)
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
    self.listenerSequence = self.listenerSequence + 1
    self.listeners[owner] = {
        callback = callback,
        selector = nil,
        lastToken = nil,
        lastGeneration = 0,
        order = self.listenerSequence,
    }
end

function Store:SubscribeFiltered(owner, callback, selector)
    if type(owner) ~= "table" or type(callback) ~= "function" then
        return
    end
    self.listenerSequence = self.listenerSequence + 1
    self.listeners[owner] = {
        callback = callback,
        selector = type(selector) == "function" and selector or nil,
        lastToken = nil,
        lastGeneration = 0,
        order = self.listenerSequence,
    }
end

local function notificationQueue(listeners)
    local queue = {}
    for owner, listener in pairs(listeners or {}) do
        queue[#queue + 1] = { owner = owner, listener = listener }
    end
    table.sort(queue, function(a, b)
        return (a.listener.order or 0) < (b.listener.order or 0)
    end)
    return queue
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
        self.notifyQueue = notificationQueue(self.listeners)
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
        self.notifyQueue = notificationQueue(self.listeners)
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

function Store:Publish(snapshot, prediction, assignments, command, diagnostics, finalizeDiagnostics)
    local previous = self:Get()
    -- Producers can mutate their working tables later; reconciliation owns
    -- changed paths and reuses only branches from the previous published state.
    snapshot = reconcileSnapshot(previous.snapshot, snapshot or {})
    prediction = reconcileBranch(previous.prediction, prediction or {})
    assignments = reconcileBranch(previous.assignments, assignments or {})
    command = reconcileBranch(previous.command, command or {})
    -- Runtime timing includes snapshot ownership/reconciliation. Finalize before
    -- notification so subscribers receive complete diagnostics with the state.
    if finalizeDiagnostics then diagnostics = finalizeDiagnostics() or diagnostics end
    diagnostics = reconcileBranch(previous.diagnostics, diagnostics or previous.diagnostics or {})
    local activePlay = type(command) == "table" and command.activePlay or nil
    local nextState = {
        revision = (previous.revision or 0) + 1,
        capturedAt = KWR.Util:Now(),
        snapshot = snapshot,
        prediction = prediction,
        assignments = assignments,
        command = command,
        activePlay = reconcileBranch(previous.activePlay, activePlay),
        diagnostics = diagnostics,
        mode = snapshot and snapshot.context and snapshot.context.preview and "PREVIEW" or "LIVE",
    }
    self.state = nextState
    self:QueueNotifications(previous, nextState)
    return nextState
end

KWR:RegisterModule("Store", Store)
