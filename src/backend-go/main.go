package main

import (
	"context"
	"database/sql"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/mattn/go-sqlite3"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
	"go.opentelemetry.io/otel/trace"
)

// Joke representa o modelo de dados para piadas
type Joke struct {
	ID   int64  `json:"id"`
	Text string `json:"text"`
}

// Constantes de caminhos de API
const (
	pathJokesRandom = "/jokes/random"
	pathJokes       = "/jokes"
	pathHealth      = "/health"
	pathMetrics     = "/metrics"
)

// Variáveis globais
var (
	db               *sql.DB
	tracer           trace.Tracer
	jokeRequestCount = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "joke_requests_total",
			Help: "Total number of joke requests",
		},
		[]string{"endpoint"},
	)
)

// initTracer configura o OpenTelemetry
func initTracer() (*sdktrace.TracerProvider, error) {
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://tempo:4318/v1/traces"
	}

	exporter, err := otlptracehttp.New(
		context.Background(),
		otlptracehttp.WithEndpoint(endpoint),
		otlptracehttp.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	// Criar resource com informações do serviço
	serviceName := os.Getenv("OTEL_SERVICE_NAME")
	if serviceName == "" {
		serviceName = "joke-api-go"
	}

	r := resource.NewWithAttributes(
		semconv.SchemaURL,
		semconv.ServiceNameKey.String(serviceName),
		semconv.ServiceVersionKey.String("1.0.0"),
		attribute.String("environment", os.Getenv("GO_ENV")),
	)

	// Criar e configurar o provider
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(r),
	)

	// Definir o tracer global
	otel.SetTracerProvider(tp)
	tracer = tp.Tracer("joke-api")

	return tp, nil
}

// setupDatabase inicializa o banco de dados SQLite
func setupDatabase() error {
	// Determinar o caminho do banco de dados
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		if os.Getenv("GO_ENV") == "production" {
			dbPath = "/data/jokes.db"
		} else {
			dbPath = filepath.Join(".", "jokes.db")
		}
	}

	// Garantir que o diretório existe
	if os.Getenv("GO_ENV") == "production" {
		os.MkdirAll("/data", 0755)
	}

	// Abrir conexão com o banco de dados
	var err error
	db, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		return err
	}

	// Criar a tabela se não existir
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS jokes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		text TEXT NOT NULL
	)`)
	if err != nil {
		return err
	}

	// Verificar se há piadas no banco, se não, inserir piadas de exemplo
	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM jokes").Scan(&count)
	if err != nil {
		return err
	}

	if count == 0 {
		sampleJokes := []string{
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
			"Qual é o super-herói favorito do programador? O Debug-man.",
		}

		tx, err := db.Begin()
		if err != nil {
			return err
		}

		stmt, err := tx.Prepare("INSERT INTO jokes (text) VALUES (?)")
		if err != nil {
			tx.Rollback()
			return err
		}
		defer stmt.Close()

		for _, joke := range sampleJokes {
			_, err = stmt.Exec(joke)
			if err != nil {
				tx.Rollback()
				return err
			}
		}

		err = tx.Commit()
		if err != nil {
			return err
		}

		log.Println("Piadas de exemplo inseridas com sucesso!")
	}

	return nil
}

// setupRoutes configura as rotas da API
func setupRoutes() *gin.Engine {
	// Usar modo de produção em ambiente de produção
	if os.Getenv("GO_ENV") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(gin.Logger())
	
	// Adicionar OpenTelemetry middleware
	r.Use(otelgin.Middleware("joke-api"))

	// Rota para piada aleatória
	r.GET(pathJokesRandom, getRandomJoke)
	
	// Rota para listar todas as piadas
	r.GET(pathJokes, listJokes)
	
	// Rota para adicionar nova piada
	r.POST(pathJokes, addJoke)
	
	// Rota para métricas do Prometheus
	r.GET(pathMetrics, gin.WrapH(promhttp.Handler()))
	
	// Rota de health check
	r.GET(pathHealth, healthCheck)

	return r
}

// getRandomJoke retorna uma piada aleatória
func getRandomJoke(c *gin.Context) {
	jokeRequestCount.WithLabelValues("random").Inc()
	
	start := time.Now()
	RecordRequestStart(pathJokesRandom)

	ctx, span := tracer.Start(c.Request.Context(), "get_random_joke")
	defer span.End()
	
	span.SetAttributes(attribute.String("endpoint", pathJokesRandom))

	var joke Joke
	err := db.QueryRowContext(ctx, "SELECT * FROM jokes ORDER BY RANDOM() LIMIT 1").Scan(&joke.ID, &joke.Text)
	RecordDatabaseQuery("SELECT", "jokes", err == nil)
	
	if err != nil {
		span.SetStatus(codes.Error, err.Error())
		log.Printf("Erro ao buscar piada: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao buscar piada"})
		RecordRequestEnd(pathJokesRandom, "GET", http.StatusInternalServerError, float64(time.Since(start).Milliseconds()))
		return
	}

	span.SetStatus(codes.Ok, "")
	span.SetAttributes(attribute.Int64("joke.id", joke.ID))
	c.JSON(http.StatusOK, joke)
	
	RecordJokeServed(pathJokesRandom, joke.ID)
	RecordRequestEnd(pathJokesRandom, "GET", http.StatusOK, float64(time.Since(start).Milliseconds()))
}

// listJokes retorna todas as piadas
func listJokes(c *gin.Context) {
	jokeRequestCount.WithLabelValues("list").Inc()
	
	start := time.Now()
	RecordRequestStart(pathJokes)

	ctx, span := tracer.Start(c.Request.Context(), "list_jokes")
	defer span.End()
	
	span.SetAttributes(attribute.String("endpoint", pathJokes))

	rows, err := db.QueryContext(ctx, "SELECT * FROM jokes")
	RecordDatabaseQuery("SELECT", "jokes", err == nil)
	
	if err != nil {
		span.SetStatus(codes.Error, err.Error())
		log.Printf("Erro ao listar piadas: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao listar piadas"})
		RecordRequestEnd(pathJokes, "GET", http.StatusInternalServerError, float64(time.Since(start).Milliseconds()))
		return
	}
	defer rows.Close()

	var jokes []Joke
	for rows.Next() {
		var joke Joke
		if err := rows.Scan(&joke.ID, &joke.Text); err != nil {
			span.SetStatus(codes.Error, err.Error())
			log.Printf("Erro ao ler piada: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao ler piada"})
			RecordRequestEnd(pathJokes, "GET", http.StatusInternalServerError, float64(time.Since(start).Milliseconds()))
			return
		}
		jokes = append(jokes, joke)
	}

	span.SetStatus(codes.Ok, "")
	span.SetAttributes(attribute.Int("jokes.count", len(jokes)))
	c.JSON(http.StatusOK, jokes)
	
	// Registrar cada piada individualmente
	for _, joke := range jokes {
		RecordJokeServed(pathJokes, joke.ID)
	}
	
	RecordRequestEnd(pathJokes, "GET", http.StatusOK, float64(time.Since(start).Milliseconds()))
}

// addJoke adiciona uma nova piada
func addJoke(c *gin.Context) {
	jokeRequestCount.WithLabelValues("create").Inc()
	
	start := time.Now()
	RecordRequestStart(pathJokes)

	ctx, span := tracer.Start(c.Request.Context(), "create_joke")
	defer span.End()
	
	span.SetAttributes(attribute.String("endpoint", pathJokes))
	span.SetAttributes(attribute.String("method", "POST"))

	var input struct {
		Text string `json:"text" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		span.SetStatus(codes.Error, "Texto da piada obrigatório")
		c.JSON(http.StatusBadRequest, gin.H{"error": "O texto da piada é obrigatório"})
		RecordRequestEnd(pathJokes, "POST", http.StatusBadRequest, float64(time.Since(start).Milliseconds()))
		return
	}

	span.SetAttributes(attribute.Int("joke.text.length", len(input.Text)))

	result, err := db.ExecContext(ctx, "INSERT INTO jokes (text) VALUES (?)", input.Text)
	RecordDatabaseQuery("INSERT", "jokes", err == nil)
	
	if err != nil {
		span.SetStatus(codes.Error, err.Error())
		log.Printf("Erro ao inserir piada: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao inserir piada"})
		RecordRequestEnd(pathJokes, "POST", http.StatusInternalServerError, float64(time.Since(start).Milliseconds()))
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		span.SetStatus(codes.Error, err.Error())
		log.Printf("Erro ao obter ID da piada: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erro ao obter ID da piada"})
		RecordRequestEnd(pathJokes, "POST", http.StatusInternalServerError, float64(time.Since(start).Milliseconds()))
		return
	}

	span.SetStatus(codes.Ok, "")
	span.SetAttributes(attribute.Int64("joke.id", id))
	c.JSON(http.StatusCreated, gin.H{"id": id, "text": input.Text})
	
	RecordJokeServed(pathJokes, id)
	RecordRequestEnd(pathJokes, "POST", http.StatusCreated, float64(time.Since(start).Milliseconds()))
}

