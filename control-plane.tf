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
  vm_size                = "Standard_B1ms"

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
  name                = "secure-loadbalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "secure-public-ip"
    public_ip_address_id = azurerm_public_ip.secure_lb_public_ip[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "secure_lb_pool" {
  name                = "secure-backendpool"
  loadbalancer_id     = azurerm_lb.secure_lb.id
}

resource "azurerm_lb_probe" "secure_lb_probe" {
  name                = "secure-probe"
  loadbalancer_id     = azurerm_lb.secure_lb.id
  protocol            = "Tcp"
  port                = 6443
}

resource "azurerm_lb_rule" "secure_lb_rule" {
  name                            = "secure-rule"
  loadbalancer_id                 = azurerm_lb.secure_lb.id
  frontend_ip_configuration_name  = "secure-public-ip"
  protocol                        = "Tcp"
  frontend_port                   = 6443
  backend_port                    = 6443
  backend_address_pool_ids         = [azurerm_lb_backend_address_pool.secure_lb_pool.id]
  probe_id                        = azurerm_lb_probe.secure_lb_probe.id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_secure_lb_association" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  ip_configuration_name     = "internal"
  backend_address_pool_id   = azurerm_lb_backend_address_pool.secure_lb_pool.id
}

resource "azurerm_network_security_group" "secure_lb_nsg" {
  name                = "secure-lb-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAdminAccess"
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
  network_security_group_id = azurerm_network_security_group.secure_lb_nsg.id
}

resource "azurerm_network_interface_security_group_association" "master_internal_nsg_association" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.internal_nsg.id
}

# Public Load Balancer for HTTP/HTTPS Traffic
resource "azurerm_public_ip" "http_lb_public_ip" {
  name                 = "http-lb-public-ip"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  allocation_method    = "Static"
}

resource "azurerm_lb" "http_lb" {
  name                = "http-loadbalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "http-public-ip"
    public_ip_address_id = azurerm_public_ip.http_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "http_lb_pool" {
  name                = "http-backendpool"
  loadbalancer_id     = azurerm_lb.http_lb.id
}

resource "azurerm_lb_probe" "http_lb_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.http_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

resource "azurerm_lb_rule" "http_lb_rule" {
  name                            = "http-rule"
  loadbalancer_id                 = azurerm_lb.http_lb.id
  frontend_ip_configuration_name  = "http-public-ip"
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
  backend_address_pool_ids         = [azurerm_lb_backend_address_pool.http_lb_pool.id]
  probe_id                        = azurerm_lb_probe.http_lb_probe.id
}

resource "azurerm_lb_rule" "https_lb_rule" {
  name                            = "https-rule"
  loadbalancer_id                 = azurerm_lb.http_lb.id
  frontend_ip_configuration_name  = "http-public-ip"
  protocol                        = "Tcp"
  frontend_port                   = 443
  backend_port                    = 443
  backend_address_pool_ids         = [azurerm_lb_backend_address_pool.http_lb_pool.id]
  probe_id                        = azurerm_lb_probe.http_lb_probe.id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_http_lb_association" {
  count                     = var.master_count
  network_interface_id      = azurerm_network_interface.master_nic[count.index].id
  ip_configuration_name     = "internal"
  backend_address_pool_id   = azurerm_lb_backend_address_pool.http_lb_pool.id
}
