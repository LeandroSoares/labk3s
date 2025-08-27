# Solução Temporária para o Problema de Permissão no Frontend

## Problema

O frontend continua apresentando erros de permissão mesmo após as alterações no Dockerfile:

```
[error] 22#22: *1 "/usr/share/nginx/html/index.html" is forbidden (13: Permission denied)
```

## Diagnóstico

Após investigação no ambiente Kubernetes, identificamos que:

1. A nova imagem Docker com permissões corrigidas ainda não foi construída pela pipeline CI/CD
2. A configuração `readOnlyRootFilesystem: true` no pod continua causando problemas de permissão

## Solução Temporária

Como solução temporária, desabilitamos a configuração `readOnlyRootFilesystem: true` nos manifestos Kubernetes:

```yaml
securityContext:
  # readOnlyRootFilesystem: true # Temporariamente desabilitado para resolver problema de permissão
  runAsNonRoot: true
  runAsUser: 101
  allowPrivilegeEscalation: false
```

## Plano para Solução Permanente

1. Aguardar a execução da pipeline CI/CD para reconstruir a imagem com as permissões corrigidas
2. Quando a nova imagem estiver disponível, reativar `readOnlyRootFilesystem: true` para melhorar a segurança
3. Verificar que o pod funciona corretamente com a nova imagem e configurações de segurança reativadas

## Como Verificar a Solução

Depois de aplicar esta alteração temporária:

```bash
kubectl apply -k k8s/app/
kubectl rollout restart deployment/frontend -n joke-app
kubectl get pods -n joke-app
```

Você deve ver o pod do frontend em estado "Running" com todos os contêineres prontos (1/1).
