local _, KWR = ...

local CountdownFrame = {}
KWR.CountdownFrame = CountdownFrame

function CountdownFrame:Build(countdown)
    return countdown or { seconds = 0, ticks = {}, state = "UNKNOWN" }
end

KWR:RegisterModule("CountdownFrame", CountdownFrame)