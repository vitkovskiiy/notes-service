const express = require('express');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const port = process.env.PORT || 8000;

if (process.env.LISTEN_FDS && parseInt(process.env.LISTEN_FDS) > 0) {
    app.listen({ fd: 3 }, () => console.log('Listening on systemd socket'));
} else {
    
    app.listen(port, () => console.log(`Listening on port ${port}`));
}

module.exports = app; 
