import DiscourseRecommended from "@discourse/lint-configs/eslint-theme";

export default [
  ...DiscourseRecommended,
  { ignores: ["node_modules/**"] },
  {
    files: ["tests-node/**"],
    languageOptions: { globals: { process: "readonly" } },
  },
];
