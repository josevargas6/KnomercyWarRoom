local _, KWR = ...

local Store = {
    listeners = {},
    state = nil,
}
KWR.Store = Store

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
                simulations = {},
            },
            assignmentIntegrity = {
                verified = 0,
                moving = 0,
                abandoned = 0,
                impossible = 0,
                unknown = 0,
                reassignmentRequired = false,
                reassignments = {},
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
    self.listeners[owner] = callback
end

function Store:Unsubscribe(owner)
    self.listeners[owner] = nil
end

function Store:Publish(snapshot, prediction, assignments, command, diagnostics)
    local previous = self:Get()
    local nextState = {
        revision = (previous.revision or 0) + 1,
        capturedAt = KWR.Util:Now(),
        snapshot = snapshot,
        prediction = prediction,
        assignments = assignments,
        command = command,
        diagnostics = diagnostics or previous.diagnostics,
        mode = snapshot and snapshot.context and snapshot.context.preview and "PREVIEW" or "LIVE",
    }
    self.state = nextState
    for owner, callback in pairs(self.listeners) do
        local ok = xpcall(function()
            callback(owner, nextState, previous)
        end, geterrorhandler())
        if not ok and nextState.diagnostics then
            nextState.diagnostics.errors = (nextState.diagnostics.errors or 0) + 1
        end
    end
    return nextState
end

KWR:RegisterModule("Store", Store)
