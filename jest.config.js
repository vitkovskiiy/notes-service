/** @type {import('jest').Config} */
const config = {
  testEnvironment: "node",
  testMatch: ["**/tests/**/*.test.js"],
  collectCoverageFrom: [
    "server.js",
    "src/**/*.js",
    "!**/node_modules/**",
    "!**/tests/**",
    "!**/prisma/**",
  ],
  coverageThreshold: {
    global: {
      lines: 40,
      functions: 40,
      branches: 40,
      statements: 40,
    },
  },
  coverageReporters: ["text", "lcov", "html"],
  testTimeout: 15000,
};

module.exports = config;
