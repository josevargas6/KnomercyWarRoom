local _, KWR = ...

local Adapter = {}
KWR.SafeSpeechAdapter = Adapter

local function api()
    return type(C_VoiceChat) == "table" and C_VoiceChat or nil
end

function Adapter:IsAvailable()
    local voice = api()
    return voice
        and type(voice.GetTtsVoices) == "function"
        and type(voice.SpeakText) == "function"
        and type(Enum) == "table"
        and type(Enum.VoiceTtsDestination) == "table"
        and Enum.VoiceTtsDestination.LocalPlayback ~= nil
end

function Adapter:ResolveVoiceID(preferred)
    preferred = KWR.Util:Number(preferred, nil)
    local voice = api()
    if not voice or type(voice.GetTtsVoices) ~= "function" then return nil end
    local ok, voices = pcall(voice.GetTtsVoices)
    if not ok or type(voices) ~= "table" then return nil end
    local first
    for _, row in ipairs(voices) do
        local voiceID = KWR.Util:Number(row and (row.voiceID or row.voiceId), nil)
        if voiceID then
            first = first or voiceID
            if preferred and voiceID == preferred then return voiceID end
        end
    end
    return first
end

function Adapter:Stop()
    local voice = api()
    if voice and type(voice.StopSpeakingText) == "function" then
        pcall(voice.StopSpeakingText)
    end
end

function Adapter:Speak(text, options)
    text = KWR.Util:Text(text, "", 600)
    if text == "" or not self:IsAvailable() then return false, "unavailable" end
    options = options or {}
    local voiceID = self:ResolveVoiceID(options.voiceID)
    if not voiceID then return false, "no-voice" end
    local rate = KWR.Util:Clamp(KWR.Util:Number(options.rate, 0) or 0, -10, 10)
    local volume = KWR.Util:Clamp(KWR.Util:Number(options.volume, 75) or 75, 0, 100)
    local ok = pcall(C_VoiceChat.SpeakText,
        voiceID,
        text,
        Enum.VoiceTtsDestination.LocalPlayback,
        rate,
        volume)
    return ok, ok and nil or "api-error"
end

KWR:RegisterModule("SafeSpeechAdapter", Adapter)