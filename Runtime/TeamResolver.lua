local _, KWR = ...

local TeamResolver = {
    assigned = nil,
    candidateFaction = nil,
    candidateSamples = 0,
    rows = {},
    sessionKey = nil,
}
KWR.TeamResolver = TeamResolver

-- PVPScoreInfo.faction uses the battleground-side enum exposed by the live
-- scoreboard. KWR live verification has repeatedly confirmed the practical
-- mapping used by the addon pipeline here is 0 = Horde, 1 = Alliance.
-- Reversing this pollutes enemy ingestion and flips win-path logic.
local HORDE_SCORE_FACTION = 0
local ALLIANCE_SCORE_FACTION = 1

local function nameKeys(name)
    name = KWR.Util:Text(name, "", 64):lower()
    if name == "" then return nil, nil end
    return name, KWR.Util:ShortName(name):lower()
end

local function scoreFactionForFactionName(faction)
    faction = KWR.Util:Text(faction, "", 16)
    if faction == "Horde" then return HORDE_SCORE_FACTION end
    if faction == "Alliance" then return ALLIANCE_SCORE_FACTION end
    return nil
end

local function rosterIdentityMaps(roster)
    local byGuid, byName, byShort, shortCounts = {}, {}, {}, {}
    for _, player in ipairs(roster or {}) do
        local guid = KWR.Util:Text(player.guid, "", 80)
        local name, short = nameKeys(player.name)
        if guid ~= "" then byGuid[guid] = player end
        if name then byName[name] = player end
        if short then
            shortCounts[short] = (shortCounts[short] or 0) + 1
            byShort[short] = player
        end
    end
    return byGuid, byName, byShort, shortCounts
end

