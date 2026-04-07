const express = require("express");
const notesRouter = require("./src/routes/notes.router");
const healthRouter = require("./src/routes/health.router");

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  if (!req.accepts("html"))
    return res.status(406).send("Only text/html supported");
  res.send(`
        <!DOCTYPE html>
        <html>
        <head><title>API Endpoints</title></head>
        <body>
            <h1>MyWebApp (Notes Service) Endpoints</h1>
            <ul>
                <li><a href="/notes">GET /notes</a></li>
                <li>POST /notes</li>
                <li>GET /notes/&lt;id&gt;</li>
                <li><a href="/health/alive">GET /health/alive</a></li>
                <li><a href="/health/ready">GET /health/ready</a></li>
            </ul>
        </body>
        </html>
    `);
});

app.use("/notes", notesRouter);
app.use("/health", healthRouter);

const port = process.env.PORT || 8000;

if (process.env.LISTEN_FDS && parseInt(process.env.LISTEN_FDS) > 0) {
  
  app.listen({ fd: 3 }, () => console.log("Listening on systemd socket"));
} else {
  
  app.listen(port, () => console.log(`Listening on port ${port}`));
}
