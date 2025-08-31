# Atualização de Segurança - golang.org/x/crypto

## Problema
Foi detectada uma vulnerabilidade crítica de segurança no pacote `golang.org/x/crypto/ssh` relacionada ao uso incorreto do `ServerConfig.PublicKeyCallback`, que pode causar um bypass de autorização.

## Solução Implementada
- Atualizamos o pacote `golang.org/x/crypto` da versão 0.21.0 para 0.41.0, que contém a correção para esta vulnerabilidade.
- Atualizamos a versão do Go de 1.21 para 1.23 em todos os Dockerfiles e no workflow do GitHub Actions.
- Atualizamos outras dependências relacionadas para garantir a compatibilidade.

## Verificação
- A compilação local foi testada e está funcionando corretamente com as novas dependências.
- O workflow de CI/CD do GitHub foi atualizado para usar a versão mais recente do Go.

## Impacto
Esta atualização não tem impacto na funcionalidade do aplicativo, pois não estamos usando diretamente o pacote `golang.org/x/crypto/ssh`. A dependência é transitiva e vem de outras bibliotecas que estamos usando.

## Próximos Passos
1. Monitorar o build do CI para garantir que tudo está funcionando corretamente com as novas versões
2. Configurar verificações de segurança automatizadas para identificar vulnerabilidades como esta no futuro
