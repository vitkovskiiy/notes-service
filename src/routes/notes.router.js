const router = require("express").Router()
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

router.get("/", async (req,res) => {
    try{
    const response = await prisma.task.findMany();
    res.status(200).send(response);
    } catch(e){
       res.status(404).json({message: e})
    }
})

router.post("/", async (req,res) => {
    console.log(req.body)
    const {titleTask, contentTask} = req.body
    try{
    const response = await prisma.task.create({
         data: {
            title: titleTask,
            content: contentTask,
         }
    });
    res.status(200).send(response);
    } catch(e){
       console.log(e)
    }
})

module.exports = router;