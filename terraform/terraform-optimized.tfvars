# Configuração terraform.tfvars para VPS com recursos limitados
# Copie este arquivo para terraform.tfvars e ajuste conforme necessário

# Caminho para o arquivo kubeconfig
kube_config_path = "~/.kube/config"

# Namespace para os serviços
namespace = "observability"

# Otimizar para VPS com recursos limitados (2 cores, 8GB RAM)
optimize_resources = true

# Configurações do Grafana
grafana_enabled = true
grafana_service_type = "ClusterIP"  # Use ClusterIP para acessar via Ingress
expose_grafana = false  # Não expor via NodePort, usar Ingress
grafana_admin_password = "admin@123"  # Senha atualizada para maior segurança

# Criar recursos de Ingress
create_ingress = true

# Configuração do cert-manager
cert_manager_version = "v1.13.1"
letsencrypt_email = "leandrogamedesigner@gmail.com"  # Email atualizado
domain_name = "www.labk3s.online"