local function dedupeFriendlyRows(rows)
    local unique, aliasIndex = {}, {}
    local nextIndex = 0
    local function score(row)
        local value = 0
        if KWR.Util:Text(row and row.guid, "", 80) ~= "" then value = value + 8 end
        if KWR.Util:Text(row and row.name, "", 64) ~= "" then value = value + 8 end
        if KWR.Util:Upper(row and row.role, "NONE", 12) ~= "NONE" then value = value + 4 end
        if KWR.Util:Text(row and row.spec, "", 32) ~= "" then value = value + 2 end
        if KWR.Util:Upper(row and row.classFile, "", 24) ~= "" then value = value + 1 end
        return value
    end

    for _, row in ipairs(rows or {}) do
        local guid = KWR.Util:Text(row and row.guid, "", 80)
        local full = nameKeys(row and row.name)
        local aliases = {}
        if guid ~= "" then aliases[#aliases + 1] = "GUID:" .. guid end
        if full then aliases[#aliases + 1] = "NAME:" .. full end
        if #aliases > 0 then
            local index
            for _, alias in ipairs(aliases) do
                local candidate = aliasIndex[alias]
                if candidate and unique[candidate] then
                    if not index then
                        index = candidate
                    elseif candidate ~= index then
                        if score(unique[candidate]) > score(unique[index]) then
                            unique[index] = unique[candidate]
                        end
                        unique[candidate] = nil
                        for knownAlias, knownIndex in pairs(aliasIndex) do
                            if knownIndex == candidate then aliasIndex[knownAlias] = index end
                        end
                    end
                end
            end
            if not index then
                nextIndex = nextIndex + 1
                index = nextIndex
                unique[index] = row
            elseif score(row) > score(unique[index]) then
                unique[index] = row
            end
            for _, alias in ipairs(aliases) do aliasIndex[alias] = index end
        end
    end
    local compact = {}
    for index = 1, nextIndex do
        if unique[index] then compact[#compact + 1] = unique[index] end
    end
    return compact, #compact ~= #(rows or {})
end

-- A real cross-realm collision is realm-qualified on at least one feed. Two
-- roster rows that render as the same unqualified short name are transitional
-- aliases of one player, never two safe assignment targets.
local function hasAmbiguousUnqualifiedShortIdentity(rows)
    local identities = {}
    local unqualified = {}
    for _, row in ipairs(rows or {}) do
        local rawName = KWR.Util:Text(row and (row.name or row.shortName), "", 96)
        local full, short = nameKeys(rawName)
        if full and short then
            identities[short] = identities[short] or {}
            identities[short][full] = true
            if not rawName:find("-", 1, true) then
                unqualified[short] = true
            end
        end
    end
    for short, names in pairs(identities) do
        local count = 0
        for _ in pairs(names) do count = count + 1 end
        if count > 1 and unqualified[short] then return true end
    end
    return false
end

function TeamResolver:NormalizePublishedRoster(roster)
    local kept = {}
    local aliasIndex = {}
    local shortIdentityCounts = {}
    local shortIdentitySeen = {}
    local shortHasQualifiedIdentity = {}

    for _, player in ipairs(roster or {}) do
        local rawName = KWR.Util:Text(player and (player.name or player.shortName), "", 96)
        local shortName = KWR.Util:CanonicalShortName(
            player and (player.shortName or player.name))
        if shortName ~= "" then
            shortIdentitySeen[shortName] = shortIdentitySeen[shortName] or {}
            local guid = KWR.Util:Text(player and player.guid, "", 96)
            local fullName = KWR.Util:CanonicalName(player and (player.name or player.shortName))
            local identity = guid ~= "" and ("GUID:" .. guid)
                or (rawName:find("-", 1, true) and fullName ~= "" and ("NAME:" .. fullName))
                or nil
            if rawName:find("-", 1, true) then
                shortHasQualifiedIdentity[shortName] = true
            end
            if identity and not shortIdentitySeen[shortName][identity] then
                shortIdentitySeen[shortName][identity] = true
                shortIdentityCounts[shortName] = (shortIdentityCounts[shortName] or 0) + 1
            end
        end
    end

    local function score(entry)
        local value = 0
        if KWR.Util:Text(entry and entry.unit, "", 24) ~= "" then
            value = value + 100
        end
        if KWR.Util:Text(entry and entry.guid, "", 96) ~= "" then
            value = value + 50
        end
        if entry and entry.connected ~= false then
            value = value + 20
        end
        if entry and entry.dead ~= true then
            value = value + 10
        end
        if entry and entry.spec and entry.spec ~= ""
            and entry.spec ~= "Unknown" then
            value = value + 8
        end
        if entry and entry.specSource
            and entry.specSource ~= "historical" then
            value = value + 4
        end
        if entry and (entry.healthPercent ~= nil
            or entry.healthMax ~= nil) then
            value = value + 4
        end
        return value
    end

    for _, player in ipairs(roster or {}) do
        local key = KWR.Util:Text(player.key, "", 96)
        local guid = KWR.Util:Text(player.guid, "", 96)
        local name = KWR.Util:CanonicalName(
            player.name or player.shortName)
        local shortName = KWR.Util:CanonicalShortName(
            player.shortName or player.name)
        local unit = KWR.Util:Text(player.unit, "", 24)
        local aliases = {}
        if key ~= "" then
            aliases[#aliases + 1] = "KEY:" .. key
        end
        if guid ~= "" then
            aliases[#aliases + 1] = "GUID:" .. guid
        end
        if name ~= "" then
            aliases[#aliases + 1] = "NAME:" .. name
        end
        -- An unqualified duplicate is never a safely distinct assignment
        -- target.  During battleground roster hydration Blizzard can briefly
        -- publish the same player under multiple GUIDs but without realm
        -- qualification; collapse that state until a realm-qualified identity
        -- proves the short-name collision is real.
        if shortName ~= "" and ((shortIdentityCounts[shortName] or 0) <= 1
            or shortHasQualifiedIdentity[shortName] ~= true) then
            aliases[#aliases + 1] = "SHORT:" .. shortName
        end
        if unit ~= "" then
            aliases[#aliases + 1] = "UNIT:" .. unit
        end

        -- Published roster hydration can briefly expose one group-owned row
        -- and one scoreboard-only row for the same player. The transient
        -- profile is only used while no stable group unit exists.
        if unit == "" and shortName ~= "" then
            aliases[#aliases + 1] = "TRANSIENT:" .. table.concat({
                shortName,
                KWR.Util:Upper(player.role, "NONE", 12),
                KWR.Util:CanonicalName(player.spec),
                KWR.Util:Upper(player.classFile, "", 24),
            }, "|")
        end

        if #aliases > 0 then
            local index
            for _, alias in ipairs(aliases) do
                if aliasIndex[alias] then
                    index = aliasIndex[alias]
                    break
                end
            end
            if not index then
                index = #kept + 1
                kept[index] = player
            elseif score(player) > score(kept[index]) then
                kept[index] = player
            end
            for _, alias in ipairs(aliases) do
                aliasIndex[alias] = index
            end
        end
    end

    local normalized = {}
    for _, player in ipairs(kept) do
        if player then
            normalized[#normalized + 1] = player
        end
    end

    -- A short name is not a display identity. Two fully resolved players can
    -- share it across realms; rendering only the short form makes a correct
    -- roster look like it contains a duplicate, while a transitional copy of
    -- one player must remain collapsed above. Keep the identity decision in
    -- this single publishing boundary so every consumer receives both a
    -- unique roster and an unambiguous row label.
    local displayCounts = {}
    for _, player in ipairs(normalized) do
        local shortName = KWR.Util:CanonicalShortName(
            player.shortName or player.name)
        if shortName ~= "" then
            displayCounts[shortName] = (displayCounts[shortName] or 0) + 1
        end
    end
    for _, player in ipairs(normalized) do
        local shortName = KWR.Util:CanonicalShortName(
            player.shortName or player.name)
        local compact = KWR.Util:Text(player.shortName, "", 64)
        local full = KWR.Util:Text(player.name, compact, 96)
        player.displayName = displayCounts[shortName] and displayCounts[shortName] > 1
            and full or compact
    end
    return normalized
end

local function enrichGroupPlayer(player, row)
    local enriched = KWR.Util:Copy(player)
    if not row then
        enriched.rosterSource = enriched.rosterSource or "group"
        return enriched
    end
    local class = KWR.Util:Text(row.class, "", 32)
    local classFile = KWR.Util:Upper(row.classFile, "", 24)
    local spec = KWR.Util:Text(row.spec, "", 32)
    local role = KWR.Util:Upper(row.role, "NONE", 12)
    if class ~= "" then enriched.class = class end
    if classFile ~= "" then enriched.classFile = classFile end
    if spec ~= "" then
        enriched.spec = spec
        enriched.specSource = "scoreboard"
    end
    if role ~= "NONE" then enriched.role = role end
    enriched.rosterSource = "group+scoreboard"
    return enriched
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
    self.sessionKey = nil
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

function TeamResolver:DetectBlitz(rows)
    local counts = {
        [HORDE_SCORE_FACTION] = 0,
        [ALLIANCE_SCORE_FACTION] = 0,
    }
    local known = 0
    for _, row in ipairs(rows or {}) do
        local faction = KWR.Util:Number(row.faction, nil)
        if counts[faction] ~= nil then
            counts[faction] = counts[faction] + 1
            known = known + 1
        end
    end
    local detected = known == 16
        and counts[HORDE_SCORE_FACTION] == 8
        and counts[ALLIANCE_SCORE_FACTION] == 8
    return detected, {
        source = detected and "scoreboard_8v8" or "scoreboard_inconclusive",
        horde = counts[HORDE_SCORE_FACTION],
        alliance = counts[ALLIANCE_SCORE_FACTION],
    }
end

function TeamResolver:ReconcileFriendlyRoster(roster, assigned, rows, expectedCount)
    roster = type(roster) == "table" and roster or {}
    expectedCount = math.max(0,
        KWR.Util:Number(expectedCount, #roster) or #roster)
    local uniqueGroup, groupHadDuplicates = dedupeFriendlyRows(roster)
    local scoreFaction = assigned and KWR.Util:Number(assigned.scoreFaction, nil)
    if scoreFaction == nil or expectedCount == 0 then
        return uniqueGroup, {
            source = groupHadDuplicates and "group_roster_deduped" or "group_roster",
            expected = expectedCount,
            friendlyRows = 0,
            repaired = 0,
            groupHadDuplicates = groupHadDuplicates == true,
        }
    end

    local friendlyRows = {}
    for _, row in ipairs(rows or {}) do
        if KWR.Util:Number(row.faction, nil) == scoreFaction then
            friendlyRows[#friendlyRows + 1] = row
        end
    end
    local scoreboardHadDuplicates
    friendlyRows, scoreboardHadDuplicates = dedupeFriendlyRows(friendlyRows)

    -- Group units are the authority for friendly identity. A complete unique
    -- group roster must never be rebuilt from scoreboard rows: the scoreboard
    -- can briefly contain stale copies with new GUIDs while players load or
    -- swap. Enrich matching group members only, preserving name, GUID, unit,
    -- cardinality, and row ownership.
    local groupIdentityConflict = hasAmbiguousUnqualifiedShortIdentity(uniqueGroup)
    local scoreboardIdentityConflict = hasAmbiguousUnqualifiedShortIdentity(friendlyRows)
    local groupAuthoritative = #uniqueGroup == expectedCount
    if groupAuthoritative then
        local byGuid, byName, byShort, shortCounts = rosterIdentityMaps(friendlyRows)
        local used, reconciled, matched = {}, {}, 0
        -- Only the already-validated group set may own friendly slots. Using
        -- the raw input here reintroduced duplicate rows after dedupe.
        for _, player in ipairs(uniqueGroup) do
            local guid = KWR.Util:Text(player.guid, "", 80)
            local full, short = nameKeys(player.name)
            local row = guid ~= "" and byGuid[guid] or nil
            if not row and full then row = byName[full] end
            if not row and short and shortCounts[short] == 1 then row = byShort[short] end
            if row and used[row] then row = nil end
            if row then
                used[row] = true
                matched = matched + 1
            end
            reconciled[#reconciled + 1] = enrichGroupPlayer(player, row)
        end
        -- Group tokens usually own identity, but a complete scoreboard is the
        -- stronger source when the group set contains a transitional,
        -- unqualified same-short-name collision. This is the live leave/join
        -- pattern that used to put one player in two team rows.
        if not groupIdentityConflict then
            return reconciled, {
                source = matched > 0 and "group_authoritative_enriched" or "group_authoritative",
                expected = expectedCount,
                friendlyRows = #friendlyRows,
                matched = matched,
                repaired = 0,
                rejectedScoreboardRows = math.max(0, #friendlyRows - matched),
                scoreboardHadDuplicates = scoreboardHadDuplicates == true,
                groupHadDuplicates = groupHadDuplicates == true,
                groupIdentityConflict = false,
                scoreboardIdentityConflict = scoreboardIdentityConflict,
            }
        end
    end

    if #friendlyRows ~= expectedCount then
        return uniqueGroup, {
            source = #friendlyRows > 0 and "scoreboard_partial" or "group_roster",
            expected = expectedCount,
            friendlyRows = #friendlyRows,
            repaired = 0,
            scoreboardHadDuplicates = scoreboardHadDuplicates == true,
            groupHadDuplicates = groupHadDuplicates == true,
            groupIdentityConflict = groupIdentityConflict,
            scoreboardIdentityConflict = scoreboardIdentityConflict,
        }
    end

    local byGuid, byName, byShort, shortCounts = rosterIdentityMaps(uniqueGroup)
    local used, reconciled, repaired = {}, {}, 0
    for _, row in ipairs(friendlyRows) do
        local guid = KWR.Util:Text(row.guid, "", 80)
        local full, short = nameKeys(row.name)
        local matched = guid ~= "" and byGuid[guid] or nil
        if not matched and full then matched = byName[full] end
        if not matched and short and shortCounts[short] == 1 then
            matched = byShort[short]
        end
        if matched and used[matched] then matched = nil end
        if matched then used[matched] = true else repaired = repaired + 1 end

        local player = matched and KWR.Util:Copy(matched) or {}
        player.name = KWR.Util:Text(row.name, player.name or "Unknown", 64)
        player.shortName = KWR.Util:ShortName(player.name)
        player.guid = guid ~= "" and guid or KWR.Util:Text(player.guid, "", 80)
        player.class = KWR.Util:Text(row.class, player.class or "Unknown", 32)
        player.classFile = KWR.Util:Upper(
            row.classFile, player.classFile or "UNKNOWN", 24)
        player.spec = KWR.Util:Text(row.spec, player.spec, 32)
        player.specSource = row.spec and row.spec ~= ""
            and "scoreboard" or player.specSource
        player.role = KWR.Util:Text(row.role, player.role or "NONE", 12)
        player.connected = matched and matched.connected ~= false or true
        player.dead = matched and matched.dead == true or false
        player.visible = matched and matched.visible == true or false
        player.lastSeenAt = KWR.Util:Now()
        player.location = matched and matched.location or "Position restricted"
        player.locationSource = matched and matched.locationSource or "PvP Scoreboard"
        player.unit = matched and matched.unit or nil
        player.unitStable = matched and matched.unitStable == true or false
        player.rosterSource = matched and "group+scoreboard" or "scoreboard"
        reconciled[#reconciled + 1] = player
    end

    return reconciled, {
        source = "scoreboard_complete",
        expected = expectedCount,
        friendlyRows = #friendlyRows,
        repaired = repaired,
        scoreboardHadDuplicates = scoreboardHadDuplicates == true,
        groupHadDuplicates = groupHadDuplicates == true,
        groupIdentityConflict = groupIdentityConflict,
        scoreboardIdentityConflict = scoreboardIdentityConflict,
    }
end

function TeamResolver:Resolve(roster, reuseScoreboard)
    local rows = reuseScoreboard == true and self.rows or self:ReadRows()
    if reuseScoreboard ~= true then self.rows = rows end
    local native = self:Native()
    local mercenary = type(UnitIsMercenary) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsMercenary, "player"), false)
    local friendlyNames = {}
    local playerGUID
    for _, player in ipairs(roster or {}) do
        local full, short = nameKeys(player.name)
        if full then friendlyNames[full] = true end
        if short then friendlyNames[short] = true end
        if player.unit == "player" then
            playerGUID = KWR.Util:Text(player.guid, "", 80)
        end
    end
    local playerName = KWR.Util:UnitName("player")
    local playerFull, playerShort = nameKeys(playerName)
    local votes = {}
    local selfFaction
    for _, row in ipairs(rows) do
        local full, short = nameKeys(row.name)
        local isPlayer = (playerGUID ~= "" and row.guid ~= "" and row.guid == playerGUID)
            or (playerFull and full == playerFull)
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
    local source = "scoreboard_pending"
    local nativeFaction = native and native.faction or "Unknown"
    local nativeScoreFaction = scoreFactionForFactionName(nativeFaction)

    -- Live battleground truth must prefer the public scoreboard side over the
    -- player's home/native faction. In modern cross-faction PvP the native
    -- faction can differ from the team the player is actually assigned to for
    -- this match, which inverts win-path logic, flag logic, and enemy truth if
    -- we lock to it too early. Native faction remains a fallback only.
    if selfFaction ~= nil then
        candidate = selfFaction
        source = "scoreboard_self"
    elseif bestFaction ~= nil and bestVotes >= 2 and not tied then
        candidate = bestFaction
        source = "scoreboard_roster"
    elseif nativeScoreFaction ~= nil and mercenary ~= true then
        candidate = nativeScoreFaction
        source = "native_lock"
    end

    if candidate ~= nil then
        if self.candidateFaction == candidate then
            self.candidateSamples = self.candidateSamples + 1
        else
            self.candidateFaction = candidate
            self.candidateSamples = 1
        end
        -- Scoreboard self/roster evidence is authoritative when available.
        -- Native faction only stabilizes early frames before live battleground
        -- rows finish populating.
        if source == "scoreboard_self"
            or source == "scoreboard_roster"
            or (source == "native_lock" and selfFaction == nil and bestFaction == nil)
            or self.candidateSamples >= 2 then
            local side, faction = self:SideForScoreFaction(candidate)
            if side then
                self.assigned = {
                    side = side,
                    faction = faction,
                    scoreFaction = candidate,
                    source = source,
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

function TeamResolver:Capture(inPvP, roster, sessionKey, reuseScoreboard)
    if not inPvP then
        self:Reset()
        return self:Native(), {}
    end
    sessionKey = KWR.Util:Text(sessionKey, "", 80)
    if sessionKey ~= "" and self.sessionKey ~= sessionKey then
        self:Reset()
        self.sessionKey = sessionKey
    elseif self.sessionKey == nil and sessionKey ~= "" then
        self.sessionKey = sessionKey
    end
    return self:Resolve(roster, reuseScoreboard)
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
