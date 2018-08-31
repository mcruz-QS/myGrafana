resource "azurerm_resource_group" "prod" {
  name     = "demo-Grafana"
  location = "${var.azure_location}"

  tags {
    environment = "myLab"
  }
}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "azurerm_network_security_group" "prod" {
  name                = "NSG"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.prod.name}"

     security_rule {
        name                       = "default-allow-ssh"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        source_address_prefix      = "${var.austin_ip}"
        destination_port_range     = "22"
        destination_address_prefix = "*"
  }
    security_rule {
            name                       = "HTTP"
            priority                   = 1002
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "80"
            source_address_prefix      = "${var.austin_ip}"
            destination_address_prefix = "*"
        }
    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "${var.austin_ip}"
        destination_address_prefix = "*"
    }
  tags {
    environment = "myLab"
  }
}

## Computer

resource "azurerm_virtual_machine" "myterraformvm" {
  count = "${var.quantity}"
  name                  = "myVMtest-${count.index + 1}"
  location              = "eastus"
  resource_group_name   = "${azurerm_resource_group.prod.name}"
  network_interface_ids = ["${azurerm_network_interface.prod.id}"]
  vm_size               = "Standard_B2s"

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "myvm"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    #  disable_password_authentication = false
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
  }

  tags {
    environment = "myLab"
  }
}

data "azurerm_public_ip" "prod" {
  name                = "${azurerm_public_ip.prod.name}"
  resource_group_name = "${azurerm_resource_group.prod.name}"
}

output "public_ip_address" {
  value = "${data.azurerm_public_ip.prod.ip_address}"
}

output "ssh_command" {
  value = "ssh azureuser@${data.azurerm_public_ip.prod.ip_address}"
}

## Random 8
resource "random_id" "prod" {
  keepers = {
    resource_group = "${azurerm_resource_group.prod.name}"
  }

  byte_length = 8
}
