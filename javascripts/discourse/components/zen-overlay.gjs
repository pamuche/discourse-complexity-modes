import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import { pickDifferent } from "../lib/affirmations";
import {
  configuredCategoryIds,
  loadForumAffirmations,
} from "../lib/forum-affirmations";

const AFFIRMATION_COUNT = 8;
const LAST_AFFIRMATION_KEY = "complexity-modes:zen-affirmation";
const LAST_PERSON_KEY = "complexity-modes:zen-person";

function remember(key, value) {
  try {
    window.localStorage.setItem(key, String(value));
  } catch {
    // storage unavailable
  }
}

function recall(key) {
  try {
    return window.localStorage.getItem(key);
  } catch {
    return null;
  }
}

// Random index in [0, count) that differs from the one stored under `key`
// (also across reloads), so every visit to Zen looks different.
function pickNew(key, count) {
  const last = parseInt(recall(key), 10);
  let next = Math.floor(Math.random() * (count - 1));
  if (next >= last && last >= 0) {
    next += 1;
  }
  remember(key, next);
  return next;
}

const UNICORN_COUNT = 18;
const ROTATE_MS = 12000;

// One of these is picked on every visit to Zen.
const PERSONS = [
  "🧘",
  "🧘‍♀️",
  "🧘‍♂️",
  "🧘🏻",
  "🧘🏼‍♀️",
  "🧘🏽‍♂️",
  "🧘🏾",
  "🧘🏿‍♀️",
  "🧘🏻‍♂️",
  "🧘🏽‍♀️",
  "🧘🏾‍♂️",
  "🧘🏿",
];

// Fixed pseudo-random layout so the scene is calm and identical each time.
const UNICORNS = Array.from({ length: UNICORN_COUNT }, (_, i) => {
  const left = (i * 37 + 11) % 100;
  const duration = 14 + ((i * 7) % 12);
  const delay = -((i * 5.3) % duration);
  const size = 1.2 + ((i * 3) % 5) * 0.35;
  const sway = 20 + ((i * 13) % 40);
  return {
    emoji: i % 4 === 3 ? "✨" : "🦄",
    style: htmlSafe(
      `left:${left}%;font-size:${size}rem;animation-duration:${duration}s;` +
        `animation-delay:${delay}s;--zen-sway:${sway}px`
    ),
  };
});

export default class ZenOverlay extends Component {
  @service complexityModes;
  @tracked person = PERSONS[0];
  @tracked current;
  @tracked forumItems = [];

  unicorns = UNICORNS;
  #timer;
  #active = false;

  get source() {
    return configuredCategoryIds().length
      ? settings.zen_affirmation_source
      : "builtin";
  }

  get builtinItems() {
    return Array.from({ length: AFFIRMATION_COUNT }, (_, i) => ({
      text: i18n(themePrefix(`complexity_modes.zen.a${i + 1}`)),
    }));
  }

  // Forum sentences when there are any, built-in ones as fallback.
  get pool() {
    if (this.source === "builtin" || !this.forumItems.length) {
      return this.builtinItems;
    }
    if (this.source === "posts") {
      return this.forumItems;
    }
    return [...this.builtinItems, ...this.forumItems];
  }

  // One-item list keyed by text, so the element is recreated (and the fade
  // animation replays) whenever the affirmation changes.
  get affirmations() {
    return this.current ? [this.current] : [];
  }

  #next(pool = this.pool) {
    const item = pickDifferent(pool, recall(LAST_AFFIRMATION_KEY));
    if (item) {
      this.current = item;
      remember(LAST_AFFIRMATION_KEY, item.text);
    }
  }

  async #loadForum() {
    const items = await loadForumAffirmations();
    if (!this.#active || !items.length) {
      return;
    }
    this.forumItems = items;
    // Swap the built-in placeholder for a forum sentence right away.
    if (this.source === "posts" || Math.random() < 0.5) {
      this.#next(items);
    }
  }

  @action
  start(element) {
    this.#active = true;
    this.person = PERSONS[pickNew(LAST_PERSON_KEY, PERSONS.length)];
    this.#next();
    element.focus();
    document.addEventListener("keydown", this.onKey);
    this.#timer = setInterval(() => this.#next(), ROTATE_MS);
    if (this.source !== "builtin") {
      this.#loadForum();
    }
  }

  @action
  stop() {
    this.#active = false;
    document.removeEventListener("keydown", this.onKey);
    clearInterval(this.#timer);
  }

  @action
  onKey(event) {
    if (event.key === "Escape") {
      this.exit();
    }
  }

  @action
  exit() {
    this.complexityModes.setZen(false);
  }

  <template>
    {{#if this.complexityModes.zen}}
      <div
        class="complexity-modes-zen-overlay"
        role="dialog"
        aria-modal="true"
        aria-label={{i18n (themePrefix "complexity_modes.zen.enter")}}
        tabindex="-1"
        {{didInsert this.start}}
        {{willDestroy this.stop}}
        {{on "click" this.exit}}
      >
        <div class="complexity-modes-zen-overlay__sky" aria-hidden="true">
          {{#each this.unicorns as |u|}}
            <span
              class="complexity-modes-zen-overlay__unicorn"
              style={{u.style}}
            >{{u.emoji}}</span>
          {{/each}}
        </div>
        <div class="complexity-modes-zen-overlay__center">
          <div class="complexity-modes-zen-overlay__person" aria-hidden="true">
            <span class="complexity-modes-zen-overlay__aura"></span>
            {{this.person}}
          </div>
          {{#each this.affirmations key="text" as |item|}}
            <figure class="complexity-modes-zen-overlay__quote">
              <p class="complexity-modes-zen-overlay__affirmation">
                {{item.text}}
              </p>
              {{#if item.url}}
                <figcaption class="complexity-modes-zen-overlay__source">
                  {{i18n (themePrefix "complexity_modes.zen.from")}}
                  <a href={{item.url}}>{{item.title}}</a>
                </figcaption>
              {{/if}}
            </figure>
          {{/each}}
        </div>
        <button
          type="button"
          class="complexity-modes-zen-overlay__exit"
          {{on "click" this.exit}}
        >{{i18n (themePrefix "complexity_modes.zen.exit")}}</button>
        <span class="complexity-modes-zen-overlay__hint">
          {{i18n (themePrefix "complexity_modes.zen.hint")}}
        </span>
      </div>
    {{/if}}
  </template>
}
