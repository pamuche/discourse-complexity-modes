import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import concatClass from "discourse/helpers/concat-class";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { pickElement } from "../lib/picker";
import {
  countMatches,
  deserialize,
  hidesSwitcher,
  LEVEL_KEYS,
  newRuleId,
  normalizeCustomCss,
  selectorError,
  suggestSelector,
} from "../lib/rules";

const t = (key, opts) =>
  i18n(themePrefix(`complexity_modes.config.${key}`), opts);

export default class ComplexityConfigModal extends Component {
  @service complexityModes;
  @service dialog;

  @tracked rules = this.complexityModes.rules.map((r) => ({ ...r }));
  @tracked customCss = normalizeCustomCss(this.complexityModes.customCss);
  @tracked transferText = "";
  @tracked transferError = null;
  @tracked picking = false;

  saved = false;
  initialLevel = this.complexityModes.level;

  willDestroy() {
    super.willDestroy(...arguments);
    if (!this.saved) {
      // Closed via X / Esc / Abbrechen: drop the preview.
      this.complexityModes.setLevel(this.initialLevel);
      this.complexityModes.apply();
    }
  }

  get sections() {
    return [2, 3].map((minLevel) => ({
      minLevel,
      title: t(`section_${minLevel}.title`),
      hint: t(`section_${minLevel}.hint`),
      rules: this.rules
        .filter((r) => r.minLevel === minLevel)
        .map((rule, index, list) => ({
          ...this.#decorate(rule),
          id: rule.id,
          first: index === 0,
          last: index === list.length - 1,
        })),
    }));
  }

  get previewLevels() {
    return [1, 2, 3].map((level) => ({
      level,
      label: i18n(themePrefix(`complexity_modes.levels.${LEVEL_KEYS[level]}`)),
    }));
  }

  get cssLevels() {
    return this.previewLevels.map((l) => ({
      ...l,
      value: this.customCss[l.level],
    }));
  }

