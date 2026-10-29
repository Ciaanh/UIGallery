local _, ns = ...

-- The catalogue: families -> components -> examples. Example files fill it at load through
-- ns.AddComponent / ns.AddExample; the UI only reads it.
--
-- Component spec:
--   id, family, title, summary          required
--   clients    string, where the API exists ("Retail, Forever"), from the Blizzard refs
--   requires   { capability, ... }      see Capabilities.LABELS
--   whenToUse  { line, ... }
--   api        { { name, description [, default] }, ... }   the "options" table of the page
--   refs       { path, ... }             Blizzard source files, relative to Interface/AddOns/
--   keywords   string                    extra words for the search box
--
-- Example spec:
--   id, title, create(stage) -> widget   required; create anchors its widget in `stage`
--   description, height (stage height, default 120), requires
--   code       { snippetId | { snippetId, tabLabel }, ... }   the @snippet regions shown under
--              the preview, one tab each (labelled Lua / XML unless a tabLabel is given)
--   controls   { control spec, ... }    see Controls.lua; each change calls apply
--   apply(widget, key, value, values)   values = every control's current value
local Registry = {}
ns.Registry = Registry

Registry.FAMILIES = {
    { id = "progress", title = "Progress & timers" },
    { id = "controls", title = "Controls" },
    { id = "layout", title = "Layout & containers" },
    { id = "visuals", title = "Visuals" },
}

local familyById = {}
for _, family in ipairs(Registry.FAMILIES) do
    family.components = {}
    familyById[family.id] = family
end

local components, examples = {}, {}

function ns.AddComponent(spec)
    assert(type(spec.id) == "string" and not components[spec.id],
        "AddComponent: missing or duplicate id " .. tostring(spec.id))
    local family = familyById[spec.family]
    assert(family, "AddComponent " .. spec.id .. ": unknown family " .. tostring(spec.family))
    assert(type(spec.title) == "string" and type(spec.summary) == "string",
        "AddComponent " .. spec.id .. ": title and summary are required")
    spec.examples = {}
    spec.familyTitle = family.title
    components[spec.id] = spec
    table.insert(family.components, spec)
    return spec
end

function ns.AddExample(componentId, spec)
    local component = components[componentId]
    assert(component, "AddExample: unknown component " .. tostring(componentId))
    assert(type(spec.id) == "string" and not examples[spec.id],
        "AddExample: missing or duplicate id " .. tostring(spec.id))
    assert(type(spec.create) == "function", "AddExample " .. spec.id .. ": create is required")
    spec.component = component
    spec.code = spec.code or {}
    spec.controls = spec.controls or {}
    examples[spec.id] = spec
    table.insert(component.examples, spec)
    return spec
end

function Registry:Get(componentId)
    return components[componentId]
end

function Registry:First()
    for _, family in ipairs(self.FAMILIES) do
        if family.components[1] then
            return family.components[1]
        end
    end
end

-- Plain-text search over the title, id, summary and keywords.
function Registry:Matches(component, query)
    if not query or query == "" then
        return true
    end
    query = query:lower()
    local haystack = (component.title .. " " .. component.id .. " " .. component.summary .. " "
        .. (component.keywords or "")):lower()
    return haystack:find(query, 1, true) ~= nil
end

function Registry:Snippet(snippetId)
    return ns.Snippets and ns.Snippets[snippetId]
end
