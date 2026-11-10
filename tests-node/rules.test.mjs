// Fast unit tests for the framework-agnostic rule model.
// Run with `pnpm test:unit` (plain Node, no Discourse needed).
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  buildCss,
  clampLevel,
  deserialize,
  normalizeRules,
  serialize,
} from "../javascripts/discourse/lib/rules.js";

// Minimal DOM stub: every selector is "valid", switcher not present.
const doc = {
  querySelector: (s) => {
    if (s.includes("!!")) {
      throw new Error("invalid");
    }
    return null;
  },
  querySelectorAll: () => [],
};

test("clampLevel", () => {
  assert.equal(clampLevel("1"), 1);
  assert.equal(clampLevel(3), 3);
  assert.equal(clampLevel("9"), 2);
  assert.equal(clampLevel("x", 3), 3);
});

test("normalizeRules accepts settings (snake_case) and storage (camelCase)", () => {
  const rules = normalizeRules([
    { label: " A ", selector: " .a ", min_level: "3" },
    { label: "B", selector: ".b", minLevel: 2, enabled: false },
    { label: "empty", selector: "  " },
    null,
  ]);
  assert.equal(rules.length, 2);
  assert.deepEqual(
    rules.map(({ label, selector, minLevel, enabled }) => ({
      label,
      selector,
      minLevel,
      enabled,
    })),
    [
      { label: "A", selector: ".a", minLevel: 3, enabled: true },
      { label: "B", selector: ".b", minLevel: 2, enabled: false },
    ]
  );
});

test("buildCss hides below minLevel, skips disabled and invalid rules", () => {
  const rules = normalizeRules([
    { label: "two", selector: ".a, .b", minLevel: 2 },
    { label: "three", selector: ".c", minLevel: 3 },
    { label: "off", selector: ".off", enabled: false },
    { label: "bad", selector: "!!bad" },
  ]);
  const css = buildCss(rules, { 1: "x{y:z}" }, doc);
  assert.match(css, /html\[data-complexity="1"\] :is\(\.a, \.b\)/);
  assert.doesNotMatch(css, /data-complexity="2"\] :is\(\.a/);
  assert.match(css, /html\[data-complexity="2"\] :is\(\.c\)/);
  assert.doesNotMatch(css, /\.off|!!bad/);
  assert.match(css, /html\[data-complexity="1"\] \{\nx\{y:z\}\n\}/);
});

test("buildCss strips comment terminators from labels", () => {
  const css = buildCss(normalizeRules([{ label: "a*/b", selector: ".x" }]), {}, doc);
  assert.match(css, /\/\* ab \*\//);
});

test("serialize/deserialize round-trip", () => {
  const rules = normalizeRules([{ label: "A", selector: ".a", minLevel: 3 }]);
  const back = deserialize(
    serialize({ level: 1, rules, customCss: { 1: "", 2: "", 3: "" } })
  );
  assert.equal(back.level, 1);
  assert.equal(back.rules[0].selector, ".a");
  assert.equal(back.rules[0].minLevel, 3);
  assert.throws(() => deserialize("null"));
});
