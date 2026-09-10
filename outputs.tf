output "vm_public_ip" {
  value       = yandex_compute_instance.app_vm.network_interface[0].nat_ip_address
  description = "Public IP of the VM"
}

output "mysql_cluster_id" {
  value       = yandex_mdb_mysql_cluster.app_mysql.id
  description = "MySQL cluster ID"
}

output "registry_id" {
  value       = yandex_container_registry.app_registry.id
  description = "Container Registry ID"
}
