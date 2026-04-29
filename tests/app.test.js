const request = require("supertest");
const app = require("../server");

describe("Notes API", () => {
  it("should return all notes", async () => {
    const res = await request(app).get("/notes");
    expect(res.statusCode).toEqual(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });

  it("should create a new note", async () => {
    const res = await request(app).post("/notes").send({
      title: "Test Note",
      content: "This is a test",
    });

    if (res.statusCode !== 201) console.log(res.body);
    expect(res.statusCode).toEqual(201);
  });
});