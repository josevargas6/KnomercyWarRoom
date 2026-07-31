local _, KWR = ...

local AssignmentDoctrine = {}
KWR.AssignmentDoctrine = AssignmentDoctrine

local DIRECT = {
    ["Anchor Defender"] = {
        job = "defend",
        backupRole = "Defense Floater",
        coverageWeight = 100,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Anchor coverage breaks the score floor if it fails.",
    },
    ["Node Defender"] = {
        job = "defend",
        backupRole = "Defense Floater",
        coverageWeight = 92,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Node defense preserves the current scoring requirement.",
    },
    ["Defense Floater"] = {
        job = "float",
        backupRole = "Anchor Defender",
        coverageWeight = 82,
        confidence = "MEDIUM",
        stayCommitted = false,
        coverageEffect = "Mobile reserve closes coverage gaps without becoming a permanent sitter.",
    },
    ["Flag Carrier"] = {
        job = "carry",
        backupRole = "Carrier Healer",
        coverageWeight = 100,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Carrier survival is the win path while the flag is live.",
    },
    ["Orb Carrier"] = {
        job = "carry",
        backupRole = "Carrier Peel",
        coverageWeight = 98,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Carrier survival converts objective value only inside supported space.",
    },
    ["Carrier Healer"] = {
        job = "heal",
        backupRole = "Return Healer",
        coverageWeight = 94,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Carrier healer keeps the objective route stable.",
    },
    ["Return Healer"] = {
        job = "heal",
        backupRole = "Carrier Healer",
        coverageWeight = 84,
        confidence = "MEDIUM",
        stayCommitted = false,
        coverageEffect = "Return healer converts grouped offense into a real cap window.",
    },
    ["Main Fight"] = {
        job = "fight",
        backupRole = "Strike Team",
        coverageWeight = 78,
        confidence = "MEDIUM",
        stayCommitted = false,
        coverageEffect = "Main fight pressure must still preserve map coverage elsewhere.",
    },
    ["Strike Team"] = {
        job = "assault",
        backupRole = "Defense Floater",
        coverageWeight = 80,
        confidence = "MEDIUM",
        stayCommitted = false,
        coverageEffect = "Strike pressure is expendable if it breaks the real score floor.",
    },
    ["Tower Sitter"] = {
        job = "defend",
        backupRole = "Defense Floater",
        coverageWeight = 96,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Tower control is direct score authority in EOTS.",
    },
    ["Cart Anchor"] = {
        job = "defend",
        backupRole = "Cart Floater",
        coverageWeight = 95,
        confidence = "HIGH",
        stayCommitted = true,
        coverageEffect = "Cart presence only matters while the route still changes the score.",
    },
    ["Cart Floater"] = {
        job = "float",
        backupRole = "Cart Anchor",
        coverageWeight = 82,
        confidence = "MEDIUM",
        stayCommitted = false,
        coverageEffect = "Cart reserve rotates between escort and delay based on route value.",
    },
}

local function inferred(role)
    role = KWR.Util:Text(role, "", 48)
    if role:find("Defender", 1, true) or role == "Tower Sitter"
        or role == "Blacksmith Spinner" or role == "Flank Defender" then
        return {
            job = "defend",
            backupRole = "Defense Floater",
            coverageWeight = 90,
            confidence = "HIGH",
            stayCommitted = true,
        }
    end
    if role:find("Float", 1, true) or role == "Response Floater"
        or role == "Outer Cap / Float" or role == "Crystal Floater" then
        return {
            job = "float",
            backupRole = "Anchor Defender",
            coverageWeight = 80,
            confidence = "MEDIUM",
            stayCommitted = false,
        }
    end
    if role:find("Healer", 1, true) then
        return {
            job = "heal",
            backupRole = "Main Fight",
            coverageWeight = 84,
            confidence = "MEDIUM",
            stayCommitted = false,
        }
    end
    if role:find("Carrier", 1, true) then
        return {
            job = "carry",
            backupRole = "Carrier Peel",
            coverageWeight = 96,
            confidence = "HIGH",
            stayCommitted = true,
        }
    end
    if role:find("Scout", 1, true) or role == "Capture Team"
        or role == "Enemy Cart Delay" then
        return {
            job = "assault",
            backupRole = "Defense Floater",
            coverageWeight = 76,
            confidence = "MEDIUM",
            stayCommitted = false,
        }
    end
    return {
        job = "fight",
        backupRole = "Strike Team",
        coverageWeight = 72,
        confidence = "MEDIUM",
        stayCommitted = false,
    }
end

function AssignmentDoctrine:Get(role)
    local direct = DIRECT[role]
    if direct then return KWR.Util:Copy(direct) end
    return inferred(role)
end

function AssignmentDoctrine:Decorate(snapshot, assignment, player)
    if not assignment then return assignment end
    local meta = self:Get(assignment.role)
    assignment.job = assignment.job or meta.job
    assignment.backupRole = assignment.backupRole or meta.backupRole
    assignment.coverageWeight = assignment.coverageWeight or meta.coverageWeight
    assignment.assignmentConfidence =
        assignment.assignmentConfidence or meta.confidence or "MEDIUM"
    assignment.stayCommitted = assignment.stayCommitted
    if assignment.stayCommitted == nil then
        assignment.stayCommitted = meta.stayCommitted == true
    end
    assignment.coverageEffect = assignment.coverageEffect or meta.coverageEffect
        or "Coverage changes when this assignment moves."

    local location = KWR.Util:Text(assignment.location, "objective", 48)
    if not assignment.successCondition then
        if assignment.job == "defend" then
            assignment.successCondition = location .. " remains covered and scoring."
        elseif assignment.job == "carry" then
            assignment.successCondition = "Carrier stays alive and advances the objective."
        elseif assignment.job == "heal" then
            assignment.successCondition = "Assigned group survives the called window."
        elseif assignment.job == "float" then
            assignment.successCondition = "Reserve arrives before the threatened coverage fails."
        else
            assignment.successCondition = "The called pressure changes the map state."
        end
    end
    if not assignment.abortCondition then
        if assignment.job == "defend" then
            assignment.abortCondition = location
                .. " becomes unrecoverable or a named relief arrives."
        elseif assignment.job == "carry" then
            assignment.abortCondition = "Carrier route loses peel or a safer handoff is called."
        else
            assignment.abortCondition = "The called objective loses value or coverage breaks elsewhere."
        end
    end
    if player and snapshot and snapshot.context and snapshot.context.mapKey
        and player.location and player.location ~= assignment.location then
        local cap = KWR.Capabilities:Resolve(player.classFile, player.spec, player.heroTalent)
        local route = KWR.Maps:TravelEstimate(
            snapshot.context.mapKey,
            player.location,
            assignment.location,
            {
                mobility = cap and cap.ratings and cap.ratings.mobility or 2,
                inCombat = player.inCombat,
            })
        if route then
            assignment.expectedArrival = assignment.expectedArrival or route.seconds
            assignment.expectedArrivalBand = assignment.expectedArrivalBand or route.band
        end
    end
    return assignment
end

KWR:RegisterModule("AssignmentDoctrine", AssignmentDoctrine)