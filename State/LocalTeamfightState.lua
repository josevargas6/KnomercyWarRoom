local _, KWR = ...

local LocalState = {}
KWR.LocalTeamfightState = LocalState

function LocalState:Build(factStore, snapshot, board)
    board = board or (KWR.BoardState and KWR.BoardState:FromSnapshot(snapshot, factStore))
    local state = {
        enemies = {},
        friendlies = {},
        context = snapshot and snapshot.context or {},
        facts = factStore and factStore.facts or {},
        board = board,
        objectives = KWR.BoardState and KWR.BoardState:Objectives(board) or {},
        confidence = "UNKNOWN",
    }
    for _, enemy in ipairs(KWR.BoardState and KWR.BoardState:Enemies(board) or {}) do
        state.enemies[#state.enemies + 1] = enemy.source or enemy
    end
    for _, player in ipairs(KWR.BoardState and KWR.BoardState:Friendlies(board) or {}) do
        state.friendlies[#state.friendlies + 1] = player.source or player
    end
    state.confidence = (#state.enemies > 0 and #state.friendlies > 0) and "INFERRED" or "UNKNOWN"
    return state
end

KWR:RegisterModule("LocalTeamfightState", LocalState)