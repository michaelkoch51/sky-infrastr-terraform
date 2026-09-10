terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                      = "michael-terraform-state-2026"
    region                      = "ru-central1"
    key                         = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true  # ← отключает запрос к AWS STS
    skip_metadata_api_check     = true
    skip_s3_checksum            = true  # ← отключает проверку контрольных сумм
  }
}
