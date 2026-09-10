# ============================================================
# VPC — Virtual Private Cloud
# ============================================================
resource "yandex_vpc_network" "app_net" {
  name        = "app-network"
  description = "Network for web application"
}

# ============================================================
# Подсети
# ============================================================
resource "yandex_vpc_subnet" "app_subnet_a" {
  name           = "app-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.app_net.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "app_subnet_b" {
  name           = "app-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.app_net.id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

# ============================================================
# Security Group для VM: SSH (22), HTTP (80), HTTPS (443)
# ============================================================
resource "yandex_vpc_security_group" "vm_sg" {
  name       = "vm-security-group"
  network_id = yandex_vpc_network.app_net.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# Security Group для MySQL: доступ только из подсетей приложения
# ============================================================
resource "yandex_vpc_security_group" "mysql_sg" {
  name       = "mysql-security-group"
  network_id = yandex_vpc_network.app_net.id

  ingress {
    description    = "MySQL from app subnets"
    protocol       = "TCP"
    port           = 3306
    v4_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
