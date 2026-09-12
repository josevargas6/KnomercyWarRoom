local _, KWR = ...

local CountdownFrame = {}
KWR.CountdownFrame = CountdownFrame

function CountdownFrame:Build(countdown)
    return KWR.CountdownState:Project(countdown)
end

KWR:RegisterModule("CountdownFrame", CountdownFrame)
