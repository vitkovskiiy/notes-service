const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

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

router.post("/:id/done", async (req, res) => {
  try {
    const updateStatus = await prisma.task.update({
      where: { id: parseInt(req.params.id) },
      data: { status: "DONE" },
    });
    res.status(200).send(updateStatus);
  } catch (e) {
    res.status(404).json({ message: e})
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
