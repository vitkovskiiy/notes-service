/** @type {import('jest').Config} */
const config = {
  testEnvironment: "node",
  testMatch: ["**/tests/**/*.test.js"],
  collectCoverage: false, // enabled via --coverage flag in npm script
  coverageDirectory: "coverage",
  collectCoverageFrom: [
    "src/**/*.js",
    "server.js",
    "!**/node_modules/**",
    "!**/tests/**",
  ],
  coverageThresholds: {
    global: {
      lines: 40,
      functions: 40,
      branches: 40,
      statements: 40,
    },
  },
  coverageReporters: ["text", "lcov", "html"],
  // Give each test file a clean DB state by using transactions or mocks
  setupFilesAfterFramework: [],
  testTimeout: 15000,
};

module.exports = config;
