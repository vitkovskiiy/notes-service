const express = require('express');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));



// Кореневий ендпоінт
app.get('/', (req, res) => {
    if (!req.accepts('html')) return res.status(406).send('Only text/html supported');
    res.send(generateHtml('API Endpoints', `
        <h1>MyWebApp (Notes Service) Endpoints</h1>
        <ul>
            <li><a href="/notes">GET /notes</a></li>
            <li>POST /notes (title, content)</li>
            <li>GET /notes/&lt;id&gt;</li>
            <li><a href="/health/alive">GET /health/alive</a></li>
            <li><a href="/health/ready">GET /health/ready</a></li>
        </ul>
    `));
});




// Бізнес-логіка: Отримати всі нотатки


// Бізнес-логіка: Створити нотатку
app.post('/notes', async (req, res) => {
    const { title, content } = req.body;
    const note = await prisma.note.create({ data: { title, content } });
    res.status(201).json(note);
});

// Бізнес-логіка: Отримати нотатку за ID
app.get('/notes/:id', async (req, res) => {
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


const port = process.env.PORT || 8000;

if (process.env.LISTEN_FDS && parseInt(process.env.LISTEN_FDS) > 0) {
    app.listen({ fd: 3 }, () => console.log('Listening on systemd socket'));
} else {
    // Звичайний запуск (для розробки)
    app.listen(port, () => console.log(`Listening on port ${port}`));
}