// healthCheck verifica se o serviço está saudável
func healthCheck(c *gin.Context) {
	start := time.Now()
	RecordRequestStart(pathHealth)
	
	err := db.Ping()
	RecordDatabaseQuery("PING", "system", err == nil)
	
	if err != nil {
		log.Printf("Health check falhou: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Banco de dados indisponível",
		})
		RecordRequestEnd(pathHealth, "GET", http.StatusInternalServerError, float64(time.Since(start).Milliseconds()))
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"timestamp": time.Now().Format(time.RFC3339),
	})
	
	RecordRequestEnd(pathHealth, "GET", http.StatusOK, float64(time.Since(start).Milliseconds()))
}

func main() {
	// Inicializar o sistema de métricas
	prometheus.MustRegister(jokeRequestCount)

	// Inicializar o tracer
	tp, err := initTracer()
	if err != nil {
		log.Fatalf("Erro ao inicializar tracer: %v", err)
	}
	defer func() {
		if err := tp.Shutdown(context.Background()); err != nil {
			log.Printf("Erro ao desligar tracer: %v", err)
		}
	}()
	
	// Inicializar o meter para métricas
	mp, err := initMeter()
	if err != nil {
		log.Fatalf("Erro ao inicializar meter: %v", err)
	}
	defer func() {
		if err := mp.Shutdown(context.Background()); err != nil {
			log.Printf("Erro ao desligar meter: %v", err)
		}
	}()

	// Inicializar banco de dados
	if err := setupDatabase(); err != nil {
		log.Fatalf("Erro ao configurar banco de dados: %v", err)
	}
	defer db.Close()

	// Inicializar o gerador de números aleatórios
	rand.Seed(time.Now().UnixNano())

	// Configurar servidor HTTP
	r := setupRoutes()

	// Configurar porta
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: r,
	}

	// Iniciar o servidor em uma goroutine
	go func() {
		log.Printf("Servidor rodando na porta %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Erro ao iniciar servidor: %v", err)
		}
	}()

	// Configurar graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Desligando servidor...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Erro ao desligar servidor: %v", err)
	}
	log.Println("Servidor desligado com sucesso")
}
