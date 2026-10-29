# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

**UIGallery** — an in-game catalogue of Blizzard UI components, like a design system's component
overview: a searchable list by family; per component a summary, "when to use", **live examples**
with playground controls, their **XML / Lua code** (copyable), the **API table** and the Blizzard
source files. It is documentation that runs: every example is real addon code.

**Status: not published.** The repo follows the workspace release standard (TOC metadata,
CHANGELOG, make-release.ps1, .pkgmeta, workflows), but the TOC has **no `X-Curse-Project-ID`**
and there is no GitHub remote yet: a `v*` tag would fail the release check. Publishing needs a
CurseForge project (id into the TOC), the GitHub repo and its `CF_API_KEY` secret.

## Client targets

Retail (`120105`) and WoW Forever (`16001`, Classic client on the 12.x Mainline UI; tell them
apart by interface version). Every template and helper used by the core UI and the examples was
checked in both trees of `../Blizzard_UI_refs` (2026-10-29). Components that need a newer API
declare `requires` (see Capabilities) and show "not available" instead of erroring.

## Layout

```
UIGallery.toc               # load order; core, generated snippets, examples, bootstrap last
UIGallery.lua               # bootstrap: SavedVariables, Capabilities:Probe, /uigallery /uig, compartment
core/Util.lua               # Print, Clamp, SafeCall (pcall + geterrorhandler), ClientInterface
core/Capabilities.lua       # optional systems probed once (nativeRadial, durationObjects, menu...)
core/Registry.lua           # FAMILIES; ns.AddComponent / ns.AddExample (spec documented there)
core/UI/Window.lua          # ButtonFrameTemplate window: search + ScrollBox nav, page scroll frame
core/UI/Page.lua            # a component's page (built once, cached): header, cards, API, refs
core/UI/Card.lua            # one example: stage (live preview), text, controls, code toggle
core/UI/Controls.lua        # playground controls: slider, check, choice, button
core/UI/CodeView.lua        # read-only copyable code block with one tab per snippet
generated/Snippets.lua      # GENERATED from the @snippet regions; never edit by hand
examples/<family>/<Name>.lua|.xml   # one component per Lua file (+ its XML templates)
media/                      # ring.tga: white + alpha, tinted in code
tools/gen-snippets.lua      # builds generated/Snippets.lua (--check: fail when stale)
tools/make-media.py         # regenerates media/ (python tools/make-media.py)
tests/run.sh                # syntax, snippets freshness, registry consistency
```

## How examples work

- **Single source.** The game cannot read files, so the code shown is extracted at build time from
  the example files themselves: regions between `-- @snippet <id>` and `-- @end` (Lua) or
  `<!-- @snippet <id> -->` and `<!-- @end -->` (XML) become `ns.Snippets[id]`. After editing an
  example, run `lua tools/gen-snippets.lua`; `tests/run.sh` fails while the file is stale.
- A snippet holds **self-contained code a reader can copy**: local constructors and helpers, full
  media paths (`Interface\\AddOns\\UIGallery\\media\\ring`), no `ns`. The registration
  (`ns.AddExample`) and the playground glue (`create` anchoring, `apply`) stay outside the regions.
- Snippets may not contain `|` (WoW escape sequences in the code view); the generator refuses it.
- `create(stage)` builds and anchors the widget inside the card's stage and returns it;
  `apply(widget, key, value, values)` reacts to a control (`values` holds them all). Both run
  through `ns.SafeCall`: an error shows in the card and goes to BugSack, the page survives. Every
  non-button control's default is applied once after `create`.
- XML examples: the template in `<Name>.xml`, its usage (and mixin) in `<Name>.lua`, listed after
  the Lua file in the toc. Example `code` entries are snippet ids or `{ id, tabLabel }`.
- **Globals exception:** XML templates need their mixins as globals, so example mixins are
  `UIGallery<Name>Mixin`; templates are named `UIGallery<Name>Template`. `tests/registry.lua`
  rejects any other new global and any unprefixed XML template.

### Adding a component

1. `examples/<family>/<Name>.lua`: `ns.AddComponent{...}` (id, family, title, summary, clients,
   whenToUse, api rows `{ name, description [, default] }`, refs, keywords, requires), then one or
   more `@snippet` regions and `ns.AddExample` calls.
2. Optional `<Name>.xml` with `@snippet` regions; add both files to the toc.
3. Check every Blizzard symbol in Retail **and** Forever (`/wow-dev:ref`); a symbol missing on one
   client becomes a capability in `core/Capabilities.lua` and a `requires` entry.
4. `lua tools/gen-snippets.lua`, `./tests/run.sh`, then look at it in game.

Player-facing text is English only for now (a developer tool); no locale table.

## Unverified, to check in game

These come from the API docs only (no Blizzard call site yet); the examples are built to show the
answer on screen:

- `CreateAnimation("RadialProgress")` (radial-animation card): the type string is inferred.
- Radial **end offset** semantics (radial-arc card: start 0.125 / end 0.875 should be a 270° arc
  open at the bottom) and the default **fill direction** (radial-ring card: clockwise expected).
- `<Color>` on a `<Texture file=...>` as vertex colour, and `<RadialProgressBar>` in XML.
- `ScrollBox` factories with plain frame types (`"Frame"`, `"Button"`) for the nav and the Lua list.
- Whether OnShow runs for a template created already visible (loading-spinner card plays the
  animations by hand in case it does not).
- `CreateFrame("ItemButton")` from addon code, and `SetItem` filling in once the item data
  arrives (itembutton card, Thunderfury may not be cached).
- An unnamed `SmallMoneyFrameTemplate` (its children are named `$parent...`) set to `STATIC`.
- The window-templates card: portraits, titles and close buttons on each template, the
  `DialogHeaderTemplate` above the dialog border.

Write the results into "Confirmed in game" below and fix the examples' wording.

## Scope

The gallery shows Blizzard's own components and how Blizzard uses them. Composite recipes built
on top of them (a speedometer, a cooldown used as a progress ring) stay out: the radial guide in
`../Blizzard_UI_refs/Blizzard_Radial_Progress_Guide.md` keeps the gauge recipe.

## Pitfalls met (keep the examples showing them)

- `NineSlicePanelTemplate` is `setAllPoints="true"`: `ClearAllPoints()` before sizing it.
- NineSlice corners keep their atlas size: a box smaller than two corners overlaps itself
  (GenericMetal, WoodenNeutralFrameTemplate: 166px corners). Re-applying a layout over another
  leaves the pieces the new one does not set; use one frame per layout.
- `SetFontObject` resets colour, shadow and justification: apply the font object first, then the
  overrides. `QuestFont` is black (made for parchment): invisible on a dark background.

## Confirmed in game

- 2026-10-29, Retail: `playAutomatically` on an `<AnimationGroup>` is **not** an XML attribute
  ("Unrecognized XML attribute" warning); start animations from `OnShow`. That load raised no
  warning for `<RadialProgressBar barFillPercent startOffset endOffset feather>`, so the client
  parses them (what they draw is still to check).

## Build / test / release

```sh
lua tools/gen-snippets.lua    # after any change to an @snippet region
./tests/run.sh                # Lua 5.1; LUA= / LUAC= override the interpreter path
```

```powershell
.\make-release.ps1            # PowerShell 7+; -> .build/UIGallery-v<version>.zip
```

`/wow-dev:deploy` installs the zip into the local clients. Release mechanics are the workspace
standard (see `../CLAUDE.md`), once the addon is published.

## Claude Code harness

`.claude/` is vendored from `code_wow-dev/repo-slice/`: edit it there and sync, not here.
