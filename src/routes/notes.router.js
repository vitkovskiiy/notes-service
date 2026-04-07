const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
const generateHtml = require("../../server")

router.get('/notes/:id', async (req, res) => {
    const note = await prisma.note.findUnique({ where: { id: parseInt(req.params.id) } });
    
    if (!note) return res.status(404).send('Note not found');
    
    if (req.accepts('html')) {
        const details = `
        <table border="1">
            <tr><th>ID</th><td>${note.id}</td></tr>
            <tr><th>Title</th><td>${note.title}</td></tr>
            <tr><th>Created At</th><td>${note.created_at}</td></tr>
            <tr><th>Content</th><td>${note.content}</td></tr>
        </table>`;
        res.send(generateHtml('Note Details', details));
    } else {
        res.json(note);
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

router.post('/notes', async (req, res) => {
    const { title, content } = req.body;
    const note = await prisma.note.create({ data: { title, content } });
    res.status(201).json(note);
});

module.exports = router;
