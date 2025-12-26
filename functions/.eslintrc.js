module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files
    ".eslintrc.js",
  ],
  plugins: [
    "@typescript-eslint",
  ],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
  ],
  rules: {
    "quotes": ["error", "double", { "allowTemplateLiterals": true }],
    "indent": ["error", 2],
    "@typescript-eslint/no-unused-vars": "warn",
    "max-len": ["warn", { "code": 120 }],
  },
};
