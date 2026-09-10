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
