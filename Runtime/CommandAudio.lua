local _, KWR = ...

local Audio = {
    lastSignature = nil,
    lastSpokenAt = 0,
    pendingToken = 0,
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
    return self:IsEnabled()
        and KWR.SafeSpeechAdapter:IsAvailable()
        and type(packet) == "table"
        and packet.audible == true
        and packet.authoritative == true
        and KWR.Util:Text(packet.spokenText, "", 600) ~= ""
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
    local function speak()
        if token ~= Audio.pendingToken or not Audio:CanSpeak(packet) then return end
        KWR.SafeSpeechAdapter:Stop()
        local ok = KWR.SafeSpeechAdapter:Speak(packet.spokenText, settings)
        if ok then
            Audio.lastSignature = signature
            Audio.lastSpokenAt = KWR.Util:Now()
        end
    end
    if delay > 0 and C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(delay, speak)
        return true, "queued"
    end
    speak()
    return true, "spoken"
end

function Audio:Repeat()
    local state = KWR.Store and KWR.Store:Get()
    local packet = state and state.snapshot and state.snapshot.executionCommand
    return self:SpeakPacket(packet, true)
end

function Audio:Observe(state)
    local packet = state and state.snapshot and state.snapshot.executionCommand
    return self:SpeakPacket(packet, false)
end

function Audio:OnInitialize()
    -- MatchRuntime invokes Observe immediately after the single Store publish.
end

KWR:RegisterModule("CommandAudio", Audio)