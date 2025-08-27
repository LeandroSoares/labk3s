FROM node:18-alpine

# Criar diretório para o banco de dados e configurar permissões 
RUN mkdir -p /data && chown -R node:node /data

WORKDIR /app

# Adicionar pacote de segurança para análise de dependências
RUN apk add --no-cache dumb-init

# Copiar arquivos de projeto e instalar dependências
COPY --chown=node:node package*.json ./
RUN npm install --production && npm cache clean --force

# Copiar código da aplicação
COPY --chown=node:node . .

# Configurar permissões adequadas
RUN chmod -R 755 /app \
    && chmod -R 777 /data

# Definir variáveis de ambiente para OpenTelemetry
ENV NODE_OPTIONS="--require ./tracing.js"
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://tempo:4318/v1/traces"
ENV OTEL_SERVICE_NAME="joke-api"

# Definir volume para persistência do SQLite
VOLUME ["/data"]

# Executar como usuário não-root
USER node

EXPOSE 3000

# Usar dumb-init como entrypoint para lidar corretamente com sinais
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
