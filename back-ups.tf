resource "azurerm_storage_account" "backup" {
  name                     = "backupstorageacc"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "backup_container" {
  name                  = "backupcontainer"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "storage_container_name" {
  value = azurerm_storage_container.backup_container.name
}
