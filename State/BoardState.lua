local _, KWR = ...

local BoardState = {}
KWR.BoardState = BoardState

function BoardState:FromSnapshot(snapshot, factStore)
    return KWR.BoardStateBuilder:Build(snapshot, factStore)
end

function BoardState:Enemies(board)
    return board and board.enemies or {}
end

function BoardState:Friendlies(board)
    return board and board.friendlies or {}
end

function BoardState:Objectives(board)
    return board and board.objectives or {}
end

function BoardState:Summary(board)
    return board and board.summary or {}
end

KWR:RegisterModule("BoardState", BoardState)