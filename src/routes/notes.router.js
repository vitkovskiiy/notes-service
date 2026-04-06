const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

const generateHtml = (title, body) => `
<!DOCTYPE html>
<html>
<head><title>${title}</title></head>
<body>${body}</body>
</html>
`;



router.get("/", async (req, res) => {
  
  try {
    const acceptHeader = req.headers.accept || '';
    const response = await prisma.task.findMany();
    if(acceptHeader.includes('text/html')){
       const parsed = response.map(task =>`${task.title} (ID: ${task.id})`);
       return res.status(200).send(`Your, tasks \n${parsed}`);
    } else {
       return res.status(200).send(response);
    }
  } catch (e) {
    res.status(404).json({ message: e });
  }
});

router.get('/notes', async (req, res) => {
    const notes = await prisma.note.findMany({ select: { id: true, title: true } });
    
    if (req.accepts('html')) {
        const rows = notes.map(n => `<tr><td>${n.id}</td><td>${n.title}</td></tr>`).join('');
        res.send(generateHtml('Notes', `<table border="1"><tr><th>ID</th><th>Title</th></tr>${rows}</table>`));
    } else {
        res.json(notes);
    }
});

router.post("/", async (req, res) => {
  try {
    const response = await prisma.task.create({
      data: {
        title: req.body.titleTask,
        content: req.body.contentTask,
      },
    });
    res.status(200).send(response);
  } catch (e) {
    res.status(404).json({ message: e})
  }
});

module.exports = router;
