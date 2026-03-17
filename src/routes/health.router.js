const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

router.get("/alive", async (req, res) => {
  res.status(200).json({ message: "OK" });
});

router.get("/ready", async (req, res) => {
  try {
    if (prisma.task) {
      res.status(200).json({ message: "Connected to database and ready to work" });
    } 
  } catch (e) {
    res.status(500).json({ message: "Something happened while tried connect to database", e});
  }
});
module.exports = router;
