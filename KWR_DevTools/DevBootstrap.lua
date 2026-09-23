local KWR = _G.KWR
if not KWR then return end

-- The build stamps the companion version from the canonical Commander TOC.
KWR.DevTools = {
    version = "@KWR_VERSION@",
    loaded = false,
    active = false,
}
