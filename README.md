# UI Gallery

An in-game catalogue of Blizzard UI components for addon authors, in the spirit of a design
system's component overview. Each component has a page with:

- a summary and when to use it;
- **live examples** you can play with (sliders, checkboxes and dropdowns drive the preview);
- the **code** of each example, XML and Lua, copyable (click it, Ctrl+C);
- the **API**: the methods, XML attributes and options that matter;
- the Blizzard source files it comes from.

Open it with `/uigallery` (or `/uig`), or from the addon compartment. `/uigallery radial` opens
the first component matching "radial".

## Components

| Family | Components |
| --- | --- |
| Progress & timers | Status bar, Radial progress, Cooldown swipe, Loading spinner |
| Controls | Button, Checkbox, Radio buttons, Slider, Number input, Edit box, Dropdown and menu, Color picker, Item button |
| Layout & containers | Windows, Panels and borders, Popup dialogs, Tabs, Scroll list (ScrollBox), Tooltip |
| Visuals | Texture and atlas, Mask texture, Animations, Text (FontString), Lines and dividers, Money display |

## Clients

Retail (12.1) and WoW Forever. Examples that need a newer API (the native radial fill, duration
objects) say so on clients that lack it instead of failing.

## License

MIT
