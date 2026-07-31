local _, KWR = ...

local Presenter = {}
KWR.CrosshairPresenter = Presenter

function Presenter:Markers(plan)
    local markers = {}
    for _, assignment in ipairs(plan and plan.assignments or {}) do
        markers[#markers + 1] = {
            guid = assignment.targetGUID,
            label = assignment.verb .. " " .. assignment.target,
            mode = "ASSIGNMENT",
        }
    end
    if plan and plan.killTarget then
        markers[#markers + 1] = {
            guid = plan.killTarget.targetGUID,
            label = "Kill " .. plan.killTarget.target,
            mode = "KILL",
        }
    end
    return markers
end

KWR:RegisterModule("CrosshairPresenter", Presenter)