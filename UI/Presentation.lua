local _, KWR = ...

local Presentation = {
    active = false,
    session = nil,
}
KWR.Presentation = Presentation

local function currentState(fallback)
    if fallback then
        return fallback
    end
    if KWR.Store and type(KWR.Store.Get) == "function" then
        return KWR.Store:Get()
    end
    return nil
end

local function setNativeRaidFramesShown(shown)
    return shown == true
end

function Presentation:IsEnabled()
    local profile = KWR.db.profile.presentation or {}
    return profile.enabled ~= false
end

function Presentation:ShouldActivate(state)
    return self:IsEnabled()
        and KWR.Util:AllowsCompactBattlefieldSurfaces(state)
        and KWR.Util:Boolean(state and state.snapshot and state.snapshot.context
            and state.snapshot.context.preview, false) ~= true
end

function Presentation:AutoShowSurfaces()
    if self.session and self.session.autoShown then return end
    self.session = self.session or {}
    self.session.autoShown = true
    self.session.rosterShown = KWR.CombatRoster and KWR.CombatRoster:AnyShown() or false
    self.session.teamShown = KWR.CombatRoster and KWR.CombatRoster:IsShown("TEAM") or false
    self.session.enemyShown = KWR.CombatRoster and KWR.CombatRoster:IsShown("ENEMY") or false

    if KWR.MainWindow and KWR.MainWindow.frame
        and KWR.MainWindow.frame:IsShown() then
        return
    end

end

function Presentation:ApplyNativeCleanup()
    local profile = KWR.db.profile.presentation or {}
    if profile.hideRaidFrames ~= true then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    self.session = self.session or {}
    if self.session.raidFramesCaptured ~= true then
        self.session.raidFramesCaptured = true
        self.session.raidManagerShown = CompactRaidFrameManager
            and CompactRaidFrameManager:IsShown() or false
        self.session.raidContainerShown = CompactRaidFrameContainer
            and CompactRaidFrameContainer:IsShown() or false
    end
    self.session.raidFrameControlSkipped = true
end

function Presentation:RestoreNativeCleanup(session)
    session = session or self.session
    if type(session) ~= "table" or session.raidFramesCaptured ~= true then
        return
    end
    session.raidFrameControlSkipped = true
end

function Presentation:RestoreSurfaces()
    local session = self.session
    self.session = nil
    if not session then return end
    self:RestoreNativeCleanup(session)
    if KWR.MainWindow and KWR.MainWindow.frame
        and KWR.MainWindow.frame:IsShown() then
        return
    end
    local state = currentState(self.lastState)
    if not state then
        return
    end
    local profile = KWR.db.profile.presentation or {}
    if not KWR.Util:AllowsCompactBattlefieldSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        if KWR.CombatRoster then
            KWR.CombatRoster:Hide(false)
        end
        return
    end

    if session.rosterShown and KWR.CombatRoster then
        KWR.CombatRoster:RequestVisibility(
            session.teamShown == true,
            session.enemyShown == true,
            false)
    elseif KWR.CombatRoster then
        KWR.CombatRoster:Hide(false)
    end
end

function Presentation:Activate(state)
    self.active = true
    self.lastState = currentState(state or self.lastState)
    self:AutoShowSurfaces()
    self:ApplyNativeCleanup()
end

function Presentation:Deactivate()
    if not self.active and not self.session then return end
    self.active = false
    self:RestoreSurfaces()
end

function Presentation:RefreshNow()
    local state = currentState(self.lastState)
    if not state then
        return
    end
    if self:ShouldActivate(state) then
        self:Activate(state)
    else
        self:Deactivate()
    end
end

function Presentation:QueueRefresh(delay)
    local token = (self.refreshToken or 0) + 1
    self.refreshToken = token
    local function run()
        if token ~= Presentation.refreshToken then return end
        Presentation:RefreshNow()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 0.05, run)
    else
        run()
    end
end

function Presentation:Update(state)
    self.lastState = state
    if self:ShouldActivate(state) then
        self:Activate(state)
        if not self.lastActivationRevision or self.lastActivationRevision ~= (state and state.revision) then
            self.lastActivationRevision = state and state.revision
            self:QueueRefresh(0.15)
            self:QueueRefresh(0.85)
        end
    else
        self.lastActivationRevision = nil
        self:Deactivate()
    end
end

function Presentation:OnInitialize()
    self.frame = CreateFrame("Frame", "KWR_PresentationController")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD"
            or event == "PLAYER_LEAVING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            Presentation:QueueRefresh(0.10)
        end
    end)
    if KWR.Store and KWR.Store.Subscribe then
        KWR.Store:Subscribe(self, self.Update)
    end
end

function Presentation:OnEnable()
    self:QueueRefresh(0.25)
end

function Presentation:OnDisable()
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
    self:Deactivate()
end

KWR:RegisterModule("Presentation", Presentation)