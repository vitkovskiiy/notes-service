const express = require("express");
const app = express();
require('dotenv').config();
app.use(express.json()); 

//import routes
const notesRouter = require("./src/routes/notes.router")
const healthRouter = require("./src/routes/health.router")

//config api routes
app.use("/tasks", notesRouter)
app.use("/health", healthRouter)

//for start page
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