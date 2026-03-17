const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

router.get("/", async (req, res) => {
  try {
    const response = await prisma.task.findMany();
    res.status(200).send(response);
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
    console.log(e);
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
    console.log(e);
  }
});

module.exports = router;
