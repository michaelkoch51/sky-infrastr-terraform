# ============================================================
# Container Registry — реестр для хранения Docker-образов
# ============================================================
resource "yandex_container_registry" "app_registry" {
  name      = "app-registry"
  folder_id = var.folder_id
}

# Репозиторий для приложения
resource "yandex_container_repository" "app_repo" {
  name = "${yandex_container_registry.app_registry.id}/app"
}
