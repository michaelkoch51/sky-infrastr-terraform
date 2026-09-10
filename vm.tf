# ============================================================
# Виртуальная машина для web-приложения
# ============================================================
# ============================================================
# Сервисный аккаунт для VM (для доступа к Container Registry)
# ============================================================
resource "yandex_iam_service_account" "vm_sa" {
  name        = "vm-sa"
  description = "Service account for VM to pull images from Container Registry"
}

# Права на чтение образов из Registry
resource "yandex_container_registry_iam_binding" "vm_sa_puller" {
  registry_id = yandex_container_registry.app_registry.id
  role        = "container-registry.images.puller"

  members = [
    "serviceAccount:${yandex_iam_service_account.vm_sa.id}",
  ]
}
resource "yandex_compute_instance" "app_vm" {
  name               = "app-vm"
  platform_id        = "standard-v3"
  zone               = var.default_zone
  service_account_id = yandex_iam_service_account.vm_sa.id
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.app_subnet_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.vm_sg.id]
  }

  metadata = {
    user-data = file("${path.module}/cloud-init.yaml")
    ssh-keys  = "${var.vm_user}:${file(var.ssh_public_key_path)}"
  }

  depends_on = [yandex_mdb_mysql_cluster.app_mysql]
}
