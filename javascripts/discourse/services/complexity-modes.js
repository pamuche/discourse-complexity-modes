import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import {
  buildCss,
  clampLevel,
  deserialize,
  LEVELS,
  normalizeCustomCss,
  normalizeRules,
  serialize,
  STORAGE_KEY,
} from "../lib/rules";

const STYLE_ID = "complexity-modes-css";

export default class ComplexityModesService extends Service {
  @tracked level;
  @tracked rules;
  @tracked customCss;
  @tracked hasOverride = false;

  constructor() {
    super(...arguments);
    this.#load();
    this.apply();
  }

  get allowCustomization() {
    return settings.allow_user_customization;
  }

  get defaultRules() {
    return normalizeRules(settings.default_rules);
  }

  get defaultCustomCss() {
    return normalizeCustomCss({
      1: settings.custom_css_level_1,
      2: settings.custom_css_level_2,
      3: settings.custom_css_level_3,
    });
  }

  setLevel(level) {
    this.level = clampLevel(level, this.level);
    this.#applyLevel();
    this.#persist();
  }

  // Applies the given (draft) rules without saving them, for live preview.
  preview(rules, customCss) {
    this.#writeCss(buildCss(rules, customCss));
  }

  // Re-applies the saved state, e.g. after a cancelled preview or once the
  // switcher has rendered (so lock-out protection can see it).
  apply() {
    this.#applyLevel();
    this.#writeCss(buildCss(this.rules, this.customCss));
  }

  saveCustomization(rules, customCss) {
    this.rules = normalizeRules(rules);
    this.customCss = normalizeCustomCss(customCss);
    this.hasOverride = true;
    this.#persist();
    this.apply();
  }

  resetCustomization() {
    this.rules = this.defaultRules;
    this.customCss = this.defaultCustomCss;
    this.hasOverride = false;
    this.#persist();
    this.apply();
  }

  export(rules = this.rules, customCss = this.customCss) {
    return serialize({ level: this.level, rules, customCss });
  }

  #load() {
    const stored = this.#readStorage();
    const urlLevel = new URLSearchParams(window.location.search).get(
      "complexity"
    );

    this.level = clampLevel(
      urlLevel ?? stored.level,
      clampLevel(settings.default_level)
    );

    if (this.allowCustomization && stored.rules) {
      this.rules = stored.rules;
      this.customCss = stored.customCss ?? this.defaultCustomCss;
      this.hasOverride = true;
    } else {
      this.rules = this.defaultRules;
      this.customCss = this.defaultCustomCss;
    }

    if (urlLevel) {
      this.#persist();
    }
  }

  #readStorage() {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      return raw ? deserialize(raw) : {};
    } catch {
      return {};
    }
  }

  #persist() {
    const data = { level: this.level };
    if (this.hasOverride) {
      data.rules = this.rules;
      data.customCss = this.customCss;
    }
    try {
      window.localStorage.setItem(STORAGE_KEY, serialize(data));
    } catch {
      // storage unavailable (private mode etc.) - keep working in memory
    }
  }

  #applyLevel() {
    document.documentElement.dataset.complexity = String(this.level);
    LEVELS.forEach((l) =>
      document.body.classList.toggle(`complexity-level-${l}`, l === this.level)
    );
  }

  #writeCss(css) {
    let style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      document.head.appendChild(style);
    }
    style.textContent = css;
  }
}
