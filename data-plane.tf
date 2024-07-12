resource "azurerm_network_interface" "worker_nic" {
  count               = var.worker_count
  name                = "${var.worker_vm_name}-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.worker_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "worker_vm" {
  count                 = var.worker_count
  name                  = "${var.worker_vm_name}-${count.index + 1}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]
  vm_size               = "Standard_B1ms"

  storage_os_disk {
    name              = "${var.worker_vm_name}-${count.index + 1}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "suse"
    offer     = "opensuse-leap-15-5"
    sku       = "gen1"
    version   = "latest"
  }


  os_profile {
    computer_name  = "${var.worker_vm_name}-${count.index + 1}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface_security_group_association" "worker_internal_nsg_association" {
  count                     = var.worker_count
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.internal_nsg.id
}
