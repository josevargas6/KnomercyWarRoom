local _, KWR = ...

local Registry = {}
KWR.ProblemSignalRegistry = Registry

local ROWS = {
    FREE_CASTING_HEALER = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.local_healer_observation",
        source = "board_state.local_enemy",
        evidence = "visible_or_recent_local + healer_role + cast_or_pressure + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Primary local healer-control problem. Safe for live calls.",
    },
    CASTER_HEALER_SUPPORT = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.local_healer_observation",
        source = "board_state.local_enemy",
        evidence = "additional local healer support lane + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Secondary local healer-control support lane.",
    },
    LOCAL_HEALER_CONTROL = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.local_healer_observation",
        source = "board_state.local_enemy",
        evidence = "confirmed_or_recent local healer + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Maintains local healer control without forcing a fake kill window.",
    },
    KILL_TARGET_AVAILABLE = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.local_kill_window",
        source = "board_state.local_enemy",
        evidence = "local target + killable_or_overextended_or_low_health + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Local kill package depends on protected-support filtering downstream.",
    },
    FLAG_CARRIER_ESCAPING = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.objective_carrier",
        source = "board_state.objective_carrier",
        evidence = "carrier exposure + map kind FLAG + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Carrier denial/kill path is live for flag maps.",
    },
    BASE_UNDER_THREAT = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "OBJECTIVE",
        detector = "EnemyProblemDetector.objective_threat",
        source = "board_state.objective_threat",
        evidence = "objective threat observation + map kind NODE + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Node denial path is wired through assignments and command output.",
    },
    STEALTH_THREAT_MISSING = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.stealth_gap",
        source = "board_state.stealth_threat",
        evidence = "stealth-threat inference + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Inference-only problem; verification must make the confidence explicit.",
    },
    FRIENDLY_HEALER_UNDER_PRESSURE = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.healer_pressure",
        source = "board_state.healer_pressure",
        evidence = "friendly support under pressure + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Peel path is live and bounded to visible/reported threat.",
    },
    OBJECTIVE_CARRIER_EXPOSED = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.objective_carrier",
        source = "board_state.objective_carrier",
        evidence = "carrier exposure on non-flag objective map + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Shared carrier punishment path for non-flag modes.",
    },
    NODE_SPIN_REQUIRED = {
        enabled = false,
        status = "DISABLED",
        subjectKind = "OBJECTIVE",
        detector = nil,
        source = nil,
        evidence = nil,
        assignment = false,
        command = false,
        verify = true,
        aar = false,
        disabledReason = "No dedicated node-spin detector currently emits this problem type.",
        notes = "Leave disabled until a real objective-spin detector exists.",
    },
    ROTATION_GAP_DETECTED = {
        enabled = false,
        status = "DISABLED",
        subjectKind = "OBJECTIVE",
        detector = nil,
        source = nil,
        evidence = nil,
        assignment = false,
        command = false,
        verify = true,
        aar = false,
        disabledReason = "Rotation gaps are handled heuristically elsewhere, not through a truth-qualified problem signal.",
        notes = "Must stay disabled until a source-qualified gap detector is implemented.",
    },
    ENEMY_COOLDOWN_WINDOW = {
        enabled = true,
        status = "SUPPORTED",
        subjectKind = "ENEMY_PLAYER",
        detector = "EnemyProblemDetector.cooldown_window",
        source = "board_state.cooldown_window",
        evidence = "exposed defensive window + evidenceID",
        assignment = true,
        command = true,
        verify = true,
        aar = true,
        notes = "Pressure window is allowed only from explicit exposed-state evidence.",
    },
    RESPAWN_WAVE_ADVANTAGE = {
        enabled = false,
        status = "DISABLED",
        subjectKind = "OBJECTIVE",
        detector = nil,
        source = nil,
        evidence = nil,
        assignment = false,
        command = false,
        verify = true,
        aar = false,
        disabledReason = "Current runtime does not own a truth-qualified respawn-wave advantage detector.",
        notes = "Planned for ET-06 after authority/order repairs.",
    },
}

local LEGACY = {
    FREE_CAST_HEALER = "FREE_CASTING_HEALER",
    KILLABLE_OVEREXTENDED = "KILL_TARGET_AVAILABLE",
    OBJECTIVE_DENIAL = "BASE_UNDER_THREAT",
}

local function canonical(problemType)
    local key = KWR.Util:Text(problemType, "", 48)
    return LEGACY[key] or key
