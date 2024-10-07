const express = require('express');
const cors = require('cors'); // Importando o CORS

const app = express();
const port = 9090;

const monitoresData = require('./monitores.json');

// Habilitar CORS para todas as origens
app.use(cors());

app.get('/', (req, res) => {
  res.send("Olá");
});

app.get('/monitores', (req, res) => {
  res.json(monitoresData);
});

app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});
