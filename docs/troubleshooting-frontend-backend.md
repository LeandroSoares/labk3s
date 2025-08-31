# Documentação das Alterações para Resolver Problemas de Comunicação Frontend-Backend

## Problema Identificado
O frontend estava apresentando falhas ao iniciar porque não conseguia resolver o nome do serviço de backend durante a inicialização.

Erro específico: 
```
[emerg] 1#1: host not found in upstream "backend-service.joke-app.svc.cluster.local" in /etc/nginx/conf.d/default.conf:15
```

## Soluções Implementadas

### 1. Frontend (k8s/app/frontend.yaml)

- **Adição de Init Container**:
  - Adicionado um container de inicialização (busybox) que aguarda até que o DNS possa resolver o nome do serviço backend antes de iniciar o container principal
  - Isso garante que o frontend só inicie quando o backend estiver disponível

- **Adição de Readiness Probe**:
  - Configurada uma verificação de prontidão para o container do frontend
  - Isso garante que o frontend só receba tráfego quando estiver totalmente pronto

- **Melhorias na Configuração do Nginx**:
  - Aprimorada a configuração do proxy para o backend com timeouts adequados
  - Utilização de variáveis para o serviço de backend para melhor resolução de nomes

### 2. Backend (k8s/app/backend-go.yaml)

- **Adição de Probes**:
  - Configuradas readiness e liveness probes para o container do backend
  - Isso ajuda o Kubernetes a monitorar a saúde do serviço e reiniciá-lo se necessário

### 3. Código Backend (src/backend-go/main.go)

- **Adição de Endpoint de Health Check**:
  - Implementado um endpoint `/health` que verifica:
    - Conectividade com o banco de dados
    - Status geral da aplicação
  - Este endpoint é utilizado pelas probes do Kubernetes

## Como Aplicar as Alterações

1. **Reconstruir a Imagem do Backend Go**:
   ```bash
   cd src/backend-go
   docker build -t <DOCKER_USERNAME>/joke-backend-go:<VERSION> .
   docker push <DOCKER_USERNAME>/joke-backend-go:<VERSION>
   ```

2. **Aplicar os Manifestos no Kubernetes**:
   ```bash
   kubectl apply -f k8s/app/backend-go.yaml -f k8s/app/frontend.yaml
   ```

3. **Verificar a Implantação**:
   ```bash
   kubectl get pods -n joke-app
   kubectl describe pod -n joke-app -l app=frontend
   kubectl describe pod -n joke-app -l app=backend-go
   ```

## Benefícios das Alterações

- **Maior Resiliência**: O sistema agora lida melhor com dependências entre serviços
- **Melhor Monitoramento**: As health probes permitem que o Kubernetes detecte e corrija problemas automaticamente
- **Inicialização Controlada**: O frontend aguarda a disponibilidade do backend antes de iniciar
