# ============================================================
# Виртуальная машина для web-приложения
# ============================================================
resource "yandex_compute_instance" "app_vm" {
  name        = "app-vm"
  platform_id = "standard-v3"
  zone        = var.default_zone

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
