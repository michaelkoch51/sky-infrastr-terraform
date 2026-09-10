# ============================================================
# MySQL кластер в Yandex Managed Service
# ============================================================
resource "yandex_mdb_mysql_cluster" "app_mysql" {
  name        = "app-mysql-cluster"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.app_net.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.micro"  # 2 vCPU, 8 GB RAM (минимальный)
    disk_type_id       = "network-ssd"
    disk_size          = 10          # GB
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.app_subnet_a.id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.app_subnet_b.id
  }

  security_group_ids = [yandex_vpc_security_group.mysql_sg.id]
}

# ============================================================
# База данных
# ============================================================
resource "yandex_mdb_mysql_database" "app_db" {
  cluster_id = yandex_mdb_mysql_cluster.app_mysql.id
  name       = var.db_name
}

# ============================================================
# Пользователь БД
# ============================================================
resource "yandex_mdb_mysql_user" "app_user" {
  cluster_id = yandex_mdb_mysql_cluster.app_mysql.id
  name       = var.db_user
  password   = var.db_password

  permission {
    database_name = yandex_mdb_mysql_database.app_db.name
    roles         = ["ALL"]
  }
}
