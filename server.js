const express = require("express");
const app = express();
require('dotenv').config();
app.use(express.json()); 

const notesRouter = require("../notes-service/src/routes/notes.router")

app.use("/tasks",notesRouter)

app.get('/', (req, res) => {
  res.send('hello world')
})

app.listen(process.env.PORT,()=> {
    console.log("server is working")
})