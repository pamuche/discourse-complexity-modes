import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";

const AFFIRMATION_COUNT = 8;
const UNICORN_COUNT = 18;
const ROTATE_MS = 12000;

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
  @tracked index = Math.floor(Math.random() * AFFIRMATION_COUNT);

  unicorns = UNICORNS;
  #timer;

  // One-item list keyed by index, so the element is recreated (and the fade
  // animation replays) whenever the affirmation changes.
  get affirmations() {
    return [
      {
        id: this.index,
        text: i18n(themePrefix(`complexity_modes.zen.a${this.index + 1}`)),
      },
    ];
  }

  @action
  start(element) {
    element.focus();
    document.addEventListener("keydown", this.onKey);
    this.#timer = setInterval(() => {
      this.index = (this.index + 1) % AFFIRMATION_COUNT;
    }, ROTATE_MS);
  }

  @action
  stop() {
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
            🧘
          </div>
          {{#each this.affirmations key="id" as |item|}}
            <p class="complexity-modes-zen-overlay__affirmation">
              {{item.text}}
            </p>
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
