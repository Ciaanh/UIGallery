# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

**UIGallery** — an in-game catalogue of Blizzard UI components, like a design system's component
overview: a searchable list by family; per component a summary, "when to use", **live examples**
with playground controls, their **XML / Lua code** (copyable), the **API table** and the Blizzard
source files. It is documentation that runs: every example is real addon code.

**Status: not published.** The repo follows the workspace release standard (TOC metadata,
CHANGELOG, make-release.ps1, .pkgmeta, workflows), but the TOC has **no `X-Curse-Project-ID`**
so a `v*` tag would fail the release check. The GitHub repo exists (public,
`github.com/Ciaanh/UIGallery`); publishing still needs a CurseForge project (id into the TOC) and
the repo's `CF_API_KEY` secret.

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
core/UI/Controls.lua        # playground controls: slider, check, choice, button; CodeFor
core/UI/CodeView.lua        # copyable code block (tabs), live calls box, "All code" window
generated/Snippets.lua      # GENERATED from the @snippet regions; never edit by hand
generated/Availability.lua  # GENERATED: per API row, the clients whose UI source has it
examples/<family>/<Name>.lua|.xml   # one component per Lua file (+ its XML templates)
examples/assets/AssetGrid.lua       # not a component: the search + grid shell of the 3 browsers
media/                      # ring.tga: white + alpha, tinted in code
tools/gen-snippets.lua      # builds generated/Snippets.lua (--check: fail when stale)
tools/gen-availability.py   # builds generated/Availability.lua from ../Blizzard_UI_refs
tools/make-media.py         # regenerates media/ (python tools/make-media.py)
tests/run.sh                # syntax, snippets + availability freshness, registry consistency
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
- **Every slider, check and choice has `code`**: a format string with exactly one `%s` (the value,
  `%q`-quoted for strings), `function(value, values) -> lines`, or `false` when another control's
  line already covers it. `Controls.CodeFor` joins them into the green "calls for the current
  settings" box under the controls; `tests/registry.lua` requires the field and runs it on the
  defaults (no `|` allowed in the output either).
- Families, in nav order: basics, progress, controls, layout, visuals, systems, assets
  (`Registry.FAMILIES`). A family with no component fails the tests.
- Protected frames (systems/SecureButton) live in their **own window on UIParent**, created on a
  click out of combat: a secure child would make the gallery window impossible to hide in combat.
- Never feed addon frames to Blizzard managers that keep shared state (e.g.
  `ActionButtonSpellAlertManager.activeAlerts`): use the template directly (ProcGlow).

### API availability badges

`tools/gen-availability.py` reads each API row's name, extracts its symbols (templates,
`obj:Method(`, `A.B(`, bare `Name(`, lower-case lead globals, `Enum.X`, `/ Alternative` names) and
looks them up in an index of each client tree of `../Blizzard_UI_refs` (XML names, Lua
definitions, API docs, and calls made by Blizzard's own code). Rows without a recognisable symbol
(fields, events, XML) get no badge. Run `python tools/gen-availability.py` after editing any API
row; `tests/registry.lua` fails when a row's name no longer matches its entry, and `tests/run.sh`
runs `--check` when the refs are present (not in CI). `--query Sym ...` answers ad hoc; the index
is cached in `.build/` (`--rebuild` after updating the refs). A false red badge means the
extraction misread the row: reword the row (or fix the tool), never hand-edit the output.
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
4. `lua tools/gen-snippets.lua`, `python tools/gen-availability.py`, `./tests/run.sh`, then look
   at it in game.

Player-facing text is English only for now (a developer tool); no locale table.

## Unverified, to check in game

Still open after the 2026-10-29 Retail pass (the cards worked, but these need a closer look):

- The default radial **fill direction** (radial-ring card: clockwise expected), and whether
  `StatusBar:SetFillStyle` / `SetReverseFill` act on the radial fill.
- Whether OnShow runs for a template created already visible: the loading-spinner card plays
  the animations by hand, which hides the answer.
- Everything on **Forever**: the pass was on Retail.
- The 2026-10-29 second batch (basics, systems, assets, help tips, layout frames, tree list, proc
  glow, models) has not been seen in game at all. Points to watch:
  - asset browsers: `C_Texture.GetAtlasElements()` size and first-open hitch; grid cells sized by
    `SetElementSize`; font cells for fonts with huge heights;
  - icon picker: dragging a spell or item onto it (opening and picking work, see below);
  - secure button: the action runs in combat; close waits for PLAYER_REGEN_ENABLED; no
    ADDON_ACTION_BLOCKED when closing the gallery in combat;
  - secret probe: which operations error on a `secretwrap` value (the card shows the client's
    answers; record them here);
  - HelpTip shows above the gallery (HelpTip uses DIALOG strata) and its button calls back;
  - proc glow loop resumes after the page is hidden and shown (`animationPlaying`);
  - `MODIFIER_STATE_CHANGED` / `PLAYER_TARGET_CHANGED` in the event log; PlayerModel animation
    IDs 4 / 5 / 60 / 69;
  - layer card: whether `SetFrameStrata` keeps the frame level.

Write the results into "Confirmed in game" below and fix the examples' wording.

## Scope

The gallery shows Blizzard's own components and how Blizzard uses them. Composite recipes built
on top of them (a speedometer, a cooldown used as a progress ring) stay out: the radial guide in
`../Blizzard_UI_refs/Blizzard_Radial_Progress_Guide.md` keeps the gauge recipe.

## Pitfalls met (keep the examples showing them)

- `NineSlicePanelTemplate` is `setAllPoints="true"`: `ClearAllPoints()` before sizing it.
- Blizzard templates often carry their own `<Anchors>` for their original parent:
  `IconSelectorPopupFrameTemplate` puts its TOPLEFT on the parent's TOPRIGHT, off screen on
  UIParent (seen in game 2026-10-30: "the popup does nothing"). Read a template's anchors and
  `ClearAllPoints()` before placing an instance.
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
- 2026-10-29, Retail, full pass through the gallery (user report "ok", BugSack empty):
  - `CreateAnimation("RadialProgress")` exists and drives the radial fill (radial-animation card).
  - Radial `endOffset` is an **absolute** end position: start 0.125 / end 0.875 draws the 270°
    arc open at the bottom (radial-arc card). `<RadialProgressBar>` in XML draws it.
  - `<Color>` on a `<Texture file=...>` tints it (vertex colour).
  - ScrollBox element factories accept plain frame types (`"Frame"`, `"Button"`).
  - `CreateFrame("ItemButton")` works from addon code; `SetItem` fills in when the data arrives.
  - An unnamed `SmallMoneyFrameTemplate` set to `STATIC` shows the amount.
  - Every window template on the window-templates card, `DialogHeaderTemplate` included.
- 2026-10-30, Retail: an addon template inheriting `IconSelectorPopupFrameTemplate` with its own
  mixin works (icon-picker card, user report "seems to work"), once its template anchor is
  cleared.

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
