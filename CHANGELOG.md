# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- In-game catalogue of Blizzard UI components (`/uigallery`, `/uig`, addon compartment): a
  searchable list by family, and per component a summary, "when to use", live examples with
  playground controls, their XML and Lua code (copyable), the API table and the Blizzard source
  files.
- Progress & timers: status bar (interpolation, timer durations, XML vertical bar), native radial
  progress (ring, XML arc, `RadialProgress` animation), cooldown swipe (icon cooldown, the action
  button's three stacked cooldowns in XML), loading spinners (LoadingSpinnerTemplate,
  SpinnerTemplate).
- Controls: buttons (panel, close, XML icon button with mixin, stretch / square / expanding /
  refresh / info templates), checkbox, radio group, sliders (minimal with steppers, raw), number
  spinner, edit boxes (input, search, scrolling multi-line), dropdowns and context menus
  (Blizzard_Menu), colour picker swatch, item button.
- Layout & containers: window templates (portrait, button frame, default panel, flat, simple,
  dialog with header) and a movable, resizable XML window; NineSlice layouts and backdrops;
  StaticPopup dialogs and the generic confirmation / input helpers; tab system; ScrollBox lists
  (Lua row, XML row template); tooltips.
- Visuals: textures and atlases, mask textures, animations (basic types, XML flipbook), font
  strings, lines and the divider atlas, money frame and money strings.
