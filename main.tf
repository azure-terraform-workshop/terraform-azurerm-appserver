resource "azurerm_resource_group" "module" {
  name     = "${local.module_name}-rg"
  location = var.location

  tags = {
    environment = "dev"
    version     = "v0.12.0"
  }
}

resource "azurerm_network_interface" "module" {
  name                = "${local.module_name}-nic${count.index}"
  location            = azurerm_resource_group.module.location
  resource_group_name = azurerm_resource_group.module.name
  count               = var.vm_count

  ip_configuration {
    name                          = "ipconfig-${count.index}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_machine" "module" {
  name                             = "${local.module_name}-vm${count.index}"
  location                         = azurerm_resource_group.module.location
  resource_group_name              = azurerm_resource_group.module.name
  network_interface_ids            = [azurerm_network_interface.module[count.index].id]
  count                            = var.vm_count
  vm_size                          = var.size
  delete_os_disk_on_termination    = var.delete_os_disk_on_termination
  delete_data_disks_on_termination = var.delete_data_disks_on_termination

  storage_image_reference {
    publisher = element(split(":", var.os), 0)
    offer     = element(split(":", var.os), 1)
    sku       = element(split(":", var.os), 2)
    version   = element(split(":", var.os), 3)
  }

  storage_os_disk {
    caching           = "ReadWrite"
    create_option     = "FromImage"
    name              = "${local.module_name}-vm${count.index}-os"
    managed_disk_type = var.disk_os_sku
  }

  storage_data_disk {
    create_option     = "Empty"
    lun               = 0
    name              = "${local.module_name}-vm${count.index}-data0"
    managed_disk_type = var.disk_data_sku
    disk_size_gb      = var.disk_data_size_gb
  }

  os_profile {
    computer_name  = "${local.module_name}vm${count.index}"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "dev"
  }
}

