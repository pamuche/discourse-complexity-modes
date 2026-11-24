import { apiInitializer } from "discourse/lib/api";
import ComplexitySwitcher from "../components/complexity-switcher";
import ZenOverlay from "../components/zen-overlay";

export default apiInitializer((api) => {
  // Instantiating the service applies the saved level + rules right away.
  api.container.lookup("service:complexity-modes");

  if (!settings.show_for_anonymous && !api.getCurrentUser()) {
    return;
  }

  api.renderInOutlet("above-site-header", ZenOverlay);

  api.headerIcons.add("complexity-modes", ComplexitySwitcher, {
    before: "user-menu",
    after: "hamburger",
  });
});
