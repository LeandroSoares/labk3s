# Correção do Problema de Permissão no Frontend

## Problema Identificado

O frontend estava falhando devido a um erro de permissão nos arquivos HTML:
```
[error] 22#22: *1 "/usr/share/nginx/html/index.html" is forbidden (13: Permission denied)
```

## Causa Raiz

**Permissões incorretas no Dockerfile**: Estávamos usando `chmod -R 644 /usr/share/nginx/html` que define as mesmas permissões para arquivos E diretórios, mas diretórios precisam ter permissão de execução (755).

O problema ocorre porque:
1. O container está configurado com `readOnlyRootFilesystem: true` (boa prática de segurança)
2. O nginx está executando como usuário não-root (101)
3. Os diretórios precisam ter permissão de execução (755) para o nginx conseguir acessar os arquivos dentro deles

## Solução Implementada

### Correção no Dockerfile

Modificamos o Dockerfile para aplicar permissões corretas:

```dockerfile
# Antes (problema)
RUN chmod -R 644 /usr/share/nginx/html \
    # outros comandos...

# Depois (solução)
RUN chmod -R 755 /usr/share/nginx/html \
    && find /usr/share/nginx/html -type f -exec chmod 644 {} \; \
    # outros comandos...
```

Mudanças realizadas:
1. Aplicamos `chmod -R 755` para dar permissão de execução aos diretórios
2. Usamos `find` para aplicar 644 apenas aos arquivos, não aos diretórios

Esta abordagem permite:
- Manter a segurança do `readOnlyRootFilesystem: true`
- Continuar executando como usuário não-root (nginx)
- Garantir que o Nginx possa acessar os arquivos HTML

## Como Aplicar a Solução

### Pipeline CI/CD

O deploy desta alteração segue o fluxo padrão de CI/CD:

1. **Commit e Push**: As alterações já foram commitadas no repositório
2. **Build pela Pipeline**: A pipeline CI/CD constrói a imagem Docker com as novas configurações
3. **Deploy pela Pipeline**: A pipeline realiza o deploy no cluster Kubernetes

> **Importante**: Não construímos imagens localmente. Todas as imagens são construídas e publicadas pela pipeline CI/CD.

### Verificação
```bash
kubectl get pods -n joke-app
kubectl logs -n joke-app deployment/frontend
```

Você deve ver o pod do frontend em estado "Running" sem erros de permissão nos logs.

## Aprendizado

Quando trabalhamos com containers que executam como usuário não-root e têm o sistema de arquivos somente leitura, precisamos garantir que:

1. Diretórios tenham permissão 755 (rwxr-xr-x) - para permitir navegação
2. Arquivos tenham permissão 644 (rw-r--r--) - para permitir leitura
3. Os arquivos e diretórios pertençam ao usuário correto (chown)
