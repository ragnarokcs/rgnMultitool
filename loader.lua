-- Primary rgnMultitool entry point for Aimware CS2.
-- Source: https://github.com/ragnarokcs/rgnMultitool

local LOADER_VERSION = "1.1.0"
local USER = "ragnarokcs"
local REPO = "rgnMultitool"
local BRANCH = "main"
local BASE = "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/"

local MANIFEST_FILE = "rgnMultitool_local_version.txt"
local CACHE_FILE = "rgnMultitool_source_cache.txt"
local EXPECTED_SIGNATURE = "RGN_MULTITOOL_SOURCE_V1"
local DEFAULT_MIN_BYTES = 250000

local function readFile(path)
    if type(file) == "table" and type(file.Read) == "function" then
        local ok, data = pcall(file.Read, path)
        if ok and type(data) == "string" then return data end
    end
    local data
    pcall(function()
        local f = file.Open(path, "r")
        if f then data = f:Read(); f:Close() end
    end)
    return data
end

local function writeFile(path, data)
    if type(file) == "table" and type(file.Write) == "function" then
        local ok = pcall(file.Write, path, data)
        if ok then return true end
    end
    local ok = false
    pcall(function()
        local f = file.Open(path, "w")
        if f then f:Write(data); f:Close(); ok = true end
    end)
    return ok
end

local function fetch(url, minBytes)
    local body
    local bust = url .. "?nocache=" .. tostring({}):gsub("%W", "")
    pcall(function() body = http.Get(bust) end)
    if type(body) ~= "string" or #body < (minBytes or 1) then
        pcall(function() body = http.Get(url) end)
    end
    if type(body) == "string" and #body >= (minBytes or 1) then return body end
    return nil
end

local function parseManifest(text)
    if type(text) ~= "string" then return nil, "manifest unavailable" end
    local out = {}
    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
        if key and value and value ~= "" then out[key] = value end
    end
    if not out.version or not out.source then return nil, "invalid manifest" end
    if not out.source:match("^[%w%._%-%/]+$") or out.source:find("..", 1, true) then
        return nil, "unsafe source path"
    end
    out.min_bytes = tonumber(out.min_bytes) or DEFAULT_MIN_BYTES
    return out
end

local function readLocalVersion()
    local text = readFile(MANIFEST_FILE)
    if type(text) ~= "string" then return nil end
    return text:match("version%s*=%s*([^%s]+)")
end

local function validateSource(source, expectedVersion, minBytes)
    if type(source) ~= "string" or #source < (minBytes or DEFAULT_MIN_BYTES) then
        return nil, "source is missing or truncated"
    end
    if not source:find(EXPECTED_SIGNATURE, 1, true) then
        return nil, "source signature mismatch"
    end
    if expectedVersion then
        local marker = 'local RGN_MULTITOOL_VERSION = "' .. expectedVersion .. '"'
        if not source:find(marker, 1, true) then return nil, "source version mismatch" end
    end
    local chunk, err = loadstring(source, "=rgnMultitool.lua")
    if not chunk then return nil, "compile error: " .. tostring(err) end
    return chunk
end

local function downloadRelease(manifest)
    local source = fetch(BASE .. manifest.source, manifest.min_bytes)
    local chunk, err = validateSource(source, manifest.version, manifest.min_bytes)
    if not chunk then return nil, err end
    if not writeFile(CACHE_FILE, source) then return nil, "cannot write update cache" end
    if not writeFile(MANIFEST_FILE, "version=" .. manifest.version .. "\n") then
        return nil, "cannot save local version"
    end
    return source, chunk
end

local updater = {
    loader_version = LOADER_VERSION,
    current_version = nil,
    remote_version = nil,
}

function updater.check()
    local manifestText = fetch(BASE .. "version.txt", 16)
    local manifest, manifestError = parseManifest(manifestText)
    if not manifest then return false, "update check failed: " .. tostring(manifestError), "error" end
    updater.remote_version = manifest.version

    local localVersion = readLocalVersion()
    local cached = readFile(CACHE_FILE)
    local cachedChunk = validateSource(cached, manifest.version, manifest.min_bytes)
    if localVersion == manifest.version and cachedChunk then
        updater.current_version = manifest.version
        return true, "rgnMultitool is up to date (v" .. manifest.version .. ")", "current"
    end

    local source, err = downloadRelease(manifest)
    if not source then return false, "update failed: " .. tostring(err), "error" end
    updater.current_version = manifest.version
    return true, "Update v" .. manifest.version .. " downloaded. Run the Lua again to apply.", "downloaded"
end

_G.RGN_MULTITOOL_BASE = BASE
_G.RGN_MULTITOOL_UPDATER = updater

local manifestText = fetch(BASE .. "version.txt", 16)
local manifest = parseManifest(manifestText)
local source, chunk, where

if manifest then
    updater.remote_version = manifest.version
    local localVersion = readLocalVersion()
    local cached = readFile(CACHE_FILE)
    if localVersion == manifest.version then
        chunk = validateSource(cached, manifest.version, manifest.min_bytes)
        if chunk then source, where = cached, "cache" end
    end
    if not chunk then
        local downloaded, downloadedChunk = downloadRelease(manifest)
        if downloaded then source, chunk, where = downloaded, downloadedChunk, "server" end
    end
end

if not chunk then
    source = readFile(CACHE_FILE)
    chunk = validateSource(source, nil, DEFAULT_MIN_BYTES)
    if chunk then where = "offline cache" end
end

if not chunk then
    print("[rgn loader] no valid release or offline cache")
    return
end

updater.current_version = source:match('local RGN_MULTITOOL_VERSION = "([^"]+)"') or "unknown"
print(string.format("[rgn loader] v%s from %s", updater.current_version, tostring(where)))
local ok, err = pcall(chunk)
if not ok then print("[rgn loader] " .. tostring(err)) end
