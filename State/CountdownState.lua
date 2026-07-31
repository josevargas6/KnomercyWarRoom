local _, KWR = ...

local CountdownState = {}
KWR.CountdownState = CountdownState

function CountdownState:Build(seconds)
    seconds = KWR.Util:Clamp(KWR.Util:Number(seconds, 5) or 5, 1, 10)
    local ticks = {}
    for index = seconds, 1, -1 do ticks[#ticks + 1] = index end
    ticks[#ticks + 1] = "GO"
    return { seconds = seconds, ticks = ticks, state = "READY" }
end

KWR:RegisterModule("CountdownState", CountdownState)