  #decorate(rule) {
    const error = selectorError(rule.selector);
    let status;
    if (error) {
      status = { css: "--error", text: t("status.invalid") };
    } else if (hidesSwitcher(rule.selector)) {
      status = { css: "--error", text: t("status.hides_switcher") };
    } else {
      const count = countMatches(rule.selector);
      status = {
        css: count ? "--ok" : "--none",
        text: t("status.matches", { count }),
      };
    }
    return { rule, status, error };
  }

  #update(rules) {
    this.rules = rules;
    this.complexityModes.preview(this.rules, this.customCss);
  }

  #patch(rule, changes) {
    this.#update(
      this.rules.map((r) => (r.id === rule.id ? { ...r, ...changes } : r))
    );
  }

  @action
  setText(rule, field, event) {
    this.#patch(rule, { [field]: event.target.value });
  }

  @action
  toggleEnabled(rule, event) {
    this.#patch(rule, { enabled: event.target.checked });
  }

  @action
  moveLevel(rule) {
    this.#patch(rule, { minLevel: rule.minLevel === 2 ? 3 : 2 });
  }

  @action
  move(rule, direction) {
    // Reorder within the rule's own section.
    const siblings = this.rules.filter((r) => r.minLevel === rule.minLevel);
    const other = siblings[siblings.indexOf(rule) + direction];
    if (!other) {
      return;
    }
    const rules = [...this.rules];
    const a = rules.indexOf(rule);
    const b = rules.indexOf(other);
    [rules[a], rules[b]] = [rules[b], rules[a]];
    this.#update(rules);
  }

  @action
  remove(rule) {
    this.#update(this.rules.filter((r) => r.id !== rule.id));
  }

  @action
  add(minLevel, selector = "", label = "") {
    this.#update([
      ...this.rules,
      { id: newRuleId(), label, selector, minLevel, enabled: true },
    ]);
  }

  @action
  async pick(minLevel) {
    this.picking = true;
    try {
      const el = await pickElement({
        ignore: (node) =>
          !!node.closest(".d-modal, .complexity-modes-switcher"),
      });
      if (el) {
        this.add(minLevel, suggestSelector(el), t("picked_label"));
      }
    } finally {
      this.picking = false;
    }
  }

  @action
  setCustomCss(level, event) {
    this.customCss = { ...this.customCss, [level]: event.target.value };
    this.complexityModes.preview(this.rules, this.customCss);
  }

  @action
  previewLevel(level) {
    this.complexityModes.setLevel(level);
  }

  @action
  setTransferText(event) {
    this.transferText = event.target.value;
  }

  @action
  exportJson() {
    this.transferText = this.complexityModes.export(this.rules, this.customCss);
    this.transferError = null;
  }

  @action
  importJson() {
    try {
      const data = deserialize(this.transferText);
      if (data.customCss) {
        this.customCss = data.customCss;
      }
      if (data.level) {
        this.complexityModes.setLevel(data.level);
      }
      this.#update(data.rules ?? this.rules);
      this.transferError = null;
    } catch (e) {
      this.transferError = t("import_error", { message: e.message });
    }
  }

  @action
  resetToDefaults() {
    this.dialog.yesNoConfirm({
      message: t("reset_confirm"),
      didConfirm: () => {
        this.saved = true;
        this.complexityModes.resetCustomization();
        this.args.closeModal();
      },
    });
  }

  @action
  save() {
    this.saved = true;
    this.complexityModes.saveCustomization(this.rules, this.customCss);
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n (themePrefix "complexity_modes.config.title")}}
      @closeModal={{@closeModal}}
      class={{concatClass
        "complexity-modes-config"
        (if this.picking "--picking")
      }}
    >
      <:body>
        <p class="complexity-modes-config__intro">
          {{i18n (themePrefix "complexity_modes.config.intro")}}
        </p>

        <div class="complexity-modes-config__preview">
          <span>{{i18n (themePrefix "complexity_modes.config.preview")}}</span>
          {{#each this.previewLevels as |item|}}
            <DButton
              class={{if
                (eq item.level this.complexityModes.level)
                "btn-primary"
                "btn-default"
              }}
              @translatedLabel={{item.label}}
              @action={{fn this.previewLevel item.level}}
            />
          {{/each}}
        </div>

        {{#each this.sections as |section|}}
          <section class="complexity-modes-config__section">
            <h3>{{section.title}}</h3>
            <p class="complexity-modes-config__hint">{{section.hint}}</p>

            <ul class="complexity-modes-config__rules">
              {{#each section.rules key="id" as |item|}}
                <li
                  class={{concatClass
                    "complexity-modes-rule"
                    (unless item.rule.enabled "--disabled")
                  }}
                >
                  <input
                    type="checkbox"
                    checked={{item.rule.enabled}}
                    title={{i18n
                      (themePrefix "complexity_modes.config.enabled")
                    }}
                    {{on "change" (fn this.toggleEnabled item.rule)}}
                  />
                  <input
                    type="text"
                    class="complexity-modes-rule__label"
                    value={{item.rule.label}}
                    placeholder={{i18n
                      (themePrefix "complexity_modes.config.label")
                    }}
                    {{on "input" (fn this.setText item.rule "label")}}
                  />
                  <input
                    type="text"
                    class={{concatClass
                      "complexity-modes-rule__selector"
                      (if item.error "--invalid")
                    }}
                    value={{item.rule.selector}}
                    placeholder=".css-class, #id"
                    spellcheck="false"
                    title={{item.error}}
                    {{on "input" (fn this.setText item.rule "selector")}}
                  />
                  <span
                    class={{concatClass
                      "complexity-modes-rule__status"
                      item.status.css
                    }}
                  >{{item.status.text}}</span>
                  <span class="complexity-modes-rule__actions">
                    <DButton
                      class="btn-flat btn-small"
                      @icon="arrow-up"
                      @title={{themePrefix "complexity_modes.config.move_up"}}
                      @disabled={{item.first}}
                      @action={{fn this.move item.rule -1}}
                    />
                    <DButton
                      class="btn-flat btn-small"
                      @icon="arrow-down"
                      @title={{themePrefix "complexity_modes.config.move_down"}}
                      @disabled={{item.last}}
                      @action={{fn this.move item.rule 1}}
                    />
                    <DButton
                      class="btn-flat btn-small"
                      @icon={{if
                        (eq section.minLevel 2)
                        "arrow-right"
                        "arrow-left"
                      }}
                      @title={{if
                        (eq section.minLevel 2)
                        (themePrefix "complexity_modes.config.move_to_3")
                        (themePrefix "complexity_modes.config.move_to_2")
                      }}
                      @action={{fn this.moveLevel item.rule}}
                    />
                    <DButton
                      class="btn-flat btn-small btn-danger"
                      @icon="trash-can"
                      @title={{themePrefix "complexity_modes.config.delete"}}
                      @action={{fn this.remove item.rule}}
                    />
                  </span>
                </li>
              {{/each}}
            </ul>

            <div class="complexity-modes-config__add">
              <DButton
                class="btn-default btn-small"
                @icon="plus"
                @label={{themePrefix "complexity_modes.config.add"}}
                @action={{fn this.add section.minLevel "" ""}}
              />
              <DButton
                class="btn-default btn-small"
                @icon="crosshairs"
                @label={{themePrefix "complexity_modes.config.pick"}}
                @action={{fn this.pick section.minLevel}}
              />
            </div>
          </section>
        {{/each}}

        <details class="complexity-modes-config__details">
          <summary>{{i18n
              (themePrefix "complexity_modes.config.custom_css")
            }}</summary>
          <p class="complexity-modes-config__hint">{{i18n
              (themePrefix "complexity_modes.config.custom_css_hint")
            }}</p>
          {{#each this.cssLevels as |item|}}
            <label class="complexity-modes-config__css">
              <span>{{item.label}}</span>
              <textarea
                spellcheck="false"
                value={{item.value}}
                {{on "input" (fn this.setCustomCss item.level)}}
              />
            </label>
          {{/each}}
        </details>

        <details class="complexity-modes-config__details">
          <summary>{{i18n
              (themePrefix "complexity_modes.config.transfer")
            }}</summary>
          <p class="complexity-modes-config__hint">{{i18n
              (themePrefix "complexity_modes.config.transfer_hint")
            }}</p>
          <textarea
            class="complexity-modes-config__transfer"
            spellcheck="false"
            value={{this.transferText}}
            {{on "input" this.setTransferText}}
          />
          {{#if this.transferError}}
            <p class="complexity-modes-config__error">{{this.transferError}}</p>
          {{/if}}
          <div class="complexity-modes-config__add">
            <DButton
              class="btn-default btn-small"
              @label={{themePrefix "complexity_modes.config.export"}}
              @action={{this.exportJson}}
            />
            <DButton
              class="btn-default btn-small"
              @label={{themePrefix "complexity_modes.config.import"}}
              @action={{this.importJson}}
            />
          </div>
        </details>
      </:body>

      <:footer>
        <DButton
          class="btn-primary"
          @label={{themePrefix "complexity_modes.config.save"}}
          @action={{this.save}}
        />
        <DButton
          class="btn-flat"
          @label={{themePrefix "complexity_modes.config.cancel"}}
          @action={{@closeModal}}
        />
        <DButton
          class="btn-danger btn-flat complexity-modes-config__reset"
          @icon="arrow-rotate-left"
          @label={{themePrefix "complexity_modes.config.reset"}}
          @action={{this.resetToDefaults}}
        />
      </:footer>
    </DModal>
  </template>
}
