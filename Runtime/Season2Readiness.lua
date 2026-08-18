local _, KWR = ...

-- A local-only bridge from the active Season 2 profile to the exact field
-- evidence needed before doctrine receives more weight. It never changes a
-- rating, recommendation, or stored AAR by itself.
local Season2Readiness = {}
KWR.Season2Readiness = Season2Readiness

local FLAG_MAPS = {
    TWINPEAKS = true,
    WSG = true,
}

local function text(value, fallback, maximum)
    return KWR.Util:Text(value, fallback or "unknown", maximum or 180)
end

function Season2Readiness:GetHotfixWatchlist()
    local watchlist = KWR.PatchData and KWR.PatchData:HotfixWatchlist() or nil
    if type(watchlist) ~= "table" then
        return {
            status = "NO_WATCHLIST",
            policy = "No active official-hotfix watchlist is available.",
            affected = {},
        }
    end
    return watchlist
end

function Season2Readiness:Build(state)
    state = state or KWR.Store:Get()
    local entry = KWR.Verification and KWR.Verification:BuildEntry(state) or {}
    local latest = KWR.AAR and KWR.AAR:GetLatest() or nil
    local live = entry.preview ~= true and entry.instanceType == "pvp"
    local rosterReady = live
        and (entry.roster or 0) > 0
        and (entry.teamSpecs or 0) >= (entry.roster or 0)
        and (entry.teamUnits or 0) >= (entry.roster or 0)
    local latestPerformance = latest and latest.performance or {}
    local latestStability = latest and latest.commandStability or {}
    local stabilityReady = latest ~= nil
        and (latestPerformance.samples or 0) > 0
        and (latestPerformance.errors or 0) == 0
        and (latestStability.certificationStatus == "READY"
            or latestStability.certificationStatus == "PASS")
    local flagMap = FLAG_MAPS[entry.mapKey] == true
    local checks = {
        {
            id = "TEAM_TRUTH",
            title = "Team truth",
            status = rosterReady and "LIVE SIGNAL" or "CAPTURE",
            detail = rosterReady
                and string.format("Live roster signal: %d/%d specs and %d/%d unit bindings. Capture the expanded Team surface.",
                    entry.teamSpecs or 0, entry.roster or 0, entry.teamUnits or 0, entry.roster or 0)
                or "Enter a real battleground, open Team, and capture expanded health/spec truth with /kwr verify.",
        },
        {
            id = "CARRIER_TARGET",
            title = "Carrier target",
            status = flagMap and (live and "CAPTURE" or "READY") or "NEXT FLAG MAP",
            detail = flagMap
                and "Capture a pickup, drop, return, or cap with the tactical command target visible; confirm it names the canonical carrier or route."
                or "Queue Twin Peaks or Warsong Gulch for a carrier-state evidence pass.",
        },
        {
            id = "STABILITY",
            title = "Stability and performance",
            status = stabilityReady and "AAR SIGNAL" or "CAPTURE",
            detail = stabilityReady
                and "Latest AAR has performance samples, no recorded runtime errors, and a passing command-stability signal. Review it before certifying."
                or "Finish one complete flag match; run /kwr perf during combat and review the automatic AAR at match end.",
        },
        {
            id = "READABILITY",
            title = "Readability",
            status = "MANUAL CAPTURE",
            detail = "At your supported scale, capture Tactical, Team, Enemies, Assignments, and Review/AAR with no meaningful clipping.",
        },
    }
    return {
        watchlist = self:GetHotfixWatchlist(),
        live = live,
        mapKey = entry.mapKey,
        latestAAR = latest,
        checks = checks,
    }
end

function Season2Readiness:SummaryLines(state)
    local run = self:Build(state)
    local watchlist = run.watchlist
    return {
        string.format("SEASON 2 HOTFIX WATCH  %s  |  %s", text(watchlist.status, "ADVISORY", 32), text(watchlist.effectiveDate, "DATE PENDING", 16)),
        "Advisory only: official tuning is visible, but KWR makes no automatic rating, prediction, or doctrine change.",
        string.format("EVIDENCE RUN  %s  |  %s", text(run.checks[1].status, "CAPTURE", 20), text(run.checks[3].status, "CAPTURE", 20)),
    }
end

function Season2Readiness:Report(state)
    local run = self:Build(state)
    local watchlist = run.watchlist
    local lines = {
        "========== KWR SEASON 2 WATCH + EVIDENCE RUN ==========" ,
        "HOTFIX STATUS: " .. text(watchlist.status, "ADVISORY", 32),
        "OFFICIAL DATE: " .. text(watchlist.effectiveDate, "not recorded", 16),
        "SOURCE: " .. text(watchlist.source, "official source not recorded", 96),
        "POLICY: " .. text(watchlist.policy, "Advisory only.", 240),
        "",
        "AFFECTED WATCHLIST:",
    }
    for _, item in ipairs(watchlist.affected or {}) do
        lines[#lines + 1] = "- " .. text(item, "official item", 160)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "EVIDENCE RUN: local capture only; no data is transmitted."
    for index, check in ipairs(run.checks) do
        lines[#lines + 1] = string.format("%d. %s [%s]", index, check.title, check.status)
        lines[#lines + 1] = "   " .. check.detail
    end
    lines[#lines + 1] = ""
    if run.latestAAR then
        lines[#lines + 1] = "NEXT: /kwr season2 aar opens the existing AAR review; use its SAVE REVIEW and COPY EXPORT controls."
    else
        lines[#lines + 1] = "NEXT: complete a real battleground; the automatic AAR will become the review and export route."
    end
    lines[#lines + 1] = "========== END SEASON 2 WATCH + EVIDENCE RUN =========="
    return table.concat(lines, "\n")
end

KWR:RegisterModule("Season2Readiness", Season2Readiness)
