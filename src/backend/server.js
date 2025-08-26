const express = require("express");
const sqlite3 = require("sqlite3").verbose();
const promClient = require("prom-client");
const path = require("path");

// Configuração do Prometheus
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Contador personalizado para requisições de piadas
const jokeRequestCounter = new promClient.Counter({
  name: "joke_requests_total",
  help: "Total number of joke requests",
  labelNames: ["endpoint"]
});
register.registerMetric(jokeRequestCounter);

// Inicialização do app Express
const app = express();
app.use(express.json());

// Configuração do SQLite
const dbPath =
  process.env.NODE_ENV === "production"
    ? path.resolve("/data/jokes.db") // Caminho para o volume no Kubernetes
    : path.resolve(__dirname, "jokes.db"); // Caminho local para desenvolvimento
const db = new sqlite3.Database(dbPath);

// Criar tabela de piadas se não existir
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS jokes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL
    )`);

  // Inserir algumas piadas de exemplo se a tabela estiver vazia
  db.get("SELECT COUNT(*) as count FROM jokes", (err, row) => {
    if (err) {
      console.error("Erro ao verificar piadas:", err);
      return;
    }

    if (row.count === 0) {
      const sampleJokes = [
        "Por que o programador faliu? Porque ele usava cache demais.",
        "Como o programador pede café? Um Java, por favor.",
        "Qual é o cúmulo do programador? Sonhar com segmentation fault.",
        "O que o HTML disse pro CSS? Não vai me dar estilo hoje?",
        "Por que os programadores preferem escuro? Porque a luz atrai bugs.",
        "Qual é a linguagem de programação mais educada? O Please-thon.",
        "Por que o servidor foi ao médico? Estava com muita requisição.",
        "Quantos programadores são necessários para trocar uma lâmpada? Nenhum. Isso é um problema de hardware.",
        "O que o Python disse ao Java? Menos chaves, mais abraços.",
        "Por que os programadores não conseguem guardar segredos? Porque eles sempre fazem log.",
        "O que acontece quando você coloca café no código? Ele vira JavaScript.",
        "Sabe por que o programador adora a natureza? Porque tem muitas árvores de diretórios.",
        "Qual é a comida favorita do programador? Byte.",
        "O que o código disse para o outro? Compila comigo?",
        "Por que o framework terminou com a biblioteca? Porque não tinha mais dependência.",
        "Por que o computador foi ao psicólogo? Porque tinha muitos conflitos internos.",
        "Qual é o animal preferido dos devs? O bug. Sempre aparece sem ser chamado.",
        "O que o Linux disse para o Windows? Você trava, eu rodo.",
        "Por que o JavaScript foi a terapia? Porque tinha muitos problemas de escopo.",
        "Qual é o super-herói favorito do programador? O Debug-man."
      ];

      const stmt = db.prepare("INSERT INTO jokes (text) VALUES (?)");
      sampleJokes.forEach(joke => {
        stmt.run(joke);
      });
      stmt.finalize();
      console.log("Piadas de exemplo inseridas com sucesso!");
    }
  });
});

// Endpoint para obter piada aleatória
app.get("/jokes/random", (req, res) => {
  jokeRequestCounter.inc({ endpoint: "random" });

  db.get("SELECT * FROM jokes ORDER BY RANDOM() LIMIT 1", (err, row) => {
    if (err) {
      console.error("Erro ao buscar piada:", err);
      return res.status(500).json({ error: "Erro ao buscar piada" });
    }

    if (!row) {
      return res.status(404).json({ error: "Nenhuma piada encontrada" });
    }

    res.json(row);
  });
});

// Endpoint para listar todas as piadas
app.get("/jokes", (req, res) => {
  jokeRequestCounter.inc({ endpoint: "list" });

  db.all("SELECT * FROM jokes", (err, rows) => {
    if (err) {
      console.error("Erro ao listar piadas:", err);
      return res.status(500).json({ error: "Erro ao listar piadas" });
    }

    res.json(rows);
  });
});

// Endpoint para adicionar nova piada
app.post("/jokes", (req, res) => {
  jokeRequestCounter.inc({ endpoint: "create" });

  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ error: "O texto da piada é obrigatório" });
  }

  db.run("INSERT INTO jokes (text) VALUES (?)", [text], function(err) {
    if (err) {
      console.error("Erro ao inserir piada:", err);
      return res.status(500).json({ error: "Erro ao inserir piada" });
    }

    res.status(201).json({ id: this.lastID, text });
  });
});

// Endpoint para métricas do Prometheus
app.get("/metrics", async (req, res) => {
  try {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

// Iniciar o servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

// Função para fechar o banco de dados ao encerrar o processo
process.on("SIGINT", () => {
  db.close(() => {
    console.log("Conexão com o banco de dados fechada");
    process.exit(0);
  });
});
