variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder ID"
}

variable "default_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "sa_key_file" {
  type        = string
  description = "Path to service account authorized key file"
  default     = "/Users/michaelkochnev/sa-key.json"
}

variable "db_name" {
  type        = string
  description = "MySQL database name"
  default     = "app_db"
}

variable "db_user" {
  type        = string
  description = "MySQL user name"
  default     = "app_user"
}

variable "db_password" {
  type        = string
  description = "MySQL user password"
  sensitive   = true
}
variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key"
  default     = "/Users/michaelkochnev/.ssh/id_ed25519.pub"
}

variable "vm_user" {
  type        = string
  description = "VM admin username"
  default     = "ubuntu"
}

variable "vm_image_id" {
  type        = string
  description = "Ubuntu 22.04 LTS image ID"
  default     = "fd8vmcue7aajpmeo39kk"
}
