# Komplexitätsstufen – Discourse theme component

Adds a switcher next to the account icon (top right) with three UI levels:

| Level | Name | What you see |
|---|---|---|
| 1 | **Fokus** | Topic lists, reading, replying, new topic. Slim sidebar (categories, group inboxes), no dropdowns, timeline, extra buttons. |
| 2 | **Standard** | Plus full sidebar, navigation dropdowns, search, post/topic extras. |
| 3 | **Alles** | Stock Discourse, nothing hidden. |

Built for treff.syndikat.org (Discourse 2026.1), works on any recent Discourse.

## Install

Admin → Customize → Themes → Install → *From a git repository* (or upload this
folder as a zip), then add the component to the active theme(s).

To try it without affecting others: install it, add it to a copy of the theme and
use that theme's *Preview*.

## How it works

Everything is plain CSS generated from a list of **rules**:

```
{ label: "Seitenleiste", selector: ".sidebar-wrapper", min_level: 2 }
```

An element matching `selector` is only shown at levels ≥ `min_level`:

- `min_level: 2` → hidden in Fokus
- `min_level: 3` → hidden in Fokus and Standard

The current level is set as `<html data-complexity="1|2|3">` (plus
`body.complexity-level-N`), and each rule becomes
`html[data-complexity="1"] :is(<selector>) { display: none !important }`.
Other themes/CSS can hook into the same attribute.

## Editing the rules

**As admin (defaults for everyone):** Component settings → `default_rules`
(list editor: add, edit, delete, reorder, change level, disable). Additional
free CSS per level in `custom_css_level_1/2/3`. `default_level` sets the
level for people who haven't picked one.

**As user (personal):** switcher → *Anpassen …* (if
`allow_user_customization` is on). The dialog lets you

- add / edit / delete rules, enable/disable them,
- move them between “Ab Standard sichtbar” and “Nur in Alles sichtbar” (→ / ←),
- reorder them (↑ / ↓),
- **pick an element** on the page with the mouse to get a selector suggestion,
- see live how many elements each selector matches on the current page,
- add custom CSS per level,
- export/import everything as JSON.

Changes preview live; *Speichern* stores them in the browser
(`localStorage`, key `complexity-modes:v1`). *Auf Standard zurücksetzen*
drops the personal rules and follows the admin defaults again. Exported JSON
can be pasted into another browser, or given to an admin to become the new
default.

## Finding selectors

- Use *Element auswählen* in the dialog, or
- browser DevTools → right click → *Inspect* and take a stable class
  (prefer names like `post-action-menu__share`; avoid `ember123` ids and
  state classes like `active`).
- The match counter only reflects the current page – a rule for the composer
  shows “0 Treffer” until the composer is open.

## Safety

- Invalid selectors are skipped (and flagged in the dialog) instead of
  breaking the stylesheet.
- Rules that would hide the switcher itself (or one of its parents, e.g.
  `.d-header`) are ignored.
- Emergency exit: append `?complexity=3` to any URL to switch to *Alles*.
