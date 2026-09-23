local _, KWR = ...

-- This production safety gate is shared with optional developer reports.
local Verification = KWR.Verification or {}
KWR.Verification = Verification

function Verification:ScoreEvidence(snapshot)
    local score = snapshot and snapshot.score or {}
    local friendly = KWR.Util:Number(score.friendly, nil)
    local enemy = KWR.Util:Number(score.enemy, nil)
    local known = KWR.Util:Text(score.source, "none", 40) == "ui_widget"
        and friendly ~= nil and enemy ~= nil
        and friendly >= 0 and enemy >= 0 and friendly < math.huge and enemy < math.huge
    return KWR.Util:Evidence(known and {
        friendly = friendly, enemy = enemy, max = KWR.Util:Number(score.max, nil),
    } or nil, score.source, score.observedAt, 5, known and "HIGH" or "NONE", known)
end

function Verification:Contract(snapshot)
    snapshot = snapshot or {}
    local context = snapshot.context or {}
    local score = snapshot.score or {}
    local objectives = snapshot.objectives or {}
    local reporter = snapshot.reporter or {}
    local now = KWR.Util:Now()
    local facts = {
        match = KWR.Util:Evidence(
            context.inPvP and context.mapKey or nil,
            context.inPvP and "instance_context" or "none",
            context.capturedAt or snapshot.capturedAt,
            context.inPvP and 10 or 30,
            context.inPvP and "HIGH" or "NONE",
            context.inPvP and KWR.Maps:Get(context.mapKey) ~= nil),
        team = KWR.Util:Evidence(
            context.team and context.team.faction or nil,
            context.team and context.team.source or "scoreboard",
            context.capturedAt or snapshot.capturedAt,
            15,
            context.team and context.team.side and "HIGH" or "NONE",
            context.team and context.team.side ~= nil),
        score = self:ScoreEvidence(snapshot),
        objectives = KWR.Util:Evidence(
            objectives.source == "ui_widget" and objectives.rows or nil,
            objectives.source,
            objectives.observedAt,
            5,
            objectives.source == "ui_widget" and "HIGH"
                or (#(objectives.rows or {}) > 0 and "LOW" or "NONE"),
            objectives.source == "ui_widget"),
        friendlyRoster = KWR.Util:Evidence(
            #(snapshot.roster or {}) > 0 and #(snapshot.roster or {}) or nil,
            "group_units",
            snapshot.capturedAt,
            8,
            #(snapshot.roster or {}) >= 8 and "HIGH" or "MEDIUM",
            #(snapshot.roster or {}) > 0),
        enemyRoster = KWR.Util:Evidence(
            #(snapshot.enemies or {}) > 0 and #(snapshot.enemies or {}) or nil,
            "pvp_scoreboard",
            snapshot.capturedAt,
            12,
            #(snapshot.enemies or {}) >= 8 and "MEDIUM" or "LOW",
            false),
        movement = KWR.Util:Evidence(
            reporter.coverage and {
                friendly = reporter.coverage.friendlyLocated or 0,
                enemy = reporter.coverage.enemyLocated or 0,
            } or nil,
            "reporter_tracks",
            reporter.updatedAt,
            8,
            reporter.coverage and
                ((reporter.coverage.friendlyLocated or 0)
                    + (reporter.coverage.enemyLocated or 0) >= 3)
                and "MEDIUM" or "LOW",
            false),
    }
    local summary = {
        verified = 0,
        observed = 0,
        stale = 0,
        unknown = 0,
        usable = 0,
        total = 0,
    }
    for _, fact in pairs(facts) do
        fact.age = fact.observedAt and math.max(0, now - fact.observedAt) or nil
        summary.total = summary.total + 1
        if fact.state == "VERIFIED" then summary.verified = summary.verified + 1
        elseif fact.state == "OBSERVED" then summary.observed = summary.observed + 1
        elseif fact.state == "STALE" then summary.stale = summary.stale + 1
        else summary.unknown = summary.unknown + 1 end
        if KWR.Util:EvidenceUsable(fact, "LOW") then
            summary.usable = summary.usable + 1
        end
    end
    local coreFresh = KWR.Util:EvidenceUsable(facts.match, "HIGH")
        and KWR.Util:EvidenceUsable(facts.team, "HIGH")
        and KWR.Util:EvidenceUsable(facts.score, "HIGH")
    local objectiveRequired = context.kind == "NODE"
        or context.kind == "HYBRID" or context.kind == "ORB"
        or context.kind == "CART" or context.kind == "RESOURCE"
    if objectiveRequired then
        coreFresh = coreFresh
            and KWR.Util:EvidenceUsable(facts.objectives, "MEDIUM")
    end
    summary.coverage = summary.total > 0
        and math.floor((summary.usable / summary.total) * 100 + 0.5) or 0
    return {
        generatedAt = now,
        facts = facts,
        summary = summary,
        coreFresh = coreFresh == true,
        aggressiveCommitAllowed = coreFresh == true
            and summary.coverage >= 65
            and summary.stale == 0,
        conservativeReason = coreFresh and nil
            or "Core match, faction, score, or objective evidence is incomplete.",
    }
end
