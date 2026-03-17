const express = require("express");
const app = express();
require('dotenv').config();
app.use(express.json()); 

const notesRouter = require("../notes-service/src/routes/notes.router")

app.use("/tasks",notesRouter)

app.get('/', (req, res) => {
  const acceptHeader = req.headers.accept || '';
    if (!acceptHeader.includes('text/html')) {
        return res.status(406).send('Not Acceptable: expected: text/html');
    }
  res.sendFile(__dirname + '/frontend/api.html');
})

app.listen(process.env.PORT,()=> {
    console.log("server is working")
})