variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Region de AWS para el despliegue"
}

variable "domain_name" {
  type        = string
  default     = "myxperiences.org"
  description = "Dominio principal de la empresa"
}

variable "hosted_zone_id" {
  type        = string
  default     = "Z0414572XT7DT8FKH56B"
  description = "Existing public Route53 hosted zone for domain_name (do not create a second zone)"
}

# Usuarios de las Bases de Datos
variable "db_user_myxperiences" {
  type        = string
  default     = "user_myxperiences"
  description = "Usuario maestro para la base de datos de Myxperiences"
}

variable "db_user_lanapp" {
  type        = string
  default     = "user_lanapp"
  description = "Usuario maestro para la base de datos de Lanapp"
}

variable "db_user_admin" {
  type        = string
  default     = "user_admin"
  description = "Usuario maestro para la base de datos de Administracion"
}

# Contrasenas de las Bases de Datos
variable "db_password_myxperiences" {
  type        = string
  description = "Password de la base de datos de Myxperiences"
}

variable "db_password_lanapp" {
  type        = string
  description = "Password de la base de datos de Lanapp"
}

variable "db_password_admin" {
  type        = string
  description = "Password de la base de datos de Administracion"
}

variable "tags_base" {
  type = map(string)
  default = {
    creator = "terraform"
    name    = "myxperiences"
  }
}

variable "lanapp_db_url" {
  type        = string
  description = "URL de la base de datos de Lanapp"
}
