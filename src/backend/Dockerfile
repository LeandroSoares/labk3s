FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

# Criar diretório para o banco de dados e configurar permissões
RUN mkdir -p /data && chown -R node:node /data

# Definir volume para persistência do SQLite
VOLUME ["/data"]

# Executar como usuário não-root
USER node

CMD ["node", "server.js"]