end

local function orderedKeys()
    local keys = {}
    for key in pairs(ROWS) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function Registry:Resolve(problemType)
    local key = canonical(problemType)
    if key == "" then return nil, key end
    return ROWS[key], key
end

function Registry:Describe(problemType)
    local row, key = self:Resolve(problemType)
    if not row then return nil end
    return {
        key = key,
        enabled = row.enabled == true,
        status = row.status or "UNKNOWN",
        subjectKind = row.subjectKind or "UNKNOWN",
        detector = row.detector,
        source = row.source,
        evidence = row.evidence,
        assignment = row.assignment == true,
        command = row.command == true,
        verify = row.verify == true,
        aar = row.aar == true,
        disabledReason = row.disabledReason,
        notes = row.notes,
        fullCoverage = row.enabled == true
            and row.assignment == true
            and row.command == true
            and row.verify == true
            and row.aar == true
            and row.detector ~= nil
            and row.source ~= nil
            and row.evidence ~= nil,
    }
end

function Registry:Entries()
    local rows = {}
    for _, key in ipairs(orderedKeys()) do
        rows[#rows + 1] = self:Describe(key)
    end
    return rows
end

function Registry:Summary()
    local summary = {
        total = 0,
        supported = 0,
        disabled = 0,
        partial = 0,
        fullCoverage = 0,
        legacyAliases = 0,
        auditOK = true,
        issues = {},
    }
    for _, row in ipairs(self:Entries()) do
        summary.total = summary.total + 1
        if row.enabled then
            if row.fullCoverage then
                summary.supported = summary.supported + 1
                summary.fullCoverage = summary.fullCoverage + 1
            else
                summary.supported = summary.supported + 1
                summary.partial = summary.partial + 1
                summary.auditOK = false
                summary.issues[#summary.issues + 1] =
                    row.key .. " is enabled without full source-to-AAR coverage."
            end
        else
            summary.disabled = summary.disabled + 1
        end
    end
    for _ in pairs(LEGACY) do
        summary.legacyAliases = summary.legacyAliases + 1
    end
    for key, definition in pairs(KWR.EnemyProblemTypes or {}) do
        if type(definition) == "table" then
            local row = self:Describe(key)
            if not row then
                summary.auditOK = false
                summary.issues[#summary.issues + 1] =
                    "Problem type " .. tostring(key) .. " is missing from the coverage registry."
            end
        end
    end
    return summary
end

function Registry:Audit(activeProblems)
    local audit = self:Summary()
    audit.active = 0
    audit.activeUnsupported = 0
    audit.activeDisabled = 0
    audit.activeUnknown = 0
    audit.activeDetails = {}
    for _, problem in ipairs(activeProblems or {}) do
        local row = self:Describe(problem and problem.type)
        audit.active = audit.active + 1
        if not row then
            audit.auditOK = false
            audit.activeUnknown = audit.activeUnknown + 1
            audit.issues[#audit.issues + 1] =
                "Active problem " .. tostring(problem and problem.type or "UNKNOWN")
                .. " has no registry row."
            audit.activeDetails[#audit.activeDetails + 1] =
                tostring(problem and problem.type or "UNKNOWN") .. " / UNKNOWN"
        elseif row.enabled ~= true then
            audit.auditOK = false
            audit.activeDisabled = audit.activeDisabled + 1
            audit.issues[#audit.issues + 1] =
                "Active problem " .. row.key .. " is disabled in the registry."
            audit.activeDetails[#audit.activeDetails + 1] =
                row.key .. " / DISABLED / " .. KWR.Util:Text(row.disabledReason, "No reason", 120)
        elseif row.fullCoverage ~= true then
            audit.auditOK = false
            audit.activeUnsupported = audit.activeUnsupported + 1
            audit.issues[#audit.issues + 1] =
                "Active problem " .. row.key .. " does not have full coverage."
            audit.activeDetails[#audit.activeDetails + 1] =
                row.key .. " / PARTIAL"
        else
            audit.activeDetails[#audit.activeDetails + 1] =
                row.key .. " / SUPPORTED / " .. KWR.Util:Text(row.subjectKind, "UNKNOWN", 24)
        end
    end
    return audit
end

function Registry:LegacyMap()
    return KWR.Util:Copy(LEGACY)
end

KWR:RegisterModule("ProblemSignalRegistry", Registry)