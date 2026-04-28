const request = require("supertest");
const server = require("../server");

describe("Basic API Tests", () => {
  it("should return 200 for health check", async () => {
    const res = await request(server).get("/health/alive");
    expect(res.statusCode).toEqual(200);
    expect(res.text).toBe("OK");
  });
  afterAll((done) => {
    server.close(done);
  });
});
