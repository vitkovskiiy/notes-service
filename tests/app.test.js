const request = require("supertest");
const app = require("../server");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

describe("Health endpoints", () => {
  it("GET /health/alive → 200", async () => {
    const res = await request(app)
      .get("/health/alive")
      .set("Accept", "application/json");
    expect(res.statusCode).toEqual(200);
  });

  it("GET /health/ready → 200", async () => {
    const res = await request(app)
      .get("/health/ready")
      .set("Accept", "application/json");
    expect(res.statusCode).toEqual(200);
  });
});

describe("Root endpoint", () => {
  it("GET / with Accept: text/html → 200 HTML page", async () => {
    const res = await request(app).get("/").set("Accept", "text/html");
    expect(res.statusCode).toEqual(400);
    expect(res.text).toMatch(/Notes Service/i);
  });

  it("GET / with Accept: application/json → 406", async () => {
    const res = await request(app).get("/").set("Accept", "application/json");
    expect(res.statusCode).toEqual(406);
  });
});

describe("Notes API", () => {
  let createdId;


  describe("POST /notes", () => {
    it("creates a note and returns 201 with JSON body", async () => {
      const res = await request(app)
        .post("/notes")
        .set("Accept", "application/json")
        .send({ title: "Test Note", content: "This is a test" });

      if (res.statusCode !== 201) console.log(res.body);
      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty("id");
      expect(res.body.title).toBe("Test Note");
      expect(res.body.content).toBe("This is a test");
      createdId = res.body.id;
    });

    it("returns 400 when title is missing", async () => {
      const res = await request(app)
        .post("/notes")
        .set("Accept", "application/json")
        .send({ content: "no title" });
      expect(res.statusCode).toEqual(400);
    });
  });

  describe("GET /notes", () => {
    it("returns 200 and a JSON array", async () => {
      const res = await request(app)
        .get("/notes")
        .set("Accept", "application/json");
      expect(res.statusCode).toEqual(200);
      expect(Array.isArray(res.body)).toBeTruthy();
    });

    it("returns 200 HTML when Accept: text/html", async () => {
      const res = await request(app).get("/notes").set("Accept", "text/html");
      expect(res.statusCode).toEqual(200);
      expect(res.text).toMatch(/<table/i);
    });

    it("contains the previously created note", async () => {
      if (!createdId) return;
      const res = await request(app)
        .get("/notes")
        .set("Accept", "application/json");
      const found = res.body.find((n) => n.id === createdId);
      expect(found).toBeDefined();
    });
  });

  describe("GET /notes/:id", () => {
    it("returns 200 JSON for existing note", async () => {
      if (!createdId) return;
      const res = await request(app)
        .get(`/notes/${createdId}`)
        .set("Accept", "application/json");
      expect(res.statusCode).toEqual(200);
      expect(res.body.id).toBe(createdId);
      expect(res.body.title).toBe("Test Note");
    });

    it("returns 200 HTML for existing note when Accept: text/html", async () => {
      if (!createdId) return;
      const res = await request(app)
        .get(`/notes/${createdId}`)
        .set("Accept", "text/html");
      expect(res.statusCode).toEqual(200);
      expect(res.text).toMatch(/Test Note/);
    });

    it("returns 404 for a non-existent note", async () => {
      const res = await request(app)
        .get("/notes/999999999")
        .set("Accept", "application/json");
      expect(res.statusCode).toEqual(404);
    });
  });
  
  afterAll(async () => {
    await prisma.$disconnect();
  });
});
