const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

router.get('/health/alive', (req, res) => res.status(200).send('OK'));

router.get('/health/ready', async (req, res) => {
    try {
        await prisma.$queryRaw`SELECT 1`;
        res.status(200).send('OK');
    } catch (error) {
        res.status(500).send('Database connection failed');
    }
});
module.exports = router;
