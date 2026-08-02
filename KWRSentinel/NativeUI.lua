local _, Sentinel = ...

local NativeUI = {}
Sentinel.NativeUI = NativeUI

function NativeUI:ToggleMap()
    if BattlefieldMapFrame and BattlefieldMapFrame:IsShown() then
        BattlefieldMapFrame:Hide()
    elseif BattlefieldMapFrame then
        BattlefieldMapFrame:Show()
    end
end

function NativeUI:ToggleScore()
    if type(ToggleScoreFrame) == "function" then
        ToggleScoreFrame()
    end
end

function NativeUI:ToggleRaidFrames()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if type(Sentinel) == "table" and type(Sentinel.Print) == "function" then
        Sentinel:Print("Native raid-frame visibility is protected by Blizzard and cannot be toggled by Sentinel.", true)
    end
    return true
end

function NativeUI:ToggleKWRRoster()
    if type(_G.KWR) == "table" and _G.KWR.CombatRoster and _G.KWR.CombatRoster.Show then
        local frame = _G.KWR.CombatRoster.frame
        if frame and frame:IsShown() then
            _G.KWR.CombatRoster:Hide(false)
        else
            _G.KWR.CombatRoster:Show("BOTH", false)
        end
    end
end

Sentinel:RegisterModule("NativeUI", NativeUI)
