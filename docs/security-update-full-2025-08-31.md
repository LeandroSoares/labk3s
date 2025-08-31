# Atualização de Segurança - 31 de Agosto de 2025

## Vulnerabilidades Corrigidas

Foram corrigidas várias vulnerabilidades de segurança no backend Go do projeto:

### Vulnerabilidades Críticas:
1. **golang.org/x/crypto/ssh**: Possibilidade de bypass de autorização devido ao uso incorreto do `ServerConfig.PublicKeyCallback`
   - Atualizado para versão 0.41.0

### Vulnerabilidades Altas:
1. **database/sql**: Condição de corrida em Postgres Scan
2. **encoding/gob**: Risco de panic devido a estouro de pilha com estruturas profundamente aninhadas
3. **golang-protobuf**: Loop infinito em protojson.Unmarshal quando unmarshal de certos formatos JSON inválidos
4. **golang.org/x/crypto/ssh**: Denial of Service no Key Exchange
5. **cross-spawn**: Vulnerabilidade de negação de serviço baseada em expressão regular (frontend)

### Vulnerabilidades Médias:
1. **net/http**: Cabeçalhos sensíveis não limpos em redirecionamentos entre origens
2. **net/http**: Smuggling de solicitações devido à aceitação de dados chunked inválidos
3. **crypto/internal/nistec**: Side-channel de timing para P-256 em ppc64le
4. **O_CREATE|O_EXCL**: Tratamento inconsistente entre Unix e Windows
5. **crypto/x509**: Uso de Zone IDs IPv6 pode ignorar restrições de nome URI
6. **golang.org/x/net/html**: Neutralização incorreta de entrada durante geração de página web
7. **golang.org/x/net/proxy**: Bypass de proxy HTTP usando IPv6 Zone IDs

## Dependências Atualizadas

### Backend Go:
- Go: 1.23.0 → 1.24.0
- golang.org/x/crypto: v0.21.0 → v0.41.0
- golang.org/x/net: v0.42.0 → v0.43.0
- google.golang.org/protobuf: v1.32.0 → v1.36.8
- google.golang.org/grpc: v1.61.1 → v1.75.0
- github.com/gin-gonic/gin: v1.9.1 → v1.10.1
- github.com/mattn/go-sqlite3: v1.14.22 → v1.14.32
- github.com/prometheus/client_golang: v1.19.0 → v1.23.0
- go.opentelemetry.io/otel: v1.24.0 → v1.38.0

### Frontend JavaScript:
- cross-spawn: atualizado para a versão mais recente
- brace-expansion: atualizado para a versão mais recente

## Próximos Passos

1. Continuar monitorando novas vulnerabilidades de segurança
2. Implementar verificações de segurança automatizadas para dependências
3. Estabelecer um cronograma regular de atualizações de segurança

## Impacto

Estas atualizações não afetam a funcionalidade do aplicativo, mas melhoram significativamente sua postura de segurança.

## Observações Adicionais

- A vulnerabilidade de baixa gravidade **brace-expansion** no frontend foi corrigida atualizando a dependência para a versão mais recente.
- As vulnerabilidades do frontend (cross-spawn e brace-expansion) são dependências transitivas que não aparecem diretamente no package.json, mas foram atualizadas explicitamente.
- O pacote **protobuf** foi mantido na versão 1.36.8, que é a mais recente disponível e contém as correções para a vulnerabilidade reportada.
