local _, KWR = ...

local SentinelRelay = {}
KWR.SentinelRelay = SentinelRelay

local function text(value, fallback, maximum)
    return KWR.Util:Text(value, fallback or "", maximum or 96)
end

local function shortName(value)
    return KWR.Util:ShortName(text(value, "", 64)):lower()
end

local function canonical(value)
    return text(value, "", 96):lower()
end

local function escape(value)
    return (text(value, "", 96):gsub("[^%w%._%-]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function field(key, value, fallback, maximum)
    return key .. "=" .. escape(text(value, fallback, maximum))
end

local function assignmentFor(assignments, playerName)
    for _, assignment in ipairs(assignments or {}) do
        if canonical(assignment.name or assignment.shortName) == canonical(playerName) then
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
            field("to", playerName, "", 64),
            field("role", personal.role or assignment.role, "HOLD", 24),
            field("where", personal.location or assignment.location, "UNKNOWN", 48),
            field("move", personal.movement or assignment.movement, "STAY", 24),
        }, ";"),
        RELAY_CONTROL = table.concat({
            field("to", playerName, "", 64),
            field("target", personal.target, "NONE", 64),
            field("mode", personal.shortRole or personal.role, "WATCH", 24),
            "fixed=" .. ((assignment.fixed == true) and "1" or "0"),
        }, ";"),
        RELAY_ACTION = table.concat({
            field("to", playerName, "", 64),
            field("action", command.action, "HOLD", 96),
            field("when", command.when, "NOW", 24),
            field("sig", execution.signature, "", 48),
        }, ";"),
    }
end

KWR:RegisterModule("SentinelRelay", SentinelRelay)
