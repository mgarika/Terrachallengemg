output "resource_group_name" {
  value = azurerm_resource_group.TFchallenge
}

output "public_ip_address" {
  value = "azurerm_linux_virtual_machine.web-vm"
}