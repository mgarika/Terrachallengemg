resource "azurerm_resource_group" "TFchallenge" {
  name     = "Mgarika-Sandbox"
  location = "East US"
}

resource "azurerm_virtual_network" "testmg-vn" {
  name                = "mgtest-network"
  resource_group_name = azurerm_resource_group.TFchallenge.name
  location            = azurerm_resource_group.TFchallenge.location
  address_space       = ["10.123.0.0/16"]
}

resource "azurerm_subnet" "testmg-subnet1" {
  name                 = "Web-subnet"
  resource_group_name  = azurerm_resource_group.TFchallenge.name
  virtual_network_name = azurerm_virtual_network.testmg-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_subnet" "testmg-subnet2" {
  name                 = "Data-subnet"
  resource_group_name  = azurerm_resource_group.TFchallenge.name
  virtual_network_name = azurerm_virtual_network.testmg-vn.name
  address_prefixes     = ["10.123.2.0/24"]
}

resource "azurerm_subnet" "testmg-subnet3" {
  name                 = "Jumpbox-subnet"
  resource_group_name  = azurerm_resource_group.TFchallenge.name
  virtual_network_name = azurerm_virtual_network.testmg-vn.name
  address_prefixes     = ["10.123.3.0/24"]
}

resource "azurerm_public_ip" "testmg_public_ip" {
  name                = "testmg_public_ip"
  resource_group_name = azurerm_resource_group.TFchallenge.name
  location            = azurerm_resource_group.TFchallenge.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "testmg-nic" {
  name                = "testmg-nic"
  resource_group_name = azurerm_resource_group.TFchallenge.name
  location            = azurerm_resource_group.TFchallenge.location
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.testmg-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.testmg_public_ip.id
  }

  depends_on = [ 
     azurerm_virtual_network.testmg-vn,
     azurerm_public_ip.testmg_public_ip
   ]
}



resource "azurerm_network_security_group" "testmg-sg" {
  name                = "testmg-sg"
  resource_group_name = azurerm_resource_group.TFchallenge.name
  location            = azurerm_resource_group.TFchallenge.location

}

resource "azurerm_network_security_rule" "testmg-dev-rule" {
  name                        = "Testmg-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.TFchallenge.name
  network_security_group_name = azurerm_network_security_group.testmg-sg.name
}
resource "azurerm_linux_virtual_machine" "web-vm" {
  name                 = "Web-linux-vm"
  resource_group_name  = azurerm_resource_group.TFchallenge.name
  location             = azurerm_resource_group.TFchallenge.location
  size                 = "Standard_B1ms"
  admin_username       = "linuxuser"
  admin_password = "Coretek123$"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.testmg-nic.id]

  os_disk {
    name                 = "WebOSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
resource "azurerm_network_interface" "vm3-nic" {
  name                = "Jumpbox-nic"
  resource_group_name = azurerm_resource_group.TFchallenge.name
  location            = azurerm_resource_group.TFchallenge.location
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.testmg-subnet3.id
    private_ip_address_allocation = "Dynamic"
    
  }

  depends_on = [ 
     azurerm_virtual_network.testmg-vn
   ]
}
resource "azurerm_windows_virtual_machine" "Jumpbox-VM" {
  name                = "Jumpbox-vm"
  resource_group_name  = azurerm_resource_group.TFchallenge.name
  location             = azurerm_resource_group.TFchallenge.location
  size                = "Standard_B1ms"
  admin_username      = "adminuser"
  admin_password      = "Coretek123$"
  network_interface_ids = [azurerm_network_interface.vm3-nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter"
    version   = "latest"
  }

}
