const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const promClient = require('prom-client');
const path = require('path');

// Configuração do Prometheus
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Contador personalizado para requisições de piadas
const jokeRequestCounter = new promClient.Counter({
    name: 'joke_requests_total',
    help: 'Total number of joke requests',
    labelNames: ['endpoint']
});
register.registerMetric(jokeRequestCounter);

// Inicialização do app Express
const app = express();
app.use(express.json());

// Configuração do SQLite
const dbPath = process.env.NODE_ENV === 'production' 
    ? path.resolve('/data/jokes.db')  // Caminho para o volume no Kubernetes
    : path.resolve(__dirname, 'jokes.db');  // Caminho local para desenvolvimento
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
                "Por que o programador saiu do banho chorando? Porque o shampoo dizia 'Repita'.",
                "Como se faz para um programador trocar uma lâmpada? Não se faz, é um problema de hardware.",
                "Por que os programadores preferem o frio? Porque têm muitos bugs no verão.",
                "O que um programador de Javascript falou para o outro? Eu consigo fazer uma Promise, mas não consigo te dar um Callback.",
                "Como um programador se afoga? Ele não implementou a interface Swimmable."
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
app.get('/jokes/random', (req, res) => {
    jokeRequestCounter.inc({ endpoint: 'random' });
    
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
app.get('/jokes', (req, res) => {
    jokeRequestCounter.inc({ endpoint: 'list' });
    
    db.all("SELECT * FROM jokes", (err, rows) => {
        if (err) {
            console.error("Erro ao listar piadas:", err);
            return res.status(500).json({ error: "Erro ao listar piadas" });
        }
        
        res.json(rows);
    });
});

// Endpoint para adicionar nova piada
app.post('/jokes', (req, res) => {
    jokeRequestCounter.inc({ endpoint: 'create' });
    
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
app.get('/metrics', async (req, res) => {
    try {
        res.set('Content-Type', register.contentType);
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
process.on('SIGINT', () => {
    db.close(() => {
        console.log('Conexão com o banco de dados fechada');
        process.exit(0);
    });
});
