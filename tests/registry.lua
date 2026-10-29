-- registry.lua ROOT: loads every Lua file of the toc, in order, against a few stubs, then checks the
-- catalogue: each family has components, each component has a summary, examples and well-formed
-- API rows, each example's snippets exist and its controls are valid, no snippet is orphaned,
-- XML mixins exist, and the files add no globals beyond the allowed ones.
local root = (arg[1] or "."):gsub("\\", "/"):gsub("/+$", "")

local function read(path)
    local f = io.open(root .. "/" .. path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local failures = {}
local function check(cond, msg)
    if not cond then failures[#failures + 1] = msg end
end

-- Stubs: only what the files touch at load time (the UI is built later, in game).
local function Stub()
    return setmetatable({}, { __index = function() return function() end end })
end
CreateFrame = function() return Stub() end
SlashCmdList = {}
StaticPopupDialogs = {}
Enum = {}
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local before = {}
for k in pairs(_G) do before[k] = true end

local ns = {}
local toc = assert(read("UIGallery.toc"), "cannot read UIGallery.toc")
local luaFiles, xmlFiles = {}, {}
for entry in toc:gmatch("[^\r\n]+") do
    local path = entry:match("^%s*([^#%s].-)%s*$")
    if path then
        path = path:gsub("\\", "/")
        if path:match("%.lua$") then luaFiles[#luaFiles + 1] = path end
        if path:match("%.xml$") then xmlFiles[#xmlFiles + 1] = path end
    end
end

for _, path in ipairs(luaFiles) do
    local chunk, err = loadfile(root .. "/" .. path)
    if not chunk then
        check(false, "load " .. path .. ": " .. tostring(err))
    else
        local ok, runErr = pcall(chunk, "UIGallery", ns)
        check(ok, "run " .. path .. ": " .. tostring(runErr))
    end
end

-- Globals: SavedVariables are set later; these are the only ones the files may define.
local ALLOWED = {
    SLASH_UIGALLERY1 = true, SLASH_UIGALLERY2 = true, UIGallery_OnAddonCompartmentClick = true,
}
for k in pairs(_G) do
    if not before[k] and not ALLOWED[k] then
        check(type(k) == "string" and k:match("^UIGallery%w*Mixin$"),
            "unexpected global " .. tostring(k) .. " (only UIGallery*Mixin tables for XML examples)")
    end
end

local Registry, Capabilities, Snippets = ns.Registry, ns.Capabilities, ns.Snippets or {}
check(Registry and Capabilities, "core modules missing")
if not (Registry and Capabilities) then
    print(table.concat(failures, "\n"))
    os.exit(1)
end

local CONTROL_TYPES = { slider = true, check = true, choice = true, button = true }
local used, componentCount, exampleCount = {}, 0, 0

local function CheckRequires(where, requires)
    for _, name in ipairs(requires or {}) do
        check(Capabilities.LABELS[name], where .. ": unknown capability " .. tostring(name))
    end
end

local function CheckControls(where, example)
    local keys = {}
    for i, spec in ipairs(example.controls) do
        local at = ("%s control %d"):format(where, i)
        check(CONTROL_TYPES[spec.type], at .. ": unknown type " .. tostring(spec.type))
        check(type(spec.key) == "string" and not keys[spec.key], at .. ": missing or duplicate key")
        keys[spec.key or i] = true
        check(type(spec.label) == "string", at .. ": no label")
        if spec.type == "slider" then
            check(spec.min < spec.max and spec.step > 0, at .. ": bad range")
            check(spec.default >= spec.min and spec.default <= spec.max, at .. ": default out of range")
        elseif spec.type == "choice" then
            local found = false
            for _, choice in ipairs(spec.choices or {}) do
                if choice[1] == spec.default then found = true end
            end
            check(found, at .. ": default not among the choices")
        elseif spec.type == "check" then
            check(type(spec.default) == "boolean", at .. ": check default must be a boolean")
        end
    end
    if #example.controls > 0 then
        check(type(example.apply) == "function", where .. ": controls without apply")
    end
end

for _, family in ipairs(Registry.FAMILIES) do
    check(#family.components > 0, "family " .. family.id .. " has no component")
    for _, component in ipairs(family.components) do
        componentCount = componentCount + 1
        local where = "component " .. component.id
        check(#component.summary > 20, where .. ": summary too short")
        check(#component.examples > 0, where .. ": no example")
        CheckRequires(where, component.requires)
        for i, row in ipairs(component.api or {}) do
            check(type(row[1]) == "string" and type(row[2]) == "string", ("%s: api row %d malformed"):format(where, i))
        end
        for _, example in ipairs(component.examples) do
            exampleCount = exampleCount + 1
            local at = "example " .. example.id
            check(type(example.title) == "string", at .. ": no title")
            CheckRequires(at, example.requires)
            check(#example.code > 0, at .. ": no code")
            for _, entry in ipairs(example.code) do
                local snippetId = type(entry) == "table" and entry[1] or entry
                check(Snippets[snippetId], at .. ": unknown snippet " .. tostring(snippetId))
                used[snippetId] = true
            end
            CheckControls(at, example)
        end
    end
end

for id in pairs(Snippets) do
    check(used[id], "snippet " .. id .. " is shown by no example")
end

for _, path in ipairs(xmlFiles) do
    local text = read(path) or ""
    for mixin in text:gmatch('mixin="([^"]+)"') do
        check(type(_G[mixin]) == "table", path .. ": mixin " .. mixin .. " is not defined by any Lua file")
    end
    for name in text:gmatch('name="([^"]+)"') do
        check(name:match("^UIGallery"), path .. ": template " .. name .. " is not prefixed UIGallery")
    end
end

if #failures > 0 then
    print(table.concat(failures, "\n"))
    os.exit(1)
end
print(("%d components, %d examples, all consistent"):format(componentCount, exampleCount))
