import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import concatClass from "discourse/helpers/concat-class";
import DMenu from "discourse/float-kit/components/d-menu";
import { i18n } from "discourse-i18n";
import { LEVEL_KEYS, SWITCHER_CLASS } from "../lib/rules";
import ComplexityConfigModal from "./complexity-config-modal";

const ICONS = { 1: "feather", 2: "sliders", 3: "layer-group" };

export default class ComplexitySwitcher extends Component {
  @service complexityModes;
  @service modal;

  switcherClass = SWITCHER_CLASS;

  // Most to least: Alles, Standard, Fokus, then Zen.
  get levels() {
    return [3, 2, 1].map((level) => ({
      level,
      icon: ICONS[level],
      current:
        !this.complexityModes.zen && level === this.complexityModes.level,
      label: i18n(themePrefix(`complexity_modes.levels.${LEVEL_KEYS[level]}`)),
      description: i18n(
        themePrefix(`complexity_modes.descriptions.${LEVEL_KEYS[level]}`)
      ),
    }));
  }

  get zenItem() {
    return {
      label: i18n(themePrefix("complexity_modes.zen.enter")),
      description: i18n(themePrefix("complexity_modes.zen.description")),
    };
  }

  get currentIcon() {
    return ICONS[this.complexityModes.level];
  }

  get title() {
    const key = LEVEL_KEYS[this.complexityModes.level];
    return i18n(themePrefix("complexity_modes.switcher_title"), {
      level: i18n(themePrefix(`complexity_modes.levels.${key}`)),
    });
  }

  @action
  registered() {
    // Re-run so rules that would hide this switcher get filtered out.
    this.complexityModes.apply();
  }

  @action
  select(level, dMenu) {
    this.complexityModes.setLevel(level);
    dMenu.close();
  }

  @action
  enterZen(dMenu) {
    dMenu.close();
    this.complexityModes.setZen(true);
  }

  @action
  openConfig(dMenu) {
    dMenu.close();
    this.modal.show(ComplexityConfigModal);
  }

  <template>
    <li
      class="header-dropdown-toggle {{this.switcherClass}}"
      {{didInsert this.registered}}
    >
      <DMenu
        @icon={{this.currentIcon}}
        @triggerClass="icon btn-flat"
        @identifier="complexity-modes"
        @title={{this.title}}
        @ariaLabel={{this.title}}
        @animated={{false}}
        class="complexity-modes-trigger"
      >
        <:content as |dMenu|>
          <DropdownMenu class="complexity-modes-menu" as |dropdown|>
            {{#each this.levels as |item|}}
              <dropdown.item>
                <DButton
                  class={{concatClass
                    "btn-transparent complexity-modes-menu__level"
                    (if item.current "--current")
                  }}
                  data-level={{item.level}}
                  @icon={{item.icon}}
                  @action={{fn this.select item.level dMenu}}
                >
                  <span class="complexity-modes-menu__text">
                    <span class="complexity-modes-menu__label">
                      {{item.label}}
                    </span>
                    <span class="complexity-modes-menu__description">
                      {{item.description}}
                    </span>
                  </span>
                </DButton>
              </dropdown.item>
            {{/each}}
            <dropdown.item>
              <DButton
                class={{concatClass
                  "btn-transparent complexity-modes-menu__level complexity-modes-menu__zen"
                  (if this.complexityModes.zen "--current")
                }}
                data-level="zen"
                @action={{fn this.enterZen dMenu}}
              >
                <span
                  class="complexity-modes-menu__emoji"
                  aria-hidden="true"
                >🧘</span>
                <span class="complexity-modes-menu__text">
                  <span class="complexity-modes-menu__label">
                    {{this.zenItem.label}}
                  </span>
                  <span class="complexity-modes-menu__description">
                    {{this.zenItem.description}}
                  </span>
                </span>
              </DButton>
            </dropdown.item>
            {{#if this.complexityModes.allowCustomization}}
              <dropdown.divider />
              <dropdown.item>
                <DButton
                  class="btn-transparent complexity-modes-menu__customize"
                  @icon="pencil"
                  @translatedLabel={{i18n
                    (themePrefix "complexity_modes.customize")
                  }}
                  @action={{fn this.openConfig dMenu}}
                />
              </dropdown.item>
            {{/if}}
          </DropdownMenu>
        </:content>
      </DMenu>
    </li>
  </template>
}
