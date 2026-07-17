-- rgnMultitool loader/update client for Aimware CS2.
-- Public source: https://github.com/ragnarokcs/rgnMultitool
-- RGN_MULTITOOL_LOADER_V2

local USER = "ragnarokcs"
local REPO = "rgnMultitool"
local BRANCH = "main"
local BASE = "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/"

local DATA_FILE = "rgnMultitool_data.txt"
local LEGACY_MANIFEST_FILE = "rgnMultitool_local_version.txt"
local LEGACY_CACHE_FILE = "rgnMultitool_source_cache.txt"
local EXPECTED_SIGNATURE = "RGN_MULTITOOL_SOURCE_V1"
local DEFAULT_MIN_BYTES = 250000

-- One length-prefixed container stores updater cache and all module settings.
-- Length prefixes allow Lua source, multiline profiles and arbitrary text to
-- coexist without escaping or one-file-per-feature clutter.
local STORE_MAGIC = "RGN_MULTITOOL_DATA_V1\n"
local Store = rawget(_G, "RGN_MULTITOOL_STORE")
if type(Store) ~= "table" or Store.file ~= DATA_FILE or Store.serializerVersion ~= 2 then
    Store = { file = DATA_FILE, entries = {}, dirty = false, serializerVersion = 2 }

    function Store.rawRead(path)
        local data
        pcall(function()
            local f = file.Open(path, "r")
            if f then data = f:Read(); f:Close() end
        end)
        return data
    end

    function Store.rawDelete(path)
        pcall(function() if file and type(file.Delete) == "function" then file.Delete(path) end end)
    end

    local raw = Store.rawRead(DATA_FILE)
    if type(raw) == "string" and raw:sub(1, #STORE_MAGIC) == STORE_MAGIC then
        local pos = #STORE_MAGIC + 1
        while pos <= #raw do
            local lineEnd = raw:find("\n", pos, true)
            if not lineEnd then break end
            local keyLen, valueLen = raw:sub(pos, lineEnd - 1):match("^(%d+):(%d+)$")
            keyLen, valueLen = tonumber(keyLen), tonumber(valueLen)
            if not keyLen or not valueLen then break end
            local keyStart = lineEnd + 1
            local keyEnd = keyStart + keyLen - 1
            local valueStart = keyEnd + 1
            local valueEnd = valueStart + valueLen - 1
            if valueEnd > #raw then break end
            Store.entries[raw:sub(keyStart, keyEnd)] = raw:sub(valueStart, valueEnd)
            pos = valueEnd + 1
        end
    end

    function Store.read(key) return Store.entries[tostring(key)] end
    function Store.write(key, value)
        Store.entries[tostring(key)] = tostring(value or "")
        Store.dirty = true
        return true
    end
    function Store.delete(key)
        Store.entries[tostring(key)] = nil
        Store.dirty = true
        return true
    end
    function Store.flush()
        if not Store.dirty then return true end
        local keys, parts = {}, { STORE_MAGIC }
        for key in pairs(Store.entries) do keys[#keys + 1] = key end
        table.sort(keys)
        for i = 1, #keys do
            local key, value = keys[i], tostring(Store.entries[keys[i]] or "")
            parts[#parts + 1] = tostring(#key) .. ":" .. tostring(#value) .. "\n" .. key .. value
        end
        local ok = false
        pcall(function()
            local f = file.Open(DATA_FILE, "w")
            if f then f:Write(table.concat(parts)); f:Close(); ok = true end
        end)
        if ok then Store.dirty = false end
        return ok
    end
    _G.RGN_MULTITOOL_STORE = Store
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
    return Store.read("updater.version")
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
    local oldSource, oldVersion = Store.read("updater.source"), Store.read("updater.version")
    Store.write("updater.source", source)
    Store.write("updater.version", manifest.version)
    if not Store.flush() then
        Store.entries["updater.source"], Store.entries["updater.version"] = oldSource, oldVersion
        Store.dirty = false
        return nil, "cannot save unified update cache"
    end
    Store.rawDelete(LEGACY_CACHE_FILE)
    Store.rawDelete(LEGACY_MANIFEST_FILE)
    return source, chunk
end

local function migrateLegacyCache(manifest)
    if Store.read("updater.source") then
        Store.rawDelete(LEGACY_CACHE_FILE)
        Store.rawDelete(LEGACY_MANIFEST_FILE)
        return
    end
    local legacySource = Store.rawRead(LEGACY_CACHE_FILE)
    local legacyVersionText = Store.rawRead(LEGACY_MANIFEST_FILE)
    local legacyVersion = type(legacyVersionText) == "string"
        and legacyVersionText:match("version%s*=%s*([^%s]+)") or nil
    local expected = legacyVersion or (manifest and manifest.version)
    local chunk = validateSource(legacySource, expected, manifest and manifest.min_bytes or DEFAULT_MIN_BYTES)
    if not chunk then return end
    Store.write("updater.source", legacySource)
    Store.write("updater.version", expected or "unknown")
    if Store.flush() then
        Store.rawDelete(LEGACY_CACHE_FILE)
        Store.rawDelete(LEGACY_MANIFEST_FILE)
    end
end

local updater = { current_version = nil, remote_version = nil, storage_version = 2 }

function updater.check()
    local manifestText = fetch(BASE .. "version.txt", 16)
    local manifest, manifestError = parseManifest(manifestText)
    if not manifest then return false, "update check failed: " .. tostring(manifestError), "error" end
    updater.remote_version = manifest.version

    local localVersion = readLocalVersion()
    local cached = Store.read("updater.source")
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
migrateLegacyCache(manifest)

if manifest then
    updater.remote_version = manifest.version
    local localVersion = readLocalVersion()
    local cached = Store.read("updater.source")
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
    source = Store.read("updater.source")
    chunk = validateSource(source, nil, DEFAULT_MIN_BYTES)
    if chunk then where = "offline cache" end
end

if not chunk then
    print("[rgnMultitool loader] FATAL: no valid server release or offline cache")
    return
end

updater.current_version = source:match('local RGN_MULTITOOL_VERSION = "([^"]+)"') or "unknown"
print(string.format("[rgnMultitool loader] v%s from %s", updater.current_version, tostring(where)))
local ok, err = pcall(chunk)
if not ok then print("[rgnMultitool loader] run error: " .. tostring(err)) end
