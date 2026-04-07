const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
const generateHtml = require("../../server")

const generateHtml = (title, body) => `
<!DOCTYPE html>
<html>
<head><title>${title}</title></head>
<body>${body}</body>
</html>
`;

router.get("/", async (req, res) => {
  try {
    const notes = await prisma.note.findMany({
      select: { id: true, title: true },
    });

    if (req.accepts("html")) {
      const rows = notes
        .map((n) => `<tr><td>${n.id}</td><td>${n.title}</td></tr>`)
        .join("");
      res.send(
        generateHtml(
          "Notes",
          `<table border="1"><tr><th>ID</th><th>Title</th></tr>${rows}</table>`,
        ),
      );
    } else {
      res.json(notes);
    }
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const response = await prisma.note.create({
      data: {
        title: req.body.title, 
        content: req.body.content,
      },
    });
    res.status(201).json(response);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});


router.get("/:id", async (req, res) => {
  try {
    const note = await prisma.note.findUnique({
      where: { id: parseInt(req.params.id) },
    });
    if (!note) return res.status(404).send("Note not found");

    if (req.accepts("html")) {
      const details = `
            <table border="1">
                <tr><th>ID</th><td>${note.id}</td></tr>
                <tr><th>Title</th><td>${note.title}</td></tr>
                <tr><th>Created At</th><td>${note.created_at}</td></tr>
                <tr><th>Content</th><td>${note.content}</td></tr>
            </table>`;
      res.send(generateHtml("Note Details", details));
    } else {
      res.json(note);
    }
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
