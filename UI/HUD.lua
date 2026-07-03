local _, KWR = ...

local HUD = {}
KWR.HUD = HUD

local function addSection(frame, key, title, y, height)
    local section = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    section:SetPoint("TOPLEFT", 10, y)
    section:SetPoint("TOPRIGHT", -10, y)
    section:SetHeight(height)
    KWR.Theme:Style(section, "panel", "border")
    section.heading = KWR.Theme:Font(section, 9, "gold", "LEFT", "OUTLINE")
    section.heading:SetPoint("TOPLEFT", 8, -6)
    section.heading:SetText(title)
    section.value = KWR.Theme:Font(section, 12, "white", "LEFT")
    section.value:SetPoint("TOPLEFT", 8, -23)
    section.value:SetPoint("BOTTOMRIGHT", -8, 5)
    frame[key] = section
end

function HUD:Create()
    if self.frame then return self.frame end
    local profile = KWR.db.profile.hud
    local frame = CreateFrame("Frame", "KWR_CommandHUD", UIParent, "BackdropTemplate")
    frame:SetSize(350, 408)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    KWR.Theme:MakeMovable(frame, profile)

    frame.brand = KWR.Theme:Title(frame, 16)
    frame.brand:SetPoint("TOPLEFT", 12, -10)
    frame.brand:SetText("KWR SCOUT HUD")
    frame.mode = KWR.Theme:Font(frame, 9, "muted", "RIGHT", "OUTLINE")
    frame.mode:SetPoint("TOPRIGHT", -12, -12)
    frame.mode:SetWidth(150)
    frame.score = KWR.Theme:Font(frame, 18, "white", "CENTER", "OUTLINE")
    frame.score:SetPoint("TOPLEFT", 10, -38)
    frame.score:SetPoint("TOPRIGHT", -10, -38)
    frame.score:SetHeight(28)
    frame.status = KWR.Theme:Font(frame, 9, "green", "CENTER")
    frame.status:SetPoint("TOPLEFT", 10, -64)
    frame.status:SetPoint("TOPRIGHT", -10, -64)

    addSection(frame, "win", "WIN CONDITION", -84, 58)
    addSection(frame, "next", "NEXT OBJECTIVE", -148, 58)
    addSection(frame, "mine", "MY ASSIGNMENT", -212, 58)
    addSection(frame, "caller", "TARGET CALLER", -276, 58)
    addSection(frame, "kill", "KILL TARGET", -340, 58)

    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then KWR.MainWindow:Show("TACTICAL") end
    end)
    self.frame = frame
    return frame
end

function HUD:Update(state)
    self.lastState = state
    if not self.ready then return end
    if self.suppressed then
        if self.frame then self.frame:Hide() end
        return
    end
    if KWR.db.profile.hud.enabled ~= true then
        if self.frame then self.frame:Hide() end
        return
    end
    local frame = self:Create()
    local snapshot, command = state.snapshot, state.command
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local short = definition and definition.short or "WORLD"
    local mine
    for _, assignment in ipairs(state.assignments or {}) do
        if assignment.name == KWR.Util:UnitName("player")
            or assignment.shortName == KWR.Util:ShortName(KWR.Util:UnitName("player")) then
            mine = assignment
            break
        end
    end
    mine = mine or state.assignments[1]
    local enemy = snapshot.combat and snapshot.combat.killTarget
        or (snapshot.enemies and snapshot.enemies[1])
    local signature = KWR.Util:Signature({
        snapshot.context.preview, snapshot.context.inPvP, short,
        snapshot.score.friendly, snapshot.score.enemy, command.signature,
        command.reassessment and command.reassessment.at,
        KWR.db.profile.guidanceMode,
        mine and mine.role, mine and mine.location,
        enemy and enemy.key, enemy and math.floor((enemy.age or 0) / 2),
        enemy and enemy.locationState, enemy and enemy.location,
        enemy and enemy.locationSource, enemy and enemy.engagementRole,
    })
    if self.lastRenderSignature == signature and frame:IsShown() then
        self.renderSkips = (self.renderSkips or 0) + 1
        return
    end
    self.renderUpdates = (self.renderUpdates or 0) + 1
    self.lastRenderSignature = signature
    frame.mode:SetText(snapshot.context.preview and "DESIGN PREVIEW" or (snapshot.context.inPvP and "LIVE COMMAND" or "FORMATION"))
    frame.score:SetText(string.format("|cff4f8cff%s %d|r  -  |cffff3b3b%d|r",
        short, snapshot.score.friendly or 0, snapshot.score.enemy or 0))
    frame.status:SetText((command.reassessment and "REASSESSED  |  " or (command.status .. "  |  "))
        .. tostring(command.confidence) .. " CONFIDENCE")
    frame.win.value:SetText(state.prediction.condition or "Waiting for battlefield truth.")
    local learning = KWR.db.profile.guidanceMode == "LEARNING"
    frame.next.heading:SetText(command.reassessment and "REASSESS RESULT" or "NEXT OBJECTIVE")
    frame.next.value:SetText((command.action or "Queue or join your team.")
        .. (learning and command.switchIf and ("\n|cff8ea3bbSWITCH: " .. KWR.Util:Text(command.switchIf, "", 52) .. "|r") or ""))

    frame.mine.value:SetText(mine and KWR.Assignments:CompactLabel(
        mine, snapshot.context.mapKey) or "Formation role pending.")
    frame.caller.value:SetText(command.who .. (learning and command.ourComposition
        and ("\n" .. KWR.Util:Text(command.ourComposition, "", 42)) or
        ("\nCurrent call: " .. KWR.Util:Text(command.action, "", 55))))

    if enemy then
        frame.kill.value:SetText(enemy.shortName .. "  |  " .. enemy.spec
            .. "\n" .. KWR.EnemyIntel:DescribeLocation(
                enemy, snapshot.context.mapKey, true))
    else
        frame.kill.value:SetText("No enemy intelligence acquired.")
    end
    frame:Show()
end

function HUD:SetSuppressed(suppressed)
    self.suppressed = suppressed == true
    if self.suppressed then
        if self.frame then self.frame:Hide() end
    else
        self:Update(self.lastState or KWR.Store:Get())
    end
end

function HUD:SetEnabled(enabled)
    KWR.db.profile.hud.enabled = enabled == true
    self.ready = true
    self:Update(KWR.Store:Get())
end

function HUD:Toggle()
    self:SetEnabled(not KWR.db.profile.hud.enabled)
end

function HUD:OnInitialize()
    KWR.Store:Subscribe(self, self.Update)
end

function HUD:OnEnable()
    local function activate()
        HUD.ready = true
        HUD:Update(HUD.lastState or KWR.Store:Get())
    end
    if C_Timer and C_Timer.After then C_Timer.After(1.5, activate) else activate() end
end

function HUD:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("HUD", HUD)
