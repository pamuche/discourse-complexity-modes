# discourse-complexity-modes

Discourse **theme component** (no Ruby/plugin code). It adds a header switcher with three UI
levels (1 Fokus, 2 Standard, 3 Alles) that hides parts of Discourse with generated CSS.
Target: treff.syndikat.org on Discourse 2026.1. See README.md for the user-facing behaviour.

## Architecture
- `javascripts/discourse/lib/rules.js`: **pure** rule model and CSS generator (`normalizeRules`,
  `buildCss`, `serialize`/`deserialize`, `suggestSelector`). Keep it free of Ember imports so it
  stays unit-testable in plain Node. DOM access goes through an injectable `doc` argument.
- `services/complexity-modes.js`: state (level, rules, customCss), localStorage
  (`complexity-modes:v1`), `?complexity=N` override, and writes `<html data-complexity>`,
  `body.complexity-level-N` and `<style id="complexity-modes-css">`.
- `components/complexity-switcher.gjs`: header icon plus DMenu, registered in
  `api-initializers/complexity-modes.gjs` via `api.headerIcons.add`.
- `components/complexity-config-modal.gjs`: the per-user rule editor (`lib/picker.js` = element picker).
- `settings.yml`: admin defaults. `default_rules` is an `objects` setting (snake_case
  `min_level` is a **string** enum "2"/"3"). The service sees it via the global `settings`.
- Rule semantics: `min_level: 2` = hidden in Fokus; `3` = hidden in Fokus and Standard.

## Conventions
- UI language is German. Every user-visible string goes through `i18n(themePrefix(...))` and
  must exist in **both** `locales/de.yml` and `locales/en.yml`.
- Use modern Discourse APIs only: `.gjs` Glimmer components, `api.headerIcons`, DMenu/DButton,
  no widgets, no `api.decorateWidget`, no jQuery.
- Selectors in default rules: prefer stable BEM-ish classes (`post-action-menu__share`).
  Never ids like `ember123` or state classes. Rules must never hide `.complexity-modes-switcher`
  or its ancestors (`.d-header`); `buildCss` drops such rules, so keep that guard.
- Block params in templates must not shadow HTML element names (`section`, `label`, …).

## Verify every change
1. `pnpm check`: Node unit tests (`tests-node/`) + eslint, stylelint, template-lint, prettier.
   `pnpm lint:fix` auto-fixes formatting.
2. Logic changes in `lib/rules.js` → add or adjust a test in `tests-node/rules.test.mjs`.
3. UI/behaviour changes → acceptance test in `test/acceptance/`. These run only inside
   Discourse (`/theme-qunit` on a dev instance), not via pnpm.
4. Selector changes → check against a real Discourse 2026.1 page (browser tools / preview
   theme); the unit tests cannot tell whether a selector matches anything.

## Dev instance
`discourse_theme watch .` syncs this folder live to a Discourse instance (needs Ruby,
`gem install discourse_theme`, and an admin API key; it stores the site in `.discourse-site`,
which is gitignored). Then use the theme's Preview and `?complexity=1|2|3` to check levels.
