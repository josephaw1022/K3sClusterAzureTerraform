output "master_vm_private_ip" {
  value = azurerm_virtual_machine.master_vm.private_ip_address
}

output "worker_vm_private_ip" {
  value = azurerm_virtual_machine.worker_vm.private_ip_address
}

output "ansible_vm_public_ip" {
  value = azurerm_virtual_machine.ansible_vm.private_ip_address
}

output "secure_lb_public_ip" {
  value = azurerm_public_ip.secure_lb_public_ip.ip_address
}

output "backup_storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "backup_storage_container_name" {
  value = azurerm_storage_container.backup_container.name
}
