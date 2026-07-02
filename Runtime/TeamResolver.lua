local _, KWR = ...

local TeamResolver = {
    assigned = nil,
    candidateFaction = nil,
    candidateSamples = 0,
    rows = {},
}
KWR.TeamResolver = TeamResolver

-- PVPScoreInfo.faction uses the battlefield team enum, not the character's
-- native faction: 0 = Horde, 1 = Alliance.
local HORDE_SCORE_FACTION = 0
local ALLIANCE_SCORE_FACTION = 1

local function nameKeys(name)
    name = KWR.Util:Text(name, "", 64):lower()
    if name == "" then return nil, nil end
    return name, KWR.Util:ShortName(name):lower()
end

function TeamResolver:SideForScoreFaction(faction)
    faction = KWR.Util:Number(faction, nil)
    if faction == HORDE_SCORE_FACTION then return "right", "Horde" end
    if faction == ALLIANCE_SCORE_FACTION then return "left", "Alliance" end
    return nil, nil
end

function TeamResolver:Native()
    local faction = KWR.Util:Text(KWR.Util:Call(UnitFactionGroup, "player"), "", 16)
    if faction == "Horde" then
        return { side = "right", faction = "Horde", source = "native_fallback" }
    end
    if faction == "Alliance" then
        return { side = "left", faction = "Alliance", source = "native_fallback" }
    end
    return { side = nil, faction = "Unknown", source = "unresolved" }
end

function TeamResolver:Reset()
    self.assigned = nil
    self.candidateFaction = nil
    self.candidateSamples = 0
    self.rows = {}
end

function TeamResolver:ReadRows()
    local rows = {}
    if type(GetNumBattlefieldScores) ~= "function"
        or not C_PvP or type(C_PvP.GetScoreInfo) ~= "function" then
        return rows
    end
    local count = math.min(KWR.Util:Number(KWR.Util:Call(GetNumBattlefieldScores), 0) or 0, 80)
    for index = 1, count do
        local info = KWR.Util:Call(C_PvP.GetScoreInfo, index)
        if type(info) == "table" then
            -- Read documented fields individually. The table and several score
            -- values may be secret in active PvP, while name and faction are
            -- explicitly public.
            local row = {
                name = KWR.Util:Text(info.name, "", 64),
                guid = KWR.Util:Text(info.guid, "", 80),
                class = KWR.Util:Text(info.className, "", 32),
                classFile = KWR.Util:Upper(info.classToken, "", 24),
                spec = KWR.Util:Text(info.talentSpec, "", 32),
                role = KWR.CombatSpells:Role(info.talentSpec, info.roleAssigned),
                faction = KWR.Util:Number(info.faction, nil),
                raceName = KWR.Util:Text(info.raceName, "", 32),
                honorLevel = KWR.Util:Number(info.honorLevel, nil),
                gender = KWR.Util:Number(info.gender, nil),
                -- Score fields can be secret during active PvP. Number() drops
                -- them to nil instead of comparing, formatting, or persisting
                -- a protected value.
                killingBlows = KWR.Util:Number(info.killingBlows, nil),
                honorableKills = KWR.Util:Number(info.honorableKills, nil),
                deaths = KWR.Util:Number(info.deaths, nil),
                damageDone = KWR.Util:Number(info.damageDone, nil),
                healingDone = KWR.Util:Number(info.healingDone, nil),
                rating = KWR.Util:Number(info.rating, nil),
                ratingChange = KWR.Util:Number(info.ratingChange, nil),
            }
            if row.name ~= "" and row.faction ~= nil then rows[#rows + 1] = row end
        end
    end
    return rows
end

function TeamResolver:Resolve(roster)
    local rows = self:ReadRows()
    self.rows = rows
    local friendlyNames = {}
    for _, player in ipairs(roster or {}) do
        local full, short = nameKeys(player.name)
        if full then friendlyNames[full] = true end
        if short then friendlyNames[short] = true end
    end
    local playerName = KWR.Util:UnitName("player")
    local playerFull, playerShort = nameKeys(playerName)
    local votes = {}
    local selfFaction
    for _, row in ipairs(rows) do
        local full, short = nameKeys(row.name)
        local isPlayer = (playerFull and full == playerFull)
            or (playerShort and short == playerShort)
        if isPlayer then selfFaction = row.faction end
        if (full and friendlyNames[full]) or (short and friendlyNames[short]) then
            votes[row.faction] = (votes[row.faction] or 0) + 1
        end
    end

    local bestFaction, bestVotes, tied = nil, 0, false
    for faction, count in pairs(votes) do
        if count > bestVotes then
            bestFaction, bestVotes, tied = faction, count, false
        elseif count == bestVotes and count > 0 then
            tied = true
        end
    end
    local candidate
    if selfFaction ~= nil and votes[selfFaction] and votes[selfFaction] >= 2 then
        candidate = selfFaction
    elseif bestFaction ~= nil and bestVotes >= 2 and not tied then
        candidate = bestFaction
    elseif selfFaction ~= nil and #roster <= 1 then
        candidate = selfFaction
    end

    if candidate ~= nil then
        if self.candidateFaction == candidate then
            self.candidateSamples = self.candidateSamples + 1
        else
            self.candidateFaction = candidate
            self.candidateSamples = 1
        end
        -- A multi-member roster vote is immediately strong. Solo/self-only
        -- evidence must repeat once to avoid the scoreboard population race.
        if bestVotes >= 2 or self.candidateSamples >= 2 then
            local side, faction = self:SideForScoreFaction(candidate)
            if side then
                self.assigned = {
                    side = side,
                    faction = faction,
                    scoreFaction = candidate,
                    source = "scoreboard_roster",
                    votes = bestVotes,
                }
            end
        end
    end
    return self.assigned or {
        side = nil,
        faction = "Unknown",
        source = "scoreboard_pending",
        votes = bestVotes,
    }, rows
end

function TeamResolver:Capture(inPvP, roster)
    if not inPvP then
        self:Reset()
        return self:Native(), {}
    end
    return self:Resolve(roster)
end

function TeamResolver:Get()
    return self.assigned or self:Native()
end

function TeamResolver:Value(left, right, team, assigned)
    assigned = assigned or self:Get()
    if not assigned or not assigned.side then return nil end
    if team == "friendly" then
        return assigned.side == "left" and left or right
    end
    return assigned.side == "left" and right or left
end

KWR:RegisterModule("TeamResolver", TeamResolver)
