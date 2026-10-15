// Framework-agnostic rule model and CSS generator.
//
// A rule hides elements matching `selector` below `minLevel`:
//   minLevel 2 -> hidden in level 1 (Fokus)
//   minLevel 3 -> hidden in level 1 and 2 (Fokus + Standard)

export const LEVELS = [1, 2, 3];
export const LEVEL_KEYS = { 1: "focus", 2: "standard", 3: "full" };
export const STORAGE_KEY = "complexity-modes:v1";
export const SWITCHER_CLASS = "complexity-modes-switcher";

let idCounter = 0;
export function newRuleId() {
  idCounter += 1;
  return `r${Date.now().toString(36)}${idCounter}`;
}

export function clampLevel(value, fallback = 2) {
  const n = parseInt(value, 10);
  return LEVELS.includes(n) ? n : fallback;
}

// Accepts rules from theme settings (snake_case) or from storage/import
// (camelCase) and returns a clean list.
export function normalizeRules(input) {
  if (!Array.isArray(input)) {
    return [];
  }

  return input
    .filter((r) => r && typeof r.selector === "string" && r.selector.trim())
    .map((r) => ({
      id: r.id || newRuleId(),
      label: String(r.label ?? "").trim(),
      selector: r.selector.trim(),
      minLevel: clampLevel(r.minLevel ?? r.min_level, 2) === 3 ? 3 : 2,
      enabled: r.enabled !== false,
    }));
}

export function normalizeCustomCss(input) {
  const css = {};
  LEVELS.forEach((l) => (css[l] = String(input?.[l] ?? "")));
  return css;
}

// Returns null if the selector is valid, otherwise the error message.
export function selectorError(selector, doc = document) {
  try {
    doc.querySelector(selector);
    return null;
  } catch (e) {
    return e.message || "invalid selector";
  }
}

export function countMatches(selector, doc = document) {
  try {
    return doc.querySelectorAll(selector).length;
  } catch {
    return null;
  }
}

// True if the selector would hide the level switcher itself (the element or
// one of its ancestors), which would lock the user out.
export function hidesSwitcher(selector, doc = document) {
  const switcher = doc.querySelector(`.${SWITCHER_CLASS}`);
  if (!switcher) {
    return false;
  }
  try {
    return [...doc.querySelectorAll(selector)].some((el) =>
      el.contains(switcher)
    );
  } catch {
    return false;
  }
}

function levelsHiding(minLevel) {
  return LEVELS.filter((l) => l < minLevel);
}

export function buildCss(rules, customCss = {}, doc = document) {
  const out = [];

  rules.forEach((rule) => {
    if (
      !rule.enabled ||
      selectorError(rule.selector, doc) ||
      hidesSwitcher(rule.selector, doc)
    ) {
      return;
    }
    // :is() keeps selector lists like ".a, .b" scoped correctly.
    const prefixes = levelsHiding(rule.minLevel)
      .map((l) => `html[data-complexity="${l}"] :is(${rule.selector})`)
      .join(",\n");
    out.push(
      `/* ${rule.label.replace(/\*\//g, "")} */\n${prefixes} { display: none !important; }`
    );
  });

  LEVELS.forEach((l) => {
    const css = (customCss[l] || "").trim();
    if (css) {
      out.push(`html[data-complexity="${l}"] {\n${css}\n}`);
    }
  });

  return out.join("\n\n");
}

// Suggests a selector describing the "kind" of element that was clicked
// (e.g. all share buttons), not just this single instance.
const UNSTABLE_CLASS =
  /^(ember|active|selected|focused|open|visible|hidden|is-|has-|--)|\d{3,}|^(btn|btn-flat|btn-default|btn-icon|btn-icon-text|btn-transparent|no-text|d-icon|widget-button)$/;

function stableClasses(el) {
  const classes = [...el.classList].filter((c) => !UNSTABLE_CLASS.test(c));
  // Prefer BEM-ish, descriptive classes first.
  classes.sort((a, b) => Number(b.includes("__")) - Number(a.includes("__")));
  return classes.slice(0, 2);
}

function partFor(el) {
  if (el.id && !/^ember\d+$/.test(el.id) && !/\d{3,}/.test(el.id)) {
    return `#${CSS.escape(el.id)}`;
  }
  const classes = stableClasses(el);
  if (classes.length) {
    return classes.map((c) => `.${CSS.escape(c)}`).join("");
  }
  return null;
}

export function suggestSelector(el) {
  const parts = [];
  let node = el;
  let depth = 0;

  while (node && node.nodeType === 1 && node !== document.body && depth < 4) {
    const part = partFor(node);
    if (part) {
      parts.unshift(part);
      if (part.startsWith("#") || parts.length >= 2) {
        break;
      }
    } else if (!parts.length) {
      parts.unshift(node.tagName.toLowerCase());
    }
    node = node.parentElement;
    depth += 1;
  }

  return parts.join(" ") || el.tagName.toLowerCase();
}

export function serialize({ level, rules, customCss }) {
  return JSON.stringify(
    {
      version: 1,
      level,
      rules: rules?.map(({ label, selector, minLevel, enabled }) => ({
        label,
        selector,
        minLevel,
        enabled,
      })),
      customCss,
    },
    null,
    2
  );
}

export function deserialize(json) {
  const data = typeof json === "string" ? JSON.parse(json) : json;
  if (!data || typeof data !== "object") {
    throw new Error("not an object");
  }
  return {
    level: data.level ? clampLevel(data.level) : undefined,
    rules: Array.isArray(data.rules) ? normalizeRules(data.rules) : undefined,
    customCss: data.customCss ? normalizeCustomCss(data.customCss) : undefined,
  };
}
