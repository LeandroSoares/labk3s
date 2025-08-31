FROM golang:1.23-alpine AS builder

# Instalar dependências de compilação
RUN apk add --no-cache gcc git musl-dev

# Configurar diretório de trabalho
WORKDIR /app

# Copiar os arquivos go.mod e go.sum
COPY go.mod go.sum ./

# Baixar dependências
RUN go mod download

# Copiar o código fonte
COPY . .

# Compilar a aplicação
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -ldflags "-s -w" -o joke-api .

# Segunda etapa de compilação para uma imagem mais limpa
FROM alpine:3.22

# Instalar dependências de runtime, criar diretório para o banco de dados, configurar permissões e criar usuário não-root
RUN apk --no-cache add ca-certificates sqlite tzdata && \
    mkdir -p /data && \
    chmod 755 /data && \
    adduser -D -g '' appuser && \
    chown -R appuser:appuser /data

# Configurar diretório de trabalho
WORKDIR /app

# Copiar o binário compilado da etapa de builder
COPY --from=builder /app/joke-api .

# Definir permissões adequadas
RUN chmod +x ./joke-api && \
    chown -R appuser:appuser /app

# Mudar para o usuário não-root
USER appuser

# Configurar variáveis de ambiente
ENV GO_ENV=production
ENV PORT=3000
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://tempo:4318"
ENV OTEL_SERVICE_NAME="joke-api-go"

# Expor a porta
EXPOSE 3000

# Definir volume para persistência do SQLite
VOLUME ["/data"]

# Comando para iniciar a aplicação
CMD ["./joke-api"]
