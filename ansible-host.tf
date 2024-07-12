resource "azurerm_network_interface" "ansible_nic" {
  name                = "${var.ansible_vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ansible_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "ansible_vm" {
  name                  = var.ansible_vm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.ansible_nic.id]
  vm_size               = "Standard_B1ms"

  storage_os_disk {
    name              = "${var.ansible_vm_name}-osdisk"
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
    computer_name  = var.ansible_vm_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_security_group" "ansible_nsg" {
  name                = "ansible-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAnsibleSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "ansible_nsg_association" {
  network_interface_id      = azurerm_network_interface.ansible_nic.id
  network_security_group_id = azurerm_network_security_group.ansible_nsg.id
}
