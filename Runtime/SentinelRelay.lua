local _, KWR = ...

local SentinelRelay = {}
KWR.SentinelRelay = SentinelRelay

local function text(value, fallback, maximum)
    return KWR.Util:Text(value, fallback or "", maximum or 96)
end

local function shortName(value)
    return KWR.Util:ShortName(text(value, "", 64)):lower()
end

local function assignmentFor(assignments, playerName)
    for _, assignment in ipairs(assignments or {}) do
        if shortName(assignment.name or assignment.shortName) == shortName(playerName) then
            return assignment
        end
    end
    return nil
end

function SentinelRelay:Build(playerName, state)
    local assignment = assignmentFor(state.assignments, playerName) or {}
    local execution = state.snapshot and state.snapshot.executionCommand or {}
    local personal = KWR.ExecutionCommandBuilder and KWR.ExecutionCommandBuilder:PersonalFor(
        execution, playerName, nil) or {}
    local command = state.command or {}
    return {
        RELAY_ASSIGN = table.concat({
            "to=" .. text(playerName, "", 64):gsub("[^%w%._%-]", "_"),
            "role=" .. text(personal.role or assignment.role, "HOLD", 24),
            "where=" .. text(personal.location or assignment.location, "UNKNOWN", 48),
            "move=" .. text(personal.movement or assignment.movement, "STAY", 24),
        }, ";"),
        RELAY_CONTROL = table.concat({
            "to=" .. text(playerName, "", 64):gsub("[^%w%._%-]", "_"),
            "target=" .. text(personal.target, "NONE", 64),
            "mode=" .. text(personal.shortRole or personal.role, "WATCH", 24),
            "fixed=" .. ((assignment.fixed == true) and "1" or "0"),
        }, ";"),
        RELAY_ACTION = table.concat({
            "to=" .. text(playerName, "", 64):gsub("[^%w%._%-]", "_"),
            "action=" .. text(command.action, "HOLD", 96):gsub("[^%w%._%-]", "_"),
            "when=" .. text(command.when, "NOW", 24),
            "sig=" .. text(execution.signature, "", 48):gsub("[^%w%._%-]", "_"),
        }, ";"),
    }
end

KWR:RegisterModule("SentinelRelay", SentinelRelay)
