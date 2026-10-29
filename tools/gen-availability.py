"""Per-client availability of every API row, from the Blizzard UI source (never shipped itself).

    python tools/gen-availability.py            # writes generated/Availability.lua
    python tools/gen-availability.py --check    # fails when the file is stale
    python tools/gen-availability.py --query CreateFramePool HelpTip:Show "Enum.StatusBarRenderMode"
    python tools/gen-availability.py --rebuild  # rescans the clients (cached in .build/)

Reads ../Blizzard_UI_refs (next to the repo in the workspace). Each client tree is indexed once:
XML names (templates, frames), Lua function definitions and top-level assignments, and the
generated API documentation (functions, script object methods, enumerations). The symbols of an
API row are read from its name column: templates passed to CreateFrame, obj:Method(...) calls,
A.B(...) functions, bare Global(...) calls, Enum.X, and the "/ Alternative" names after a slash.
A row without any recognisable symbol gets no badge.
"""
import json
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
REFS = os.path.normpath(os.path.join(ROOT, "..", "Blizzard_UI_refs"))
CACHE = os.path.join(ROOT, ".build")
OUTPUT = os.path.join(ROOT, "generated", "Availability.lua")
CLIENTS = [("retail", "Retail"), ("forever", "Forever"), ("classic", "Classic")]

XML_NAME = re.compile(r'\bname="([A-Za-z_][\w]*)"')
LUA_FUNCTION = re.compile(r'^\s*(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(', re.M)
LUA_ASSIGN = re.compile(r'^([A-Za-z_][\w.]*)\s*=(?!=)', re.M)
DOC_NAMESPACE = re.compile(r'\bNamespace\s*=\s*"([\w.]+)"')
CALLED_METHOD = re.compile(r':([A-Za-z_]\w*)\s*\(')
CALLED_GLOBAL = re.compile(r'(?<![\w.:])([A-Z]\w*)\s*\(')
DOC_NAME = re.compile(r'\bName\s*=\s*"(\w+)",\s*\n\s*Type\s*=\s*"(\w+)"')


def build_index(tree):
    names, functions, methods, globals_, enums = set(), set(), set(), set(), set()
    called_methods, called = set(), set()
    for folder, _, files in os.walk(tree):
        docs = os.path.basename(folder) == "Blizzard_APIDocumentationGenerated"
        for file in files:
            path = os.path.join(folder, file)
            if file.endswith(".xml"):
                text = open(path, encoding="utf-8", errors="replace").read()
                names.update(XML_NAME.findall(text))
            elif file.endswith(".lua"):
                text = open(path, encoding="utf-8", errors="replace").read()
                if docs:
                    match = DOC_NAMESPACE.search(text)
                    namespace = match.group(1) if match else None
                    for name, kind in DOC_NAME.findall(text):
                        if kind == "Function":
                            methods.add(name)
                            functions.add(namespace + "." + name if namespace else name)
                        elif kind == "Enumeration":
                            enums.add(name)
                    continue
                for full in LUA_FUNCTION.findall(text):
                    functions.add(full.replace(":", "."))
                    methods.add(re.split(r"[.:]", full)[-1])
                globals_.update(LUA_ASSIGN.findall(text))
                called_methods.update(CALLED_METHOD.findall(text))
                called.update(CALLED_GLOBAL.findall(text))
    return {
        "names": sorted(names), "functions": sorted(functions), "methods": sorted(methods),
        "globals": sorted(globals_), "enums": sorted(enums),
        "called_methods": sorted(called_methods), "called": sorted(called),
    }


def load_index(key, folder, rebuild):
    tree = os.path.join(REFS, folder, "BlizzardInterfaceCode", "Interface", "AddOns")
    if not os.path.isdir(tree):
        sys.exit("missing Blizzard UI source: " + tree)
    path = os.path.join(CACHE, "refs-index-" + key + ".json")
    if not rebuild and os.path.exists(path):
        data = json.load(open(path, encoding="utf-8"))
    else:
        data = build_index(tree)
        os.makedirs(CACHE, exist_ok=True)
        json.dump(data, open(path, "w", encoding="utf-8"))
    return {k: set(v) for k, v in data.items()}


