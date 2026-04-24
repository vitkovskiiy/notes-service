const request = require("supertest");
const express = require("express");
const healthRouter = require("../src/routes/health.router");

const app = express();
app.use("/health", healthRouter);

describe("Health Endpoints", () => {
  it("should return OK on /health/alive", async () => {
    const res = await request(app).get("/health/alive");
    expect(res.statusCode).toEqual(200);
    expect(res.text).toBe("OK");
  });
});
