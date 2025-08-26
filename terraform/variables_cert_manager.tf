# Variáveis adicionais para cert-manager
variable "cert_manager_version" {
  description = "Versão do cert-manager"
  type        = string
  default     = "v1.13.1"
}

variable "letsencrypt_email" {
  description = "Email para registro no Let's Encrypt"
  type        = string
  default     = "seu-email@exemplo.com"  # Substitua pelo seu email real
}

variable "domain_name" {
  description = "Nome de domínio para o certificado"
  type        = string
  default     = "www.labk3s.online"
}