def present(index, kind, symbol):
    # "A|B": alternatives (a shorthand name and its expansions); any of them will do.
    if "|" in symbol:
        return any(present(index, kind, alternative) for alternative in symbol.split("|"))
    if kind == "template":
        return symbol in index["names"]
    if kind == "method":
        # Defined by Blizzard's Lua or the API docs, or called by Blizzard's code (C methods
        # without documentation, like GameTooltip:AddDoubleLine).
        return symbol in index["methods"] or symbol in index["called_methods"]
    if kind == "enum":
        return symbol in index["enums"]
    if kind == "qualified":
        return symbol in index["functions"] or symbol in index["globals"]
    # bare: a global function, a global value, a documented function or a mixin method
    return (symbol in index["functions"] or symbol in index["globals"] or symbol in index["methods"]
            or symbol in index["names"] or symbol in index["called"] or symbol in index["called_methods"])


TEMPLATE_ARG = re.compile(r'CreateFrame\(\s*"\w+"\s*,[^,]*,[^,]*,\s*"(\w+)"')
TEMPLATE_WORD = re.compile(r'\b(?:Template|inherits=")\s*"?([A-Z]\w+)')
METHOD_CALL = re.compile(r'\b\w+:([A-Za-z_]\w*)\s*\(')
QUALIFIED_CALL = re.compile(r'(?<![\w:.])([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+)\s*\(')
ENUM = re.compile(r'\bEnum\.(\w+)')
BARE_CALL = re.compile(r'(?<![\w:."])([A-Z]\w*)\s*\(')
# Lower-case globals (issecretvalue, secretwrap) only as the row's lead name or a "/ name(" one:
# elsewhere a lower-case call is a parameter ("fn(frame, data)").
LOWER_CALL = re.compile(r'(?:^|/)\s*([a-z]\w*)\s*\(')
SLASH_NAME = re.compile(r'/\s*([A-Z]\w+)(?=\s*(?:/|$|\(|\s))')
LEAD_NAME = re.compile(r'\s*(?:\w+:)?([A-Za-z_][\w.]*)')
IGNORED = {"XML", "Lua", "CreateFrame"}


def symbols(row_name):
    found = []
    def add(kind, symbol):
        if symbol not in IGNORED and (kind, symbol) not in found:
            found.append((kind, symbol))
    for match in TEMPLATE_ARG.findall(row_name):
        add("template", match)
    for match in TEMPLATE_WORD.findall(row_name):
        add("template", match)
    for match in ENUM.findall(row_name):
        add("enum", match)
    if "(" not in row_name:
        # Fields and parentKeys ("IncrementButton / DecrementButton"): nothing to look up.
        return found
    has_method = False
    for match in METHOD_CALL.findall(row_name):
        add("method", match)
        has_method = True
    for match in QUALIFIED_CALL.findall(row_name):
        if not match.startswith("Enum."):
            add("qualified", match)
    for match in BARE_CALL.findall(row_name):
        add("bare", match)
    for match in LOWER_CALL.findall(row_name):
        add("bare", match)
    # "/ Name" is often shorthand for the row's first name with its end replaced
    # ("GameTooltip_AddNormalLine / AddErrorLine(...)", "SetFlipBookRows / Columns").
    lead = LEAD_NAME.match(row_name)
    first = lead.group(1) if lead else ""
    if lead and re.match(r'\s*/', row_name[lead.end():]) and not any(s == first for _, s in found):
        add("method" if has_method else "bare", first)
    prefixes = [first[:i] for i in range(1, len(first)) if first[i].isupper() or first[i - 1] in "_."]
    for match in SLASH_NAME.findall(row_name):
        kind = "method" if has_method else "bare"
        expanded = "|".join([match] + [p + match for p in prefixes])
        found[:] = [(k, s) for k, s in found if not (s == match and k in ("method", "bare"))]
        add(kind, expanded)
    if "CreateFrame(" in row_name and not found:
        add("bare", "CreateFrame")
    return found


