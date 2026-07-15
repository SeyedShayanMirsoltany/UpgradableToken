module.exports = {
  plugins: ["prettier-plugin-solidity"],
  overrides: [
    {
      files: "*.sol",
      options: {
        printWidth: 170,       // 👈 عرض خط بیشتر = شکستن کمتر
        tabWidth: 4,
        useTabs: false,
        bracketSpacing: true,
        singleQuote: false,
        explicitTypes: "always"
      }
    }
  ]
};
