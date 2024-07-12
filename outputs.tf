output "master_vm_private_ip" {
  value = [for i in range(var.master_count) : azurerm_network_interface.master_nic[i].private_ip_address]
}

output "worker_vm_private_ip" {
  value = [for i in range(var.worker_count) : azurerm_network_interface.worker_nic[i].private_ip_address]
}


output "secure_lb_public_ip" {
  value = azurerm_public_ip.secure_lb_public_ip[0].ip_address
}

output "backup_storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "backup_storage_container_name" {
  value = azurerm_storage_container.backup_container.name
}