COMPONENT = re.compile(r'ns\.AddComponent\(\{(.*?)\n\}\)', re.S)
COMPONENT_ID = re.compile(r'^\s{4}id\s*=\s*"([\w-]+)"', re.M)
API_BLOCK = re.compile(r'^\s{4}api\s*=\s*\{\n(.*?)^\s{4}\},', re.M | re.S)
ROW = re.compile(r'^\s*\{\s*"((?:[^"\\]|\\.)*)"', re.M)


def lua_unescape(s):
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


def toc_lua_files():
    files = []
    for line in open(os.path.join(ROOT, "UIGallery.toc"), encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#") and line.endswith(".lua"):
            files.append(line.replace("\\", "/"))
    return files


def api_rows():
    rows = []
    for path in toc_lua_files():
        if not path.startswith("examples/"):
            continue
        text = open(os.path.join(ROOT, path), encoding="utf-8").read()
        for block in COMPONENT.findall(text):
            cid = COMPONENT_ID.search(block).group(1)
            api = API_BLOCK.search(block + "\n")
            if not api:
                continue
            for i, raw in enumerate(ROW.findall(api.group(1)), start=1):
                rows.append((cid, i, lua_unescape(raw)))
    return rows


def lua_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def generate(indexes):
    lines = [
        "-- GENERATED by tools/gen-availability.py from ../Blizzard_UI_refs: do not edit.",
        "-- Per API row: the clients whose UI source defines every symbol of the row's name.",
        "local _, ns = ...",
        "",
        "ns.Availability = {",
    ]
    current = None
    for cid, i, name in api_rows():
        syms = symbols(name)
        if cid != current:
            if current is not None:
                lines.append("    },")
            lines.append("    [" + lua_string(cid) + "] = {")
            current = cid
        parts = ["name = " + lua_string(name)]
        if syms:
            missing = []
            for key, _ in CLIENTS:
                absent = [s.split("|")[0] for k, s in syms if not present(indexes[key], k, s)]
                parts.append(key + " = " + ("false" if absent else "true"))
                if absent:
                    missing.append(key + " = " + lua_string(", ".join(absent)))
            if missing:
                parts.append("missing = { " + ", ".join(missing) + " }")
        lines.append("        [" + str(i) + "] = { " + ", ".join(parts) + " },")
    if current is not None:
        lines.append("    },")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main(argv):
    rebuild = "--rebuild" in argv
    indexes = {key: load_index(key, folder, rebuild) for key, folder in CLIENTS}
    if "--query" in argv:
        for arg in argv[argv.index("--query") + 1:]:
            if arg.startswith("--"):
                continue
            kind = ("enum" if arg.startswith("Enum.") else "method" if ":" in arg
                    else "qualified" if "." in arg else "bare")
            symbol = arg[5:] if kind == "enum" else arg.split(":")[-1] if kind == "method" else arg
            marks = ["%s %s" % (key, "yes" if present(indexes[key], kind, symbol) else "NO")
                     for key, _ in CLIENTS]
            print("%-50s %s" % (arg, "  ".join(marks)))
        return 0
    text = generate(indexes)
    if "--check" in argv:
        old = open(OUTPUT, encoding="utf-8").read() if os.path.exists(OUTPUT) else ""
        if old != text:
            print("generated/Availability.lua is stale: run python tools/gen-availability.py")
            return 1
        print("generated/Availability.lua up to date")
        return 0
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("generated/Availability.lua: %d rows" % len(api_rows()))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
