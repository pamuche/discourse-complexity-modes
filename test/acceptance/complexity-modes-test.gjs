// In-browser acceptance tests. They run inside Discourse core:
//   - local dev Discourse:  http://localhost:4200/theme-qunit
//   - or:  discourse_theme rspec / bin/rake themes:qunit[name,"Komplexitätsstufen (Complexity Modes)"]
import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const STORAGE_KEY = "complexity-modes:v1";

function level() {
  return document.documentElement.dataset.complexity;
}

acceptance("Complexity modes | logged in", function (needs) {
  needs.user();
  needs.hooks.beforeEach(() => localStorage.removeItem(STORAGE_KEY));
  needs.hooks.afterEach(() => localStorage.removeItem(STORAGE_KEY));

  test("renders the switcher in the header", async function (assert) {
    await visit("/");
    assert.dom(".d-header .complexity-modes-switcher").exists();
  });

  test("applies the default level and generated stylesheet", async function (assert) {
    await visit("/");
    assert.strictEqual(level(), String(settings.default_level));
    assert.dom("#complexity-modes-css", document.head).exists();
    assert
      .dom(document.body)
      .hasClass(`complexity-level-${settings.default_level}`);
  });

  test("switching level updates <html> and persists", async function (assert) {
    await visit("/");
    await click(".complexity-modes-trigger");
    await click(".complexity-modes-menu__level:first-of-type");
    assert.strictEqual(level(), "1");
    assert.dom(document.body).hasClass("complexity-level-1");
    assert.strictEqual(JSON.parse(localStorage.getItem(STORAGE_KEY)).level, 1);
  });

  test("Fokus keeps categories and inboxes in the sidebar, hides the rest", async function (assert) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ version: 1, level: 1 }));
    await visit("/");
    assert.strictEqual(level(), "1");
    const css = document.getElementById("complexity-modes-css").textContent;
    assert.true(
      css.includes(
        'html[data-complexity="1"] :is(.sidebar-section[data-section-name]:not('
      )
    );
    assert.false(css.includes(":is(.sidebar-wrapper"));
    assert.false(css.includes('[data-link-name="groups"]'));
  });

  test("never hides the switcher itself", async function (assert) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ version: 1, level: 1 }));
    await visit("/");
    assert.dom(".complexity-modes-switcher").isVisible();
  });
});

acceptance("Complexity modes | anonymous", function () {
  test("switcher hidden when show_for_anonymous is off", async function (assert) {
    await visit("/");
    if (settings.show_for_anonymous) {
      assert.dom(".complexity-modes-switcher").exists();
    } else {
      assert.dom(".complexity-modes-switcher").doesNotExist();
    }
  });
});
