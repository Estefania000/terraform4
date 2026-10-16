variable "loc" {
  description = "Región"
  type        = string
  default     = "chilecentral"
}

variable "rg_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-tf4-chile-001"
}

variable "tags" {
  type = map(string)
  default = {
    env     = "prod"
    managed = "terraform"
    owner   = "estefania"
  }
}