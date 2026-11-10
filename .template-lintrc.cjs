const base = require("@discourse/lint-configs/template-lint");

module.exports = {
  ...base,
  rules: {
    ...base.rules,
    // Form fields inside a <details> disclosure are fine.
    "no-nested-interactive": ["error", { ignoredTags: ["details"] }],
  },
};
