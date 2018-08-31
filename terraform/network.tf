## networking
resource "azurerm_network_interface" "prod" {
  name                      = "pNIC"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.prod.name}"
  network_security_group_id = "${azurerm_network_security_group.prod.id}"

  ip_configuration {
    name                          = "pIP"
    subnet_id                     = "${azurerm_subnet.prod.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.prod.id}"
  }

  tags {
    environment = "myLab"
  }
}

resource "azurerm_virtual_network" "prod" {
  name                = "pnetwork"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.prod.name}"
}

resource "azurerm_subnet" "prod" {
  name                 = "psubnet"
  resource_group_name  = "${azurerm_resource_group.prod.name}"
  virtual_network_name = "${azurerm_virtual_network.prod.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "prod" {
  name                         = "PublicIp"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.prod.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${random_string.fqdn.result}"

  tags {
    environment = "myLab"
  }
}

## this is for DNS
data "azurerm_resource_group" "test" {
  name = "macfun-app"
}

data "azurerm_dns_zone" "test" {
  name                = "test4me.xyz"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
}

resource "azurerm_dns_cname_record" "test" {
  name                = "myGrafana"
  zone_name           = "${data.azurerm_dns_zone.test.name}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  ttl                 = 3600
  record              = "${azurerm_public_ip.prod.fqdn}"
}