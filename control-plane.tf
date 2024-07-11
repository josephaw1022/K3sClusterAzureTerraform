resource "azurerm_network_interface" "master_nic" {
  count               = var.master_count
  name                = "${var.master_vm_name}-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.master_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "master_vm" {
  count                  = var.master_count
  name                   = "${var.master_vm_name}-${count.index + 1}"
  location               = var.location
  resource_group_name    = azurerm_resource_group.main.name
  network_interface_ids  = [azurerm_network_interface.master_nic[count.index].id]
  vm_size                = "Standard_DS1_v2"

  storage_os_disk {
    name              = "${var.master_vm_name}-${count.index + 1}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "SUSE"
    offer     = "openSUSE-Leap"
    sku       = "15.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.master_vm_name}-${count.index + 1}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_public_ip" "secure_lb_public_ip" {
  count                = var.master_count
  name                 = "secure-lb-public-ip-${count.index + 1}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  allocation_method    = "Static"
}

resource "azurerm_lb" "secure_lb" {
  count               = var.master_count
  name                = "secure-loadbalancer-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "secure-public-ip-${count.index + 1}"
    public_ip_address_id = azurerm_public_ip.secure_lb_public_ip[count.index].id
  }
}

resource "azurerm_lb_backend_address_pool" "secure_lb_pool" {
  count               = var.master_count
  name                = "secure-backendpool-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.secure_lb[count.index].id
}

resource "azurerm_lb_probe" "secure_lb_probe" {
  count               = var.master_count
  name                = "secure-probe-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.secure_lb[count.index].id
  protocol            = "Tcp"
  port                = 6443
}

resource "azurerm_lb_rule" "secure_lb_rule" {
  count                           = var.master_count
  name                            = "secure-rule-${count.index + 1}"
  resource_group_name             = azurerm_resource_group.main.name
  loadbalancer_id                 = azurerm_lb.secure_lb[count.index].id
  frontend_ip_configuration_name  = "secure-public-ip-${count.index + 1}"
  protocol                        = "Tcp"
  frontend_port                   = 6443
  backend_port                    = 6443
  backend_address_pool_id         = azurerm_lb_backend_address_pool.secure_lb_pool[count.index].id
  probe_id                        = azurerm_lb_probe.secure_lb_probe[count.index].id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_secure_lb_association" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  ip_configuration_name     = "internal"
  backend_address_pool_id   = azurerm_lb_backend_address_pool.secure_lb_pool[count.index].id
}

resource "azurerm_network_security_group" "secure_lb_nsg" {
  count               = var.master_count
  name                = "secure-lb-nsg-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAdminAccess-${count.index + 1}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "secure_lb_nsg_association" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.secure_lb_nsg[count.index].id
}

resource "azurerm_network_interface_security_group_association" "master_internal_nsg_association" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.internal_nsg.id
}
