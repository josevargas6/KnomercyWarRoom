local KWR = _G.KWR
if not KWR or not KWR.DevTools then return end

local DevTools = KWR.DevTools
local MODULE_NAMES = { "Diagnostics", "Preview", "Verification", "Season2Readiness" }

function DevTools:Deactivate()
    for index = #MODULE_NAMES, 1, -1 do
        local module = KWR:GetModule(MODULE_NAMES[index])
        if module and module.__kwrEnabled then
            KWR:CallModule(module, "OnDisable")
            module.__kwrEnabled = false
        end
    end
    self.active = false
end

function DevTools:Activate()
    if self.version ~= KWR.version then
        return false, "Developer Tools version does not match Commander. Install matching packages."
    end
    for _, name in ipairs(MODULE_NAMES) do
        local module = KWR:GetModule(name)
        if not module then
            self:Deactivate()
            return false, "Developer Tools is incomplete: " .. name
        end
        if not module.__kwrInitialized then
            if not KWR:CallModule(module, "OnInitialize") then
                KWR:CallModule(module, "OnDisable")
                self:Deactivate()
                return false, "Developer Tools initialization failed: " .. name
            end
            module.__kwrInitialized = true
        end
        if not module.__kwrEnabled then
            if not KWR:CallModule(module, "OnEnable") then
                -- An enable callback may subscribe before it fails.
                KWR:CallModule(module, "OnDisable")
                self:Deactivate()
                return false, "Developer Tools activation failed: " .. name
            end
            module.__kwrEnabled = true
        end
    end
    self.active = true
    return true
end

DevTools.loaded = true
