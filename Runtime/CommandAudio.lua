local _, KWR = ...

local Audio = {
    lastSignature = nil,
    lastSpokenAt = 0,
    pendingToken = 0,
    acknowledgements = 0,
    lastAcknowledgedAt = 0,
}
KWR.CommandAudio = Audio

local function profile()
    return KWR.db and KWR.db.profile and KWR.db.profile.hud
        and KWR.db.profile.hud.audio or {}
end

function Audio:IsEnabled()
    return profile().enabled == true
end

function Audio:SetEnabled(enabled)
    profile().enabled = enabled == true
    if not enabled then
        self.pendingToken = self.pendingToken + 1
        KWR.SafeSpeechAdapter:Stop()
    end
    return true
end

function Audio:CanSpeak(packet)
    if type(packet) == "table" and packet.countdown and packet.countdown.id then
        local projected = KWR.CountdownState:Project(packet.countdown)
        if projected.state == "UNTIMED" or projected.text ~= packet.countdown.text then return false end
    end
    return self:IsEnabled()
        and KWR.SafeSpeechAdapter:IsAvailable()
        and type(packet) == "table"
        and packet.audible == true
        and packet.authoritative == true
        and KWR.Util:Text(packet.spokenText, "", 600) ~= ""
end

function Audio:IsCurrent(packet)
    -- A queued voice callback may outlive the Store revision that made it.
    -- Old packets lacking lifecycle identity remain usable for legacy/manual
    -- callers, but every production builder packet binds to exact command ID
    -- and revision before it is allowed to speak.
    if type(packet) ~= "table" then return false end
    local commandId = KWR.Util:Text(packet.commandId, "", 192)
    local revision = KWR.Util:Number(packet.commandRevision, nil)
    if commandId == "" or revision == nil then return true end
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    local command = state and state.command or nil
    if type(command) ~= "table" or command.commandId ~= commandId
        or command.commandRevision ~= revision then
        return false
    end
    local current = state.snapshot and state.snapshot.executionCommand or nil
    local signature = KWR.Util:Text(packet.signature, "", 240)
    if type(current) == "table" and signature ~= ""
        and KWR.Util:Text(current.signature, "", 240) ~= signature then
        return false
    end
    return true
end

function Audio:SpeakPacket(packet, force)
    if not self:CanSpeak(packet) then return false, "silent" end
    local signature = KWR.Util:Text(packet.signature, "", 240)
    if not force and signature ~= "" and signature == self.lastSignature then
        return false, "duplicate"
    end
    self.pendingToken = self.pendingToken + 1
    local token = self.pendingToken
    local settings = profile()
    local minimum = KWR.Util:Clamp(
        KWR.Util:Number(settings.minimumInterval, 6) or 6, 2, 30)
    local now = KWR.Util:Now()
    local delay = force and 0 or math.max(0, minimum - (now - (self.lastSpokenAt or 0)))
    local function speak(requireCurrent)
        if token ~= Audio.pendingToken or (requireCurrent and not Audio:IsCurrent(packet))
            or not Audio:CanSpeak(packet) then return end
        KWR.SafeSpeechAdapter:Stop()
        local ok = KWR.SafeSpeechAdapter:Speak(packet.spokenText, settings)
        if ok then
            Audio.lastSignature = signature
            Audio.lastSpokenAt = KWR.Util:Now()
        end
    end
    if delay > 0 and C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(delay, function() speak(true) end)
        return true, "queued"
    end
    speak(false)
    return true, "spoken"
end

function Audio:Replay()
    local state = KWR.Store and KWR.Store:Get()
    local packet = state and state.snapshot and state.snapshot.executionCommand
    if not state or not state.command or type(packet) ~= "table"
        or KWR.Util:Text(packet.canonicalCommandSignature, "", 240) == ""
        or packet.canonicalCommandSignature ~= state.command.signature
        or packet.commandAction ~= state.command.action then
        return false, "command_conflict"
    end
    local ok, status = self:SpeakPacket(packet, true)
    if ok then
        self.acknowledgements = (self.acknowledgements or 0) + 1
        self.lastAcknowledgedAt = KWR.Util:Now()
    end
    return ok, status
end

function Audio:Acknowledge()
    self.acknowledgements = (self.acknowledgements or 0) + 1
    self.lastAcknowledgedAt = KWR.Util:Now()
end

function Audio:Observe(state)
    local packet = state and state.snapshot and state.snapshot.executionCommand
    if not state or not state.command or type(packet) ~= "table"
        or KWR.Util:Text(packet.canonicalCommandSignature, "", 240) == ""
        or packet.canonicalCommandSignature ~= state.command.signature
        or packet.commandAction ~= state.command.action then
        return false, "command_conflict"
    end
    return self:SpeakPacket(packet, false)
end

function Audio:OnInitialize()
    -- MatchRuntime invokes Observe immediately after the single Store publish.
end

KWR:RegisterModule("CommandAudio", Audio)
